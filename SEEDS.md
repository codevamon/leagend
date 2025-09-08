# Documentación de Seeds - Leagend

## Estado Actual de Seeds

### Archivo Principal
**Archivo:** `db/seeds.rb`

**Estado:** El archivo está prácticamente vacío, solo contiene comentarios de ejemplo. No hay datos iniciales implementados.

```ruby
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
```

### Archivos Adicionales
- **`db/seeds/`** - Directorio no existe
- **`lib/tasks/`** - Solo contiene `assets_diag.rake` (diagnóstico de assets)
- **No hay archivos de seeds adicionales**

## Recomendaciones para Implementar Seeds

### 1. Usuarios Demo
```ruby
# Usuario administrador
admin_user = User.find_or_create_by!(email: "admin@leagend.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Admin"
  user.last_name = "Leagend"
  user.phone = "+1234567890"
end

# Usuarios regulares
users = [
  { email: "player1@leagend.com", first_name: "Juan", last_name: "Pérez" },
  { email: "player2@leagend.com", first_name: "María", last_name: "García" },
  { email: "player3@leagend.com", first_name: "Carlos", last_name: "López" }
]

users.each do |user_data|
  User.find_or_create_by!(email: user_data[:email]) do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.first_name = user_data[:first_name]
    user.last_name = user_data[:last_name]
    user.phone = "+1234567890"
  end
end
```

### 2. Arenas de Ejemplo
```ruby
# Propietarios de arenas
owners = User.limit(3)
owners.each_with_index do |user, index|
  owner = Owner.find_or_create_by!(user: user) do |o|
    o.level = :verified
  end
  
  Arena.find_or_create_by!(name: "Arena #{index + 1}") do |arena|
    arena.owner = owner
    arena.address = "Calle #{index + 1}, Ciudad"
    arena.latitude = 40.7128 + (index * 0.01)
    arena.longitude = -74.0060 + (index * 0.01)
    arena.capacity = 20
    arena.price_per_hour = 50.0
  end
end
```

### 3. Clubs y Clanes
```ruby
# Clubs
clubs = [
  { name: "Club Deportivo Central", description: "Club principal de la ciudad" },
  { name: "Club Atlético Norte", description: "Club del norte de la ciudad" },
  { name: "Club Deportivo Sur", description: "Club del sur de la ciudad" }
]

clubs.each do |club_data|
  club = Club.find_or_create_by!(name: club_data[:name]) do |c|
    c.description = club_data[:description]
    c.owner = User.first
  end
  
  # Crear membresías para algunos usuarios
  User.limit(5).each do |user|
    Membership.find_or_create_by!(user: user, joinable: club) do |membership|
      membership.role = :member
      membership.status = :approved
    end
  end
end

# Clanes
clans = [
  { name: "Clan Warriors", description: "Clan de jugadores experimentados" },
  { name: "Clan Legends", description: "Clan de leyendas del fútbol" }
]

clans.each do |clan_data|
  clan = Clan.find_or_create_by!(name: clan_data[:name]) do |c|
    c.description = clan_data[:description]
    c.owner = User.second
  end
  
  # Crear membresías
  User.limit(3).each do |user|
    Membership.find_or_create_by!(user: user, joinable: clan) do |membership|
      membership.role = :member
      membership.status = :approved
    end
  end
end
```

### 4. Duelos de Prueba
```ruby
# Crear equipos
teams = []
User.limit(10).each_slice(5) do |users|
  team = Team.create!(
    name: "Equipo #{teams.count + 1}",
    captain: users.first
  )
  
  # Agregar miembros al equipo
  users.each do |user|
    TeamMembership.create!(team: team, user: user)
  end
  
  teams << team
end

# Crear duelos
duels = [
  {
    home_team: teams[0],
    starts_at: 1.day.from_now,
    ends_at: 1.day.from_now + 2.hours,
    duel_type: :friendly,
    challenge_type: :direct,
    arena: Arena.first
  },
  {
    home_team: teams[1],
    starts_at: 2.days.from_now,
    ends_at: 2.days.from_now + 2.hours,
    duel_type: :training,
    challenge_type: :challengee,
    arena: Arena.second
  }
]

duels.each do |duel_data|
  Duel.create!(duel_data)
end
```

### 5. Reservaciones de Ejemplo
```ruby
# Reservaciones para arenas
Arena.limit(2).each do |arena|
  Reservation.create!(
    reservable: arena,
    user: User.first,
    start_time: 1.day.from_now,
    end_time: 1.day.from_now + 2.hours,
    status: :confirmed
  )
end
```

## Estructura Recomendada

### Archivos de Seeds Organizados
```
db/seeds/
├── 01_users.rb          # Usuarios y administradores
├── 02_owners.rb          # Propietarios de arenas
├── 03_arenas.rb          # Arenas y horarios
├── 04_clubs_clans.rb     # Clubs y clanes
├── 05_teams.rb           # Equipos
├── 06_duels.rb           # Duelos de prueba
├── 07_reservations.rb    # Reservaciones
└── 08_notifications.rb   # Notificaciones de ejemplo
```

### Comando para Ejecutar Seeds
```bash
# Ejecutar todos los seeds
rails db:seed

# Ejecutar seeds específicos
rails db:seed:replant
```

## Notas Importantes

1. **No hay seeds de roles** - Los roles se asignan manualmente o a través de la lógica de negocio
2. **No hay seeds de pagos** - No existe sistema de pagos implementado
3. **No hay datos de Stripe** - No hay integración con Stripe configurada
4. **Seeds vacíos** - La aplicación necesita implementar seeds para desarrollo y testing

## Próximos Pasos

1. Implementar seeds básicos para desarrollo
2. Crear seeds específicos para testing
3. Implementar seeds para producción (datos mínimos)
4. Documentar el proceso de seeding
5. Crear tasks de Rake para diferentes entornos
