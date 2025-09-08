# Documentación de Modelos - Leagend

## Modelos Principales

### 1. User (Usuario)
**Archivo:** `app/models/user.rb`

**Asociaciones:**
- `has_one :owner`
- `has_one :referee`
- `has_many :owned_clubs` (clubs como propietario)
- `has_many :refereed_duels` (duelos como árbitro)
- `has_many :admins` (administradores)
- `has_many :clubs, through: :admins`
- `has_many :clans, through: :admins`
- `has_many :memberships` (membresías en clubs/clans)
- `has_many :team_memberships`
- `has_many :teams, through: :team_memberships`
- `has_many :duels, through: :teams`
- `has_many :callups` (convocatorias)
- `has_many :called_up_teams, through: :callups`
- `has_many :notifications, as: :recipient`
- `has_many :owned_teams` (equipos como líder)
- `has_many :stats`
- `has_many :sent_reservations` (reservas enviadas)
- `has_many :received_reservations` (reservas recibidas)

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :id, presence: true`
- `validates :slug, presence: true, uniqueness: true, length: { maximum: 50 }`
- `validates :slug, format: { without: /\s/, message: "cannot contain spaces" }`

**Callbacks:**
- `before_validation :set_uuid, on: :create`
- `before_validation :ensure_unique_slug, on: :create`
- `before_save :set_avatar_from_url, if: -> { image_url.present? && avatar.blank? }`

**Características especiales:**
- Usa Devise para autenticación
- Integración con Google OAuth2
- FriendlyId para slugs amigables
- Active Storage para avatares y portadas
- Métodos de estadísticas (wins, losses, draws)

### 2. Duel (Duelo)
**Archivo:** `app/models/duel.rb`

**Asociaciones:**
- `belongs_to :home_team, class_name: 'Team', optional: true`
- `belongs_to :away_team, class_name: 'Team', optional: true`
- `belongs_to :referee, class_name: 'User', optional: true`
- `belongs_to :man_of_the_match, class_name: 'User', optional: true`
- `belongs_to :arena, optional: true`
- `belongs_to :club, optional: true`
- `belongs_to :clan, optional: true`
- `has_one :result`
- `has_many :callups`
- `has_many :lineups`
- `has_many :duel_goals`
- `has_many :scorers, through: :duel_goals, source: :User`
- `has_many :challenges_as_challenger`
- `has_many :challenges_as_challengee`

**Enums:**
- `enum :status` - pending, open, ongoing, finished, merged, cancelled, postponed
- `enum :duel_type` - friendly, bet, rematch, training, hobbie
- `enum :challenge_type` - challengee, challenger, direct

**Validaciones:**
- `validates :starts_at, :ends_at, presence: true`
- `validates :price, :budget, :referee_fee, numericality: { greater_than_or_equal_to: 0 }`
- `validates :duel_type, presence: true`
- `validates :duration_minutes, inclusion: { in: DURATION_MINUTES }`
- `validate :end_date_after_start_date`
- `validate :arena_availability`
- `validate :validate_team_sizes`
- `validate :validate_duel_type`

**Callbacks:**
- `before_create :generate_uuid`
- `before_save :set_expires_at, if: :temporary?`
- `before_validation` - establece duración por defecto
- `after_save :notify_status_change, if: -> { saved_change_to_status? }`

### 3. Arena (Arena)
**Archivo:** `app/models/arena.rb`

**Asociaciones:**
- `belongs_to :owner, class_name: "Owner"`
- `has_many :reservations, as: :reservable`
- `has_many :duels`
- `has_many_attached :photos`
- `has_many :business_hours, class_name: "ArenaBusinessHour"`
- `has_many :closures, class_name: "ArenaClosure"`
- `has_one :last_verification, class_name: "ArenaVerification"`

**Enums:**
- `enum :status` - unverified, pending_review, verified

**Validaciones:**
- `validates :name, :address, presence: true`
- `validates :prestige, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }`
- `validate :photos_limit`

**Callbacks:**
- `before_create :generate_uuid`
- `after_validation :geocode, if: :should_geocode?`

**Características especiales:**
- Geocodificación automática con Geocoder
- FriendlyId para slugs
- Límite de 15 fotos máximo

### 4. Team (Equipo)
**Archivo:** `app/models/team.rb`

**Asociaciones:**
- `belongs_to :club, optional: true`
- `belongs_to :clan, optional: true`
- `belongs_to :joinable, polymorphic: true, optional: true`
- `belongs_to :captain, class_name: 'User', optional: true`
- `has_many :callups, as: :teamable`
- `has_many :called_up_users, through: :callups`
- `has_many :home_duels, class_name: 'Duel'`
- `has_many :away_duels, class_name: 'Duel'`
- `has_many :results` (relación compleja con duelos)

**Enums:** No tiene enums definidos

**Validaciones:** No tiene validaciones específicas

**Callbacks:**
- `before_create :generate_uuid`
- `before_create :set_expiration_if_temporary`

### 5. Clan (Clan)
**Archivo:** `app/models/clan.rb`

**Asociaciones:**
- `belongs_to :king, class_name: 'User'`
- `has_many :admins`
- `has_many :users, through: :admins`
- `has_many :memberships, as: :joinable`
- `has_many :teams, as: :joinable`
- `has_many :team_memberships, through: :teams`
- `has_one_attached :avatar`

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :name, presence: true`

**Callbacks:**
- `before_validation :set_uuid, on: :create`
- `before_validation :set_slug, on: :create`
- `after_create :create_creator_membership`

### 6. Club (Club)
**Archivo:** `app/models/club.rb`

**Asociaciones:**
- `belongs_to :king, class_name: 'User'`
- `has_many :admins`
- `has_many :users, through: :admins`
- `has_many :memberships, as: :joinable`
- `has_many :teams, as: :joinable`
- `has_one_attached :avatar`

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :name, presence: true`
- `validates :user_id, presence: true`

**Callbacks:**
- `before_validation :set_uuid, on: :create`
- `before_validation :set_slug, on: :create`
- `after_create :create_king_membership`

## Modelos de Soporte

### 7. Membership (Membresía)
**Archivo:** `app/models/membership.rb`

**Asociaciones:**
- `belongs_to :user`
- `belongs_to :joinable, polymorphic: true` (Club o Clan)

**Enums:**
- `enum :status` - pending, approved, rejected
- `enum :role` - admin, member, king

**Validaciones:**
- `validates :user_id, uniqueness: { scope: [:joinable_type, :joinable_id] }`

**Callbacks:**
- `before_create :generate_uuid`

### 8. Challenge (Desafío)
**Archivo:** `app/models/challenge.rb`

**Asociaciones:**
- `belongs_to :challenger_duel, class_name: 'Duel'`
- `belongs_to :challengee_duel, class_name: 'Duel'`

**Enums:**
- `enum :status` - pending, accepted, rejected

**Validaciones:**
- `validates :challenger_duel_id, :challengee_duel_id, presence: true`
- `validates :challenger_duel_id, uniqueness: { scope: :challengee_duel_id }`

### 9. Callup (Convocatoria)
**Archivo:** `app/models/callup.rb`

**Asociaciones:**
- `belongs_to :duel, optional: true`
- `belongs_to :user`
- `belongs_to :teamable, polymorphic: true`

**Enums:**
- `enum :status` - pending, accepted, rejected

**Validaciones:**
- `validates :user_id, uniqueness: { scope: [:teamable_id, :teamable_type] }`

**Callbacks:**
- `before_create :generate_uuid`

### 10. Lineup (Alineación)
**Archivo:** `app/models/lineup.rb`

**Asociaciones:**
- `belongs_to :duel`
- `belongs_to :teamable, polymorphic: true`
- `belongs_to :user`

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :user_id, uniqueness: { scope: [:duel_id, :teamable_id, :teamable_type] }`

**Callbacks:**
- `before_create :generate_uuid`

### 11. Reservation (Reserva)
**Archivo:** `app/models/reservation.rb`

**Asociaciones:**
- `belongs_to :reservable, polymorphic: true`
- `belongs_to :payer, class_name: "User"`
- `belongs_to :receiver, class_name: "User"`

**Enums:**
- `enum :status` - held, reserved, paid, canceled

**Validaciones:**
- `validates :starts_at, :ends_at, presence: true`
- `validate :ends_after_start`
- `validate :no_overlap_for_arena`

**Callbacks:**
- `before_create :generate_uuid`

### 12. Result (Resultado)
**Archivo:** `app/models/result.rb`

**Asociaciones:**
- `belongs_to :referee, optional: true`
- `belongs_to :best_player, class_name: "User", optional: true`
- `belongs_to :home_teamable, polymorphic: true`
- `belongs_to :away_teamable, polymorphic: true`

**Enums:**
- `enum :outcome` - win, loss, draw

**Validaciones:** No tiene validaciones específicas

**Callbacks:**
- `before_create :generate_uuid`

### 13. Notification (Notificación)
**Archivo:** `app/models/notification.rb`

**Asociaciones:**
- `belongs_to :recipient, polymorphic: true`
- `belongs_to :sender, polymorphic: true`
- `belongs_to :notifiable, polymorphic: true, optional: true`

**Enums:**
- `enum :category` - callup, duel, club, team, general, challenge, club_association
- `enum :status` - unread, read

**Validaciones:**
- `validates :message, presence: true`

**Callbacks:**
- `before_create :generate_uuid`
- `after_create :send_notification`

### 14. Owner (Propietario)
**Archivo:** `app/models/owner.rb`

**Asociaciones:**
- `belongs_to :user`
- `has_many :arenas`

**Enums:**
- `enum :level` - basic, verified, pro, admin

**Validaciones:** No tiene validaciones específicas

**Callbacks:**
- `before_create :generate_uuid`

### 15. Referee (Árbitro)
**Archivo:** `app/models/referee.rb`

**Asociaciones:**
- `belongs_to :user`
- `has_many :duels`
- `has_many :reservations, as: :reservable`

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :fee, numericality: { greater_than_or_equal_to: 0 }`
- `validates :user_id, uniqueness: true`

**Callbacks:**
- `before_create :generate_uuid`

### 16. Admin (Administrador)
**Archivo:** `app/models/admin.rb`

**Asociaciones:**
- `belongs_to :user`
- `belongs_to :club, optional: true`
- `belongs_to :clan, optional: true`

**Enums:**
- `enum :level` - editor, admin, king, moderator

**Validaciones:**
- `validates :level, presence: true`

**Callbacks:**
- `before_create :generate_uuid`

## Modelos de Verificación y Horarios

### 17. ArenaVerification (Verificación de Arena)
**Archivo:** `app/models/arena_verification.rb`

**Asociaciones:**
- `belongs_to :arena`
- `belongs_to :submitted_by, class_name: "User"`

**Enums:**
- `enum :status` - draft, submitted, approved, rejected

**Validaciones:** No tiene validaciones específicas

**Callbacks:**
- `before_create { self.id ||= SecureRandom.uuid }`

### 18. ArenaBusinessHour (Horario de Negocio)
**Archivo:** `app/models/arena_business_hour.rb`

**Asociaciones:**
- `belongs_to :arena`

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :weekday, inclusion: { in: 0..6 }`
- `validates :opens_at, :closes_at, presence: true, unless: :closed?`
- `validate :range_valid`

**Callbacks:**
- `before_create { self.id ||= SecureRandom.uuid }`

### 19. ArenaClosure (Cierre de Arena)
**Archivo:** `app/models/arena_closure.rb`

**Asociaciones:**
- `belongs_to :arena`

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :starts_at, :ends_at, presence: true`
- `validate :range_valid`

**Callbacks:**
- `before_create { self.id ||= SecureRandom.uuid }`

### 20. DuelGoal (Gol de Duelo)
**Archivo:** `app/models/duel_goal.rb`

**Asociaciones:**
- `belongs_to :duel`
- `belongs_to :user`
- `belongs_to :team`

**Enums:** No tiene enums definidos

**Validaciones:** No tiene validaciones específicas

**Callbacks:**
- `before_create :generate_uuid`

### 21. Page (Página)
**Archivo:** `app/models/page.rb`

**Asociaciones:** No tiene asociaciones

**Enums:** No tiene enums definidos

**Validaciones:**
- `validates :title, presence: true`
- `validates :slug, presence: true, uniqueness: true`

**Callbacks:**
- `before_create :generate_uuid`
- `before_validation :generate_slug, on: :create`

## Patrones Comunes

### UUIDs
Todos los modelos principales usan UUIDs como identificadores primarios, generados automáticamente con `SecureRandom.uuid` en callbacks `before_create`.

### FriendlyId
Los modelos `User`, `Arena`, `Clan`, `Club` y `Page` usan FriendlyId para generar slugs amigables.

### Geocodificación
El modelo `Arena` incluye geocodificación automática usando la gema Geocoder.

### Active Storage
Los modelos `User`, `Arena`, `Clan` y `Club` usan Active Storage para manejo de archivos (avatares, fotos, etc.).

### Polimorfismo
Se usa polimorfismo en:
- `Membership` (joinable: Club o Clan)
- `Team` (joinable: Club o Clan)
- `Callup` (teamable: Team o TeamMembership)
- `Lineup` (teamable: Team o TeamMembership)
- `Reservation` (reservable: Arena o Referee)
- `Notification` (recipient, sender, notifiable)

### Enums Principales
- **Status de Duelo:** pending, open, ongoing, finished, merged, cancelled, postponed
- **Tipo de Duelo:** friendly, bet, rematch, training, hobbie
- **Status de Membresía:** pending, approved, rejected
- **Rol de Membresía:** admin, member, king
- **Nivel de Admin:** editor, admin, king, moderator
- **Nivel de Owner:** basic, verified, pro, admin
