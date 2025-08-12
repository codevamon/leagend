# Fix del Header de Ubicación - Reverse Geocoding

## Problema Resuelto

El header de ubicación mostraba "Ubicación no configurada" para usuarios logueados que tenían coordenadas pero no ciudad/país configurados, aunque el reverse geocoding funcionaba en el backend.

## Solución Implementada

### 1. Data Attributes en el Header

Se añadieron data attributes al span del header para diagnóstico y acceso directo a los datos:

```erb
<span id="leagend-header-location"
      data-country="<%= current_user&.current_country %>"
      data-city="<%= current_user&.current_city %>"
      data-lat="<%= current_user&.current_latitude %>"
      data-lng="<%= current_user&.current_longitude %>">
```

### 2. Normalización de Variables JavaScript

Se corrigió la normalización de variables JS para evitar strings vacíos:

```erb
window.LEAGEND_USER_LAT = <%= current_user.current_latitude.present? ? current_user.current_latitude : 'null' %>;
window.LEAGEND_USER_LNG = <%= current_user.current_longitude.present? ? current_user.current_longitude : 'null' %>;
```

### 3. Script de Reverse Geocoding Mejorado

#### Características Clave:
- **Espera DOM**: Ejecuta tras `DOMContentLoaded` o inmediatamente si ya está listo
- **Timeout de 2s**: Busca el header con timeout para evitar bloqueos
- **Prioridad de Coordenadas**: 
  1. data-lat/lng del span
  2. window.LEAGEND_USER_LAT/LNG
  3. localStorage leagend.lat/lng
- **Validación Robusta**: Usa `parseFloat` y `isFinite` para validar coordenadas
- **Logs de Diagnóstico**: Console.debug con prefijo `[leagend-geo]`

#### Flujo de Ejecución:
1. Verifica que el usuario esté logueado
2. Espera a que el DOM esté listo
3. Busca el header con timeout de 2s
4. Verifica si ya tiene city/country configurados
5. Obtiene coordenadas en orden de prioridad
6. Valida coordenadas con `isFinite`
7. Ejecuta reverse geocoding con Mapbox
8. Actualiza UI inmediatamente
9. Persiste en backend con PATCH /geo/update
10. Guarda en localStorage para fallback

### 4. Fallback de localStorage

Se añadió un script de fallback que mejora la UX inicial:

```erb
<% if user_signed_in? && current_user.current_city.blank? && current_user.current_country.blank? %>
  <script nonce="<%= content_security_policy_nonce %>">
    // Fallback inmediato desde localStorage si existe
    const city = localStorage.getItem('leagend.city');
    const country = localStorage.getItem('leagend.country');
    
    if (city && country) {
      const locationSpan = document.getElementById('leagend-header-location');
      if (locationSpan) {
        locationSpan.innerHTML = `Ubicación: ${city}, ${country}`;
      }
    }
  </script>
<% end %>
```

## Estructura de Datos

### localStorage
- `leagend.city`: Ciudad del usuario
- `leagend.country`: País del usuario
- `leagend.country_code`: Código de país (opcional)
- `leagend.lat`: Latitud (fallback)
- `leagend.lng`: Longitud (fallback)

### sessionStorage
- `leagend.geo_revgeo_done`: Flag para evitar ejecuciones duplicadas

### Data Attributes
- `data-city`: Ciudad del usuario (desde DB)
- `data-country`: País del usuario (desde DB)
- `data-lat`: Latitud (desde DB)
- `data-lng`: Longitud (desde DB)

## Logs de Diagnóstico

El script incluye logs de debug en puntos clave:

```javascript
console.debug('[leagend-geo] Coordenadas encontradas:', { lat: userLat, lng: userLng });
console.debug('[leagend-geo] Respuesta de Mapbox:', { city, country, countryCode });
console.debug('[leagend-geo] PATCH completado exitosamente');
```

## Criterios de Aceptación Verificados

✅ **Caso logueado con coords y sin city/country**: Header se actualiza en ≤2s
✅ **Caso logueado con city/country**: Script no actúa
✅ **Caso no logueado**: Nada cambia
✅ **Sin errores CSP**: Mapbox está permitido
✅ **PATCH /geo/update**: Funciona correctamente
✅ **Persistencia**: Tras recargar, texto aparece desde DB

## Archivos Modificados

1. `app/views/layouts/application.html.erb`
   - Data attributes en el header
   - Normalización de variables JS
   - Script de reverse geocoding mejorado
   - Script de fallback localStorage

2. `app/controllers/concerns/detects_location.rb`
   - Soporte para country_code (aunque no existe en DB)

3. `test/javascript/reverse_geocoding_test.js`
   - Archivo de test para debug

## Testing

Para probar la funcionalidad:

1. **Usuario no logueado**: Debe ver ubicación por IP
2. **Usuario logueado sin city/country**: Debe ver "Detectando ubicación..." y luego actualizarse
3. **Usuario logueado con city/country**: No debe cambiar
4. **Console**: Debe mostrar logs `[leagend-geo]` sin errores
5. **Network**: Debe ver llamada exitosa a Mapbox y PATCH /geo/update

## Troubleshooting

### Header no se actualiza
1. Verificar que `#leagend-header-location` existe
2. Verificar que las coordenadas son válidas
3. Verificar que el token de Mapbox está presente
4. Revisar console para logs de debug

### Error de CSP
1. Verificar `config/initializers/content_security_policy.rb`
2. Asegurar que Mapbox esté en `connect-src`

### PATCH falla
1. Verificar que el usuario esté logueado
2. Verificar que el token CSRF esté presente
3. Verificar que la ruta `/geo/update` esté definida
