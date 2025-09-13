# Seeds para Reservations - Sistema Global de Calendarios (SGC)
# Crear datos mínimos para testing de validaciones y estados

puts "🌱 Creando seeds para Reservations..."

# Crear usuarios de prueba si no existen
user1 = User.find_or_create_by!(email: "test_user@leagend.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.firstname = "Usuario"
  u.lastname = "Prueba"
  u.phone_number = "3001234567"
end

referee1 = User.find_or_create_by!(email: "referee@leagend.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.firstname = "Referee"
  u.lastname = "Prueba"
  u.phone_number = "3007654321"
end

# Crear owner para la arena
owner1 = Owner.find_or_create_by!(user: user1) do |o|
  o.level = "verified"
end

# Crear arena de prueba si no existe
arena1 = Arena.find_or_create_by!(name: "Arena de Prueba SGC") do |a|
  a.owner = owner1
  a.address = "Calle 123 #45-67, Bogotá"
  a.latitude = 4.6097
  a.longitude = -74.0817
  a.price_per_hour = 50000.0 # $50,000 COP
  a.rentable = true
  a.status = "verified"
end

# Crear reservas de prueba
puts "📅 Creando reservas de prueba..."

# 1. Reserva bloqueada para arena (status: blocked)
blocked_reservation = Reservation.find_or_create_by!(
  reservable: arena1,
  payer: user1,
  receiver: user1,
  starts_at: Time.current.beginning_of_day + 9.hours, # 9:00 AM hoy
  ends_at: Time.current.beginning_of_day + 10.hours   # 10:00 AM hoy
) do |r|
  r.status = :blocked
  r.amount_cents = 0
  r.duration_minutes = 60
end

puts "✅ Reserva bloqueada creada: #{blocked_reservation.id}"

# 2. Reserva confirmada para usuario (status: reserved) - 60 min por defecto
user_reservation = Reservation.find_or_create_by!(
  reservable: arena1,
  payer: user1,
  receiver: user1,
  starts_at: Time.current.beginning_of_day + 14.hours, # 2:00 PM hoy
  ends_at: Time.current.beginning_of_day + 15.hours     # 3:00 PM hoy (60 min)
) do |r|
  r.status = :reserved
  r.amount_cents = 50000
  r.duration_minutes = 60
end

puts "✅ Reserva de usuario creada: #{user_reservation.id}"

# 3. Reserva tentativa para referee (status: held)
referee_reservation = Reservation.find_or_create_by!(
  reservable: arena1,
  payer: referee1,
  receiver: referee1,
  starts_at: Time.current.beginning_of_day + 18.hours, # 6:00 PM hoy
  ends_at: Time.current.beginning_of_day + 19.hours     # 7:00 PM hoy (60 min)
) do |r|
  r.status = :held
  r.amount_cents = 50000
  r.duration_minutes = 60
end

puts "✅ Reserva tentativa de referee creada: #{referee_reservation.id}"

puts "🎯 Seeds de Reservations completados!"
puts "📊 Resumen:"
puts "   - 1 reserva bloqueada (arena)"
puts "   - 1 reserva confirmada (usuario)"
puts "   - 1 reserva tentativa (referee)"
puts "   - Todas con duración de 60 minutos"
puts ""
puts "🧪 Tests manuales posibles:"
puts "   - Crear reservas que se solapen → falla validación"
puts "   - Crear blocked por arena → pasa validación"
puts "   - Crear held → al confirmar pasa a reserved"
