# Documentación de UI/UX - Leagend

## Seeds y Datos Iniciales

### Seeds
**Archivo:** `db/seeds.rb`

**Estado actual:** El archivo de seeds está vacío, solo contiene comentarios de ejemplo. No hay datos iniciales configurados.

**Recomendación:** Implementar seeds para:
- Usuarios demo (admin, usuarios regulares)
- Arenas de ejemplo
- Clubs y clanes de prueba
- Duelos de muestra

## Sistema de Roles

### Estructura de Roles

#### 1. Roles de Usuario (Membership)
**Modelo:** `Membership`
**Enum:** `role`
- `admin` (0) - Administrador de club/clan
- `member` (1) - Miembro regular
- `king` (2) - Rey/propietario de club/clan

#### 2. Niveles de Administrador
**Modelo:** `Admin`
**Enum:** `level`
- `editor` (0) - Editor básico
- `admin` (1) - Administrador
- `king` (2) - Rey/propietario
- `moderator` (3) - Moderador

#### 3. Niveles de Propietario
**Modelo:** `Owner`
**Enum:** `level`
- `basic` (0) - Básico
- `verified` (1) - Verificado
- `pro` (2) - Profesional
- `admin` (3) - Administrador del sistema

### Jerarquía de Permisos

#### Usuarios
- **Usuario regular:** Puede crear duelos, unirse a clubs/clans
- **Miembro de club/clan:** Puede gestionar equipos, crear duelos asociados
- **Admin de club/clan:** Puede aprobar miembros, gestionar el club/clan
- **Rey de club/clan:** Control total del club/clan

#### Propietarios de Arena
- **Básico:** Puede crear arenas básicas
- **Verificado:** Arenas verificadas con más funcionalidades
- **Pro:** Funcionalidades avanzadas de gestión
- **Admin:** Acceso completo al sistema

## Configuración de Pagos

### Stripe
**Estado:** No se encontró configuración de Stripe en los archivos analizados.

**Archivos revisados:**
- `config/initializers/` - No hay archivos de Stripe
- `Gemfile` - No se encontró gema de Stripe
- Controladores - No hay integración de pagos

**Recomendación:** Implementar integración con Stripe para:
- Pagos de reservas de arenas
- Comisiones de duelos
- Suscripciones premium
- Pagos de árbitros

### Configuración de Pagos Necesaria

#### 1. Gemas Requeridas
```ruby
# Gemfile
gem 'stripe'
gem 'stripe-rails'
```

#### 2. Inicializador de Stripe
```ruby
# config/initializers/stripe.rb
Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key: ENV['STRIPE_SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
```

#### 3. Variables de Entorno
```bash
# .env
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

## Flujos de Usuario Principales

### 1. Registro y Autenticación
- **Registro:** Formulario con Devise + Google OAuth2
- **Login:** Email/password o Google
- **Perfil:** Edición de datos personales, avatar, ubicación

### 2. Creación de Duelos
- **Wizard de 4 pasos:**
  1. Selección de equipo
  2. Convocatoria de jugadores
  3. Selección de arena (con mapa)
  4. Configuración final
- **Gestión:** Panel de gestión con opciones avanzadas

### 3. Gestión de Arenas
- **Creación:** Formulario con geocodificación automática
- **Verificación:** Proceso de verificación por administradores
- **Reservas:** Sistema de disponibilidad y reservas

### 4. Clubs y Clans
- **Creación:** Formulario con avatar y descripción
- **Membresías:** Sistema de solicitud y aprobación
- **Gestión:** Panel de administración para líderes

## Componentes UI Clave

### 1. Wizard de Duelos
**Archivo:** `app/views/duels/`
- **Paso 1:** Selección de equipo existente o creación
- **Paso 2:** Convocatoria de jugadores con búsqueda
- **Paso 3:** Selección de arena con mapa interactivo
- **Paso 4:** Configuración final y confirmación

### 2. Mapa Interactivo
**Controlador:** `arena_location_controller.js`
- **Geocodificación:** Búsqueda de direcciones
- **Marcadores:** Arenas disponibles
- **Filtros:** Por proximidad (3km)
- **Autocompletado:** Direcciones, ciudades, países

### 3. Sistema de Notificaciones
**Modelo:** `Notification`
- **Tipos:** Convocatorias, duelos, clubs, equipos, desafíos
- **Estados:** Leído/No leído
- **Acciones:** Botones de acción contextual

### 4. Panel de Gestión
**Controlador:** `DuelsController#manage`
- **Jugadores:** Lista de convocados y disponibles
- **Arenas:** Selección y reserva
- **Estados:** Control de duelo (iniciar, postergar, cancelar)
- **Asociaciones:** Clubs y clanes

## Responsive Design

### Breakpoints
- **Mobile:** < 768px
- **Tablet:** 768px - 1024px
- **Desktop:** > 1024px

### Componentes Responsivos
- **Mapas:** Adaptación de zoom y controles
- **Formularios:** Campos apilados en móvil
- **Tablas:** Scroll horizontal en móvil
- **Modales:** Pantalla completa en móvil

## Accesibilidad

### Navegación por Teclado
- **Tab order:** Navegación lógica
- **Focus indicators:** Visibles y claros
- **Skip links:** Para saltar contenido

### Contraste y Legibilidad
- **Colores:** Cumple WCAG 2.1 AA
- **Tipografía:** Tamaños legibles
- **Iconos:** Con texto alternativo

### Screen Readers
- **ARIA labels:** En elementos interactivos
- **Alt text:** En imágenes
- **Semantic HTML:** Estructura clara

## Performance

### Optimizaciones Implementadas
- **Debounce:** En búsquedas y geocoding
- **Lazy loading:** De mapas y imágenes
- **Caché:** De ubicaciones del usuario
- **Turbo:** Para navegación SPA

### Métricas Objetivo
- **First Contentful Paint:** < 1.5s
- **Largest Contentful Paint:** < 2.5s
- **Cumulative Layout Shift:** < 0.1

## Testing UI

### Estrategia de Testing
- **System tests:** Flujos completos de usuario
- **Integration tests:** Interacciones entre componentes
- **Unit tests:** Lógica de controladores Stimulus

### Herramientas Recomendadas
- **Capybara:** Para system tests
- **Stimulus Testing:** Para controladores
- **Chrome DevTools:** Para debugging

## Internacionalización

### Idiomas Soportados
- **Español:** Idioma principal
- **Inglés:** Parcialmente implementado

### Archivos de Traducción
- `config/locales/en.yml`
- `config/locales/devise.en.yml`
- `config/locales/simple_form.en.yml`

## Temas y Personalización

### Tema Actual
- **Framework:** Bootstrap 5
- **Colores:** Azul primario (#007bff)
- **Tipografía:** Sistema de fuentes del sistema

### Personalización
- **Variables CSS:** Para colores y espaciado
- **Componentes:** Reutilizables y modulares
- **Temas:** Preparado para múltiples temas

## Monitoreo y Analytics

### Métricas de Usuario
- **Eventos:** Clicks, navegación, formularios
- **Conversiones:** Creación de duelos, reservas
- **Errores:** JavaScript, formularios, API

### Herramientas Recomendadas
- **Google Analytics:** Para métricas generales
- **Sentry:** Para errores JavaScript
- **Hotjar:** Para heatmaps y grabaciones

## Próximas Mejoras UI/UX

### Corto Plazo
1. **Implementar Stripe** para pagos
2. **Mejorar responsive** en móviles
3. **Añadir animaciones** de transición
4. **Optimizar mapas** para mejor performance

### Mediano Plazo
1. **PWA** para experiencia móvil nativa
2. **Dark mode** para mejor usabilidad
3. **Notificaciones push** para eventos importantes
4. **Chat en tiempo real** para coordinación

### Largo Plazo
1. **AI/ML** para recomendaciones de duelos
2. **Realidad aumentada** para visualización de arenas
3. **Gamificación** para engagement
4. **Integración social** con redes sociales
