# Documentación de Roles - Leagend

## Sistema de Roles

### Estructura General
El sistema de roles en Leagend está distribuido en múltiples modelos, cada uno con su propio enum de roles/niveles. No hay un rol directo en el modelo User.

## 1. Roles de Membresía (Membership)

### Modelo: `Membership`
**Archivo:** `app/models/membership.rb`

**Enum:** `role`
```ruby
enum :role, { admin: 0, member: 1, king: 2 }
```

**Jerarquía de Roles:**
- **`king` (2)** - Rey/Propietario del club/clan
  - Máximo nivel de autoridad
  - Puede gestionar completamente el club/clan
  - Puede asignar y revocar roles de otros miembros
  - Puede eliminar el club/clan

- **`admin` (0)** - Administrador del club/clan
  - Puede gestionar miembros
  - Puede aprobar/rechazar solicitudes de membresía
  - Puede crear y gestionar duelos del club/clan
  - No puede eliminar el club/clan

- **`member` (1)** - Miembro regular
  - Puede participar en duelos del club/clan
  - Puede ver información del club/clan
  - No tiene permisos administrativos

**Asociaciones:**
- `belongs_to :user`
- `belongs_to :joinable, polymorphic: true` (Club o Clan)

**Validaciones:**
- Un usuario no puede tener múltiples membresías en la misma entidad
- Validación de unicidad por `user_id`, `joinable_type`, `joinable_id`

## 2. Niveles de Administrador (Admin)

### Modelo: `Admin`
**Archivo:** `app/models/admin.rb`

**Enum:** `level`
```ruby
enum :level, { editor: 0, admin: 1, king: 2, moderator: 3 }
```

**Jerarquía de Niveles:**
- **`king` (2)** - Rey/Propietario
  - Control total sobre el club/clan
  - Puede asignar cualquier nivel de admin
  - Puede eliminar el club/clan

- **`moderator` (3)** - Moderador
  - Puede moderar contenido y duelos
  - Puede gestionar disputas
  - Puede suspender miembros temporalmente

- **`admin` (1)** - Administrador
  - Puede gestionar miembros y duelos
  - Puede aprobar/rechazar solicitudes
  - Puede crear contenido del club/clan

- **`editor` (0)** - Editor básico
  - Puede editar contenido del club/clan
  - Puede crear duelos
  - Permisos limitados de gestión

**Asociaciones:**
- `belongs_to :user`
- `belongs_to :club, optional: true`
- `belongs_to :clan, optional: true`

**Validaciones:**
- `level` es obligatorio

## 3. Niveles de Propietario (Owner)

### Modelo: `Owner`
**Archivo:** `app/models/owner.rb`

**Enum:** `level`
```ruby
enum :level, { basic: 0, verified: 1, pro: 2, admin: 3 }
```

**Jerarquía de Niveles:**
- **`admin` (3)** - Administrador del sistema
  - Control total sobre todas las arenas
  - Puede gestionar otros propietarios
  - Acceso a funciones administrativas del sistema

- **`pro` (2)** - Propietario profesional
  - Arenas de alta calidad
  - Acceso a funciones premium
  - Soporte prioritario
  - Puede gestionar múltiples arenas

- **`verified` (1)** - Propietario verificado
  - Arena verificada por el sistema
  - Acceso a funciones avanzadas
  - Prioridad en búsquedas

- **`basic` (0)** - Propietario básico
  - Nivel inicial
  - Funciones básicas de gestión de arena
  - Limitaciones en funciones avanzadas

**Asociaciones:**
- `belongs_to :user`
- `has_many :arenas, foreign_key: :owner_id`

## 4. Árbitros (Referee)

### Modelo: `Referee`
**Archivo:** `app/models/referee.rb`

**Características:**
- No tiene enum de roles/niveles
- Cada usuario puede ser solo un árbitro
- Tiene una tarifa (`fee`) asociada

**Asociaciones:**
- `belongs_to :user`
- `has_many :duels`
- `has_many :reservations, as: :reservable`

**Validaciones:**
- `fee` debe ser mayor o igual a 0
- `user_id` debe ser único (un usuario = un árbitro)

**Funcionalidades:**
- `available_between?(start_time, end_time)` - Verificar disponibilidad

## 5. Usuario (User)

### Modelo: `User`
**Archivo:** `app/models/user.rb`

**Características:**
- No tiene enum de roles directo
- Los roles se manejan a través de asociaciones:
  - `has_one :owner` - Puede ser propietario de arena
  - `has_one :referee` - Puede ser árbitro
  - `has_many :admins` - Puede ser admin de clubs/clanes
  - `has_many :memberships` - Puede ser miembro de clubs/clanes

## Flujo de Autorización

### 1. Gestión de Club/Clan
```ruby
# Verificar si un usuario puede gestionar un club
def can_manage_club?(user, club)
  return false unless user.present? && club.present?
  
  # Es el propietario del club
  return true if club.owner == user
  
  # Es admin del club con nivel suficiente
  admin = club.admins.find_by(user: user)
  return true if admin&.level.in?(['admin', 'king', 'moderator'])
  
  # Es miembro con rol de king
  membership = club.memberships.find_by(user: user)
  return true if membership&.role == 'king'
  
  false
end
```

### 2. Gestión de Arena
```ruby
# Verificar si un usuario puede gestionar una arena
def can_manage_arena?(user, arena)
  return false unless user.present? && arena.present?
  
  # Es el propietario de la arena
  return true if arena.owner.user == user
  
  # Es admin del sistema
  return true if arena.owner.level == 'admin'
  
  false
end
```

### 3. Gestión de Duelo
```ruby
# Verificar si un usuario puede gestionar un duelo
def can_manage_duel?(user, duel)
  return false unless user.present? && duel.present?
  
  # Es capitán de algún equipo
  return true if duel.home_team&.captain == user
  return true if duel.away_team&.captain == user
  
  # Es árbitro del duelo
  return true if duel.referee == user
  
  # Es admin del club/clan asociado
  if duel.club.present?
    return true if duel.club.admins.exists?(user: user, level: ['admin', 'king'])
  end
  
  if duel.clan.present?
    return true if duel.clan.admins.exists?(user: user, level: ['admin', 'king'])
  end
  
  false
end
```

## Casos de Uso Comunes

### 1. Crear Club
```ruby
# Solo usuarios regulares pueden crear clubs
def can_create_club?(user)
  user.present? && !user.owner.present?
end
```

### 2. Aplicar para Membresía
```ruby
# Cualquier usuario puede aplicar para membresía
def can_apply_for_membership?(user, joinable)
  return false unless user.present? && joinable.present?
  
  # No puede aplicar si ya es miembro
  !joinable.memberships.exists?(user: user)
end
```

### 3. Asignar Árbitro
```ruby
# Solo admins pueden asignar árbitros
def can_assign_referee?(user, duel)
  return false unless user.present? && duel.present?
  
  # Es admin del club/clan asociado
  if duel.club.present?
    return duel.club.admins.exists?(user: user, level: ['admin', 'king'])
  end
  
  if duel.clan.present?
    return duel.clan.admins.exists?(user: user, level: ['admin', 'king'])
  end
  
  false
end
```

## Notas Importantes

1. **No hay roles globales** - Todos los roles son contextuales a entidades específicas
2. **Jerarquía flexible** - Diferentes modelos tienen diferentes jerarquías
3. **Polimorfismo** - Membership puede ser para Club o Clan
4. **Validaciones** - Cada modelo tiene sus propias validaciones de roles
5. **Escalabilidad** - El sistema permite agregar nuevos niveles sin afectar existentes
