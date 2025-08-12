# Ejemplos de Uso de Ubicación - Leagend

## Uso Básico en Controladores

### 1. Acceder a la Ubicación Actual

```ruby
class ArenasController < ApplicationController
  def index
    # La ubicación ya está disponible automáticamente
    user_location = current_location
    
    if user_location[:city].present?
      # Filtrar arenas por ciudad del usuario
      @arenas = Arena.where(city: user_location[:city])
    else
      # Mostrar todas las arenas si no hay ubicación
      @arenas = Arena.all
    end
  end
end
```

### 2. Usar Ubicación en Vistas

```erb
<!-- En app/views/arenas/index.html.erb -->
<% if current_location[:city].present? %>
  <div class="alert alert-info">
    <i class="fas fa-map-marker-alt"></i>
    Mostrando arenas cerca de <%= current_location[:city] %>, <%= current_location[:country] %>
  </div>
<% end %>
```

### 3. Filtrar por Región

```ruby
class DuelsController < ApplicationController
  def index
    location = current_location
    
    @duels = Duel.joins(:arena)
    
    if location[:region].present?
      @duels = @duels.where(arenas: { region: location[:region] })
    end
    
    if location[:country].present?
      @duels = @duels.where(arenas: { country: location[:country] })
    end
  end
end
```

### 4. Sugerencias de Ubicación

```ruby
class UsersController < ApplicationController
  def edit
    @user = current_user
    
    # Sugerir ubicación basada en IP si no está configurada
    if @user.current_country.blank? && @user.current_city.blank?
      location = current_location
      @suggested_country = location[:country]
      @suggested_city = location[:city]
    end
  end
end
```

## Uso en Servicios

### 1. Servicio de Recomendaciones

```ruby
# app/services/arena_recommendation_service.rb
class ArenaRecommendationService
  def initialize(user_location)
    @user_location = user_location
  end
  
  def recommend_arenas
    Arena.near(@user_location[:city], 50) if @user_location[:city].present?
  end
  
  def suggest_teams
    Team.joins(:arena)
        .where(arenas: { city: @user_location[:city] })
        .limit(5) if @user_location[:city].present?
  end
end

# En el controlador
class ExploreController < ApplicationController
  def index
    @recommendations = ArenaRecommendationService.new(current_location).recommend_arenas
  end
end
```

### 2. Servicio de Notificaciones Locales

```ruby
# app/services/local_notification_service.rb
class LocalNotificationService
  def initialize(user)
    @user = user
  end
  
  def send_local_duel_notifications
    return unless @user.current_city.present?
    
    local_duels = Duel.joins(:arena)
                      .where(arenas: { city: @user.current_city })
                      .where('duels.scheduled_at > ?', Time.current)
    
    local_duels.each do |duel|
      Notification.create!(
        recipient: @user,
        title: "Nuevo duelo en tu ciudad",
        body: "Se ha programado un duelo en #{duel.arena.name}",
        notifiable: duel
      )
    end
  end
end
```

## Uso en Modelos

### 1. Scopes Geográficos

```ruby
# app/models/arena.rb
class Arena < ApplicationRecord
  scope :near_user, ->(user) {
    if user.current_city.present?
      where(city: user.current_city)
    elsif user.current_country.present?
      where(country: user.current_country)
    else
      none
    end
  }
  
  scope :in_region, ->(region) { where(region: region) if region.present? }
end

# En el controlador
class ArenasController < ApplicationController
  def index
    @arenas = Arena.near_user(current_user)
    
    # También puedes usar la ubicación de la sesión
    if current_location[:region].present?
      @arenas = @arenas.in_region(current_location[:region])
    end
  end
end
```

### 2. Validaciones de Ubicación

```ruby
# app/models/duel.rb
class Duel < ApplicationRecord
  validate :arena_in_user_region, if: :user_has_location?
  
  private
  
  def user_has_location?
    user&.current_city.present? || user&.current_country.present?
  end
  
  def arena_in_user_region
    return unless arena && user
    
    if user.current_city.present? && arena.city != user.current_city
      errors.add(:arena, "debe estar en tu ciudad actual (#{user.current_city})")
    end
  end
end
```

## Uso en JavaScript

### 1. Acceder a Ubicación en Stimulus

```javascript
// app/javascript/controllers/arena_map_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Escuchar cambios de ubicación
    document.addEventListener('locationUpdated', this.handleLocationUpdate.bind(this))
  }
  
  handleLocationUpdate(event) {
    const { lat, lng } = event.detail
    this.centerMap(lat, lng)
  }
  
  centerMap(lat, lng) {
    // Centrar mapa en la nueva ubicación
    if (this.map) {
      this.map.setView([lat, lng], 13)
    }
  }
}
```

### 2. Filtrar Arenas por Distancia

```javascript
// app/javascript/controllers/arena_filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["arena", "distance"]
  
  filterByDistance() {
    if (!navigator.geolocation) return
    
    navigator.geolocation.getCurrentPosition((position) => {
      const userLat = position.coords.latitude
      const userLng = position.coords.longitude
      
      this.arenaTargets.forEach(arena => {
        const arenaLat = parseFloat(arena.dataset.latitude)
        const arenaLng = parseFloat(arena.dataset.longitude)
        
        const distance = this.calculateDistance(userLat, userLng, arenaLat, arenaLng)
        
        if (distance <= 50) { // 50km
          arena.style.display = 'block'
        } else {
          arena.style.display = 'none'
        }
      })
    })
  }
  
  calculateDistance(lat1, lng1, lat2, lng2) {
    // Fórmula de Haversine para calcular distancia
    const R = 6371 // Radio de la Tierra en km
    const dLat = (lat2 - lat1) * Math.PI / 180
    const dLng = (lng2 - lng1) * Math.PI / 180
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
               Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
               Math.sin(dLng/2) * Math.sin(dLng/2)
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    return R * c
  }
}
```

## Uso en Tests

### 1. Mock de Ubicación

```ruby
# test/controllers/arenas_controller_test.rb
class ArenasControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
    @user.update!(current_city: "Madrid", current_country: "ES")
    sign_in @user
  end
  
  test "should filter arenas by user location" do
    # Crear arena en Madrid
    madrid_arena = arenas(:one)
    madrid_arena.update!(city: "Madrid", country: "ES")
    
    # Crear arena en Barcelona
    barcelona_arena = arenas(:two)
    barcelona_arena.update!(city: "Barcelona", country: "ES")
    
    get :index
    
    assert_response :success
    assert_includes assigns(:arenas), madrid_arena
    assert_not_includes assigns(:arenas), barcelona_arena
  end
end
```

### 2. Test de Concern

```ruby
# test/controllers/concerns/detects_location_test.rb
class DetectsLocationTest < ActionController::TestCase
  test "should provide current_location helper" do
    @controller.stubs(:cached_location).returns({
      country: "ES",
      city: "Madrid"
    })
    
    location = @controller.current_location
    
    assert_equal "ES", location[:country]
    assert_equal "Madrid", location[:city]
  end
end
```

## Consideraciones de Performance

### 1. Cache de Ubicación

```ruby
# La ubicación se cachea automáticamente
# No se hace request a ipinfo.io en cada página
location = current_location # Usa cache, no hace HTTP request
```

### 2. Lazy Loading

```ruby
# Solo usar ubicación cuando sea necesario
class ArenasController < ApplicationController
  def index
    # Ubicación solo se detecta si no está cacheada
    @arenas = Arena.all
    
    # Filtrar solo si es necesario
    if params[:near_me] == 'true'
      location = current_location
      @arenas = @arenas.where(city: location[:city]) if location[:city].present?
    end
  end
end
```

### 3. Background Jobs

```ruby
# Para operaciones pesadas de ubicación
class UpdateUserLocationJob < ApplicationJob
  def perform(user_id, lat, lng)
    user = User.find(user_id)
    
    # Geocoding inverso, actualización de timezone, etc.
    # Se ejecuta en background para no bloquear la UI
  end
end
```

## Debugging

### 1. Ver Ubicación en Consola

```ruby
# En Rails console
# Ver ubicación cacheada
ApplicationController.new.send(:cached_location)

# Ver si está cacheada
ApplicationController.new.send(:location_already_cached?)
```

### 2. Logs de Ubicación

```ruby
# Los logs muestran:
# "Ubicación cacheada: {:country=>\"ES\", :city=>\"Madrid\"}"
# "Ubicación actualizada para usuario xxx: {:current_country=>\"ES\"}"
# "Ubicación exacta actualizada para usuario xxx: {:current_latitude=>\"40.4168\"}"
```

### 3. Verificar en Navegador

```javascript
// En consola del navegador
// Ver cookies de ubicación
document.cookie

// Ver estado del controlador Stimulus
application.getControllerForElementAndIdentifier(
  document.querySelector('[data-controller="location"]'), 
  'location'
)
```
