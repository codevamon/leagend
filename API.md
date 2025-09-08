# Documentación de API - Leagend

## Estructura de Rutas

### Rutas Principales (Web)
**Archivo:** `config/routes.rb`

#### Usuarios
- `GET /users` - Lista de usuarios
- `GET /users/:id` - Perfil de usuario
- `GET /users/:id/edit` - Editar perfil
- `PATCH /users/:id` - Actualizar perfil
- `DELETE /users/:id` - Eliminar usuario
- `GET /users/:id/callups` - Convocatorias del usuario

#### Duelos
- `GET /duels` - Lista de duelos
- `GET /duels/new` - Crear duelo
- `POST /duels` - Crear duelo
- `GET /duels/:id` - Ver duelo
- `PATCH /duels/:id` - Actualizar duelo
- `GET /duels/when` - Seleccionar fecha (deprecated)
- `GET /duels/select_team` - Seleccionar equipo (deprecated)
- `GET /duels/callup_players` - Convocar jugadores (deprecated)
- `GET /duels/select_arena` - Seleccionar arena (deprecated)
- `GET /duels/select_type` - Seleccionar tipo (deprecated)
- `POST /duels/confirm` - Confirmar duelo (deprecated)
- `GET /duels/responsibility` - Responsabilidad
- `GET /duels/my_duels` - Mis duelos
- `PATCH /duels/:id/start` - Iniciar duelo
- `PATCH /duels/:id/complete` - Completar duelo
- `GET /duels/:id/manage` - Gestionar duelo
- `PATCH /duels/:id/randomize_teams` - Aleatorizar equipos
- `PATCH /duels/:id/publish_for_freeplayers` - Publicar para jugadores libres
- `PATCH /duels/:id/postpone` - Postergar duelo
- `PATCH /duels/:id/cancel` - Cancelar duelo
- `PATCH /duels/:id/accept_challenge` - Aceptar desafío
- `PATCH /duels/:id/challenge_team` - Desafiar equipo
- `GET /duels/:id/available_players` - Jugadores disponibles
- `POST /duels/:id/callup_player` - Convocar jugador
- `PATCH /duels/:id/toggle_freeplayers` - Toggle jugadores libres
- `POST /duels/:id/associate_with_club` - Asociar con club
- `POST /duels/:id/associate_with_clan` - Asociar con clan
- `PATCH /duels/:id/approve_club_association` - Aprobar asociación de club
- `PATCH /duels/:id/reject_club_association` - Rechazar asociación de club
- `POST /duels/:id/self_callup_captain` - Autoconvocar capitán

#### Arenas
- `GET /arenas` - Lista de arenas
- `GET /arenas/new` - Crear arena
- `POST /arenas` - Crear arena
- `GET /arenas/:id` - Ver arena
- `GET /arenas/:id/edit` - Editar arena
- `PATCH /arenas/:id` - Actualizar arena
- `POST /arenas/geocode` - Geocodificar dirección
- `GET /arenas/:id/availability` - Disponibilidad de arena

#### Equipos
- `GET /teams/:id` - Ver equipo
- `GET /teams/:id/edit` - Editar equipo
- `PATCH /teams/:id` - Actualizar equipo
- `DELETE /teams/:id` - Eliminar equipo
- `GET /teams/:id/callup_users` - Usuarios para convocar
- `POST /teams/:id/create_callup` - Crear convocatoria
- `GET /teams/:id/callup_users` - Usuarios convocados
- `PATCH /teams/:id/assign_leader` - Asignar líder

#### Clubs y Clans
- `GET /clubs` - Lista de clubs
- `GET /clubs/new` - Crear club
- `POST /clubs` - Crear club
- `GET /clubs/:id` - Ver club
- `GET /clubs/:id/edit` - Editar club
- `PATCH /clubs/:id` - Actualizar club
- `DELETE /clubs/:id` - Eliminar club
- `POST /clubs/:id/join` - Unirse al club
- `POST /clubs/:id/approve_member` - Aprobar miembro

- `GET /clans` - Lista de clanes
- `GET /clans/new` - Crear clan
- `POST /clans` - Crear clan
- `GET /clans/:id` - Ver clan
- `GET /clans/:id/edit` - Editar clan
- `PATCH /clans/:id` - Actualizar clan
- `DELETE /clans/:id` - Eliminar clan
- `POST /clans/:id/join` - Unirse al clan

#### Notificaciones
- `GET /notifications` - Lista de notificaciones
- `PATCH /notifications/:id` - Actualizar notificación
- `PUT /notifications/mark_all_read` - Marcar todas como leídas

#### Convocatorias
- `POST /callups/send_callup` - Enviar convocatoria
- `POST /callups/:id/accept` - Aceptar convocatoria
- `POST /callups/:id/reject` - Rechazar convocatoria

#### Desafíos
- `POST /challenges` - Crear desafío
- `GET /challenges/:id` - Ver desafío
- `PATCH /challenges/:id/accept` - Aceptar desafío
- `PATCH /challenges/:id/reject` - Rechazar desafío

#### Reservas
- `GET /reservations/:id` - Ver reserva
- `PATCH /reservations/:id/cancel` - Cancelar reserva

#### Propietarios
- `GET /owners/new` - Crear propietario
- `POST /owners` - Crear propietario
- `GET /owners/:id` - Ver propietario

#### Árbitros
- `GET /referees` - Lista de árbitros
- `GET /referees/:id` - Ver árbitro
- `GET /referees/:id/reservations/new` - Nueva reserva de árbitro
- `POST /referees/:id/reservations` - Crear reserva de árbitro

### API REST (v1)
**Namespace:** `/api/v1/`

#### Usuarios API
- `GET /api/v1/users` - Lista de usuarios (JSON)
- `GET /api/v1/users/:id` - Usuario específico (JSON)

#### Clubs API
- `GET /api/v1/clubs` - Lista de clubs (JSON)
- `GET /api/v1/clubs/:id` - Club específico (JSON)

#### Clans API
- `GET /api/v1/clans` - Lista de clanes (JSON)
- `GET /api/v1/clans/:id` - Clan específico (JSON)

#### Equipos API
- `GET /api/v1/teams` - Lista de equipos (JSON)
- `GET /api/v1/teams/:id` - Equipo específico (JSON)

#### Duelos API
- `GET /api/v1/duels` - Lista de duelos (JSON)
- `GET /api/v1/duels/:id` - Duelo específico (JSON)

#### Árbitros API
- `GET /api/v1/referees` - Lista de árbitros (JSON)
- `GET /api/v1/referees/:id` - Árbitro específico (JSON)

#### Arenas API
- `GET /api/v1/arenas` - Lista de arenas (JSON)
- `GET /api/v1/arenas/:id` - Arena específica (JSON)
- `GET /api/v1/arenas/:id/availability` - Disponibilidad de arena (JSON)

#### Reservas API
- `POST /api/v1/reservations` - Crear reserva (JSON)
- `PATCH /api/v1/reservations/:id/cancel` - Cancelar reserva (JSON)

### Rutas de Administración
**Namespace:** `/admin/`

- `GET /admin/clubs` - Administrar clubs
- `GET /admin/clubs/:id` - Ver club
- `GET /admin/clubs/:id/edit` - Editar club
- `PATCH /admin/clubs/:id` - Actualizar club
- `DELETE /admin/clubs/:id` - Eliminar club

- `GET /admin/clans` - Administrar clanes
- `GET /admin/clans/:id` - Ver clan
- `GET /admin/clans/:id/edit` - Editar clan
- `PATCH /admin/clans/:id` - Actualizar clan
- `DELETE /admin/clans/:id` - Eliminar clan

- `GET /admin/teams` - Administrar equipos
- `GET /admin/teams/:id` - Ver equipo
- `GET /admin/teams/:id/edit` - Editar equipo
- `PATCH /admin/teams/:id` - Actualizar equipo
- `DELETE /admin/teams/:id` - Eliminar equipo

- `GET /admin/duels` - Administrar duelos
- `GET /admin/duels/:id` - Ver duelo
- `GET /admin/duels/:id/edit` - Editar duelo
- `PATCH /admin/duels/:id` - Actualizar duelo
- `DELETE /admin/duels/:id` - Eliminar duelo

- `GET /admin/referees` - Administrar árbitros
- `GET /admin/referees/:id` - Ver árbitro
- `GET /admin/referees/:id/edit` - Editar árbitro
- `PATCH /admin/referees/:id` - Actualizar árbitro
- `DELETE /admin/referees/:id` - Eliminar árbitro

- `GET /admin/arenas` - Administrar arenas
- `GET /admin/arenas/:id` - Ver arena
- `GET /admin/arenas/:id/edit` - Editar arena
- `PATCH /admin/arenas/:id` - Actualizar arena
- `DELETE /admin/arenas/:id` - Eliminar arena

- `GET /admin/arena_verifications` - Verificaciones de arena
- `GET /admin/arena_verifications/:id` - Ver verificación
- `PATCH /admin/arena_verifications/:id/approve` - Aprobar verificación
- `PATCH /admin/arena_verifications/:id/reject` - Rechazar verificación

## Controladores con Respuesta JSON

### Controladores API Específicos

#### Api::V1::ArenasController
**Archivo:** `app/controllers/api/v1/arenas_controller.rb`

**Endpoints JSON:**
- `GET /api/v1/arenas` - Retorna lista de arenas con fotos adjuntas
- `GET /api/v1/arenas/:id` - Retorna arena específica
- `GET /api/v1/arenas/:id/availability` - Retorna slots de disponibilidad

**Filtros soportados:**
- `status` - Filtrar por estado de verificación
- `city` - Filtrar por ciudad
- `rentable` - Filtrar por disponibilidad de alquiler
- `price_min` - Precio mínimo por hora
- `price_max` - Precio máximo por hora

#### Api::V1::ReservationsController
**Archivo:** `app/controllers/api/v1/reservations_controller.rb`

**Endpoints JSON:**
- `POST /api/v1/reservations` - Crear reserva
- `PATCH /api/v1/reservations/:id/cancel` - Cancelar reserva

**Autenticación:** Requiere `authenticate_user!`

### Controladores Web con Respuesta JSON

#### ArenasController
**Archivo:** `app/controllers/arenas_controller.rb`

**Endpoints JSON:**
- `GET /arenas/:id/availability` - Disponibilidad de arena
- `POST /arenas/geocode` - Geocodificación de dirección

#### DuelsController
**Archivo:** `app/controllers/duels_controller.rb`

**Endpoints JSON:**
- `POST /duels/:id/callup_player` - Convocar jugador (soporta Turbo Stream y JSON)
- `POST /duels/:id/self_callup_captain` - Autoconvocar capitán (soporta Turbo Stream y JSON)

## Autenticación y Autorización

### Devise
- **Configuración:** `config/initializers/devise.rb`
- **Modelo:** `User`
- **Estrategias:** Database authenticable, Registerable, Recoverable, Rememberable, Validatable
- **OAuth:** Google OAuth2 integrado

### Autorización
- **Método:** Manual (sin Pundit/Cancan)
- **Verificaciones:** `before_action :authenticate_user!` en controladores protegidos
- **Autorización específica:** Métodos personalizados como `authorize_duel_management!`

### Rutas de Autenticación
- `GET /users/sign_in` - Iniciar sesión
- `POST /users/sign_in` - Procesar inicio de sesión
- `GET /users/sign_up` - Registrarse
- `POST /users/sign_up` - Procesar registro
- `DELETE /users/sign_out` - Cerrar sesión
- `GET /users/password/new` - Recuperar contraseña
- `POST /users/password` - Procesar recuperación
- `GET /users/password/edit` - Cambiar contraseña
- `PATCH /users/password` - Procesar cambio de contraseña

## Serialización

### Sin Serializers Específicos
La aplicación no usa ActiveModel::Serializer, JBuilder o serializers personalizados. Los controladores API retornan directamente los objetos ActiveRecord como JSON usando el método `render json:`.

### Formato de Respuesta JSON
```ruby
# Ejemplo de respuesta de arena
{
  "id": "uuid-string",
  "name": "Arena Name",
  "address": "123 Main St",
  "city": "Bogotá",
  "country": "Colombia",
  "latitude": 4.7110,
  "longitude": -74.0721,
  "status": "verified",
  "price_per_hour": 50000,
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

## Rutas de Geolocalización

### GeoController
- `GET /geo/current` - Obtener ubicación actual del usuario
- `PATCH /geo/update` - Actualizar ubicación del usuario

**Parámetros:**
- `latitude` - Latitud
- `longitude` - Longitud
- `zip` - Código postal (opcional)
- `timezone` - Zona horaria (opcional)

## Rutas Especiales

### Duelos con Equipos
- `POST /duels/create_team_and_callup` - Crear equipo y convocatoria
- `POST /duels/send_callups_to_all` - Enviar convocatorias a todos
- `POST /duels/finalize_creation` - Finalizar creación de duelo
- `POST /duels/:duel_id/accept` - Aceptar duelo abierto
- `GET /duels/open` - Duelos abiertos

### Líneas de Alineación y Goles
- `GET /duels/:duel_id/lineups` - Alineaciones del duelo
- `GET /duels/:duel_id/lineups/:id/edit` - Editar alineación
- `PATCH /duels/:duel_id/lineups/:id` - Actualizar alineación
- `DELETE /duels/:duel_id/lineups/:id` - Eliminar alineación
- `GET /duels/:duel_id/duel_goals` - Goles del duelo
- `GET /duels/:duel_id/duel_goals/new` - Nuevo gol
- `POST /duels/:duel_id/duel_goals` - Crear gol
- `DELETE /duels/:duel_id/duel_goals/:id` - Eliminar gol
- `GET /duels/:duel_id/results/new` - Nuevo resultado
- `POST /duels/:duel_id/results` - Crear resultado
- `GET /duels/:duel_id/results/:id/edit` - Editar resultado
- `PATCH /duels/:duel_id/results/:id` - Actualizar resultado

## Consideraciones de API

### CORS
No se encontró configuración específica de CORS, lo que sugiere que la API está diseñada para uso interno de la aplicación web.

### Rate Limiting
No se encontró configuración de rate limiting en los controladores analizados.

### Versionado
- Solo existe versión v1 de la API
- Namespace `/api/v1/` para endpoints API
- Controladores web sin versionado

### Paginación
No se implementó paginación en los endpoints API analizados.

### Filtros y Búsqueda
- Arenas: Filtros por status, ciudad, rentable, precio
- Duelos: Filtros por estado, fecha, tipo
- Usuarios: Sin filtros específicos implementados
