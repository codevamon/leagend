module ApplicationHelper
  def parse_time_from_session(time_value)
    return nil if time_value.nil?
    
    if time_value.is_a?(String)
      Time.zone.parse(time_value)
    elsif time_value.is_a?(ActiveSupport::TimeWithZone) || time_value.is_a?(Time) || time_value.is_a?(DateTime)
      time_value
    else
      # Fallback para otros tipos
      Time.zone.parse(time_value.to_s)
    end
  rescue => e
    Rails.logger.error "Error parsing time from session: #{e.message}"
    Time.current
  end

  # Helper para obtener la ubicación actual del usuario
  def current_user_location
    if user_signed_in?
      # Usuario loggeado: obtener desde el modelo User
      user = current_user
      {
        country: user.current_country,
        city: user.current_city,
        latitude: user.current_latitude,
        longitude: user.current_longitude
      }
    else
      # Usuario no loggeado: obtener desde cookies
      {
        country: cookies[:location_country],
        city: cookies[:location_city],
        latitude: cookies[:location_latitude],
        longitude: cookies[:location_longitude]
      }
    end
  end

  # Helper para formatear la ubicación para mostrar
  def format_location_display(location)
    return "Ubicación no configurada" if location[:country].blank? && location[:city].blank?
    
    parts = []
    
    if location[:city].present?
      parts << location[:city]
    end
    
    if location[:country].present?
      parts << location[:country]
    end
    
    if location[:latitude].present? && location[:longitude].present?
      parts << "(Lat: #{location[:latitude]}, Lng: #{location[:longitude]})"
    end
    
    parts.join(", ")
  end

  # Helper para verificar si hay ubicación disponible
  def has_location_data?(location)
    location[:country].present? || location[:city].present? || 
    location[:latitude].present? || location[:longitude].present?
  end
end
