# Documentación de Componentes Frontend - Leagend

## Stimulus Controllers

### 1. duel_steps_controller.js
**Archivo:** `app/javascript/controllers/duel_steps_controller.js`

**Propósito:** Controlador principal para el wizard de creación de duelos

**Targets:**
- `step` - Elementos de paso del wizard
- `progress` - Barra de progreso
- `nextBtn`, `prevBtn`, `submitBtn` - Botones de navegación
- `arenaId` - Campo de ID de arena
- `mapContainer` - Contenedor del mapa
- `arenaList`, `arenaGrid` - Listas de arenas
- `arenaSearch` - Campo de búsqueda de arenas
- `latitude`, `longitude` - Campos de coordenadas
- `summaryMap` - Mapa de resumen
- `durationSelect` - Selector de duración

**Values:**
- `currentStep` - Paso actual (Number, default: 1)
- `totalSteps` - Total de pasos (Number, default: 4)

**Funcionalidades principales:**
- Navegación entre pasos del wizard
- Validación de formularios
- Integración con mapas (Mapbox)
- Gestión de duración de duelos
- Filtrado de arenas por proximidad (3km)
- Autocompletado de ubicaciones

**Métodos clave:**
- `nextStep()` - Avanzar al siguiente paso
- `prevStep()` - Retroceder al paso anterior
- `validateStep()` - Validar paso actual
- `updateArenaMarkers()` - Actualizar marcadores de arenas
- `filterArenasByDistance()` - Filtrar arenas por distancia

### 2. arena_location_controller.js
**Archivo:** `app/javascript/controllers/arena_location_controller.js`

**Propósito:** Controlador para gestión de ubicaciones y mapas interactivos

**Targets:**
- `country`, `city`, `address`, `neighborhood` - Campos de ubicación
- `latitude`, `longitude` - Campos de coordenadas
- `map` - Contenedor del mapa
- `geocoderCountry`, `geocoderCity`, `geocoderAddress` - Contenedores de geocoders

**Values:**
- `editable` - Si el mapa es editable (Boolean, default: false)
- `centerLat` - Latitud central (Number, default: 4.7110)
- `centerLng` - Longitud central (Number, default: -74.0721)
- `zoom` - Nivel de zoom (Number, default: 13)

**Funcionalidades principales:**
- Integración con Mapbox GL JS
- Geocodificación directa e inversa
- Autocompletado de direcciones, ciudades y países
- Gestión de marcadores draggables
- Sincronización entre mapa y formularios
- Debounce para optimizar llamadas API

**Métodos clave:**
- `initializeMap()` - Inicializar mapa Mapbox
- `initializeGeocoders()` - Configurar geocoders
- `reverseGeocode()` - Geocodificación inversa
- `updateMapLocation()` - Actualizar ubicación del mapa
- `handleLocationChanged()` - Manejar cambios de ubicación

### 3. arena_map_controller.js
**Archivo:** `app/javascript/controllers/arena_map_controller.js`

**Propósito:** Controlador para mapas de solo lectura (visualización)

**Targets:**
- `map` - Contenedor del mapa

**Values:**
- `editable` - Si el mapa es editable (Boolean, default: false)
- `centerLat` - Latitud central (Number, default: 4.7110)
- `centerLng` - Longitud central (Number, default: -74.0721)
- `zoom` - Nivel de zoom (Number, default: 13)

**Funcionalidades principales:**
- Mapa de solo lectura para visualización
- Marcador fijo no draggable
- Controles de navegación básicos
- Popup informativo

### 4. arena_reservation_controller.js
**Archivo:** `app/javascript/controllers/arena_reservation_controller.js`

**Propósito:** Controlador para sistema de reservas de arenas

**Targets:**
- `dateInput` - Campo de fecha
- `slotsContainer` - Contenedor de slots disponibles
- `reserveBtn` - Botón de reserva
- `modalDate`, `modalTime`, `modalPrice` - Campos del modal
- `confirmBtn` - Botón de confirmación

**Values:**
- `arenaSlug` - Slug de la arena (String)
- `pricePerHour` - Precio por hora (Number, default: 0)

**Funcionalidades principales:**
- Selección de fecha y horarios
- Consulta de disponibilidad via API
- Modal de confirmación de reserva
- Integración con sistema de reservas

**Métodos clave:**
- `handleDateChange()` - Manejar cambio de fecha
- `fetchAvailability()` - Obtener disponibilidad
- `displaySlots()` - Mostrar slots disponibles
- `selectSlot()` - Seleccionar slot
- `handleConfirmReservation()` - Confirmar reserva

### 5. duel_form_controller.js
**Archivo:** `app/javascript/controllers/duel_form_controller.js`

**Propósito:** Controlador para formularios de duelos

**Targets:**
- `startsAt` - Campo de hora de inicio
- `duration` - Campo de duración
- `endsAt` - Campo de hora de fin
- `form` - Formulario principal

**Funcionalidades principales:**
- Cálculo automático de hora de fin
- Validación de formularios
- Reset de formularios

**Métodos clave:**
- `updateEndTime()` - Actualizar hora de fin
- `validateForm()` - Validar formulario
- `reset()` - Resetear formulario

### 6. location_controller.js
**Archivo:** `app/javascript/controllers/location_controller.js`

**Propósito:** Controlador para geolocalización del usuario

**Targets:**
- `status` - Elemento de estado
- `button` - Botón de ubicación

**Values:**
- `enabled` - Si está habilitado (Boolean)
- `userSignedIn` - Si el usuario está logueado (Boolean)

**Funcionalidades principales:**
- Solicitud de permisos de geolocalización
- Obtención de ubicación actual
- Actualización de ubicación en servidor
- Manejo de errores de geolocalización

**Métodos clave:**
- `requestLocation()` - Solicitar ubicación
- `handleLocationSuccess()` - Manejar éxito de ubicación
- `handleLocationError()` - Manejar errores
- `updateLocationOnServer()` - Actualizar en servidor

### 7. location_display_controller.js
**Archivo:** `app/javascript/controllers/location_display_controller.js`

**Propósito:** Controlador para mostrar información de ubicación

**Targets:**
- `display` - Elemento de visualización

**Funcionalidades principales:**
- Mostrar ubicación actual del usuario
- Actualizar display cuando cambia la ubicación
- Efectos visuales de actualización

**Métodos clave:**
- `handleLocationUpdate()` - Manejar actualización de ubicación
- `updateLocationDisplay()` - Actualizar display
- `refresh()` - Refrescar información

### 8. static_map_controller.js
**Archivo:** `app/javascript/controllers/static_map_controller.js`

**Propósito:** Controlador para mapas estáticos simples

**Values:**
- `lat` - Latitud (Number)
- `lng` - Longitud (Number)
- `zoom` - Zoom (Number, default: 14)

**Funcionalidades principales:**
- Mapa estático con marcador
- Visualización básica de ubicación

### 9. modal_controller.js
**Archivo:** `app/javascript/controllers/modal_controller.js`

**Propósito:** Controlador para modales Bootstrap

**Targets:**
- `content` - Contenido del modal

**Funcionalidades principales:**
- Apertura y cierre de modales
- Resize de mapas en modales
- Limpieza de contenido

**Métodos clave:**
- `open()` - Abrir modal
- `close()` - Cerrar modal
- `resizeMapInModal()` - Redimensionar mapa en modal

### 10. sign_out_controller.js
**Archivo:** `app/javascript/controllers/sign_out_controller.js`

**Propósito:** Controlador para cierre de sesión

**Targets:**
- `link` - Enlace de cierre de sesión

**Funcionalidades principales:**
- Manejo de cierre de sesión via AJAX
- Redirección después del cierre

### 11. hello_controller.js
**Archivo:** `app/javascript/controllers/hello_controller.js`

**Propósito:** Controlador de ejemplo básico

**Funcionalidades principales:**
- Ejemplo simple de Stimulus controller

## ViewComponents

**Nota:** No se encontraron ViewComponents en la estructura de archivos analizada. La aplicación parece usar partials de Rails tradicionales en lugar de ViewComponents.

## Partials Clave

### Partials de Duelos
**Directorio:** `app/views/duels/`

#### Partials principales:
- `_form.html.erb` - Formulario de duelo
- `_duel_details_section.html.erb` - Sección de detalles del duelo
- `_callup_button.html.erb` - Botón de convocatoria
- `_freeplayers_toggle.html.erb` - Toggle de jugadores libres
- `_arena_selection.html.erb` - Selección de arena
- `_team_management.html.erb` - Gestión de equipos
- `_duel_status.html.erb` - Estado del duelo
- `_duel_actions.html.erb` - Acciones del duelo

### Partials de Arenas
**Directorio:** `app/views/arenas/`

#### Partials principales:
- `_form.html.erb` - Formulario de arena
- `_arena_card.html.erb` - Tarjeta de arena
- `_arena_map.html.erb` - Mapa de arena
- `_availability_slots.html.erb` - Slots de disponibilidad
- `_arena_photos.html.erb` - Galería de fotos
- `_arena_info.html.erb` - Información de arena

### Partials Compartidos
**Directorio:** `app/views/shared/`

#### Partials principales:
- `_flash.html.erb` - Mensajes flash
- `_navigation.html.erb` - Navegación principal
- `_footer.html.erb` - Pie de página
- `_loading.html.erb` - Indicador de carga

### Partials de Layout
**Directorio:** `app/views/layouts/`

#### Layouts principales:
- `application.html.erb` - Layout principal
- `devise.html.erb` - Layout para Devise
- `admin.html.erb` - Layout para administración

## Integración con Mapbox

### Configuración
- **Token:** Obtenido desde `meta[name="mapbox-token"]`
- **Estilos:** `mapbox://styles/mapbox/streets-v12`
- **Geocoding:** API de Mapbox para geocodificación
- **Autocomplete:** MapboxGeocoder para autocompletado

### Controladores que usan Mapbox:
1. `arena_location_controller.js` - Mapa interactivo con geocoding
2. `arena_map_controller.js` - Mapa de solo lectura
3. `static_map_controller.js` - Mapa estático simple
4. `duel_steps_controller.js` - Integración en wizard de duelos

## Patrones de Comunicación

### Eventos Personalizados
- `leagend:location_changed` - Cambio de ubicación
- `leagend:arena_selected` - Arena seleccionada
- `locationUpdated` - Actualización de ubicación del usuario

### Turbo Streams
- Respuestas Turbo Stream en controladores para actualizaciones dinámicas
- Integración con modales y formularios
- Actualizaciones en tiempo real de listas y formularios

### AJAX
- Peticiones AJAX para geocodificación
- Actualización de ubicación del usuario
- Cierre de sesión via AJAX

## Consideraciones de UX

### Responsive Design
- Controllers adaptados para móviles
- Modales responsivos
- Mapas adaptativos

### Performance
- Debounce en búsquedas y geocoding
- Lazy loading de mapas
- Caché de ubicaciones

### Accesibilidad
- Navegación por teclado
- Indicadores de estado
- Mensajes de error claros

## Dependencias Frontend

### JavaScript Libraries
- **Stimulus** - Framework de controladores
- **Mapbox GL JS** - Mapas interactivos
- **MapboxGeocoder** - Geocodificación
- **Bootstrap** - Framework CSS y modales
- **Turbo** - Navegación SPA

### CSS Framework
- **Bootstrap 5** - Framework principal
- **Font Awesome** - Iconos
- **Custom CSS** - Estilos personalizados
