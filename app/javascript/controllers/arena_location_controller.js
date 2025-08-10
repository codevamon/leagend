import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "city", "address", "latitude", "longitude", "map", "geocoderCountry", "geocoderCity", "geocoderAddress"]
  static values = { 
    editable: { type: Boolean, default: false },
    centerLat: { type: Number, default: 4.7110 },
    centerLng: { type: Number, default: -74.0721 },
    zoom: { type: Number, default: 13 }
  }

  connect() {
    this.debounceTimer = null
    this.geocoders = {}
    this.currentBias = null
    this.map = null
    this.marker = null
    this.mapboxRetryCount = 0
    this.maxRetries = 20
    
    // Crear referencias a los métodos del modal
    this._onModalShown = this.handleModalShown.bind(this)
    this._onModalHidden = this.handleModalHidden.bind(this)
    
    // Escuchar eventos del modal para resize del mapa
    this.setupModalListeners()
    
    // Esperar a que Mapbox esté disponible
    this.waitForMapbox()
  }

  disconnect() {
    this.cleanupMap()
    this.cleanupGeocoders()
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    this.mapboxRetryCount = 0 // Reset retry count
    
    // Remover listeners del modal
    this.removeModalListeners()
  }

  // Configurar listeners para eventos del modal
  setupModalListeners() {
    // Escuchar cuando el modal se abre
    document.addEventListener('shown.bs.modal', this.handleModalShown.bind(this))
    
    // Escuchar cuando el modal se oculta
    document.addEventListener('hidden.bs.modal', this.handleModalHidden.bind(this))
  }

  // Remover listeners del modal
  removeModalListeners() {
    document.removeEventListener('shown.bs.modal', this.handleModalShown.bind(this))
    document.removeEventListener('hidden.bs.modal', this.handleModalHidden.bind(this))
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
    console.log('waitForMapbox: verificando disponibilidad...');
    console.log('mapboxgl disponible:', typeof mapboxgl !== 'undefined');
    console.log('MapboxGeocoder disponible:', typeof MapboxGeocoder !== 'undefined');
    
    if (typeof mapboxgl !== 'undefined' && typeof MapboxGeocoder !== 'undefined') {
      console.log('Mapbox disponible, inicializando...');
      this.initializeMap()
      this.initializeGeocoders()
    } else if (this.mapboxRetryCount < this.maxRetries) {
      console.log(`Mapbox no disponible, reintento ${this.mapboxRetryCount + 1}/${this.maxRetries}...`);
      this.mapboxRetryCount++
      
      // Escuchar eventos personalizados de carga
      const checkAvailability = () => {
        if (typeof mapboxgl !== 'undefined' && typeof MapboxGeocoder !== 'undefined') {
          console.log('Mapbox disponible después de esperar eventos, inicializando...');
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
        console.log('Evento mapboxgeocoder:loaded recibido');
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
      this.dispatchLocationChangedEvent(lat, lng)
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
      this.dispatchLocationChangedEvent(lat, lng)
    }
  }

  // Manejar selección de dirección
  handleAddressSelection(result) {
    const addressName = result.place_name
    const cityName = this.getContextText(result.context || [], ["place", "locality"])
    const countryName = this.getContextText(result.context || [], ["country"])
    
    this.addressTarget.value = addressName
    if (cityName) this.cityTarget.value = cityName
    if (countryName) this.countryTarget.value = countryName
    
    // Actualizar coordenadas y mapa
    if (result.center) {
      const [lng, lat] = result.center
      this.latitudeTarget.value = lat
      this.longitudeTarget.value = lng
      
      // Mover marker y centrar mapa
      this.updateMapLocation(lat, lng)
      
      // Disparar evento de cambio de ubicación
      this.dispatchLocationChangedEvent(lat, lng)
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
          
          // Actualizar el mapa si está disponible
          this.updateMapLocation(data.lat, data.lng)
          
          // Disparar evento de cambio de ubicación
          this.dispatchLocationChangedEvent(data.lat, data.lng)
          
          console.log('Geocodificación backend exitosa:', { lat: data.lat, lng: data.lng })
        } else {
          console.log('No se encontraron coordenadas para la dirección')
          this.latitudeTarget.value = ''
          this.longitudeTarget.value = ''
        }
      } else {
        console.warn('Error en geocodificación backend:', response.status)
        this.latitudeTarget.value = ''
        this.longitudeTarget.value = ''
      }
    } catch (error) {
      console.error('Error en geocodificación backend:', error)
      this.latitudeTarget.value = ''
      this.longitudeTarget.value = ''
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
    })
    
    console.log('Mapa inicializado exitosamente');
  }

  setupMarkerEvents() {
    if (!this.marker) return
    
    this.marker.on("dragend", () => {
      const { lat, lng } = this.marker.getLngLat()
      this.updateCoordinates(lat, lng)
      this.reverseGeocode(lat, lng)
      this.dispatchLocationChangedEvent(lat, lng)
    })
  }

  updateCoordinates(lat, lng) {
    if (this.hasLatitudeTarget) this.latitudeTarget.value = lat
    if (this.hasLongitudeTarget) this.longitudeTarget.value = lng
  }
  
  // Geocodificación inversa cuando se mueve el marker
  async reverseGeocode(lat, lng) {
    try {
      const token = mapboxgl.accessToken
      const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${token}&language=es&types=address,poi,place`
      const res = await fetch(url)
      const data = await res.json()
      const feat = data?.features?.[0]
      
      if (!feat) return
      
      const city = this.getContextText(feat.context || [], ["place", "locality"])
      const country = this.getContextText(feat.context || [], ["country"])
      
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
      
      // Disparar evento de cambio de ubicación
      this.dispatchLocationChangedEvent(lat, lng)
    } catch(error) {
      console.warn("Error en geocodificación inversa:", error)
    }
  }
  
  // Disparar evento global de cambio de ubicación
  dispatchLocationChangedEvent(lat, lng) {
    window.dispatchEvent(new CustomEvent("leagend:location_changed", {
      detail: { lat: lat, lng: lng }
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
}
