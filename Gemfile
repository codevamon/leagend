source "https://rubygems.org"

ruby "3.2.6"

# Base
gem "rails", "~> 8.0.1"
gem "puma", ">= 5.0"
# gem "sqlite3", "~> 1.4", group: [:development, :test]
gem 'sqlite3', '~> 2.1', group: [:development, :test]
gem "pg", "~> 1.1", group: :production
gem "aws-sdk-s3", require: false


# Active Storage y procesamiento de imágenes
gem "image_processing", "~> 1.2"

# Modern Asset Pipeline
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Seguridad y optimización
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Funcionalidades adicionales
gem "jbuilder"
gem "devise"
gem "friendly_id", "~> 5.4.0"
gem "geocoder", "~> 1.8"
gem "will_paginate", "~> 3.1"
gem "simple_form", "~> 5.0"
gem "omniauth", "~> 2.0"
gem "omniauth-google-oauth2"
gem 'omniauth-rails_csrf_protection'
gem 'pundit', '~> 2.3' # Para autorización
gem 'activeadmin', '~> 3.2' # Para el panel de administración
gem 'sidekiq', '~> 7.0' # Para tareas en segundo plano
gem 'rack-cors', '~> 2.0' # Para manejar CORS en la API
gem 'kaminari', '~> 1.2' # Para paginación
gem 'ransack', '~> 4.0' # Para búsquedas

# Frontend
gem "sassc-rails", ">= 2.1.0"
gem "font-awesome-sass"
gem "jquery-rails", "~> 4.5"

# Mapas y geolocalización
gem "gmaps4rails", "~> 2.1"
gem "country_select"

# Notificaciones y breadcrumbs
gem "noticed", "~> 1.6"
gem "breadcrumbs_on_rails", "~> 3.0"

# Tareas y procesamiento en segundo plano
gem "rufus-scheduler"
gem "streamio-ffmpeg", "~> 3.0"

# Otros
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem 'sprockets-rails'


group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ], require: "debug/prelude"
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "dotenv-rails"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console", ">= 4.1.0"
  # gem "rack-mini-profiler", "~> 2.0"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
