# frozen_string_literal: true
module GuestLocationCache
  extend ActiveSupport::Concern

  # Intenta ambas variantes (firmada y normal) para mayor compatibilidad
  def guest_country
    cookies.signed[:lgd_country] || cookies[:lgd_country] || nil
  end

  def guest_city
    cookies.signed[:lgd_city] || cookies[:lgd_city] || nil
  end

  def guest_lat
    (cookies.signed[:lgd_lat] || cookies[:lgd_lat]).presence
  end

  def guest_lng
    (cookies.signed[:lgd_lng] || cookies[:lgd_lng]).presence
  end

  # Flag compacto para saber si tenemos algo útil
  def has_guest_location_cookies?
    guest_country.present? || guest_city.present? || (guest_lat.present? && guest_lng.present?)
  end
end
