class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # protect_from_forgery with: :exception, unless: -> { request.env['omniauth.origin'].present? }
  protect_from_forgery with: :exception, unless: -> { request.path.start_with?('/auth/') }
  before_action :configure_devise_params, if: :devise_controller?

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
end
