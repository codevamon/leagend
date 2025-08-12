class GeoController < ApplicationController
  include DetectsLocation
  
  before_action :ensure_location_cached, only: [:current]
  
  # GET /geo/current
  # Retorna la ubicación actual (por IP o cacheada)
  def current
    location = cached_location
    
    respond_to do |format|
      format.json do
        if location.any?
          render json: { 
            success: true, 
            location: location,
            source: 'ip_detection'
          }
        else
          render json: { 
            success: false, 
            message: "No se pudo detectar ubicación" 
          }, status: :unprocessable_entity
        end
      end
      
      format.html do
        redirect_to root_path
      end
    end
  end

  # PATCH /geo/update
  # Actualiza ubicación exacta del usuario (HTML5 Geolocation)
  def update
    unless user_signed_in?
      render json: { 
        success: false, 
        message: "Usuario debe estar loggeado" 
      }, status: :unauthorized
      return
    end

    lat = params[:latitude]
    lng = params[:longitude]
    zip = params[:zip]
    timezone = params[:timezone]
    city = params[:city]
    country = params[:country]
    country_code = params[:country_code]

    # Para backfill desde localStorage, permitir actualización sin coordenadas
    if city.present? && country.present? && lat.blank? && lng.blank?
      # Backfill desde localStorage - solo actualizar city/country
      result = update_location_from_backfill(city, country, country_code)
      if result[:success]
        render json: result
      else
        render json: result, status: :unprocessable_entity
      end
      return
    end

    # Validar coordenadas básicas para actualizaciones normales
    unless lat.present? && lng.present?
      render json: { 
        success: false, 
        message: "Coordenadas latitud y longitud son requeridas" 
      }, status: :unprocessable_entity
      return
    end

    # Validar formato de coordenadas
    begin
      lat_float = Float(lat)
      lng_float = Float(lng)
      
      unless lat_float.between?(-90, 90) && lng_float.between?(-180, 180)
        render json: { 
          success: false, 
          message: "Coordenadas fuera de rango válido" 
        }, status: :unprocessable_entity
        return
      end
    rescue ArgumentError
      render json: { 
        success: false, 
        message: "Formato de coordenadas inválido" 
      }, status: :unprocessable_entity
      return
    end

    # Actualizar ubicación
    result = update_exact_location(lat, lng, zip, timezone, city, country, country_code)
    
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  private

  # Actualiza ubicación desde backfill (localStorage) sin coordenadas
  def update_location_from_backfill(city, country, country_code)
    return { success: false, message: "Usuario debe estar loggeado" } unless user_signed_in?
    
    user = current_user
    changes = {}
    
    # Solo actualizar si cambió
    changes[:current_city] = city if city && user.current_city != city
    changes[:current_country] = country if country && user.current_country != country
    changes[:current_country_code] = country_code if country_code && user.current_country_code != country_code
    
    if changes.any?
      user.update(changes)
      Rails.logger.info "Backfill de ubicación completado para usuario #{user.id}: #{changes.inspect}"
      { success: true, message: "Ubicación actualizada desde backfill" }
    else
      { success: false, message: "No hay cambios para actualizar" }
    end
  rescue => e
    Rails.logger.error "Error en backfill de ubicación: #{e.message}"
    { success: false, message: "Error actualizando ubicación desde backfill" }
  end

  # Solo permitir parámetros seguros
  def geo_params
    params.permit(:latitude, :longitude, :zip, :timezone, :city, :country, :country_code)
  end
end
