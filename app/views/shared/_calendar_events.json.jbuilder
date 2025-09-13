# Partial para centralizar eventos del calendario
# Genera JSON para FullCalendar con reservas y disponibilidades

# Eventos de reservas
json.array! reservations do |r|
  json.title case r.status
             when "held" then "Reserva Tentativa"
             when "reserved" then "Reservado"
             when "paid" then "Pagado"
             when "canceled" then "Cancelado"
             when "blocked" then "Bloqueado"
             else r.status&.humanize || "Sin Estado"
             end
  json.start r.starts_at
  json.end r.ends_at
  json.color case r.status
             when "blocked" then "#dc2626"      # Rojo para bloqueos
             when "reserved" then "#16a34a"     # Verde para reservado
             when "paid" then "#059669"         # Verde oscuro para pagado
             when "canceled" then "#6b7280"     # Gris para cancelado
             when "held" then "#f59e0b"         # Naranja para tentativo
             else "#6366f1"                     # Azul por defecto
             end
  json.editable false
  json.selectable false
  json.className "reservation-event"
  json.extendedProps do
    json.type "reservation"
    json.status r.status
    json.reservable_type r.reservable_type
    json.id r.id
  end
end

# Eventos de disponibilidades
json.array! availabilities do |a|
  json.title a.reason.present? ? a.reason : (a.status == "blocked" ? "No Disponible" : "Disponible")
  json.start a.starts_at
  json.end a.ends_at
  json.color a.status == "blocked" ? "#1e40af" : "#eab308"  # Azul para bloqueado, amarillo para disponible
  json.editable false
  json.selectable false
  json.className "availability-event"
  json.extendedProps do
    json.type "availability"
    json.status a.status
    json.availablable_type a.availablable_type
    json.id a.id
  end
end
