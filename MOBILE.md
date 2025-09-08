# 📱 Mobile — Leagend

## 1. Objetivo
El módulo mobile busca ofrecer un **complemento ligero** al MVP web de Leagend.  
Se implementará con **Ionic + Capacitor** para Android/iOS, consumiendo la API Rails.

## 2. Stack Técnico
- **Framework:** Ionic + React.
- **Nativo:** Capacitor (Android/iOS).
- **Backend:** Rails API (`/api/v1/`).
- **Auth:** Google OAuth2 (con JWT recomendado para mobile).
- **Persistencia:** AsyncStorage (tokens, sesión, configuraciones).

## 3. Estructura de Proyecto



´´´´´
leagend/
├── app/ # Backend Rails
├── mobile/ # App Ionic
├── config/
└── ...


´´´´´´



## 4. Pantallas Mínimas
1. **Login**
   - Botón Google OAuth.
   - Persistencia de sesión en AsyncStorage.
2. **Dashboard**
   - Lista de duelos (`GET /api/v1/duels`).
   - Filtro simple por estado.
3. **Detalle de Duelo**
   - Info de arena, equipos, fecha/hora.
   - Acción “Unirme” o “Aceptar convocatoria”.
4. **Crear Duelo**
   - Wizard simplificado (arena + fecha/hora).
   - Confirmación final.
5. **Perfil**
   - Ver/editar datos básicos.
   - Listado de duelos del usuario.

## 5. Endpoints Usados
- `GET /api/v1/users/:id`
- `GET /api/v1/duels`, `POST /api/v1/duels`
- `GET /api/v1/arenas`
- `GET /api/v1/arenas/:id/availability`
- `POST /api/v1/reservations`

## 6. Capacitor Plugins (MVP)
- `@capacitor/geolocation` → ubicación de arenas.
- `@capacitor/camera` → fotos de perfil/arenas.
- `@capacitor/push-notifications` → notificaciones de duelos.
- `@capacitor/local-notifications` → recordatorios.
- `@capacitor/network` → estado de conexión.
- `@capacitor/splash-screen` + `@capacitor/status-bar`.

## 7. UI y Estilo
- Basado en componentes de Ionic (`IonPage`, `IonHeader`, `IonContent`).
- Theming con CSS variables adaptadas a Leagend.
- Dark mode opcional.
- Splash screen y logo personalizados.

## 8. Limitaciones del Prototipo
- Sin pagos en mobile (solo visualización).
- Notificaciones push configuradas, pero no activas en MVP.
- Moderación avanzada y clanes fuera de alcance.

## 9. Próximos Pasos
- Configurar `config/initializers/cors.rb` en Rails.
- Implementar JWT Auth en backend.
- Crear servicios API en Ionic.
- Lanzar build local en Android/iOS para pruebas.
