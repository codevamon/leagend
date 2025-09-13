# Seeds para Arena Blocks - Sistema Global de Calendarios (SGC)
# Permitir que owners verificados bloqueen horarios de sus arenas

puts "🌱 Creando seeds para Arena Blocks..."

# Usar la arena existente y hacer que su owner sea verificado
arena_central = Arena.find_by(name: "Arena de Prueba SGC")
if arena_central.nil?
  puts "❌ Error: Arena de Prueba SGC no encontrada. Ejecuta primero los seeds de reservations."
  exit
end

# Hacer que el owner de la arena sea verificado
arena_central.owner.update!(level: "verified")
owner_verified = arena_central.owner

puts "✅ Owner verificado actualizado: #{owner_verified.id}"
puts "✅ Arena Central: #{arena_central.name}"

# Crear bloqueos de arena por el owner verificado
puts "📅 Creando bloqueos de arena..."

# 1. Bloqueo por feriado completo (8 horas)
feriado_block = Reservation.find_or_create_by!(
  reservable: arena_central,
  payer: owner_verified.user,
  receiver: owner_verified.user,
  starts_at: 1.day.from_now.beginning_of_day,        # Mañana a las 00:00
  ends_at: 1.day.from_now.beginning_of_day + 8.hours # Mañana a las 08:00
) do |r|
  r.status = :blocked
  r.amount_cents = 0
  r.duration_minutes = 480 # 8 horas
end

puts "✅ Bloqueo por feriado creado: #{feriado_block.id}"

# 2. Bloqueo por mantenimiento (4 horas)
mantenimiento_block = Reservation.find_or_create_by!(
  reservable: arena_central,
  payer: owner_verified.user,
  receiver: owner_verified.user,
  starts_at: 3.days.from_now.beginning_of_day + 14.hours,  # En 3 días a las 2:00 PM
  ends_at: 3.days.from_now.beginning_of_day + 18.hours     # En 3 días a las 6:00 PM
) do |r|
  r.status = :blocked
  r.amount_cents = 0
  r.duration_minutes = 240 # 4 horas
end

puts "✅ Bloqueo por mantenimiento creado: #{mantenimiento_block.id}"

# 3. Bloqueo por evento privado (6 horas)
evento_block = Reservation.find_or_create_by!(
  reservable: arena_central,
  payer: owner_verified.user,
  receiver: owner_verified.user,
  starts_at: 5.days.from_now.beginning_of_day + 18.hours,  # En 5 días a las 6:00 PM
  ends_at: 5.days.from_now.beginning_of_day + 24.hours      # En 5 días a las 12:00 AM
) do |r|
  r.status = :blocked
  r.amount_cents = 0
  r.duration_minutes = 360 # 6 horas
end

puts "✅ Bloqueo por evento privado creado: #{evento_block.id}"

puts "🎯 Seeds de Arena Blocks completados!"
puts "📊 Resumen:"
puts "   - 1 owner verificado"
puts "   - 1 arena verificada"
puts "   - 3 bloqueos de arena (feriado, mantenimiento, evento privado)"
puts ""
puts "🧪 Tests manuales posibles:"
puts "   - Owner verificado crea bloqueo → válido"
puts "   - Owner no verificado crea bloqueo → error"
puts "   - Otro usuario intenta crear → error"
