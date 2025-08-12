# Implementación de Reverse Geocoding Asíncrono - Leagend

## Resumen

Se ha implementado un sistema de reverse geocoding asíncrono que detecta automáticamente cuando un usuario logueado tiene coordenadas pero no país/ciudad, y utiliza la API de Mapbox para obtener esta información y actualizar tanto la UI como la base de datos.

## Funcionalidad

### **Cuándo se Activa**
- Usuario está logueado (`user_signed_in? = true`)
- No se ha ejecutado ya en esta sesión (`leagend.geo_revgeo_done` no está en sessionStorage)
- Existe el contenedor del header (`#leagend-header-location`)
- No hay country/city ya configurados en el header
- Hay coordenadas válidas disponibles (lat/lng)

### **Flujo de Ejecución**
1. **Detección automática** al cargar la página
2. **Verificación de condiciones** antes de ejecutar
3. **Llamada a Mapbox API** con timeout de 2.5 segundos
4. **Actualización inmediata de UI** si es exitoso
5. **Persistencia en backend** vía PATCH `/geo/update`
6. **Prevención de duplicados** con flag en sessionStorage

## Implementación Técnica

### **1. Variables JavaScript en Layout**
```erb
<% if user_signed_in? %>
  <script nonce="<%= content_security_policy_nonce %>">
    window.LEAGEND_USER_SIGNED_IN = true;
    window.LEAGEND_USER_LAT = '<%= current_user.current_latitude %>';
    window.LEAGEND_USER_LNG = '<%= current_user.current_longitude %>';
  </script>
<% else %>
  <script nonce="<%= content_security_policy_nonce %>">
    window.LEAGEND_USER_SIGNED_IN = false;
  </script>
<% end %>
```

### **2. Contenedor con ID Estable**
```erb
<span id="leagend-header-location">
  <% location = current_user_location %>
  <% if has_location_data?(location) %>
    Ubicación: <%= format_location_display(location) %>
  <% else %>
    <em>Detectando ubicación...</em>
  <% end %>
</span>
```

### **3. Script de Reverse Geocoding**
- **Ubicación:** Justo antes de `</body>`
- **Nonce CSP:** Incluye `nonce="<%= content_security_policy_nonce %>"`
- **Tamaño:** ~80 líneas de código
- **Timeout:** 2.5 segundos máximo
- **Fallback:** No rompe la UI si falla

## Sistema de Backfill de Ubicación

### **Objetivo**
Reutilizar la ubicación cacheada de invitados (cookies/localStorage) para usuarios logueados sin ubicación persistida, mejorando la UX inmediata.

### **Implementación**

#### **1. Server-Side Backfill (ApplicationController)**
```ruby
before_action :backfill_user_location_from_cookies

def backfill_user_location_from_cookies
  return unless user_signed_in?
  return unless current_user.current_country.blank? || current_user.current_city.blank?
  return unless has_guest_location_cookies?
  
  # Actualizar solo campos en blanco desde cookies de invitados
  changes = {}
  changes[:current_country] = guest_country_from_cookie if current_user.current_country.blank?
  changes[:current_city] = guest_city_from_cookie if current_user.current_city.blank?
  changes[:current_country_code] = guest_country_code_from_cookie if current_user.current_country_code.blank?
  
  current_user.update_columns(changes) if changes.any?
end
```

#### **2. Client-Side Fallback (Layout)**
```javascript
// Script de fallback robusto para localStorage
if (user_signed_in? && current_user.current_city.blank? && current_user.current_country.blank?) {
  const city = localStorage.getItem('leagend.city');
  const country = localStorage.getItem('leagend.country');
  
  if (city && country) {
    // 1. Actualizar header inmediatamente
    locationSpan.innerHTML = `Ubicación: ${city}, ${country}`;
    
    // 2. Enviar PATCH para persistir (sin coordenadas)
    fetch('/geo/update', {
      method: 'PATCH',
      body: JSON.stringify({ city, country, country_code })
    });
    
    // 3. Marcar como completado
    sessionStorage.setItem('leagend.backfill_done', '1');
  }
}
```

#### **3. Controlador Geo Actualizado**
```ruby
def update
  # Para backfill desde localStorage, permitir sin coordenadas
  if city.present? && country.present? && lat.blank? && lng.blank?
    result = update_location_from_backfill(city, country, country_code)
    render json: result
    return
  end
  
  # Validación normal para actualizaciones con coordenadas
  # ...
end
```

### **Orden de Preferencia**

#### **1. Server-Side (Cookies)**
- **Prioridad:** Máxima
- **Ejecución:** Primer request del usuario logueado
- **Ventaja:** Inmediato, sin JavaScript
- **Limitación:** Solo cookies existentes

#### **2. Client-Side (localStorage)**
- **Prioridad:** Alta
- **Ejecución:** Primer render de la página
- **Ventaja:** ≤200ms, header actualizado al instante
- **Limitación:** Requiere JavaScript habilitado

#### **3. Reverse Geocoding (Mapbox)**
- **Prioridad:** Baja (plan B)
- **Ejecución:** Solo si no hay cache usable
- **Ventaja:** Datos más precisos
- **Limitación:** 2.5s timeout, requiere coordenadas

### **Prevención de Duplicación**
- **SessionStorage Flag:** `leagend.backfill_done = "1"`
- **Server-Side:** Solo campos en blanco
- **Client-Side:** Solo si no se completó en sesión

### **Campos Actualizados**
- `current_country`: País desde cookies/localStorage
- `current_city`: Ciudad desde cookies/localStorage  
- `current_country_code`: Código de país desde cookies/localStorage
- **No se tocan:** `current_latitude`, `current_longitude`

## API de Mapbox

### **Endpoint Utilizado**
```
https://api.mapbox.com/geocoding/v5/mapbox.places/{lng},{lat}.json
```

### **Parámetros**
- `types=place,region,country`: Solo lugares, regiones y países
- `language=es`: Respuesta en español
- `access_token={token}`: Token de Mapbox desde credenciales

### **Procesamiento de Respuesta**
1. **City:** Busca en `place_type: "place"` o `"locality"`
2. **Country:** Busca en `place_type: "country"`
3. **Country Code:** Extrae `properties.short_code` y convierte a mayúsculas

## Backend

### **GeoController#update**
- **Método:** PATCH
- **Ruta:** `/geo/update`
- **Parámetros aceptados:** `city`, `country`, `country_code`, `latitude`, `longitude`, `zip`, `timezone`
- **Validación:** Solo usuarios logueados

### **Concern DetectsLocation**
- **Método actualizado:** `update_exact_location(lat, lng, zip, timezone, city, country, country_code)`
- **Campos actualizados:** `current_city`, `current_country`
- **Cookies:** También se guardan city/country en cookies para usuarios no logueados

## Seguridad y CSP

### **Content Security Policy**
- **Nonce:** Cada script incluye nonce único
- **No inline styles:** Solo JavaScript puro
- **Origen:** Solo scripts del mismo dominio

### **Validaciones**
- **Usuario autenticado:** Solo usuarios logueados pueden actualizar
- **Parámetros permitidos:** Lista explícita de parámetros seguros
- **CSRF Token:** Incluido en todas las peticiones PATCH

## Casos de Uso

### **Caso 1: Usuario No Logueado**
- **Comportamiento:** No se ejecuta el script
- **Resultado:** Se muestra ubicación por IP desde cookies/sesión

### **Caso 2: Usuario Logueado con Country/City**
- **Comportamiento:** No se ejecuta el script
- **Resultado:** Se muestra ubicación desde `current_user.current_*`

### **Caso 3: Usuario Logueado sin Country/City pero con Lat/Lng**
- **Comportamiento:** Se ejecuta reverse geocoding
- **Resultado:** 
  1. UI se actualiza inmediatamente a "Ciudad, País"
  2. Se hace PATCH a `/geo/update`
  3. En la siguiente carga, se lee desde DB

### **Caso 4: Usuario Logueado sin Coordenadas**
- **Comportamiento:** No se ejecuta el script
- **Resultado:** Se muestra "Detectando ubicación..."

## Prevención de Loops

### **SessionStorage Flag**
```javascript
sessionStorage.setItem('leagend.geo_revgeo_done', 'true');
```

### **Verificaciones Múltiples**
1. **Usuario logueado:** `window.LEAGEND_USER_SIGNED_IN`
2. **Flag de sesión:** `leagend.geo_revgeo_done`
3. **Contenedor existe:** `#leagend-header-location`
4. **Coordenadas válidas:** `userLat` y `userLng` no null
5. **Token Mapbox:** Disponible en meta tag

## Manejo de Errores

### **Timeout**
- **Duración:** 2.5 segundos
- **Implementación:** `AbortController` con `setTimeout`
- **Resultado:** Si tarda más, se cancela sin afectar UX

### **Errores de API**
- **Mapbox falla:** No se actualiza la UI
- **Red falla:** Solo log en consola
- **Datos incompletos:** Solo se actualiza si hay city Y country

### **Fallbacks**
- **Sin coordenadas:** No se ejecuta
- **Sin token Mapbox:** No se ejecuta
- **Sin contenedor:** No se ejecuta

## Performance

### **Lazy Loading**
- **Ejecución:** Solo cuando es necesario
- **Tiempo:** ~300-1500ms típico
- **Impacto:** Mínimo, no bloquea la carga de la página

### **Cache**
- **SessionStorage:** Evita ejecuciones duplicadas
- **Cookies:** Coordenadas disponibles para usuarios no logueados
- **DB:** Persistencia permanente para usuarios logueados

## Monitoreo y Debugging

### **Logs del Backend**
```
"Ubicación exacta actualizada para usuario xxx: {:current_city=>\"Madrid\", :current_country=>\"España\"}"
```

### **Console del Frontend**
```
"Error en reverse geocoding: Mapbox API error"
"Error persistiendo ubicación: NetworkError"
```

### **Verificación Visual**
- **Antes:** "Detectando ubicación..." o "Ubicación no configurada"
- **Después:** "Ubicación: Madrid, España"

## Mantenimiento

### **Dependencias**
- **Mapbox API:** Verificar límites y disponibilidad
- **Token:** Verificar validez en credenciales
- **SessionStorage:** Limpiar si es necesario

### **Troubleshooting**
- **No se ejecuta:** Verificar `window.LEAGEND_USER_SIGNED_IN`
- **No actualiza UI:** Verificar contenedor `#leagend-header-location`
- **No persiste:** Verificar logs del backend y CSRF token

## Futuras Mejoras

### **Posibles Extensiones**
- **Geocoding inverso más inteligente:** Priorizar tipos de lugares
- **Cache de respuestas:** Evitar llamadas repetidas a Mapbox
- **Fallback a otros servicios:** Si Mapbox falla
- **Métricas:** Tracking de éxito/fallo del reverse geocoding

### **Optimizaciones**
- **Background job:** Para usuarios con muchas coordenadas
- **Batch processing:** Múltiples usuarios simultáneamente
- **Rate limiting:** Control de llamadas a Mapbox API
