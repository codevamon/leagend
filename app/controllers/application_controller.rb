class ApplicationController < ActionController::Base
  include DetectsLocation
  include GuestLocationCache
  
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # protect_from_forgery with: :exception, unless: -> { request.env['omniauth.origin'].present? }
  protect_from_forgery with: :exception, unless: -> { request.path.start_with?('/auth/') }
  before_action :configure_devise_params, if: :devise_controller?
  before_action :ensure_location_cached
  before_action :backfill_user_location_from_cookies

  def find_user_name
    if user_signed_in?
      return current_user.id
    end
  end

  # def after_sign_in_path_for(resource)
  #   console_path
  # end

  protected

  def configure_devise_params
    devise_parameter_sanitizer.permit(:sign_in) do |user_params|
      user_params.permit(:email, :password, :remember_me)
    end

    devise_parameter_sanitizer.permit(:sign_up) do |user|
      user.permit(:firstname, :lastname, :email, :birthday, :password, :password_confirmation, :slug, :remember_me)
    end

    devise_parameter_sanitizer.permit(:account_update) do |user|
      user.permit(:firstname, :lastname, :email, :birthday, :password, :password_confirmation, :slug, 
                  :bio, :owner, :partner, :active, :live, :prestige, :height_cm, 
                  :fav, :skills, :rate, :shot, :pass, :cross, :dribbling,
                  :defense, :position, :dorsal, :status, :latitude, :longitude, :coverpage, :avatar,
                  :phone_number, :country_code)
    end
  end

  # Rellena current_* solo cuando el usuario esté logueado y falten país/ciudad.
  # Nunca bloquea el request; si algo falla, solo loguea debug y sigue.
  def backfill_user_location_from_cookies
    return unless user_signed_in?

    # Solo si alguno falta
    needs_country = current_user.respond_to?(:current_country) && current_user.current_country.blank?
    needs_city    = current_user.respond_to?(:current_city)    && current_user.current_city.blank?
    needs_latlng  = (current_user.respond_to?(:current_latitude)  && current_user.current_latitude.blank?) ||
                    (current_user.respond_to?(:current_longitude) && current_user.current_longitude.blank?)

    return unless needs_country || needs_city || needs_latlng
    return unless has_guest_location_cookies?

    changes = {}
    changes[:current_country]   = guest_country if needs_country && guest_country.present?
    changes[:current_city]      = guest_city    if needs_city    && guest_city.present?

    # Guarda lat/lng si están disponibles y faltan
    if needs_latlng && guest_lat.present? && guest_lng.present?
      changes[:current_latitude]  = guest_lat
      changes[:current_longitude] = guest_lng
    end

    return if changes.empty?

    # Persistimos sin validaciones para no bloquear
    current_user.update_columns(changes)
  rescue => e
    Rails.logger.debug("[geo-backfill] skip: #{e.class}: #{e.message}")
  end
end
