# Configuración de Geocoder para Mapbox
Geocoder.configure(
  # Configuración global
  timeout: 5,
  lookup: :mapbox,
  
  # API Key de Mapbox (token secreto para backend)
  api_key: Rails.application.credentials.dig(:mapbox, :secret_token),
  
  # Configuración específica de Mapbox
  mapbox: {
    # Configuraciones adicionales si son necesarias
  },
  
  # Configuración de idioma
  language: :es,
  
  # Configuración de unidades
  units: :km,
  
  # Configuración de límites geográficos (opcional)
  # bounds: [[-90, -180], [90, 180]]
)
