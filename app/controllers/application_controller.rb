class ApplicationController < ActionController::Base
  include DetectsLocation
  
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

  # Backfill de ubicación desde cookies de invitados para usuarios logueados
  def backfill_user_location_from_cookies
    return unless user_signed_in?
    return unless current_user.current_country.blank? || current_user.current_city.blank?
    return unless has_guest_location_cookies?
    
    begin
      changes = {}
      changes[:current_country] = guest_country_from_cookie if current_user.current_country.blank? && guest_country_from_cookie.present?
      changes[:current_city] = guest_city_from_cookie if current_user.current_city.blank? && guest_city_from_cookie.present?
      changes[:current_country_code] = guest_country_code_from_cookie if current_user.current_country_code.blank? && guest_country_code_from_cookie.present?
      
      if changes.any?
        current_user.update_columns(changes)
        Rails.logger.debug "Backfill de ubicación completado para usuario #{current_user.id}: #{changes.inspect}"
      end
    rescue => e
      Rails.logger.error "Error en backfill de ubicación para usuario #{current_user.id}: #{e.message}"
    end
  end
end
