module DetectsLocation
  extend ActiveSupport::Concern

  # Método público para acceder a la ubicación desde otros controladores
  def current_location
    cached_location
  end

  private

  # Detecta ubicación por IP y la guarda en cookies/sesión
  def ensure_location_cached
    return if location_already_cached?
    
    location = detect_location_by_ip
    return unless location
    
    cache_location(location)
    update_user_location(location) if user_signed_in?
  end

  # Verifica si ya tenemos ubicación cacheada
  def location_already_cached?
    session[:location_detected] || cookies[:location_country].present?
  end

  # Detecta ubicación aproximada por IP usando servicio gratuito
  def detect_location_by_ip
    return nil if Rails.env.test?
    
    begin
      # Usar ipinfo.io (gratuito, 50k requests/mes)
      response = Net::HTTP.get_response(URI("http://ipinfo.io/json"))
      return nil unless response.is_a?(Net::HTTPSuccess)
      
      data = JSON.parse(response.body)
      
      {
        country: data['country'],
        city: data['city'],
        region: data['region'],
        timezone: data['timezone']
      }
    rescue => e
      Rails.logger.warn "Error detectando ubicación por IP: #{e.message}"
      nil
    end
  end

  # Guarda ubicación en cookies y sesión
  def cache_location(location)
    # Cookies (persistentes)
    cookies[:location_country] = location[:country] if location[:country]
    cookies[:location_city] = location[:city] if location[:city]
    cookies[:location_region] = location[:region] if location[:region]
    cookies[:location_timezone] = location[:timezone] if location[:timezone]
    
    # Sesión (temporal)
    session[:location_detected] = true
    session[:location_data] = location
    
    Rails.logger.info "Ubicación cacheada: #{location.inspect}"
  end

  # Actualiza ubicación del usuario en DB si está loggeado
  def update_user_location(location)
    return unless user_signed_in?
    
    user = current_user
    changes = {}
    
    # Solo actualizar si cambió
    changes[:current_country] = location[:country] if location[:country] && user.current_country != location[:country]
    changes[:current_city] = location[:city] if location[:city] && user.current_city != location[:city]
    
    if changes.any?
      user.update(changes)
      Rails.logger.info "Ubicación actualizada para usuario #{user.id}: #{changes.inspect}"
    end
  end

  # Obtiene ubicación cacheada
  def cached_location
    {
      country: cookies[:location_country] || session.dig(:location_data, :country),
      city: cookies[:location_city] || session.dig(:location_data, :city),
      region: cookies[:location_region] || session.dig(:location_data, :region),
      timezone: cookies[:location_timezone] || session.dig(:location_data, :timezone)
    }.compact
  end

  # Actualiza ubicación exacta del usuario (HTML5 Geolocation)
  def update_exact_location(lat, lng, zip = nil, timezone = nil, city = nil, country = nil, country_code = nil)
    return unless user_signed_in?
    
    user = current_user
    changes = {}
    
    # Convertir coordenadas a string para mantener consistencia con DB
    changes[:current_latitude] = lat.to_s if lat
    changes[:current_longitude] = lng.to_s if lng
    changes[:current_zip] = zip if zip
    changes[:current_timezone] = timezone if timezone
    
    # Añadir city y country si están disponibles
    changes[:current_city] = city if city
    changes[:current_country] = country if country
    
    if changes.any?
      user.update(changes)
      
      # También guardar coordenadas en cookies para usuarios no loggeados
      if lat && lng
        cookies[:location_latitude] = lat.to_s
        cookies[:location_longitude] = lng.to_s
      end
      
      # Guardar city y country en cookies también
      if city
        cookies[:location_city] = city
      end
      if country
        cookies[:location_country] = country
      end
      
      Rails.logger.info "Ubicación exacta actualizada para usuario #{user.id}: #{changes.inspect}"
      { success: true, message: "Ubicación actualizada" }
    else
      { success: false, message: "No hay cambios para actualizar" }
    end
  rescue => e
    Rails.logger.error "Error actualizando ubicación exacta: #{e.message}"
    { success: false, message: "Error actualizando ubicación" }
  end
end
