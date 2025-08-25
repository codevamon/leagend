import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "city", "address", "neighborhood", "latitude", "longitude", "map", "geocoderCountry", "geocoderCity", "geocoderAddress"]
  static values = { 
    editable: { type: Boolean, default: false },
    centerLat: { type: Number, default: 4.7110 },
    centerLng: { type: Number, default: -74.0721 },
    zoom: { type: Number, default: 13 }
  }

  // Helper para determinar el contexto del formulario
  formContext() {
    const contextEl = this.element.closest('[data-context]');
    return contextEl ? contextEl.dataset.context : 'arena';
  }

  connect() {
    this.debounceTimer = null
    this.geocoders = {}
    this.currentBias = null
    this.map = null
    this.marker = null
    this.mapboxRetryCount = 0
    this.maxRetries = 20
    
    // VARIABLE PARA COORDENADAS PENDIENTES: Si el mapa no está listo cuando llegan coords
    this.pendingCenter = null
    
    // VARIABLE PARA MARCADORES DE ARENAS: Array para gestionar marcadores existentes
    this.arenaMarkers = []
    
    // VARIABLE PARA TIMER DE ACTUALIZACIÓN DE ARENAS: Para debounce de actualizaciones
    this.arenaUpdateTimer = null
    
    // Crear referencias a los métodos del modal
    this._onModalShown = this.handleModalShown.bind(this)
    this._onModalHidden = this.handleModalHidden.bind(this)
    
    // ESCUCHAR EVENTO DE CAMBIO DE UBICACIÓN: Para centrar mapa y sincronizar
    this._onLocationChanged = this.handleLocationChanged.bind(this)
    window.addEventListener("leagend:location_changed", this._onLocationChanged)
    
    // Escuchar eventos del modal para resize del mapa
    this.setupModalListeners()
    
    // Configurar observer para detectar cambios en las tarjetas de arena
    this.setupArenaObserver()
    
    // Esperar a que Mapbox esté disponible
    this.waitForMapbox()
  }

  disconnect() {
    this.cleanupMap()
    this.cleanupGeocoders()
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    if (this.arenaUpdateTimer) {
      clearTimeout(this.arenaUpdateTimer)
    }
    this.mapboxRetryCount = 0 // Reset retry count
    
    // LIMPIAR LISTENER DE CAMBIO DE UBICACIÓN
    window.removeEventListener("leagend:location_changed", this._onLocationChanged)
    
    // Remover listeners del modal
    this.removeModalListeners()
    // Limpiar el observer de arena
    this.removeArenaObserver()
  }

  // Configurar listeners para eventos del modal
  setupModalListeners() {
    // Escuchar cuando el modal se abre
    document.addEventListener('shown.bs.modal', this._onModalShown)
    
    // Escuchar cuando el modal se oculta
    document.addEventListener('hidden.bs.modal', this._onModalHidden)
  }

  // Configurar observer para detectar cambios en las tarjetas de arena
  setupArenaObserver() {
    // Observer para detectar cambios en el DOM que puedan afectar las tarjetas de arena
    this.arenaObserver = new MutationObserver((mutations) => {
      let shouldUpdateMarkers = false;
      
      mutations.forEach((mutation) => {
        // Verificar si se agregaron o removieron tarjetas de arena
        if (mutation.type === 'childList') {
          const hasArenaCards = mutation.addedNodes.length > 0 || mutation.removedNodes.length > 0;
          if (hasArenaCards) {
            shouldUpdateMarkers = true;
          }
        }
      });
      
      // Actualizar marcadores si es necesario
      if (shouldUpdateMarkers) {
        console.log('Cambios detectados en tarjetas de arena, actualizando marcadores...');
        // Usar debounce para evitar múltiples actualizaciones rápidas
        if (this.arenaUpdateTimer) {
          clearTimeout(this.arenaUpdateTimer);
        }
        this.arenaUpdateTimer = setTimeout(() => {
          this.updateArenaMarkers();
        }, 300);
      }
    });
    
    // Observar cambios en el documento
    this.arenaObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // Remover listeners del modal
  removeModalListeners() {
    document.removeEventListener('shown.bs.modal', this._onModalShown)
    document.removeEventListener('hidden.bs.modal', this._onModalHidden)
  }

  // Remover observer de arena
  removeArenaObserver() {
    if (this.arenaObserver) {
      this.arenaObserver.disconnect()
      this.arenaObserver = null
    }
  }

  // Manejar cuando el modal se abre
  handleModalShown(event) {
    // Verificar si este controlador está dentro del modal que se abrió
    if (event.target.contains(this.element)) {
      console.log('Modal abierto, ejecutando resize del mapa...');
      // Esperar un poco para que el modal esté completamente visible
      setTimeout(() => {
        this.resizeMap()
      }, 100)
    }
  }

  // Manejar cuando el modal se oculta
  handleModalHidden(event) {
    // Verificar si este controlador está dentro del modal que se ocultó
    if (event.target.contains(this.element)) {
      console.log('Modal ocultado');
    }
  }

  // Esperar a que Mapbox esté disponible antes de inicializar
  waitForMapbox() {
    // console.log('waitForMapbox: verificando disponibilidad...');
    // console.log('mapboxgl disponible:', typeof mapboxgl !== 'undefined');
    // console.log('MapboxGeocoder disponible:', typeof MapboxGeocoder !== 'undefined');
    
    if (typeof mapboxgl !== 'undefined' && typeof MapboxGeocoder !== 'undefined') {
      // console.log('Mapbox disponible, inicializando...');
      this.initializeMap()
      this.initializeGeocoders()
    } else if (this.mapboxRetryCount < this.maxRetries) {
      console.log(`Mapbox no disponible, reintento ${this.mapboxRetryCount + 1}/${this.maxRetries}...`);
      this.mapboxRetryCount++
      
      // Escuchar eventos personalizados de carga
      const checkAvailability = () => {
        if (typeof mapboxgl !== 'undefined' && typeof MapboxGeocoder !== 'undefined') {
          // console.log('Mapbox disponible después de esperar eventos, inicializando...');
          this.initializeMap()
          this.initializeGeocoders()
          return true
        }
        return false
      }
      
      // Verificar inmediatamente en caso de que se haya cargado entre llamadas
      if (checkAvailability()) return
      
      // Esperar eventos de carga
      window.addEventListener('mapboxgl:loaded', () => {
        console.log('Evento mapboxgl:loaded recibido');
        setTimeout(() => checkAvailability(), 100)
      })
      
      window.addEventListener('mapboxgeocoder:loaded', () => {
        // console.log('Evento mapboxgeocoder:loaded recibido');
        setTimeout(() => checkAvailability(), 100)
      })
      
      // Fallback: reintentar cada 250ms
      setTimeout(() => this.waitForMapbox(), 250)
    } else {
      console.error('Mapbox no disponible después de reintentos máximos');
      // Inicializar mapa sin geocoders si al menos mapboxgl está disponible
      if (typeof mapboxgl !== 'undefined') {
        console.log('Inicializando mapa sin geocoders...');
        this.initializeMap()
        // Registrar one-shot para cuando aparezca MapboxGeocoder
        this.waitForGeocoder()
      }
    }
  }

  // Esperar a que aparezca MapboxGeocoder después de que el mapa esté listo
  waitForGeocoder() {
    if (typeof MapboxGeocoder !== 'undefined') {
      console.log('MapboxGeocoder apareció, inicializando geocoders...');
      this.initializeGeocoders()
    } else {
      // Reintentar cada 100ms
      setTimeout(() => this.waitForGeocoder(), 100)
    }
  }

  // Limpieza completa del mapa
  cleanupMap() {
    if (this.map) {
      console.log('Limpiando mapa existente...');
      this.map.remove()
      this.map = null
    }
    if (this.marker) {
      console.log('Limpiando marcador...');
      this.marker = null
    }
    // Limpiar marcadores de arenas
    this.removeArenaMarkers();
    // Limpiar contenedor para cumplir "container should be empty"
    if (this.hasMapTarget) {
      console.log('Limpiando contenedor del mapa...');
      this.mapTarget.innerHTML = ''
    }
  }

  // Limpieza de geocoders para evitar duplicados
  cleanupGeocoders() {
    Object.values(this.geocoders).forEach(geocoder => {
      if (geocoder && typeof geocoder.remove === 'function') {
        geocoder.remove()
      }
    })
    this.geocoders = {}
  }

  // Helper para escribir valores en campos hidden de forma segura
  setVal(id, v) {
    const el = document.getElementById(id);
    if (el) el.value = (v ?? "").toString();
  }

  // Función principal para escribir en campos hidden
  writeHidden({ country, city, address, neighborhood, lat, lng }) {
    const p = this.formContext(); // 'duel' | 'arena'
    if (p === 'duel') {
      // Para duelos, usar los campos del formulario directamente
      if (this.hasCountryTarget) this.countryTarget.value = country || '';
      if (this.hasCityTarget) this.cityTarget.value = city || '';
      if (this.hasAddressTarget) this.addressTarget.value = address || '';
      if (typeof lat === 'number') this.latitudeTarget.value = lat.toFixed(6);
      if (typeof lng === 'number') this.longitudeTarget.value = lng.toFixed(6);
    } else {
      // Para arenas, usar el formato anterior
      this.setVal(`${p}_country`, country);
      this.setVal(`${p}_city`, city);
      this.setVal(`${p}_address`, address);
      this.setVal(`${p}_neighborhood`, neighborhood);
      if (typeof lat === 'number') this.setVal(`${p}_latitude`, lat.toFixed(6));
      if (typeof lng === 'number') this.setVal(`${p}_longitude`, lng.toFixed(6));
    }
  }

  // Inicialización de los tres geocoders independientes
  initializeGeocoders() {
    console.log('Inicializando geocoders...');
    const token = this.getMapboxToken()
    if (!token || typeof MapboxGeocoder === 'undefined') {
      console.warn("Mapbox token o MapboxGeocoder no disponible")
      console.log('Token:', token ? 'presente' : 'ausente');
      console.log('MapboxGeocoder:', typeof MapboxGeocoder);
      return
    }

    console.log('Token Mapbox válido, creando geocoders...');

    // Limpiar geocoders existentes antes de crear nuevos
    this.cleanupGeocoders()

    // Geocoder para países
    this.geocoders.country = new MapboxGeocoder({
      accessToken: token,
      mapboxgl,
      types: 'country',
      language: 'es',
      limit: 8,
      marker: false,
      placeholder: "Buscar país...",
      proximity: this.getProximityBias()
    })

    // Geocoder para ciudades
    this.geocoders.city = new MapboxGeocoder({
      accessToken: token,
      mapboxgl,
      types: 'place,locality',
      language: 'es',
      limit: 8,
      marker: false,
      placeholder: "Buscar ciudad...",
      proximity: this.getProximityBias()
    })

    // Geocoder para direcciones
    this.geocoders.address = new MapboxGeocoder({
      accessToken: token,
      mapboxgl,
      types: 'address,street,poi',
      language: 'es',
      limit: 8,
      marker: false,
      placeholder: "Buscar dirección...",
      proximity: this.getProximityBias()
    })

    console.log('Geocoders creados, configurando eventos...');

    // Configurar eventos para cada geocoder
    this.setupGeocoderEvents()
    
    console.log('Montando geocoders en contenedores...');
    
    // Montar geocoders en sus contenedores
    this.geocoders.country.addTo(this.geocoderCountryTarget)
    this.geocoders.city.addTo(this.geocoderCityTarget)
    this.geocoders.address.addTo(this.geocoderAddressTarget)
    
    console.log('Geocoders montados exitosamente');
  }

  // Configurar eventos para cada geocoder
  setupGeocoderEvents() {
    // Evento para selección de país
    this.geocoders.country.on("result", (e) => {
      const result = e.result
      this.handleCountrySelection(result)
    })

    // Evento para selección de ciudad
    this.geocoders.city.on("result", (e) => {
      const result = e.result
      this.handleCitySelection(result)
    })

    // Evento para selección de dirección
    this.geocoders.address.on("result", (e) => {
      const result = e.result
      this.handleAddressSelection(result)
    })

    // Evento para limpiar campos
    this.geocoders.country.on("clear", () => {
      this.countryTarget.value = ''
      this.updateGeocoderBias()
    })

    this.geocoders.city.on("clear", () => {
      this.cityTarget.value = ''
      this.updateGeocoderBias()
    })

    this.geocoders.address.on("clear", () => {
      this.addressTarget.value = ''
      this.updateGeocoderBias()
    })
  }

  // Manejar selección de país
  handleCountrySelection(result) {
    const countryName = result.text
    this.countryTarget.value = countryName
    
    // Actualizar campos hidden del formulario
    this.writeHidden({ 
      country: countryName, 
      city: null, 
      address: null, 
      neighborhood: null, 
      lat: null, 
      lng: null 
    })
    
    // Limpiar ciudad si no pertenece al país seleccionado
    if (this.cityTarget.value) {
      const cityCountry = this.getContextText(result.context || [], ["country"])
      if (cityCountry && cityCountry !== countryName) {
        this.cityTarget.value = ''
        this.addressTarget.value = ''
        this.latitudeTarget.value = ''
        this.longitudeTarget.value = ''
      }
    }

    // Actualizar bias para otros geocoders
    this.updateGeocoderBias()
    
    // Centrar mapa en el país si tiene bbox
    if (result.bbox && this.map) {
      this.map.fitBounds(result.bbox, { padding: 50 })
    }
    
    // Disparar evento de cambio de ubicación si hay coordenadas
    if (result.center) {
      const [lng, lat] = result.center
      this.dispatchLocationChangedEvent(lat, lng, null, countryName, null, null, 'country_selection')
    }
  }

  // Manejar selección de ciudad
  handleCitySelection(result) {
    const cityName = result.text
    const countryName = this.getContextText(result.context || [], ["country"])
    
    this.cityTarget.value = cityName
    if (countryName) {
      this.countryTarget.value = countryName
    }
    
    // Actualizar campos hidden del formulario
    this.writeHidden({ 
      country: countryName || this.countryTarget.value, 
      city: cityName, 
      address: null, 
      neighborhood: null, 
      lat: null, 
      lng: null 
    })
    
    // Actualizar bias para geocoder de direcciones
    this.updateGeocoderBias()
    
    // Centrar mapa en la ciudad
    if (result.center && this.map) {
      this.map.flyTo({ 
        center: result.center, 
        zoom: 12 
      })
    }
    
    // Disparar evento de cambio de ubicación
    if (result.center) {
      const [lng, lat] = result.center
      this.dispatchLocationChangedEvent(lat, lng, cityName, countryName, null, null, 'city_selection')
    }
  }

  // Manejar selección de dirección - actualiza #duel_city de forma confiable
  handleAddressSelection(result) {
    const addressName = result.place_name
    const countryName = this.getContextText(result.context || [], ["country"])
    
    // PRIORIDAD para ciudad: place → locality → region
    let cityName = this.getContextText(result.context || [], ["place", "locality"])
    if (!cityName) {
      cityName = this.getContextText(result.context || [], ["region"])
    }
    
    const neighborhood = this.getContextText(result.context || [], ["neighborhood"])
    
    console.log(`Dirección seleccionada: ${addressName}`)
    console.log(`Ciudad extraída: ${cityName} (prioridad: place/locality → region)`)
    console.log(`País: ${countryName}`)
    
    // Actualizar campos del formulario
    this.addressTarget.value = addressName
    if (cityName) {
      this.cityTarget.value = cityName
    }
    if (countryName) {
      this.countryTarget.value = countryName
    }
    
    // Actualizar campos hidden del formulario
    this.writeHidden({ 
      country: countryName || this.countryTarget.value, 
      city: cityName || this.cityTarget.value, 
      address: addressName, 
      neighborhood: neighborhood, 
      lat: null, 
      lng: null 
    })
    
    // Actualizar bias para otros geocoders
    this.updateGeocoderBias()
    
    // Centrar mapa en la dirección
    if (result.center && this.map) {
      this.map.flyTo({ 
        center: result.center, 
        zoom: 15 
      })
    }
    
    // Disparar evento de cambio de ubicación con coordenadas
    if (result.center) {
      const [lng, lat] = result.center
      this.dispatchLocationChangedEvent(lat, lng, cityName, countryName, addressName, neighborhood, 'address_selection')
    }
  }

  // Método principal para programar geocodificación con debounce
  schedule() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    
    this.debounceTimer = setTimeout(() => {
      this.geocode()
    }, 600) // 600ms de debounce
  }

  // Método para geocodificar la dirección (backend como red de seguridad)
  async geocode() {
    const country = this.countryTarget.value?.trim()
    const city = this.cityTarget.value?.trim()
    const address = this.addressTarget.value?.trim()

    // Solo geocodificar si tenemos los tres campos
    if (!country || !city || !address) {
      return
    }

    try {
      const response = await fetch('/arenas/geocode.json', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ country, city, address })
      })

      if (response.ok) {
        const data = await response.json()
        if (data.lat && data.lng) {
          this.latitudeTarget.value = data.lat
          this.longitudeTarget.value = data.lng
          
          // Actualizar también los campos hidden del formulario
          this.writeHidden({ 
            country: this.countryTarget?.value || null, 
            city: this.cityTarget?.value || null, 
            address: this.addressTarget?.value || null, 
            neighborhood: null, 
            lat: data.lat, 
            lng: data.lng 
          })
          
          // Actualizar el mapa si está disponible
          this.updateMapLocation(data.lat, data.lng)
          
          // Disparar evento de cambio de ubicación
          this.dispatchLocationChangedEvent(data.lat, data.lng, null, null, null, null, 'backend_geocode')
          
          console.log('Geocodificación backend exitosa:', { lat: data.lat, lng: data.lng })
        } else {
          console.log('No se encontraron coordenadas para la dirección')
          this.latitudeTarget.value = ''
          this.longitudeTarget.value = ''
          this.writeHidden({ 
            country: this.countryTarget?.value || null, 
            city: this.cityTarget?.value || null, 
            address: this.addressTarget?.value || null, 
            neighborhood: null, 
            lat: null, 
            lng: null 
          })
        }
      } else {
        console.warn('Error en geocodificación backend:', response.status)
        this.latitudeTarget.value = ''
        this.longitudeTarget.value = ''
        this.writeHidden({ 
          country: this.countryTarget?.value || null, 
          city: this.cityTarget?.value || null, 
          address: this.addressTarget?.value || null, 
          neighborhood: null, 
          lat: null, 
          lng: null 
        })
      }
    } catch (error) {
      console.error('Error en geocodificación backend:', error)
      this.latitudeTarget.value = ''
      this.longitudeTarget.value = ''
      this.writeHidden({ 
        country: this.countryTarget?.value || null, 
        city: this.cityTarget?.value || null, 
        address: this.addressTarget?.value || null, 
        neighborhood: null, 
        lat: null, 
        lng: null 
      })
    }
  }

  // Actualizar bias de geocoders basado en selecciones actuales
  updateGeocoderBias() {
    const bias = this.getProximityBias()
    
    if (this.geocoders.city && typeof this.geocoders.city.setProximity === 'function') {
      this.geocoders.city.setProximity(bias)
    }
    if (this.geocoders.address && typeof this.geocoders.address.setProximity === 'function') {
      this.geocoders.address.setProximity(bias)
    }
  }

  // Obtener bias de proximidad basado en coordenadas actuales o país/ciudad seleccionados
  getProximityBias() {
    // Priorizar coordenadas existentes
    if (this.hasLatitudeTarget && this.hasLongitudeTarget && 
        this.latitudeTarget.value && this.longitudeTarget.value) {
      return {
        longitude: parseFloat(this.longitudeTarget.value),
        latitude: parseFloat(this.latitudeTarget.value)
      }
    }
    
    // Fallback a coordenadas por defecto
    return {
      longitude: this.centerLngValue,
      latitude: this.centerLatValue
    }
  }

  // Método para actualizar la ubicación del mapa
  updateMapLocation(lat, lng) {
    if (this.map && this.marker) {
      this.marker.setLngLat([lng, lat])
      this.map.flyTo({ center: [lng, lat], zoom: 15 })
    }
  }

  // Inicialización del mapa
  initializeMap() {
    console.log('Inicializando mapa...');
    const token = this.getMapboxToken()
    if (!token) {
      console.warn("Mapbox token no encontrado")
      return
    }
    
    if (typeof mapboxgl === 'undefined') {
      console.warn("Mapbox GL JS no cargado")
      return
    }
    
    console.log('Token y Mapbox GL disponibles, creando mapa...');
    mapboxgl.accessToken = token

    // Limpiar contenedor antes de crear el mapa para cumplir "container should be empty"
    if (this.hasMapTarget) {
      console.log('Limpiando contenedor del mapa...');
      this.mapTarget.innerHTML = ''
    }

    // Determinar coordenadas iniciales
    let initialLat = this.centerLatValue
    let initialLng = this.centerLngValue
    
    if (this.hasLatitudeTarget && this.latitudeTarget.value) {
      initialLat = parseFloat(this.latitudeTarget.value)
    }
    if (this.hasLongitudeTarget && this.longitudeTarget.value) {
      initialLng = parseFloat(this.longitudeTarget.value)
    }

    console.log('Coordenadas iniciales:', { lat: initialLat, lng: initialLng });

    // Crear el mapa
    this.map = new mapboxgl.Map({
      container: this.mapTarget,
      style: "mapbox://styles/mapbox/streets-v12",
      center: [initialLng, initialLat], 
      zoom: this.zoomValue
    })
    
    // Guardar instancia global para reutilizar
    window.leagendMap = this.map
    
    console.log('Mapa creado, agregando controles...');
    this.map.addControl(new mapboxgl.NavigationControl(), "top-right")

    // Crear marcador draggable si es editable
    this.marker = new mapboxgl.Marker({ 
      draggable: this.editableValue 
    }).setLngLat([initialLng, initialLat]).addTo(this.map)

    console.log('Marcador creado, draggable:', this.editableValue);

    // Configurar eventos del marcador si es editable
    if (this.editableValue) {
      this.setupMarkerEvents()
    }

    // Centrar en coordenadas existentes si las hay
    if (this.hasLatitudeTarget && this.hasLongitudeTarget && 
        this.latitudeTarget.value && this.longitudeTarget.value) {
      this.map.flyTo({ 
        center: [parseFloat(this.longitudeTarget.value), parseFloat(this.latitudeTarget.value)], 
        zoom: 15 
      })
    }

    // Resize del mapa cuando se carga completamente
    this.map.on('load', () => {
      console.log('Mapa cargado completamente, ejecutando resize...');
      if (this.map) {
        this.map.resize()
      }
      
      // VERIFICAR COORDENADAS PENDIENTES: Si hay coordenadas esperando, centrar el mapa
      if (this.pendingCenter) {
        console.log('🎯 ARENA-LOCATION: Mapa listo, aplicando coordenadas pendientes:', this.pendingCenter)
        this.centerMapToCoordinates(this.pendingCenter.lat, this.pendingCenter.lng)
        this.pendingCenter = null // Limpiar pendiente
      }
      
      // CREAR MARCADORES DE ARENAS: Una vez que el mapa esté listo
      this.createArenaMarkers();
    })
    
    console.log('Mapa inicializado exitosamente');
  }

  // Crear marcadores para todas las arenas visibles
  createArenaMarkers() {
    if (!this.map) {
      console.log('No hay mapa disponible para crear marcadores de arenas');
      return;
    }

    console.log('Creando marcadores de arenas...');
    
    // Remover marcadores existentes para evitar duplicados
    this.removeArenaMarkers();
    
    // Buscar todas las tarjetas de arena visibles
    const arenaCards = document.querySelectorAll('.arena-card');
    console.log(`Encontradas ${arenaCards.length} tarjetas de arena`);
    
    arenaCards.forEach(card => {
      const arenaId = card.dataset.arenaId;
      const lat = parseFloat(card.dataset.lat);
      const lng = parseFloat(card.dataset.lng);
      const name = card.dataset.arenaName;
      const city = card.dataset.city;
      
      // Verificar que tenemos coordenadas válidas
      if (!arenaId || !Number.isFinite(lat) || !Number.isFinite(lng) || !name) {
        console.warn('Datos de arena incompletos:', { arenaId, lat, lng, name });
        return;
      }
      
      console.log(`Creando marcador para arena: ${name} en (${lat}, ${lng})`);
      
      // Crear popup con el nombre de la arena
      const popup = new mapboxgl.Popup({ 
        offset: 25,
        closeButton: true,
        closeOnClick: false
      }).setText(name);
      
      // Crear marcador
      const marker = new mapboxgl.Marker({
        color: '#007bff', // Color azul para diferenciar del marcador de ubicación
        scale: 0.8
      })
        .setLngLat([lng, lat])
        .setPopup(popup)
        .addTo(this.map);
      
      // AÑADIR MANEJADOR DE CLICK para sincronizar ubicación
      marker.getElement().addEventListener('click', () => {
        this.handleArenaMarkerClick(arenaId, name, city, lat, lng);
      });
      
      // Guardar referencia del marcador
      this.arenaMarkers.push(marker);
    });
    
    console.log(`Marcadores de arenas creados: ${this.arenaMarkers.length}`);
  }

  // MANEJAR CLICK EN MARCADOR DE ARENA: Sincronizar ubicación y emitir eventos
  handleArenaMarkerClick(arenaId, name, city, lat, lng) {
    console.log(`🎯 ARENA-LOCATION: Click en marcador de arena ${name} (${arenaId}) en (${lat}, ${lng})`);
    
    // 1. MOVER MARCADOR PRINCIPAL a la ubicación de la arena
    if (this.marker) {
      this.marker.setLngLat([lng, lat]);
      console.log('📍 ARENA-LOCATION: Marcador principal movido a ubicación de arena');
    }
    
    // 2. ACTUALIZAR CAMPOS HIDDEN con las coordenadas de la arena
    this.updateCoordinates(lat, lng);
    
    // 3. HACER REVERSE GEOCODING para completar country/city/address
    this.reverseGeocode(lat, lng);
    
    // 4. CENTRAR/ZOOM MAPA en la ubicación de la arena
    if (this.map) {
      this.map.flyTo({
        center: [lng, lat],
        zoom: 15,
        duration: 2000,
        essential: true
      });
      console.log('🗺️ ARENA-LOCATION: Mapa centrado en ubicación de arena');
    }
    
    // 5. EMITIR EVENTOS para sincronizar con el wizard
    // Evento de cambio de ubicación (source: 'arena_marker')
    this.dispatchLocationChangedEvent(lat, lng, city, null, null, null, 'arena_marker');
    
    // Evento de arena seleccionada
    this.dispatchArenaSelectedEvent(arenaId, name, city, lat, lng);
    
    console.log('✅ ARENA-LOCATION: Eventos emitidos para sincronización con wizard');
  }

  // DISPARAR EVENTO DE ARENA SELECCIONADA
  dispatchArenaSelectedEvent(arenaId, name, city, lat, lng) {
    const eventData = {
      id: arenaId,
      name: name,
      city: city,
      lat: lat,
      lng: lng
    };
    
    console.log('📡 ARENA-LOCATION: Disparando evento leagend:arena_selected:', eventData);
    
    window.dispatchEvent(new CustomEvent("leagend:arena_selected", {
      detail: eventData
    }));
  }

  // Remover todos los marcadores de arenas existentes
  removeArenaMarkers() {
    if (this.arenaMarkers.length > 0) {
      console.log(`Removiendo ${this.arenaMarkers.length} marcadores de arenas existentes`);
      this.arenaMarkers.forEach(marker => {
        if (marker && typeof marker.remove === 'function') {
          marker.remove();
        }
      });
      this.arenaMarkers = [];
    }
  }

  // Método público para actualizar marcadores de arenas (útil para filtros)
  updateArenaMarkers() {
    if (this.map && this.map.isStyleLoaded()) {
      console.log('Actualizando marcadores de arenas...');
      this.createArenaMarkers();
    } else {
      console.log('Mapa no listo, marcadores se crearán cuando esté disponible');
    }
  }

  // Método público para forzar actualización de marcadores (útil para llamadas externas)
  refreshArenaMarkers() {
    console.log('Forzando actualización de marcadores de arenas...');
    this.updateArenaMarkers();
  }

  setupMarkerEvents() {
    if (!this.marker) return
    
    // Usar arrow function para mantener el binding de this
    this.marker.on("dragend", () => {
      const { lat, lng } = this.marker.getLngLat()
      console.log('📍 ARENA-LOCATION: Marcador arrastrado a:', { lat, lng })
      
      // Actualizar coordenadas en campos hidden
      this.updateCoordinates(lat, lng)
      
      // Hacer reverse geocoding para completar country/city/address
      this.reverseGeocode(lat, lng)
      
      // EMITIR EVENTO DE CAMBIO DE UBICACIÓN: Para que el paso recalcule filtro de 3km
      this.dispatchLocationChangedEvent(lat, lng, null, null, null, 'marker_drag')
    })
  }

  updateCoordinates(lat, lng) {
    if (this.hasLatitudeTarget) this.latitudeTarget.value = lat
    if (this.hasLongitudeTarget) this.longitudeTarget.value = lng
    
    // Actualizar también los campos hidden del formulario
    this.writeHidden({ 
      country: this.countryTarget?.value || null, 
      city: this.cityTarget?.value || null, 
      address: this.addressTarget?.value || null, 
      neighborhood: null, 
      lat: lat, 
      lng: lng 
    })
  }
  
  // Geocodificación inversa cuando se mueve el marker - actualiza #duel_city de forma confiable
  async reverseGeocode(lat, lng) {
    try {
      const token = mapboxgl.accessToken
      const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${token}&language=es&types=address,poi,place`
      const res = await fetch(url)
      const data = await res.json()
      const feat = data?.features?.[0]
      
      if (!feat) return
      
      console.log(`Reverse geocoding para (${lat}, ${lng}): ${feat.place_name}`)
      
      // PRIORIDAD para ciudad: place → locality → region
      let city = this.getContextText(feat.context || [], ["place", "locality"])
      if (!city) {
        city = this.getContextText(feat.context || [], ["region"])
      }
      
      const country = this.getContextText(feat.context || [], ["country"])
      
      console.log(`Ciudad extraída: ${city} (prioridad: place/locality → region)`)
      console.log(`País: ${country}`)
      
      // Solo actualizar si no están ya llenos o si son diferentes
      if (country && (!this.countryTarget.value || this.countryTarget.value !== country)) {
        this.countryTarget.value = country
      }
      if (city && (!this.cityTarget.value || this.cityTarget.value !== city)) {
        this.cityTarget.value = city
      }
      if (feat.place_name && (!this.addressTarget.value || this.addressTarget.value !== feat.place_name)) {
        this.addressTarget.value = feat.place_name
      }
      
      // Actualizar campos hidden del formulario
      this.writeHidden({ 
        country: country || this.countryTarget.value, 
        city: city || this.cityTarget.value, 
        address: feat.place_name || this.addressTarget.value, 
        neighborhood: null, 
        lat: lat, 
        lng: lng 
      })
      
      // Disparar evento de cambio de ubicación
      this.dispatchLocationChangedEvent(lat, lng, city, country, feat.place_name, null, 'reverse_geocode')
    } catch(error) {
      console.warn("Error en geocodificación inversa:", error)
    }
  }
  
  // Disparar evento global de cambio de ubicación con información completa
  dispatchLocationChangedEvent(lat, lng, city = null, country = null, address = null, neighborhood = null, source = 'unknown') {
    const eventData = {
      lat: lat,
      lng: lng,
      city: city || this.cityTarget?.value || null,
      country: country || this.countryTarget?.value || null,
      address: address || this.addressTarget?.value || null,
      neighborhood: neighborhood || null,
      source: source
    }
    
    console.log('Disparando evento leagend:location_changed:', eventData)
    
    window.dispatchEvent(new CustomEvent("leagend:location_changed", {
      detail: eventData
    }))
  }
  
  getContextText(ctx, types) { 
    return ctx.find(c => types.some(t => c.id?.startsWith(t)))?.text || "" 
  }

  getMapboxToken() {
    console.log('Buscando token de Mapbox...');
    
    // Prioridad 1: data-mapbox-token del elemento del controlador
    if (this.element.dataset.mapboxToken) {
      console.log('Token encontrado en data-mapbox-token del controlador');
      return this.element.dataset.mapboxToken
    }
    
    // Prioridad 2: meta tag en el documento actual
    const metaTag = document.querySelector('meta[name="mapbox-token"]')
    console.log('Meta tag encontrado:', metaTag ? 'sí' : 'no');
    if (metaTag?.content) {
      console.log('Token encontrado en meta tag');
      return metaTag.content
    }
    
    // Prioridad 3: buscar en el turbo-frame modal si estamos en uno
    const modalFrame = document.querySelector('#modal')
    if (modalFrame) {
      const modalMetaTag = modalFrame.querySelector('meta[name="mapbox-token"]')
      if (modalMetaTag?.content) {
        console.log('Token encontrado en meta tag del modal');
        return modalMetaTag.content
      }
    }
    
    // Prioridad 4: buscar en cualquier elemento padre que tenga el token
    let parent = this.element.parentElement
    while (parent && parent !== document.body) {
      if (parent.dataset.mapboxToken) {
        console.log('Token encontrado en data-mapbox-token de elemento padre');
        return parent.dataset.mapboxToken
      }
      parent = parent.parentElement
    }
    
    console.error("Token de Mapbox no encontrado ni en data-mapbox-token ni en meta[name='mapbox-token']")
    return null
  }

  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag?.content || ''
  }

  // Método para re-inicializar después de navegaciones Turbo
  reconnect() {
    this.cleanupMap()
    this.cleanupGeocoders()
    this.mapboxRetryCount = 0
    this.waitForMapbox()
  }

  // Método para resize del mapa (útil para modales)
  resizeMap() {
    if (this.map) {
      console.log('Ejecutando resize del mapa...');
      try {
        this.map.resize()
        console.log('Resize del mapa ejecutado exitosamente');
      } catch (error) {
        console.warn('Error al hacer resize del mapa:', error);
      }
    } else {
      console.log('No hay mapa disponible para hacer resize');
    }
  }

  // MANEJAR CAMBIO DE UBICACIÓN: Centrar mapa y sincronizar
  handleLocationChanged(event) {
    console.log('📍 ARENA-LOCATION: Evento leagend:location_changed recibido')
    console.trace('📍 TRACE: handleLocationChanged() llamado desde:')
    
    if (!event?.detail) {
      console.warn('⚠️ ARENA-LOCATION: Evento sin detail')
      return
    }
    
    const { lat, lng, source } = event.detail
    console.log(`📍 ARENA-LOCATION: Coordenadas recibidas: (${lat}, ${lng}) desde ${source}`)
    
    // VERIFICAR que las coordenadas son numéricas válidas
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      console.warn('⚠️ ARENA-LOCATION: Coordenadas no válidas:', event.detail)
      return
    }
    
    // SI EL MAPA ESTÁ LISTO: Centrar inmediatamente
    if (this.map && this.map.isStyleLoaded()) {
      console.log('✅ ARENA-LOCATION: Mapa listo, centrando inmediatamente')
      this.centerMapToCoordinates(lat, lng)
      this.pendingCenter = null // Limpiar pendiente
    } else {
      // SI EL MAPA NO ESTÁ LISTO: Cachear para cuando esté listo
      console.log('⏳ ARENA-LOCATION: Mapa no listo, cacheando coordenadas pendientes')
      this.pendingCenter = { lat, lng, source }
    }
  }
  
  // CENTRAR MAPA A COORDENADAS ESPECÍFICAS
  centerMapToCoordinates(lat, lng) {
    console.log(`🎯 ARENA-LOCATION: Centrando mapa a (${lat}, ${lng})`)
    
    if (!this.map) {
      console.warn('⚠️ ARENA-LOCATION: No hay mapa para centrar')
      return
    }
    
    // Mover marcador a nuevas coordenadas
    if (this.marker) {
      this.marker.setLngLat([lng, lat])
      console.log('📍 ARENA-LOCATION: Marcador movido a nuevas coordenadas')
    }
    
    // Centrar mapa con animación suave
    this.map.flyTo({
      center: [lng, lat],
      zoom: 14,
      duration: 2000,
      essential: true
    })
    
    console.log('✅ ARENA-LOCATION: Mapa centrado exitosamente')
  }
}
