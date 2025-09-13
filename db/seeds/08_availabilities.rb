# Seeds para Availabilities - Sistema Global de Calendarios (SGC)
# Crear datos mínimos para testing de bloqueos personales

puts "🌱 Creando seeds para Availabilities..."

# Obtener usuarios existentes de los seeds anteriores
user1 = User.find_by(email: "test_user@leagend.com")
referee1 = User.find_by(email: "referee@leagend.com")

if user1.nil? || referee1.nil?
  puts "❌ Error: Usuarios no encontrados. Ejecuta primero los seeds de reservations."
  exit
end

puts "📊 Usuarios encontrados:"
puts "  - User: #{user1.email}"
puts "  - Referee: #{referee1.email}"

# Crear availabilities de prueba
puts "📅 Creando availabilities de prueba..."

# 1. Referee bloqueado por vacaciones (3 días)
referee_vacation = Availability.find_or_create_by!(
  availablable: referee1,
  starts_at: 1.day.from_now.beginning_of_day,    # Mañana a las 00:00
  ends_at: 3.days.from_now.end_of_day,           # En 3 días a las 23:59
  reason: "Vacaciones",
  status: :blocked
)

puts "✅ Referee bloqueado por vacaciones: #{referee_vacation.id}"

# 2. User bloqueado por lesión (4 horas)
user_injury = Availability.find_or_create_by!(
  availablable: user1,
  starts_at: 2.days.from_now.beginning_of_day + 8.hours,  # En 2 días a las 8:00 AM
  ends_at: 2.days.from_now.beginning_of_day + 12.hours,   # En 2 días a las 12:00 PM
  reason: "Lesión en la rodilla",
  status: :blocked
)

puts "✅ User bloqueado por lesión: #{user_injury.id}"

# 3. Referee disponible (ventana de disponibilidad)
referee_available = Availability.find_or_create_by!(
  availablable: referee1,
  starts_at: 5.days.from_now.beginning_of_day + 9.hours,  # En 5 días a las 9:00 AM
  ends_at: 5.days.from_now.beginning_of_day + 17.hours,   # En 5 días a las 5:00 PM
  reason: "Horario disponible",
  status: :available
)

puts "✅ Referee disponible: #{referee_available.id}"

# 4. User disponible (fin de semana)
user_available = Availability.find_or_create_by!(
  availablable: user1,
  starts_at: 6.days.from_now.beginning_of_day,    # En 6 días (sábado)
  ends_at: 7.days.from_now.end_of_day,            # En 7 días (domingo)
  reason: "Fin de semana disponible",
  status: :available
)

puts "✅ User disponible: #{user_available.id}"

puts "🎯 Seeds de Availabilities completados!"
puts "📊 Resumen:"
puts "   - 1 referee bloqueado por vacaciones (3 días)"
puts "   - 1 user bloqueado por lesión (4 horas)"
puts "   - 1 referee disponible (8 horas)"
puts "   - 1 user disponible (fin de semana)"
puts ""
puts "🧪 Tests manuales posibles:"
puts "   - Crear availabilities que se solapen → falla validación"
puts "   - Crear blocked válido → pasa validación"
puts "   - Crear available válido → pasa validación"
