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
    
    // VARIABLE PARA TIMER DE AUTOCOMPLETE: Para debounce de autocomplete
    this.addressAutocompleteTimer = null
    
    // VARIABLE PARA TIMER DE GEOCODIFICACIÓN DE CIUDAD: Para debounce de geocodificación
    this.cityGeocodeTimer = null
    
    // CACHÉ PARA BIAS DE CIUDAD: Para restringir autocomplete a ciudad actual
    this.cityBias = null
    
    // GUARDA ANTI RE-ENTRADA para updateArenaMarkers
    this._updatingMarkers = false
    
    // BANDERA para evitar duplicar MutationObserver
    this._cardsObserverInitialized = false
    
      // FLAG DE DEBUG para controlar logs verbosos
    this.debug = false
    
    // Método para habilitar logs verbosos (útil para debugging)
    this.enableDebug = this.enableDebug.bind(this)
    this.disableDebug = this.disableDebug.bind(this)
    
    // Crear referencias a los métodos del modal
    this._onModalShown = this.handleModalShown.bind(this)
    this._onModalHidden = this.handleModalHidden.bind(this)
    
    // ESCUCHAR EVENTO DE CAMBIO DE UBICACIÓN: Para centrar mapa y sincronizar
    this._onLocationChanged = this.handleLocationChanged.bind(this)
    window.addEventListener("leagend:location_changed", this._onLocationChanged)
    
    // ESCUCHAR EVENTOS PARA AUTOCOMPLETE: Para ocultar sugerencias
    this._onDocumentClick = this.handleDocumentClick.bind(this)
    this._onDocumentKeydown = this.handleDocumentKeydown.bind(this)
    document.addEventListener('click', this._onDocumentClick)
    document.addEventListener('keydown', this._onDocumentKeydown)
    
    // Escuchar eventos del modal para resize del mapa
    this.setupModalListeners()
    
    // Configurar observer para detectar cambios en las tarjetas de arena
    // Solo configurar si no está ya inicializado
    if (!this._cardsObserverInitialized) {
      this.setupArenaObserver()
    }
    
    // Esperar a que Mapbox esté disponible
    this.waitForMapbox()
    
    // Inicializar cityBias si ya hay valores en los campos
    this.initializeCityBiasFromExistingValues()
    
    if (this.formContext() === 'arena') {
      // Usar cache si existe
      const storedLat = localStorage.getItem('leagend:lastLat');
      const storedLng = localStorage.getItem('leagend:lastLng');
      
      const applyUserLocation = (lat, lng) => {
        console.log('📍 ARENA-LOCATION: Aplicando ubicación inicial de usuario en arenas/new', { lat, lng });
        this.updateCoordinates(lat, lng);       // guarda en hidden fields
        this.updateMapLocation(lat, lng);       // mueve marcador + centra mapa
        this.reverseGeocode(lat, lng);          // completa country, city, address
        this.dispatchLocationChangedEvent(lat, lng, null, null, null, null, 'arena_user_location');
        // Guardar cache
        try {
          localStorage.setItem('leagend:lastLat', String(lat));
          localStorage.setItem('leagend:lastLng', String(lng));
        } catch(_) {}
      };
      
      if (storedLat && storedLng) {
        applyUserLocation(parseFloat(storedLat), parseFloat(storedLng));
      } else if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            applyUserLocation(pos.coords.latitude, pos.coords.longitude);
          },
          (err) => {
            console.warn('⚠️ ARENA-LOCATION: Error obteniendo geolocalización del usuario', err);
          }
        );
      }
    }
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
    if (this.addressAutocompleteTimer) {
      clearTimeout(this.addressAutocompleteTimer)
    }
    if (this.cityGeocodeTimer) {
      clearTimeout(this.cityGeocodeTimer)
    }
    this.mapboxRetryCount = 0 // Reset retry count
    
    // LIMPIAR LISTENER DE CAMBIO DE UBICACIÓN
    window.removeEventListener("leagend:location_changed", this._onLocationChanged)
    
    // LIMPIAR LISTENERS DE AUTOCOMPLETE
    document.removeEventListener('click', this._onDocumentClick)
    document.removeEventListener('keydown', this._onDocumentKeydown)
    
    // Remover listeners del modal
    this.removeModalListeners()
    // Limpiar el observer de arena
    this.removeArenaObserver()
    
    // Limpiar sugerencias de autocomplete
    this.clearAddressSuggestions()
    
    // Resetear banderas de control
    this._updatingMarkers = false
    this._cardsObserverInitialized = false
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
    // EVITAR DUPLICAR OBSERVER: Solo crear una instancia
    if (this._cardsObserverInitialized || this.arenaObserver) {
      if (this.debug) console.log('Observer de arena ya inicializado o existente, saltando...');
      return;
    }
    
    // Buscar el contenedor específico de la grilla de arenas (NO document.body)
    const arenaGridContainer = document.querySelector('.arenas-grid, .arenas-container, [data-arenas-grid]');
    if (!arenaGridContainer) {
      if (this.debug) console.log('Contenedor de grilla de arenas no encontrado, saltando observer...');
      return;
    }
    
    if (this.debug) console.log('Configurando observer para contenedor de grilla de arenas:', arenaGridContainer);
    
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
        if (this.debug) console.log('Cambios detectados en tarjetas de arena, programando actualización...');
        // Usar debounce para evitar múltiples actualizaciones rápidas
        if (this.arenaUpdateTimer) {
          clearTimeout(this.arenaUpdateTimer);
        }
        this.arenaUpdateTimer = setTimeout(() => {
          this.updateArenaMarkers();
        }, 150); // Reducido a 150ms para mejor respuesta
      }
    });
    
    // Observar SOLO el contenedor de la grilla, NO todo el documento
    this.arenaObserver.observe(arenaGridContainer, {
      childList: true,
      subtree: false // NO subtree para evitar cambios en marcadores del mapa
    });
    
    this._cardsObserverInitialized = true;
    if (this.debug) console.log('Observer de arena configurado exitosamente');
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
      this._cardsObserverInitialized = false
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
    
    // Solo actualizar country si está vacío Y no tiene foco
    if (!this.countryTarget.value && document.activeElement !== this.countryTarget) {
      this.countryTarget.value = countryName
    }
    
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
        // Solo limpiar si están vacíos Y no tienen foco
        if (!this.cityTarget.value && document.activeElement !== this.cityTarget) {
          this.cityTarget.value = ''
        }
        if (!this.addressTarget.value && document.activeElement !== this.addressTarget) {
          this.addressTarget.value = ''
        }
        // Siempre limpiar coordenadas
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
    
    // Solo actualizar city si está vacío Y no tiene foco
    if (!this.cityTarget.value && document.activeElement !== this.cityTarget) {
      this.cityTarget.value = cityName
    }
    
    // Solo actualizar country si está vacío Y no tiene foco
    if (countryName && !this.countryTarget.value && document.activeElement !== this.countryTarget) {
      this.countryTarget.value = countryName
    }
    
    // ALMACENAR CITY BIAS para restringir autocomplete de direcciones
    if (result.center) {
      const [lng, lat] = result.center;
      this.cityBias = {
        lng: lng,
        lat: lat,
        bbox: result.bbox || null,
        name: cityName,
        country: countryName
      };
      console.log('🏙️ ARENA-LOCATION: City bias almacenado:', this.cityBias);
    }
    
    // Actualizar bias para geocoder de direcciones
    this.updateGeocoderBias()
    
    // SOLO actualizar cityTarget.value y bias de geocoder
    // NO mover marcador, NO actualizar coordenadas, NO disparar eventos
    console.log('🏙️ ARENA-LOCATION: Ciudad seleccionada - solo actualiza campo city y bias')
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
    
    // Solo actualizar address si está vacío Y no tiene foco
    if (!this.addressTarget.value && document.activeElement !== this.addressTarget) {
      this.addressTarget.value = addressName
    }
    
    // 🧭 JERARQUÍA: Solo actualizar city si está vacío Y no tiene foco
    // Address tiene prioridad sobre city, pero respetamos si el usuario está escribiendo
    if (cityName && !this.cityTarget.value && document.activeElement !== this.cityTarget) {
      this.cityTarget.value = cityName
      console.log('🧭 Jerarquía: city actualizado desde address (campo vacío y sin foco)')
    } else if (cityName && this.cityTarget.value) {
      console.log('🧭 Jerarquía: city NO actualizado desde address (ya tiene valor)')
    } else if (cityName && document.activeElement === this.cityTarget) {
      console.log('🧭 Jerarquía: city NO actualizado desde address (usuario escribiendo)')
    }
    
    // Solo actualizar country si está vacío Y no tiene foco
    if (countryName && !this.countryTarget.value && document.activeElement !== this.countryTarget) {
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
  // DESHABILITADO: Ya no ejecuta geocoding automático al escribir
  // Solo se ejecuta manualmente desde submitAddressSearch()
  schedule() {
    // Comentado para evitar movimiento automático del marcador
    // El geocoding ahora solo se ejecuta manualmente desde submitAddressSearch()
    console.log('🔍 ARENA-LOCATION: schedule() llamado pero deshabilitado para evitar movimiento automático')
    return
    
    // Código original comentado:
    // if (this.debounceTimer) {
    //   clearTimeout(this.debounceTimer)
    // }
    // 
    // this.debounceTimer = setTimeout(() => {
    //   this.geocode()
    // }, 600) // 600ms de debounce
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
      draggable: false 
    }).setLngLat([initialLng, initialLat]).addTo(this.map)

    console.log('Marcador creado, draggable:', this.editableValue);

    // Configurar eventos del marcador si es editable
    if (this.editableValue) {
      this.setupMarkerEvents()
    }

    // === Helpers para centro y estado ===
    this.isArenaSelected = () => {
      const el = document.getElementById('duel_arena_id');
      return !!(el && String(el.value).trim() !== '');
    };

    const getLatInput = () => document.querySelector('[name="duel[latitude]"]');
    const getLngInput = () => document.querySelector('[name="duel[longitude]"]');

    // Debounce simple
    const debounce = (fn, wait = 400) => {
      let t; return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), wait); };
    };

    // === 1) Mantener marcador en el centro durante pan/zoom ===
    const syncMarkerToCenter = () => {
      if (!this.map || !this.marker) return;
      if (this.isArenaSelected()) return; // no pisar si hay arena seleccionada
      const c = this.map.getCenter();
      this.marker.setLngLat([c.lng, c.lat]);
    };

    // === 2) Al terminar movimiento, escribir inputs + evento + reverse geocode (debounced) ===
    const writeCenterToHiddenAndDispatch = () => {
      if (!this.map) return;
      if (this.isArenaSelected()) return; // no actualizar si hay arena seleccionada
      const c = this.map.getCenter();
      const latInput = getLatInput();
      const lngInput = getLngInput();
      if (latInput) latInput.value = Number(c.lat).toFixed(6);
      if (lngInput) lngInput.value = Number(c.lng).toFixed(6);

      // Notificar a duel_steps para recalcular 3km
      window.dispatchEvent(new CustomEvent("leagend:location_changed", {
        detail: { lat: c.lat, lng: c.lng, source: 'map_center_move' }
      }));

      // Reverse geocoding solo al final del movimiento (debounced)
      if (typeof this.reverseGeocode === 'function') {
        this._revGeoDebounced = this._revGeoDebounced || debounce((lat, lng) => {
          try { this.reverseGeocode(lat, lng); } catch(_) {}
        }, 500);
        this._revGeoDebounced(c.lat, c.lng);
      }

      // Persistencia local (opcional)
      try {
        localStorage.setItem('leagend:lastLat', String(c.lat));
        localStorage.setItem('leagend:lastLng', String(c.lng));
      } catch(_) {}
    };

    // Desactivar el zoom por doble clic: lo usaremos para fijar ubicación
    this.map.doubleClickZoom.disable();

    // === Listeners de movimiento/zoom ===
    this.map.on('move',     syncMarkerToCenter);
    this.map.on('moveend',  writeCenterToHiddenAndDispatch);
    this.map.on('zoomend',  writeCenterToHiddenAndDispatch);

    // Sincronía inicial para que el marker ya aparezca centrado al cargar
    syncMarkerToCenter();

    // Fijar ubicación con DOBLE CLIC
    this.map.on('dblclick', (e) => {
      const { lng, lat } = e.lngLat || {};
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return;

      try {
        // Mover marcador visual (independiente de si hay arena seleccionada)
        this.marker?.setLngLat([lng, lat]);

        // Actualizar inputs
        const latInput = document.querySelector('[name="duel[latitude]"]');
        const lngInput = document.querySelector('[name="duel[longitude]"]');
        if (latInput) latInput.value = Number(lat).toFixed(6);
        if (lngInput) lngInput.value = Number(lng).toFixed(6);

        // Notificar (no se ignora por el anti-loop)
        window.dispatchEvent(new CustomEvent("leagend:location_changed", {
          detail: { lat, lng, source: 'map_dblclick' }
        }));

        // Reverse geocoding
        if (typeof this.reverseGeocode === 'function') {
          try { this.reverseGeocode(lat, lng); } catch(_) {}
        }
      } catch (err) {
        console.warn('No se pudo procesar dblclick en mapa:', err);
      }
    });

    // LONG-PRESS DESHABILITADO POR DECISIÓN UX
    // Se eliminó el comportamiento de mantener presionado (long-press) que movía el marcador/centro del mapa.
    // Solo se mantiene el doble clic para mover el marcador/centro.
    // Referencia: Eliminación de long-press para mejorar UX - mantener solo doble clic

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
      // Solo crear si no hay marcadores existentes
      if (this.arenaMarkers.length === 0) {
        this.createArenaMarkers();
      }
    })
    
    console.log('Mapa inicializado exitosamente');
  }

  // Crear marcadores para todas las arenas visibles
  createArenaMarkers() {
    if (!this.map) {
      if (this.debug) console.log('No hay mapa disponible para crear marcadores de arenas');
      return;
    }

    if (this.debug) console.log('Creando marcadores de arenas...');
    
    // Remover marcadores existentes para evitar duplicados
    this.removeArenaMarkers();
    
    // Buscar todas las tarjetas de arena visibles
    const arenaCards = document.querySelectorAll('.arena-card');
    if (this.debug) console.log(`Encontradas ${arenaCards.length} tarjetas de arena`);
    
    arenaCards.forEach(card => {
      const arenaId = card.dataset.arenaId;
      const lat = parseFloat(card.dataset.lat);
      const lng = parseFloat(card.dataset.lng);
      const name = card.dataset.arenaName;
      const city = card.dataset.city;
      
      // Verificar que tenemos coordenadas válidas
      if (!arenaId || !Number.isFinite(lat) || !Number.isFinite(lng) || !name) {
        if (this.debug) console.warn('Datos de arena incompletos:', { arenaId, lat, lng, name });
        return;
      }
      
      if (this.debug) console.log(`Creando marcador para arena: ${name} en (${lat}, ${lng})`);
      
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
    
    if (this.debug) console.log(`Marcadores de arenas creados: ${this.arenaMarkers.length}`);
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
      if (this.debug) console.log(`Removiendo ${this.arenaMarkers.length} marcadores de arenas existentes`);
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
    // GUARDA ANTI RE-ENTRADA: Evitar múltiples ejecuciones simultáneas
    if (this._updatingMarkers) {
      if (this.debug) console.log('updateArenaMarkers ya en ejecución, saltando...');
      return;
    }
    
    if (this.map && this.map.isStyleLoaded()) {
      this._updatingMarkers = true;
      
      try {
        if (this.debug) console.log('Actualizando marcadores de arenas...');
        this.createArenaMarkers();
      } finally {
        // GARANTIZAR que la bandera se libere incluso si hay errores
        this._updatingMarkers = false;
      }
    } else {
      if (this.debug) console.log('Mapa no listo, marcadores se crearán cuando esté disponible');
    }
  }

  // Método público para forzar actualización de marcadores (útil para llamadas externas)
  refreshArenaMarkers() {
    if (this.debug) console.log('Forzando actualización de marcadores de arenas...');
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
      
      // 🧭 JERARQUÍA: Solo rellenar city o country si están vacíos y sin foco
      // Address: NUNCA sobrescribir si ya tiene texto
      if (country && !this.countryTarget.value && document.activeElement !== this.countryTarget) {
        this.countryTarget.value = country
        console.log('🧭 Jerarquía: country actualizado desde reverseGeocode (campo vacío y sin foco)')
      }
      if (city && !this.cityTarget.value && document.activeElement !== this.cityTarget) {
        this.cityTarget.value = city
        console.log('🧭 Jerarquía: city actualizado desde reverseGeocode (campo vacío y sin foco)')
      } else if (city && this.cityTarget.value) {
        console.log('🧭 Jerarquía: city NO actualizado desde reverseGeocode (ya tiene valor)')
      } else if (city && document.activeElement === this.cityTarget) {
        console.log('🧭 Jerarquía: city NO actualizado desde reverseGeocode (usuario escribiendo)')
      }
      // Address: NUNCA sobrescribir si ya tiene texto
      if (feat.place_name && !this.addressTarget.value && document.activeElement !== this.addressTarget) {
        this.addressTarget.value = feat.place_name
        console.log('🧭 Jerarquía: address actualizado desde reverseGeocode (campo vacío y sin foco)')
      } else if (feat.place_name && this.addressTarget.value) {
        console.log('🧭 Jerarquía: address NO actualizado desde reverseGeocode (ya tiene valor)')
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
      
      // NO disparar evento de cambio de ubicación
      // reverseGeocode solo completa campos de texto, no mueve marcador
      console.log('🔄 ARENA-LOCATION: reverseGeocode completado - solo campos de texto actualizados')
    } catch(error) {
      console.warn("Error en geocodificación inversa:", error)
    }
  }
  
  // Disparar evento global de cambio de ubicación con información completa
  dispatchLocationChangedEvent(
    lat, lng,
    city = null,
    country = null,
    address = null,
    neighborhood = null,
    source = 'unknown',
    noCenter = false // 👈 nuevo flag
  ) {
    const eventData = {
      lat: lat,
      lng: lng,
      city: city || this.cityTarget?.value || null,
      country: country || this.countryTarget?.value || null,
      address: address || this.addressTarget?.value || null,
      neighborhood: neighborhood || null,
      source: source,
      noCenter: !!noCenter // 👈 incluir en el detail
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
    
    // Resetear banderas de control
    this._updatingMarkers = false
    this._cardsObserverInitialized = false
    
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
    
    const { lat, lng, source, noCenter } = event.detail
    console.log(`📍 ARENA-LOCATION: Coordenadas recibidas: (${lat}, ${lng}) desde ${source}`)
    
    // ⛔ ignorar si el emisor pide explícitamente no centrar
    if (noCenter) {
      console.log('🔄 ARENA-LOCATION: Evento con noCenter=true, no se recentra el mapa')
      return
    }
    
    // 🔒 ya ignorabas esto; mantenlo
    if (source === 'map_center_move') {
      console.log('🔄 ARENA-LOCATION: Evento de map_center_move ignorado para evitar loop')
      return
    }
    
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
    
    // Evitar animaciones innecesarias (micro saltos)
    const cur = this.map.getCenter()
    const eps = 1e-7
    const same =
      Math.abs(cur.lat - lat) < eps &&
      Math.abs(cur.lng - lng) < eps

    if (this.marker) {
      this.marker.setLngLat([lng, lat])
      console.log('📍 ARENA-LOCATION: Marcador movido a nuevas coordenadas')
    }

    if (same) {
      console.log('✅ ARENA-LOCATION: Ya está centrado; se evita flyTo')
      return
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
  
  // Método para habilitar logs verbosos
  enableDebug() {
    this.debug = true;
    console.log('🔍 ARENA-LOCATION: Modo debug habilitado');
  }
  
  // Método para deshabilitar logs verbosos
  disableDebug() {
    this.debug = false;
    console.log('🔍 ARENA-LOCATION: Modo debug deshabilitado');
  }

  // Se llama en cada tecla del Address; implementa autocomplete con debounce
  onAddressInput(e) {
    const query = e.target.value.trim();
    
    // 🧭 JERARQUÍA: Si el usuario edita address → nunca sobrescribir city manualmente escrito
    // (No hay limpieza automática, solo respeto por el valor existente)
    console.log('🧭 Jerarquía aplicada: address editado → respetando city existente');
    
    // Limpiar timer anterior si existe
    if (this.addressAutocompleteTimer) {
      clearTimeout(this.addressAutocompleteTimer);
    }
    
    // Si el query está vacío, limpiar sugerencias
    if (!query) {
      this.clearAddressSuggestions();
      return;
    }
    
    // Debounce de 300ms para evitar demasiadas llamadas a la API
    this.addressAutocompleteTimer = setTimeout(() => {
      this.fetchAddressSuggestions(query);
    }, 300);
  }

  // Se llama cuando se edita el campo de ciudad manualmente
  onCityInput(e) {
    const cityName = e.target.value.trim();
    
    // 🧭 JERARQUÍA: Si el usuario edita city → limpiar solo address
    this.applyHierarchyOnCityChange();
    
    // Limpiar timer anterior si existe
    if (this.cityGeocodeTimer) {
      clearTimeout(this.cityGeocodeTimer);
    }
    
    // Si el campo está vacío, limpiar cityBias
    if (!cityName) {
      this.cityBias = null;
      console.log('🏙️ ARENA-LOCATION: City bias limpiado - campo ciudad vacío');
      return;
    }
    
    // Debounce de 500ms para geocodificar ciudad y actualizar bias
    this.cityGeocodeTimer = setTimeout(() => {
      const countryName = this.hasCountryTarget ? this.countryTarget.value?.trim() : null;
      this.geocodeCityForBias(cityName, countryName);
    }, 500);
  }

  // Se llama cuando se edita el campo de país manualmente
  onCountryInput(e) {
    const countryName = e.target.value.trim();
    
    // 🧭 JERARQUÍA: Si el usuario edita country → limpiar city y address
    this.applyHierarchyOnCountryChange();
    
    // Si hay una ciudad seleccionada, actualizar el bias con el nuevo país
    if (this.cityBias && this.hasCityTarget && this.cityTarget.value.trim()) {
      const cityName = this.cityTarget.value.trim();
      console.log('🌍 ARENA-LOCATION: País cambiado, actualizando city bias para:', cityName, countryName);
      
      // Limpiar timer anterior si existe
      if (this.cityGeocodeTimer) {
        clearTimeout(this.cityGeocodeTimer);
      }
      
      // Debounce de 500ms para geocodificar ciudad con nuevo país
      this.cityGeocodeTimer = setTimeout(() => {
        this.geocodeCityForBias(cityName, countryName);
      }, 500);
    }
  }

  // Obtener sugerencias de direcciones desde la API de Mapbox
  async fetchAddressSuggestions(query) {
    try {
      const token = this.getMapboxToken();
      if (!token) {
        console.warn('Token de Mapbox no disponible para autocomplete');
        return;
      }

      // Construir query completa incluyendo ciudad y país para priorizar resultados
      let fullQuery = query;
      const country = this.hasCountryTarget ? this.countryTarget.value?.trim() : '';
      
      if (this.cityBias?.name) {
        fullQuery += `, ${this.cityBias.name}`;
      }
      if (country) {
        fullQuery += `, ${country}`;
      }
      
      // Construir URL base con query completa
      let url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(fullQuery)}.json?autocomplete=true&limit=5&language=es&access_token=${token}`;
      
      console.log('🔍 ARENA-LOCATION: Query completa enviada a Mapbox:', fullQuery);
      
      // Añadir restricción de país si está disponible
      if (country) {
        // Mapear nombres de países a códigos ISO
        const countryCode = this.getCountryCode(country);
        if (countryCode) {
          url += `&country=${countryCode}`;
          console.log('🌍 ARENA-LOCATION: Restringiendo a país:', countryCode);
        }
      }
      
      // Añadir bias de proximidad y bbox si tenemos información de ciudad
      if (this.cityBias) {
        url += `&proximity=${this.cityBias.lng},${this.cityBias.lat}`;
        console.log('🏙️ ARENA-LOCATION: Usando bias de ciudad:', { lng: this.cityBias.lng, lat: this.cityBias.lat });
        
        if (this.cityBias.bbox) {
          url += `&bbox=${this.cityBias.bbox.join(',')}`;
          console.log('📦 ARENA-LOCATION: Usando bbox de ciudad:', this.cityBias.bbox);
        }
      }
      
      console.log('🔍 ARENA-LOCATION: Consultando autocomplete:', url);
      
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Error en API de Mapbox: ${response.status}`);
      }

      const data = await response.json();
      
      // Filtrar sugerencias para que solo aparezcan las que están en la ciudad actual
      let features = data.features || [];
      if (this.cityBias?.name) {
        const inCity = [];
        const outCity = [];
        for (const f of features) {
          const cityName = this.getContextText(f.context || [], ["place", "locality"]) ||
                           this.getContextText(f.context || [], ["region"]);
          if (cityName === this.cityBias.name) {
            inCity.push(f);
          } else {
            outCity.push(f);
          }
        }
        // Si hay resultados en la ciudad, mostrar SOLO esos
        features = inCity.length > 0 ? inCity.slice(0, 5) : outCity.slice(0, 5);
        console.log(`🏙️ ARENA-LOCATION: ${inCity.length} sugerencias dentro de ${this.cityBias.name}, ${outCity.length} fuera`);
      }
      
      this.displayAddressSuggestions(features);
      
    } catch (error) {
      console.error('❌ ARENA-LOCATION: Error en autocomplete:', error);
      this.clearAddressSuggestions();
    }
  }

  // Mostrar sugerencias en el dropdown
  displayAddressSuggestions(suggestions) {
    const container = document.getElementById('address-suggestions');
    if (!container) {
      console.warn('Contenedor de sugerencias no encontrado');
      return;
    }

    // Limpiar sugerencias anteriores
    container.innerHTML = '';

    if (suggestions.length === 0) {
      container.style.display = 'none';
      return;
    }

    // Crear elementos de sugerencia
    suggestions.forEach((suggestion, index) => {
      const [lng, lat] = suggestion.center;
      const placeName = suggestion.place_name;
      
      const suggestionElement = document.createElement('div');
      suggestionElement.className = 'list-group-item list-group-item-action';
      suggestionElement.style.cursor = 'pointer';
      suggestionElement.innerHTML = `
        <div class="d-flex align-items-center">
          <i class="fas fa-map-marker-alt text-primary me-2"></i>
          <div>
            <div class="fw-semibold">${placeName}</div>
            <small class="text-muted">${lat.toFixed(6)}, ${lng.toFixed(6)}</small>
          </div>
        </div>
      `;
      
      // Añadir datos para el evento de selección
      suggestionElement.dataset.lat = lat;
      suggestionElement.dataset.lng = lng;
      suggestionElement.dataset.place = placeName;
      suggestionElement.dataset.context = JSON.stringify(suggestion.context || []);
      
      // Evento de click
      suggestionElement.addEventListener('click', (e) => {
        this.selectAddressSuggestion(e);
      });
      
      // Evento de hover para mejor UX
      suggestionElement.addEventListener('mouseenter', () => {
        suggestionElement.classList.add('active');
      });
      
      suggestionElement.addEventListener('mouseleave', () => {
        suggestionElement.classList.remove('active');
      });
      
      container.appendChild(suggestionElement);
    });

    container.style.display = 'block';
    console.log(`✅ ARENA-LOCATION: ${suggestions.length} sugerencias mostradas`);
  }

  // Limpiar sugerencias del dropdown
  clearAddressSuggestions() {
    const container = document.getElementById('address-suggestions');
    if (container) {
      container.innerHTML = '';
      container.style.display = 'none';
    }
  }

  // Seleccionar una sugerencia del dropdown
  selectAddressSuggestion(e) {
    const element = e.currentTarget;
    const lat = parseFloat(element.dataset.lat);
    const lng = parseFloat(element.dataset.lng);
    const place = element.dataset.place;
    const context = JSON.parse(element.dataset.context || '[]');

    console.log('🎯 ARENA-LOCATION: Sugerencia seleccionada:', { lat, lng, place });

    // Actualizar el input con la dirección seleccionada
    if (this.hasAddressTarget) {
      this.addressTarget.value = place;
    }

    // Actualizar coordenadas
    this.updateCoordinates(lat, lng);

    // Mover marcador y centrar mapa
    this.updateMapLocation(lat, lng);

    // Extraer información de contexto para completar otros campos
    const countryName = this.getContextText(context, ["country"]);
    const cityName = this.getContextText(context, ["place", "locality"]) || 
                    this.getContextText(context, ["region"]);

    // Solo actualizar country si está vacío Y no tiene foco
    if (countryName && !this.countryTarget.value && document.activeElement !== this.countryTarget) {
      this.countryTarget.value = countryName;
    }
    
    // 🧭 JERARQUÍA: NO sobrescribir cityTarget si ya tiene valor → respetar la ciudad fijada por el usuario
    // Solo actualizar si está completamente vacío Y no tiene foco
    if (cityName && !this.cityTarget.value && document.activeElement !== this.cityTarget) {
      this.cityTarget.value = cityName;
      console.log('🧭 Jerarquía: city actualizado desde sugerencia (campo vacío y sin foco)')
    } else if (cityName && this.cityTarget.value) {
      console.log('🧭 Jerarquía: city NO actualizado desde sugerencia (ya tiene valor)')
    } else if (cityName && document.activeElement === this.cityTarget) {
      console.log('🧭 Jerarquía: city NO actualizado desde sugerencia (usuario escribiendo)')
    }

    // Actualizar campos hidden del formulario
    this.writeHidden({ 
      country: countryName || this.countryTarget.value, 
      city: cityName || this.cityTarget.value, 
      address: place, 
      neighborhood: null, 
      lat: lat, 
      lng: lng 
    });

    // Disparar evento de cambio de ubicación
    this.dispatchLocationChangedEvent(lat, lng, cityName, countryName, place, null, 'address_autocomplete');

    // Limpiar sugerencias
    this.clearAddressSuggestions();

    console.log('✅ ARENA-LOCATION: Sugerencia procesada exitosamente');
  }

  // Manejar click fuera del input para ocultar sugerencias
  handleDocumentClick(e) {
    const addressField = document.getElementById('address-field');
    const suggestionsContainer = document.getElementById('address-suggestions');
    
    if (addressField && suggestionsContainer && 
        !addressField.contains(e.target) && 
        suggestionsContainer.style.display !== 'none') {
      this.clearAddressSuggestions();
    }
  }

  // Manejar teclas para ocultar sugerencias
  handleDocumentKeydown(e) {
    if (e.key === 'Escape') {
      this.clearAddressSuggestions();
    }
  }

  // Mapear nombres de países a códigos ISO para la API de Mapbox
  getCountryCode(countryName) {
    const countryMap = {
      'Colombia': 'CO',
      'colombia': 'CO',
      'COLOMBIA': 'CO',
      'México': 'MX',
      'mexico': 'MX',
      'MEXICO': 'MX',
      'España': 'ES',
      'españa': 'ES',
      'ESPAÑA': 'ES',
      'Argentina': 'AR',
      'argentina': 'AR',
      'ARGENTINA': 'AR',
      'Chile': 'CL',
      'chile': 'CL',
      'CHILE': 'CL',
      'Perú': 'PE',
      'peru': 'PE',
      'PERU': 'PE',
      'Venezuela': 'VE',
      'venezuela': 'VE',
      'VENEZUELA': 'VE',
      'Ecuador': 'EC',
      'ecuador': 'EC',
      'ECUADOR': 'EC',
      'Bolivia': 'BO',
      'bolivia': 'BO',
      'BOLIVIA': 'BO',
      'Paraguay': 'PY',
      'paraguay': 'PY',
      'PARAGUAY': 'PY',
      'Uruguay': 'UY',
      'uruguay': 'UY',
      'URUGUAY': 'UY',
      'Brasil': 'BR',
      'brasil': 'BR',
      'BRASIL': 'BR',
      'Estados Unidos': 'US',
      'estados unidos': 'US',
      'ESTADOS UNIDOS': 'US',
      'United States': 'US',
      'united states': 'US',
      'UNITED STATES': 'US'
    };
    
    return countryMap[countryName] || null;
  }

  // Geocodificar ciudad para obtener bias cuando se edita manualmente
  async geocodeCityForBias(cityName, countryName = null) {
    try {
      const token = this.getMapboxToken();
      if (!token) {
        console.warn('Token de Mapbox no disponible para geocodificar ciudad');
        return;
      }

      // Construir query de búsqueda
      let query = cityName;
      if (countryName) {
        const countryCode = this.getCountryCode(countryName);
        if (countryCode) {
          query = `${cityName}, ${countryCode}`;
        }
      }

      const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?types=place,locality&limit=1&access_token=${token}`;
      
      console.log('🏙️ ARENA-LOCATION: Geocodificando ciudad para bias:', url);
      
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Error en API de Mapbox: ${response.status}`);
      }

      const data = await response.json();
      const feature = data.features?.[0];

      if (feature && feature.center) {
        const [lng, lat] = feature.center;
        this.cityBias = {
          lng: lng,
          lat: lat,
          bbox: feature.bbox || null,
          name: cityName,
          country: countryName
        };
        console.log('✅ ARENA-LOCATION: City bias actualizado desde geocodificación:', this.cityBias);
      } else {
        console.warn('⚠️ ARENA-LOCATION: No se encontró información de geocodificación para la ciudad:', cityName);
        this.cityBias = null;
      }
      
    } catch (error) {
      console.error('❌ ARENA-LOCATION: Error geocodificando ciudad:', error);
      this.cityBias = null;
    }
  }

  // Inicializar cityBias desde valores existentes en los campos
  async initializeCityBiasFromExistingValues() {
    const cityName = this.hasCityTarget ? this.cityTarget.value?.trim() : '';
    const countryName = this.hasCountryTarget ? this.countryTarget.value?.trim() : '';
    
    if (cityName) {
      console.log('🏙️ ARENA-LOCATION: Inicializando city bias desde valores existentes:', cityName, countryName);
      await this.geocodeCityForBias(cityName, countryName);
    }
  }

  // Dispara la búsqueda manual (click botón o Enter en el input)
  async submitAddressSearch(e) {
    e?.preventDefault?.();
    e?.stopPropagation?.();

    const country = this.hasCountryTarget ? this.countryTarget.value?.trim() : '';
    const city    = this.hasCityTarget    ? this.cityTarget.value?.trim()    : '';
    const address = this.hasAddressTarget ? this.addressTarget.value?.trim() : '';

    if (!country || !city || !address) {
      console.warn('submitAddressSearch: faltan datos para geocodificar', {country, city, address});
      return;
    }

    console.log('🔍 ARENA-LOCATION: Ejecutando búsqueda manual de dirección:', {country, city, address});

    try {
      // Usar API de Mapbox directamente para geocoding
      const token = this.getMapboxToken();
      if (!token) {
        throw new Error('Token de Mapbox no disponible');
      }

      // Construir query de búsqueda - SOLO ADDRESS
      if (!address) {
        console.warn('submitAddressSearch: No hay address para buscar');
        return;
      }
      
      const query = address;
      let url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?access_token=${token}&language=es&limit=1`;
      
      // Usar city/country como bias de proximidad, no en el string
      if (city || country) {
        const bias = this.getProximityBias();
        if (bias && bias.longitude && bias.latitude) {
          url += `&proximity=${bias.longitude},${bias.latitude}`;
          console.log('🔍 ARENA-LOCATION: Usando bias de proximidad:', bias);
        }
      }

      console.log('🔍 ARENA-LOCATION: Consultando API de Mapbox:', url);

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Error en API de Mapbox: ${response.status}`);
      }

      const data = await response.json();
      const feature = data.features?.[0];

      if (!feature || !feature.center) {
        console.warn('submitAddressSearch: No se encontraron coordenadas para la dirección');
        return;
      }

      const [lng, lat] = feature.center;
      console.log('✅ ARENA-LOCATION: Coordenadas encontradas:', {lat, lng});

      // Actualizar coordenadas (SIEMPRE se actualizan)
      this.updateCoordinates(lat, lng);
      
      // Mover marcador y centrar mapa
      this.updateMapLocation(lat, lng);

      // Actualizar campos de texto - PRIORIDAD ABSOLUTA A ADDRESS
      const countryName = this.getContextText(feature.context || [], ["country"]);
      const cityName = this.getContextText(feature.context || [], ["place", "locality"]) || 
                      this.getContextText(feature.context || [], ["region"]);
      const addressName = feature.place_name;

      // Country: solo si está vacío Y no tiene foco
      if (countryName && !this.countryTarget.value && document.activeElement !== this.countryTarget) {
        this.countryTarget.value = countryName;
      }
      
      // 🧭 JERARQUÍA: City: solo si está vacío Y no tiene foco
      if (cityName && !this.cityTarget.value && document.activeElement !== this.cityTarget) {
        this.cityTarget.value = cityName;
        console.log('🧭 Jerarquía: city actualizado desde búsqueda manual (campo vacío y sin foco)')
      } else if (cityName && this.cityTarget.value) {
        console.log('🧭 Jerarquía: city NO actualizado desde búsqueda manual (ya tiene valor)')
      } else if (cityName && document.activeElement === this.cityTarget) {
        console.log('🧭 Jerarquía: city NO actualizado desde búsqueda manual (usuario escribiendo)')
      }
      
      // Address: NUNCA sobrescribir si ya tiene texto
      if (addressName && !this.addressTarget.value && document.activeElement !== this.addressTarget) {
        this.addressTarget.value = addressName;
      }

      // Actualizar campos hidden del formulario
      this.writeHidden({ 
        country: countryName || this.countryTarget.value, 
        city: cityName || this.cityTarget.value, 
        address: addressName || this.addressTarget.value, 
        neighborhood: null, 
        lat: lat, 
        lng: lng 
      });

      // Disparar evento de cambio de ubicación
      this.dispatchLocationChangedEvent(lat, lng, cityName, countryName, addressName, null, 'address_manual_search');

      console.log('✅ ARENA-LOCATION: Búsqueda manual completada exitosamente');

    } catch (err) {
      console.error('❌ ARENA-LOCATION: Error en búsqueda manual:', err);
      
      // Fallback: intentar con backend si Mapbox falla
      try {
        console.log('🔄 ARENA-LOCATION: Intentando fallback con backend...');
        const res = await fetch('/arenas/geocode.json', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': this.getCSRFToken()
          },
          body: JSON.stringify({ country, city, address })
        });

        if (res.ok) {
          const data = await res.json();
          const lat = parseFloat(data.lat);
          const lng = parseFloat(data.lng);

          if (Number.isFinite(lat) && Number.isFinite(lng)) {
            this.updateCoordinates(lat, lng);
            this.updateMapLocation(lat, lng);
            this.dispatchLocationChangedEvent(lat, lng, city, country, address, null, 'address_manual_search_fallback');
            console.log('✅ ARENA-LOCATION: Fallback con backend exitoso');
          }
        }
      } catch (fallbackErr) {
        console.error('❌ ARENA-LOCATION: Fallback también falló:', fallbackErr);
      }
    }
  }

  // ========================================
  // MÉTODOS DE JERARQUÍA DE INPUTS
  // ========================================
  
  // 🧭 JERARQUÍA: Si el usuario edita country → limpiar city y address
  applyHierarchyOnCountryChange() {
    console.log('🧭 Jerarquía aplicada: country editado → limpiando city y address');
    
    // Limpiar city si NO tiene foco
    if (this.hasCityTarget && document.activeElement !== this.cityTarget) {
      this.cityTarget.value = '';
      console.log('✅ Campo city limpiado (sin foco)');
    } else if (this.hasCityTarget) {
      console.log('⏸️ Campo city NO limpiado (tiene foco)');
    }
    
    // Limpiar address si NO tiene foco
    if (this.hasAddressTarget && document.activeElement !== this.addressTarget) {
      this.addressTarget.value = '';
      console.log('✅ Campo address limpiado (sin foco)');
    } else if (this.hasAddressTarget) {
      console.log('⏸️ Campo address NO limpiado (tiene foco)');
    }
    
    // Limpiar coordenadas siempre (no dependen del foco)
    if (this.hasLatitudeTarget) this.latitudeTarget.value = '';
    if (this.hasLongitudeTarget) this.longitudeTarget.value = '';
    console.log('✅ Coordenadas limpiadas');
    
    // Limpiar cityBias ya que cambió el país
    this.cityBias = null;
    console.log('✅ City bias limpiado');
    
    // Limpiar sugerencias de autocomplete
    this.clearAddressSuggestions();
  }
  
  // 🧭 JERARQUÍA: Si el usuario edita city → limpiar solo address
  applyHierarchyOnCityChange() {
    console.log('🧭 Jerarquía aplicada: city editado → limpiando solo address');
    
    // Limpiar address si NO tiene foco
    if (this.hasAddressTarget && document.activeElement !== this.addressTarget) {
      this.addressTarget.value = '';
      console.log('✅ Campo address limpiado (sin foco)');
    } else if (this.hasAddressTarget) {
      console.log('⏸️ Campo address NO limpiado (tiene foco)');
    }
    
    // Limpiar coordenadas siempre (no dependen del foco)
    if (this.hasLatitudeTarget) this.latitudeTarget.value = '';
    if (this.hasLongitudeTarget) this.longitudeTarget.value = '';
    console.log('✅ Coordenadas limpiadas');
    
    // Limpiar sugerencias de autocomplete
    this.clearAddressSuggestions();
  }
}
