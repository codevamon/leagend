# Implementación de Detección de Ubicación - Leagend

## Resumen

Se ha implementado un sistema de detección de ubicación **no intrusivo** que:
- Detecta automáticamente país/ciudad por IP
- Permite ubicación exacta opcional con HTML5 Geolocation
- Mantiene compatibilidad total con OmniAuth/Google
- No afecta tiempos de carga críticos

## Arquitectura

### 1. Concern `DetectsLocation`

**Archivo:** `app/controllers/concerns/detects_location.rb`

**Funcionalidades:**
- `ensure_location_cached`: Detecta ubicación por IP una vez por sesión
- `detect_location_by_ip`: Usa ipinfo.io (gratuito, 50k requests/mes)
- `cache_location`: Guarda en cookies y sesión
- `update_user_location`: Actualiza DB si usuario está loggeado
- `update_exact_location`: Actualiza ubicación exacta (HTML5)

**Integración:** Incluido en `ApplicationController` con `before_action :ensure_location_cached`

### 2. Controlador `GeoController`

**Archivo:** `app/controllers/geo_controller.rb`

**Endpoints:**
- `GET /geo/current`: Retorna ubicación actual (por IP o cacheada)
- `PATCH /geo/update`: Actualiza ubicación exacta del usuario

**Validaciones:**
- Coordenadas requeridas (lat, lng)
- Formato numérico válido
- Rangos geográficos correctos (-90 a 90 lat, -180 a 180 lng)
- Usuario autenticado para actualización

### 3. JavaScript Stimulus

**Archivo:** `app/javascript/controllers/location_controller.js`

**Funcionalidades:**
- Detección automática de permisos existentes
- Solicitud de ubicación HTML5 opcional
- Manejo de errores y estados
- Comunicación asíncrona con servidor
- Eventos para otros componentes

**Integración:** Registrado como `location` en Stimulus

### 4. Frontend

**Archivo:** `app/views/shared/_location_widget.html.erb`

**Características:**
- Widget opcional no intrusivo
- Muestra ubicación actual del usuario
- Botón para habilitar ubicación exacta
- Estados visuales claros
- Responsive design

## Flujo de Funcionamiento

### Usuario No Loggeado
1. **Primera visita:** Se detecta IP automáticamente
2. **Ubicación guardada:** En cookies y sesión
3. **Subsiguientes visitas:** Se lee de cache (no más requests IP)

### Usuario Loggeado
1. **Login:** Se detecta IP si no está cacheada
2. **Guardado automático:** `current_country` y `current_city` en DB
3. **Ubicación exacta:** Opcional via HTML5 Geolocation

### HTML5 Geolocation (Opcional)
1. **Usuario acepta:** Cookies de ubicación
2. **Permiso:** Navegador solicita acceso
3. **Coordenadas:** Se obtienen y envían al servidor
4. **Actualización:** `current_latitude`, `current_longitude`, `current_zip`, `current_timezone`

## Rutas

```ruby
# Rutas de geolocalización
get "geo/current", to: "geo#current"
patch "geo/update", to: "geo#update"
```

## Seguridad

### Validaciones
- Coordenadas numéricas válidas
- Rangos geográficos correctos
- Autenticación requerida para actualización
- Parámetros permitidos explícitamente

### Rate Limiting
- Detección IP una vez por sesión
- Cookies persistentes para evitar requests repetidos
- Timeout de 10 segundos para HTML5 Geolocation

## Compatibilidad

### OmniAuth/Google
- **Sin cambios:** Login funciona exactamente igual
- **Ubicación:** Se detecta automáticamente en background
- **Campos:** Solo se actualizan si están vacíos o cambian

### Controladores Existentes
- **Sin impacto:** Todos los flujos funcionan igual
- **Ubicación disponible:** Via `cached_location` helper
- **Performance:** No afecta tiempos de carga críticos

## Testing

### Tests Incluidos
- `test/controllers/concerns/detects_location_test.rb`
- `test/controllers/geo_controller_test.rb`

### Cobertura
- Detección por IP
- Cache de ubicación
- Validaciones de coordenadas
- Autenticación requerida
- Manejo de errores

## Configuración

### Dependencias
- **ipinfo.io:** Servicio gratuito de detección IP
- **Font Awesome:** Iconos para UI
- **Stimulus:** Framework JavaScript

### Variables de Entorno
- No se requieren API keys adicionales
- ipinfo.io funciona sin autenticación
- Límite: 50,000 requests por mes

## Monitoreo

### Logs
- Ubicación detectada por IP
- Actualizaciones de ubicación exacta
- Errores de detección
- Cambios en ubicación de usuario

### Métricas
- Usuarios con ubicación configurada
- Tasa de éxito de HTML5 Geolocation
- Errores de validación de coordenadas

## Mantenimiento

### Actualizaciones
- **ipinfo.io:** Verificar límites mensuales
- **Coordenadas:** Validar rangos geográficos
- **Cookies:** Revisar expiración y seguridad

### Troubleshooting
- **Ubicación no detectada:** Verificar conectividad a ipinfo.io
- **HTML5 falla:** Verificar permisos del navegador
- **DB no actualiza:** Verificar campos `current_*` en modelo User

## Futuras Mejoras

### Posibles Extensiones
- **Geocoding inverso:** Obtener dirección desde coordenadas
- **Timezone automático:** Detectar zona horaria por IP
- **Cache distribuido:** Redis para ubicaciones compartidas
- **Métricas avanzadas:** Analytics de uso de ubicación

### Optimizaciones
- **Lazy loading:** Solo detectar cuando sea necesario
- **Background jobs:** Actualización asíncrona de ubicación
- **CDN:** Cache de respuestas de ipinfo.io
