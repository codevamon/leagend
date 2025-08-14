import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progress", "nextBtn", "prevBtn", "submitBtn", "arenaId", "mapContainer", "arenaList", "arenaGrid", "arenaSearch", "latitude", "longitude"]
  static values = { 
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 4 }
  }

  // Campos/estado internos
  arenas = []
  arenaMarkers = new Map()
  currentLat = null
  currentLng = null
  debouncedRecompute = null

  connect() {
    // Inicializar debouncedRecompute
    this.debouncedRecompute = this.debounce(this.recomputeAndRender.bind(this), 250)
    
    this.showCurrentStep()
    this.updateProgress()
    this.updateButtons()
    this.setupEventListeners()
    
    // Inicializar componentes después de un breve delay para asegurar que el DOM esté listo
    setTimeout(() => {
      this.initFlatpickr()
      this.initMapbox()
      
      // Intentar geolocalización si estamos en Step 1
      if (this.currentStepValue === 1) {
        this.attemptGeolocation()
      }
      
      // Verificar si hay arenas en el DOM y mostrar mensaje si no las hay
      if (this.hasArenaListTarget) {
        const arenaItems = this.arenaListTarget.querySelectorAll('.arena-item')
        if (arenaItems.length === 0) {
          this.toggleNoArenasMessage(true)
        }
      }
    }, 100)
  }

  setupEventListeners() {
    // Escuchar cambios en campos para actualizar resumen
    this.element.addEventListener('change', (e) => {
      if (e.target.matches('input, select')) {
        this.updateSummary()
      }
    })

    // Escuchar cambios en campos de ubicación
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('#duel_country, #duel_city, #duel_address')) {
        this.updateSummary()
      }
    })

    // Escuchar cambios en campos de coordenadas para recalcular distancias
    this.element.addEventListener('change', (e) => {
      if (e.target.matches('#duel_latitude, #duel_longitude')) {
        this.updateArenaDistances()
      }
    })

    // Suscribirse a cambios de ubicación desde arena_location_controller
    window.addEventListener("leagend:location_changed", this.onLocationChanged.bind(this))
    
    // Cargar arenas desde el DOM
    this.buildArenasFromDOM()
    
    // Si hay lat/lng en hidden, llamar onLocationChanged
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      const lat = parseFloat(this.latitudeTarget.value)
      const lng = parseFloat(this.longitudeTarget.value)
      if (lat && lng) {
        this.onLocationChanged({ detail: { lat, lng } })
      }
    }
  }

  // Navegar al siguiente paso
  next() {
    if (this.canProceedToNext()) {
      this.currentStepValue++
      this.showCurrentStep()
      this.updateProgress()
      this.updateButtons()
      this.updateSummary()
      this.scrollToTop()
      
      // Si llegamos al Step 3, verificar selección de arena
      if (this.currentStepValue === 3) {
        this.checkStep3ArenaSelection()
      }
    }
  }

  // Navegar al paso anterior
  previous() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showCurrentStep()
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()
    }
  }

  // Ir a un paso específico
  goToStep(event) {
    const step = parseInt(event.currentTarget.dataset.step)
    if (step >= 1 && step <= this.totalStepsValue) {
      this.currentStepValue = step
      this.showCurrentStep()
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()
      
      // Si llegamos al Step 3, verificar selección de arena
      if (this.currentStepValue === 3) {
        this.checkStep3ArenaSelection()
      }
    }
  }

  // Mostrar solo el paso actual
  showCurrentStep() {
    this.stepTargets.forEach((step, index) => {
      const stepNumber = index + 1
      if (stepNumber === this.currentStepValue) {
        step.classList.remove('d-none')
        step.classList.add('step-active')
      } else {
        step.classList.add('d-none')
        step.classList.remove('step-active')
      }
    })
    
    // Actualizar barra de progreso simple
    const dots = this.element.querySelectorAll("[data-step-dot]")
    dots.forEach(dot => {
      const stepNumber = parseInt(dot.dataset.stepDot)
      if (stepNumber <= this.currentStepValue) {
        dot.classList.add('wizard-dot--active')
      } else {
        dot.classList.remove('wizard-dot--active')
      }
    })

    // Si llegamos al Step 3, verificar si ya hay una arena seleccionada
    if (this.currentStepValue === 3) {
      this.checkStep3ArenaSelection()
    }

    // Si estamos en Step 1, forzar resize del mapa que maneja arena_location_controller
    if (this.currentStepValue === 1) {
      setTimeout(() => {
        if (window.leagendMap && typeof window.leagendMap.resize === 'function') {
          window.leagendMap.resize()
        }
      }, 100)
    }
  }

  // Verificar selección de arena en Step 3
  checkStep3ArenaSelection() {
    if (!this.hasArenaIdTarget || !this.arenaIdTarget.value) return

    const arenaId = this.arenaIdTarget.value
    
    // Buscar la arena card correspondiente en Step 3
    const arenaCard = this.element.querySelector(`.arena-card[data-arena-id="${arenaId}"]`)
    if (arenaCard) {
      // Marcar la card como seleccionada
      this.element.querySelectorAll('.arena-card').forEach(card => {
        card.classList.remove('arena-card--selected')
      })
      arenaCard.classList.add('arena-card--selected')
    }
  }

  // Actualizar barra de progreso
  updateProgress() {
    if (this.hasProgressTarget) {
      const percentage = (this.currentStepValue / this.totalStepsValue) * 100
      this.progressTarget.style.width = `${percentage}%`
    }
  }

  // Actualizar estado de botones
  updateButtons() {
    // Botón anterior
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentStepValue === 1
      this.prevBtnTarget.classList.toggle('btn-secondary', this.currentStepValue === 1)
      this.prevBtnTarget.classList.toggle('btn-outline-secondary', this.currentStepValue > 1)
    }

    // Botón siguiente
    if (this.hasNextBtnTarget) {
      const isLastStep = this.currentStepValue === this.totalStepsValue
      this.nextBtnTarget.classList.toggle('d-none', isLastStep)
    }

    // Botón submit
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.classList.toggle('d-none', this.currentStepValue !== this.totalStepsValue)
    }
  }



  // Mostrar confirmación de selección de arena
  showArenaSelectionConfirmation(arenaName) {
    // Remover confirmaciones previas
    const existingConfirmations = this.element.querySelectorAll('.arena-selection-confirmation')
    existingConfirmations.forEach(conf => conf.remove())

    // Crear confirmación
    const confirmation = document.createElement('div')
    confirmation.className = 'alert alert-success arena-selection-confirmation mt-3'
    confirmation.innerHTML = `
      <i class="fas fa-check-circle me-2"></i>
      <strong>Arena seleccionada:</strong> ${arenaName}
    `

    // Insertar después del grid de arenas
    const arenaGrid = this.hasArenaGridTarget ? this.arenaGridTarget : this.element.querySelector('[data-duel-steps-target="arenaGrid"]')
    if (arenaGrid) {
      arenaGrid.appendChild(confirmation)
    }

    // Auto-remover después de 3 segundos
    setTimeout(() => {
      if (confirmation.parentNode) {
        confirmation.remove()
      }
    }, 3000)
  }



  // Actualizar resumen del duelo
  updateSummary() {
    // Ubicación
    const country = document.getElementById('duel_country')?.value || '-'
    const city = document.getElementById('duel_city')?.value || '-'
    const address = document.getElementById('duel_address')?.value || '-'

    document.getElementById('summary-country').textContent = country
    document.getElementById('summary-city').textContent = city
    document.getElementById('summary-address').textContent = address

    // Fecha y Hora
    const startsAt = document.getElementById('duel_starts_at')?.value
    if (startsAt) {
      const date = new Date(startsAt)
      const formattedDate = date.toLocaleDateString('es-ES', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      })
      const formattedTime = date.toLocaleTimeString('es-ES', { 
        hour: '2-digit', 
        minute: '2-digit' 
      })

      document.getElementById('summary-date').textContent = formattedDate
      document.getElementById('summary-time').textContent = formattedTime
    }

    // Duración
    const duration = document.getElementById('duel_duration')?.value
    if (duration) {
      const durationText = duration === '1' ? '1 hora' : `${duration} horas`
      document.getElementById('summary-duration').textContent = durationText
    }

    // Tipo de duelo
    const duelType = document.getElementById('duel_duel_type')?.value
    if (duelType) {
      const typeText = duelType.charAt(0).toUpperCase() + duelType.slice(1)
      document.getElementById('summary-duel-type').textContent = typeText
    }

    // Arena
    let arenaName = 'Sin arena seleccionada'
    let hasArena = false
    
    if (this.hasArenaIdTarget && this.arenaIdTarget.value) {
      hasArena = true
      
      // Buscar el nombre de la arena en el DOM usando data-arena-name
      const selectedArenaCard = this.element.querySelector(`.arena-card[data-arena-id="${this.arenaIdTarget.value}"]`)
      if (selectedArenaCard && selectedArenaCard.dataset.arenaName) {
        arenaName = selectedArenaCard.dataset.arenaName
      } else {
        // Fallback: buscar en el select para mantener compatibilidad
        const arenaSelect = document.getElementById('duel_arena_id')
        if (arenaSelect && arenaSelect.value) {
          const selectedOption = arenaSelect.options[arenaSelect.selectedIndex]
          arenaName = selectedOption.text
        }
      }
    }
    
    document.getElementById('summary-arena').textContent = arenaName
    
    // Mostrar/ocultar disclaimer según si hay arena seleccionada
    const disclaimer = document.getElementById('no-arena-disclaimer')
    if (disclaimer) {
      if (hasArena) {
        disclaimer.classList.add('d-none')
      } else {
        disclaimer.classList.remove('d-none')
      }
    }

    // Árbitro
    const assignReferee = document.getElementById('assign_referee')?.checked
    if (assignReferee) {
      document.getElementById('summary-referee').textContent = 'Asignación automática solicitada'
    } else {
      document.getElementById('summary-referee').textContent = 'Sin árbitro asignado'
    }
  }

  // Validar si se puede avanzar al siguiente paso
  canProceedToNext() {
    const currentStepElement = this.stepTargets[this.currentStepValue - 1]
    if (!currentStepElement) return false

    // Obtener campos requeridos del paso actual
    const requiredFields = currentStepElement.querySelectorAll('[required]')
    let isValid = true

    requiredFields.forEach(field => {
      if (!field.checkValidity()) {
        field.classList.add('is-invalid')
        isValid = false
      } else {
        field.classList.remove('is-invalid')
        field.classList.add('is-valid')
      }
    })

    // Validaciones específicas por paso
    if (this.currentStepValue === 1) {
      isValid = this.validateLocationStep()
    } else if (this.currentStepValue === 2) {
      isValid = this.validateDateTimeStep()
    }

    return isValid
  }

  // Validar paso de ubicación
  validateLocationStep() {
    const country = document.getElementById('duel_country')
    const city = document.getElementById('duel_city')
    const address = document.getElementById('duel_address')

    if (!country?.value || !city?.value || !address?.value) {
      this.showValidationError('Por favor completa todos los campos de ubicación')
      return false
    }

    return true
  }

  // Validar paso de fecha y hora
  validateDateTimeStep() {
    const startsAt = document.getElementById('duel_starts_at')
    const duration = document.getElementById('duel_duration')

    if (!startsAt?.value || !duration?.value) {
      this.showValidationError('Por favor completa la fecha, hora y duración')
      return false
    }

    // Validar que la fecha sea futura
    const selectedDate = new Date(startsAt.value)
    const now = new Date()
    
    if (selectedDate <= now) {
      this.showValidationError('La fecha y hora deben ser futuras')
      startsAt.classList.add('is-invalid')
      return false
    }

    return true
  }

  // Mostrar error de validación
  showValidationError(message) {
    // Remover errores previos
    const existingError = this.element.querySelector('.validation-error')
    if (existingError) {
      existingError.remove()
    }

    // Crear y mostrar nuevo error
    const errorDiv = document.createElement('div')
    errorDiv.className = 'alert alert-danger validation-error mt-3'
    errorDiv.innerHTML = `
      <i class="fas fa-exclamation-triangle me-2"></i>
      ${message}
    `
    
    const currentStep = this.stepTargets[this.currentStepValue - 1]
    currentStep.appendChild(errorDiv)

    // Auto-remover después de 5 segundos
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  // Scroll suave hacia arriba
  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }

  // Resetear al primer paso
  reset() {
    this.currentStepValue = 1
    this.showCurrentStep()
    this.updateProgress()
    this.updateButtons()
    
    // Limpiar validaciones
    this.element.querySelectorAll('.is-valid, .is-invalid').forEach(field => {
      field.classList.remove('is-valid', 'is-invalid')
    })
    
    // Limpiar errores de validación
    this.element.querySelectorAll('.validation-error').forEach(error => {
      error.remove()
    })
  }

  // Inicializar Flatpickr para el campo de fecha y hora
  initFlatpickr() {
    const startsAtInput = document.getElementById('duel_starts_at')
    if (startsAtInput && typeof flatpickr !== 'undefined') {
      // Configurar locale español
      const spanishLocale = {
        firstDayOfWeek: 1,
        weekdays: {
          shorthand: ['Dom', 'Lun', 'Mar', 'Mié', 'Juv', 'Vie', 'Sáb'],
          longhand: ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']
        },
        months: {
          shorthand: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
          longhand: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
        },
        rangeSeparator: ' hasta ',
        weekAbbreviation: 'Sem',
        amPM: ['AM', 'PM'],
        yearAriaLabel: 'Año',
        monthAriaLabel: 'Mes',
        hourAriaLabel: 'Hora',
        minuteAriaLabel: 'Minuto',
        time_24hr: true
      }

      flatpickr(startsAtInput, {
        enableTime: true,
        dateFormat: "Y-m-d H:i",
        minDate: "today",
        time_24hr: true,
        locale: spanishLocale,
        minuteIncrement: 15,
        placeholder: "Selecciona fecha y hora",
        onChange: () => {
          this.updateSummary()
        }
      })
    }
  }

  // Inicializar Mapbox Geocoder para autocompletado de ubicación
  initMapbox() {
    const token = this.mapboxToken()
    if (!token) return // Fallback silencioso si no hay token
    // Evitar geocoder duplicado si arena_location_controller ya lo renderiza
    const addressInput = document.getElementById('duel_address')
    const arenaGeocoderExists = document.querySelector('[data-arena-location-target="geocoderAddress"]')
    if (addressInput && typeof MapboxGeocoder !== 'undefined' && !arenaGeocoderExists) {
      const geocoder = new MapboxGeocoder({
        accessToken: token,
        types: 'address',
        countries: ['co'],
        language: 'es',
        placeholder: 'Busca una dirección...'
      })
      geocoder.addTo(`#${addressInput.id}`)
      geocoder.on('result', (e) => {
        const result = e.result
        addressInput.value = result.place_name
        const ctx = result.context || []
        const country = ctx.find(c => c.id.startsWith('country'))?.text || ''
        const city = ctx.find(c => c.id.startsWith('place'))?.text || ''
        const countryInput = document.getElementById('duel_country')
        const cityInput = document.getElementById('duel_city')
        if (countryInput && !countryInput.value) countryInput.value = country
        if (cityInput && !cityInput.value) cityInput.value = city
        this.updateSummary()
        this.onAddressCoordsChanged()
      })
    }
    
    // Crear mapa si existe mapContainerTarget
    if (this.hasMapContainerTarget) {
      this.createMap()
    }

    // Si hay lat/lng en hidden, llamar onLocationChanged
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      const lat = parseFloat(this.latitudeTarget.value)
      const lng = parseFloat(this.longitudeTarget.value)
      if (lat && lng) {
        this.onLocationChanged({ detail: { lat, lng } })
      }
    }
  }

  // Crear mapa Mapbox
  createMap() {
    const token = this.mapboxToken()
    if (!token || typeof mapboxgl === 'undefined' || !this.hasMapContainerTarget) return

    // Obtener coordenadas iniciales (de campos hidden o por defecto)
    const latInput = document.getElementById('duel_latitude')
    const lngInput = document.getElementById('duel_longitude')
    const initialLat = latInput?.value ? parseFloat(latInput.value) : 0
    const initialLng = lngInput?.value ? parseFloat(lngInput.value) : 0

    // Crear mapa
    this.map = new mapboxgl.Map({
      container: this.mapContainerTarget,
      style: 'mapbox://styles/mapbox/streets-v11',
      center: [initialLng, initialLat],
      zoom: 12,
      accessToken: token
    })

    // Agregar controles de navegación
    this.map.addControl(new mapboxgl.NavigationControl())

    // Crear marcador de ubicación
    this.locationMarker = new mapboxgl.Marker({ color: '#007bff' })
      .setLngLat([initialLng, initialLat])
      .addTo(this.map)

    // Cargar arenas y dibujar marcadores
    this.loadArenasFromDOM()
    this.drawArenaMarkers()
    
    // Actualizar lista por proximidad y refrescar marcadores
    this.updateNearbyList()
    this.refreshMarkers()
    
    // Si no hay arenas, mostrar mensaje
    if (!this.arenas || this.arenas.length === 0) {
      this.toggleNoArenasMessage(true)
    }
  }

  // Cargar arenas desde el DOM
  loadArenasFromDOM() {
    if (!this.hasArenaGridTarget) return

    this.arenas = []
    const arenaCards = this.arenaGridTarget.querySelectorAll('.arena-card')
    
    arenaCards.forEach(card => {
      const arena = {
        id: card.dataset.arenaId,
        name: card.dataset.arenaName || "",
        city: card.dataset.city || "",
        lat: parseFloat(card.dataset.lat),
        lng: parseFloat(card.dataset.lng),
        el: card,
        marker: null,
        distance: null,
        visible: true
      }
      this.arenas.push(arena)
    })
  }

  // Construir catálogo de arenas desde el DOM (alias para compatibilidad)
  buildArenasFromDOM() {
    this.loadArenasFromDOM()
  }

  // Dibujar marcadores de arenas en el mapa
  drawArenaMarkers() {
    if (!this.map || !this.arenas) return

    this.arenas.forEach(arena => {
      // Crear marcador
      const marker = new mapboxgl.Marker({ color: '#28a745' })
        .setLngLat([arena.lng, arena.lat])
        .addTo(this.map)

      // Crear popup
      const popup = new mapboxgl.Popup({ offset: 25 })
        .setHTML(`
          <div class="text-center">
            <h6 class="mb-1">${arena.name}</h6>
            <small class="text-muted">${arena.city || ''}</small>
          </div>
        `)

      marker.setPopup(popup)

      // Guardar referencia al marcador
      arena.marker = marker

      // Agregar evento click al marcador
      marker.getElement().addEventListener('click', () => {
        this.selectArenaById(arena.id)
      })
    })
  }

  // Resaltar arena seleccionada
  highlightArena(arena) {
    if (!arena || !this.map) return

    // Remover clase active de todas las arenas
    this.arenas.forEach(a => {
      if (a.el) {
        a.el.classList.remove('arena-card--selected')
      }
    })

    // Agregar clase active a la arena seleccionada
    if (arena.el) {
      arena.el.classList.add('arena-card--selected')
    }

    // Centrar mapa en la arena
    this.map.flyTo({
      center: [arena.lng, arena.lat],
      zoom: 15,
      duration: 1000
    })
  }

  // Llamado cuando cambian las coordenadas de la dirección
  onAddressCoordsChanged() {
    const latInput = document.getElementById('duel_latitude')
    const lngInput = document.getElementById('duel_longitude')
    
    if (latInput?.value && lngInput?.value) {
      const lat = parseFloat(latInput.value)
      const lng = parseFloat(lngInput.value)

      // Actualizar marcador de ubicación si existe
      if (this.locationMarker) {
        this.locationMarker.setLngLat([lng, lat])
      }

      // Centrar mapa en la nueva ubicación
      if (this.map) {
        this.map.flyTo({
          center: [lng, lat],
          zoom: 14,
          duration: 1000
        })
      }

      // Recalcular distancias y actualizar lista/marcadores
      this.debouncedRecompute()
    }
  }

  // Nuevo método para manejar cambios de ubicación desde arena_location_controller
  onLocationChanged(e) {
    if (!e?.detail) return
    this.currentLat = parseFloat(e.detail.lat)
    this.currentLng = parseFloat(e.detail.lng)
    this.debouncedRecompute()
  }

  // Nuevo método para manejar búsqueda de arenas
  onSearchInput() {
    this.debouncedRecompute()
  }

  // Nuevo método para recalcular y renderizar todo
  recomputeAndRender() {
    // proteger si no hay mapa aún
    const map = this.map || null
    // texto búsqueda
    const q = (this.arenaSearchTarget?.value || "").trim().toLowerCase()
    // calcular distancia y visibilidad
    const hasCoords = Number.isFinite(this.currentLat) && Number.isFinite(this.currentLng)
    
    this.arenas.forEach(a => {
      if (hasCoords && Number.isFinite(a.lat) && Number.isFinite(a.lng)) {
        a.distance = this.haversineKm(this.currentLat, this.currentLng, a.lat, a.lng)
      } else {
        a.distance = Infinity
      }
      const inRadius = a.distance <= 500
      const matches = q.length === 0 || a.name.toLowerCase().includes(q) || (a.city||"").toLowerCase().includes(q)
      a.visible = inRadius && matches && Number.isFinite(a.distance)
    })

    // ordenar y reordenar DOM (solo visibles)
    const visibles = this.arenas.filter(a => a.visible).sort((x,y) => x.distance - y.distance)
    
    // ocultar/mostrar
    this.arenas.forEach(a => a.el.classList.toggle("d-none", !a.visible))
    
    // reordenar contenedor por distancia
    const frag = document.createDocumentFragment()
    visibles.forEach(a => frag.appendChild(a.el))
    if (this.arenaGridTarget) this.arenaGridTarget.appendChild(frag)
    
    // markers
    if (map) this.refreshMarkers(map, visibles)
    
    // si hay una arena seleccionada y quedó oculta, limpia visual pero no bloquea el paso
    const selectedId = this.arenaIdTarget?.value
    if (selectedId) {
      const sel = this.arenas.find(a => a.id === selectedId)
      this.arenas.forEach(a => a.el.classList.toggle("arena-card--selected", a && sel && a.id === sel.id && a.visible))
    }
    
    // mostrar mensaje si no hay arenas visibles
    if (visibles.length === 0) {
      this.toggleNoArenasMessage(true)
    } else {
      this.toggleNoArenasMessage(false)
    }
  }

  // Seleccionar arena desde el card
  selectArenaCard(e) {
    const arenaCard = e.currentTarget
    const arenaId = arenaCard.dataset.arenaId
    this.selectArenaById(arenaId)
  }

  // Seleccionar arena por ID
  selectArenaById(id) {
    const a = this.arenas.find(x => x.id === id)
    if (!a) return
    
    if (this.arenaIdTarget) this.arenaIdTarget.value = id
    
    this.arenas.forEach(x => x.el.classList.toggle("arena-card--selected", x.id === id))
    
    // opcional: centrar mapa en el marker si existe
    const m = this.arenaMarkers.get(id)
    if (m && this.map) {
      try {
        this.map.flyTo({ 
          center: m.getLngLat(), 
          zoom: Math.max(this.map.getZoom(), 13), 
          speed: 0.6 
        })
      } catch(e) {}
    }
    
    // refrescar resumen si ya tienes updateSummary()
    if (this.updateSummary) this.updateSummary()
  }

  // Actualizar distancias de arenas y filtrar por proximidad
  updateArenaDistances() {
    if (this.arenas && this.arenas.length > 0) {
      this.debouncedRecompute()
    }
  }

  // Helper para obtener token de Mapbox
  mapboxToken() {
    const metaTag = document.querySelector('meta[name="mapbox-token"]')
    return metaTag ? metaTag.getAttribute('content') : null
  }

  // Intentar geolocalización del navegador
  attemptGeolocation() {
    if (!navigator.geolocation) return

    navigator.geolocation.getCurrentPosition(
      (position) => this.onGeolocationSuccess(position),
      () => this.onGeolocationError(),
      { 
        enableHighAccuracy: true, 
        timeout: 8000 
      }
    )
  }

  // Éxito en geolocalización
  onGeolocationSuccess(position) {
    const { latitude, longitude } = position.coords
    
    // Actualizar campos hidden de lat/lng
    const latInput = document.getElementById('duel_latitude')
    const lngInput = document.getElementById('duel_longitude')
    
    if (latInput && lngInput) {
      latInput.value = latitude
      lngInput.value = longitude
    }

    // Intentar reverse geocoding con Mapbox
    this.reverseGeocode(latitude, longitude)
  }

  // Error en geolocalización (fallback silencioso)
  onGeolocationError() {
    // No hacer nada, dejar inputs como están
  }

  // Reverse geocoding usando Mapbox API
  async reverseGeocode(lat, lng) {
    const token = this.mapboxToken()
    if (!token) return

    try {
      const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${token}&language=es&types=address,place,country`
      
      const response = await fetch(url)
      if (!response.ok) return
      
      const data = await response.json()
      if (data.features && data.features.length > 0) {
        this.parseReverseGeocodeResult(data.features, lat, lng)
      }
    } catch (error) {
      // Fallback silencioso si falla la API
    }
  }

  // Parsear resultado del reverse geocoding
  parseReverseGeocodeResult(features, lat, lng) {
    let country = ''
    let city = ''
    let address = ''

    // Buscar país
    const countryFeature = features.find(f => f.place_type.includes('country'))
    if (countryFeature) {
      country = countryFeature.text
    }

    // Buscar ciudad/place
    const placeFeature = features.find(f => f.place_type.includes('place'))
    if (placeFeature) {
      city = placeFeature.text
    }

    // Buscar dirección
    const addressFeature = features.find(f => f.place_type.includes('address'))
    if (addressFeature) {
      address = addressFeature.text
    }

    // Rellenar inputs solo si están vacíos
    this.fillLocationInputs(country, city, address, lat, lng)
  }

  // Rellenar campos de ubicación
  fillLocationInputs(country, city, address, lat, lng) {
    const countryInput = document.getElementById('duel_country')
    const cityInput = document.getElementById('duel_city')
    const addressInput = document.getElementById('duel_address')

    // Solo rellenar si están vacíos
    if (countryInput && !countryInput.value && country) {
      countryInput.value = country
    }
    
    if (cityInput && !cityInput.value && city) {
      cityInput.value = city
    }
    
    if (addressInput && !addressInput.value && address) {
      addressInput.value = address
    }

    // Llamar a onAddressCoordsChanged para centrar mapa y filtrar
    this.onAddressCoordsChanged()
  }

  // Utilidad para calcular distancia entre dos puntos usando fórmula de Haversine
  haversineKm(lat1, lng1, lat2, lng2) {
    const R = 6371 // Radio de la Tierra en kilómetros
    const dLat = this.toRadians(lat2 - lat1)
    const dLng = this.toRadians(lng2 - lng1)
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2)
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    return R * c
  }

  // Helper para convertir grados a radianes
  toRadians(degrees) {
    return degrees * (Math.PI / 180)
  }

  // Limpieza al desconectar el controller
  disconnect() {
    // Remover event listener global
    window.removeEventListener("leagend:location_changed", this.onLocationChanged)
    
    // Eliminar markers
    for (const m of this.arenaMarkers.values()) {
      m.remove()
    }
    this.arenaMarkers.clear()
  }

  // Actualizar lista de arenas cercanas basada en distancia
  updateNearbyList(radiusKm = 20, limit = 20) {
    if (!this.arenas || this.arenas.length === 0) {
      this.toggleNoArenasMessage(true)
      return
    }

    const latInput = document.getElementById('duel_latitude')
    const lngInput = document.getElementById('duel_longitude')
    
    // Si no hay coordenadas actuales, no filtrar por distancia
    if (!latInput?.value || !lngInput?.value) {
      // Mostrar top N por nombre como fallback
      this.arenas.slice(0, limit).forEach((arena, index) => {
        if (arena.el) {
          arena.el.style.display = ''
          arena.distance = null
          const distanceEl = arena.el.querySelector('[data-distance]')
          if (distanceEl) {
            distanceEl.textContent = '—'
          }
        }
      })
      return
    }

    const currentLat = parseFloat(latInput.value)
    const currentLng = parseFloat(lngInput.value)

    // Calcular distancia para cada arena
    this.arenas.forEach(arena => {
      arena.distance = this.haversineKm(currentLat, currentLng, arena.lat, arena.lng)
    })

    // Ordenar por distancia ascendente
    this.arenas.sort((a, b) => a.distance - b.distance)

    // Filtrar y mostrar arenas dentro del radio
    let visibleCount = 0
    this.arenas.forEach((arena, index) => {
      if (arena.el) {
        const isWithinRadius = arena.distance <= radiusKm
        const isWithinLimit = index < limit
        
        if (isWithinRadius && isWithinLimit) {
          arena.el.style.display = ''
          visibleCount++
          
          // Actualizar texto de distancia
          const distanceEl = arena.el.querySelector('[data-distance]')
          if (distanceEl) {
            distanceEl.textContent = `~ ${arena.distance.toFixed(1)} km`
          }
        } else {
          arena.el.style.display = 'none'
        }
      }
    })

    // Si ninguna arena está dentro del radio, mostrar las N más cercanas
    if (visibleCount === 0) {
      this.arenas.slice(0, limit).forEach((arena, index) => {
        if (arena.el) {
          arena.el.style.display = ''
          const distanceEl = arena.el.querySelector('[data-distance]')
          if (distanceEl) {
            distanceEl.textContent = `~ ${arena.distance.toFixed(1)} km`
          }
        }
      })
    }

    // Mostrar/ocultar mensaje de "no hay arenas"
    this.toggleNoArenasMessage(visibleCount === 0)
    
    // Si hay arenas visibles, ocultar el mensaje
    if (visibleCount > 0) {
      this.toggleNoArenasMessage(false)
    }
  }

  // Mostrar/ocultar mensaje de "no hay arenas"
  toggleNoArenasMessage(show) {
    const noArenasMessage = document.getElementById('no-arenas-message')
    if (noArenasMessage) {
      if (show) {
        noArenasMessage.classList.remove('d-none')
      } else {
        noArenasMessage.classList.add('d-none')
      }
    }
  }

  // Refrescar marcadores en el mapa basado en visibilidad
  refreshMarkers(map, visibles) {
    // eliminar markers que ya no están visibles
    for (const [id, m] of this.arenaMarkers.entries()) {
      if (!visibles.find(a => a.id === id)) {
        m.remove()
        this.arenaMarkers.delete(id)
      }
    }
    
    // crear/update markers visibles
    visibles.forEach(a => {
      if (!this.arenaMarkers.has(a.id) && Number.isFinite(a.lat) && Number.isFinite(a.lng)) {
        const marker = new mapboxgl.Marker().setLngLat([a.lng, a.lat]).addTo(map)
        marker.getElement().addEventListener('click', () => this.selectArenaById(a.id))
        this.arenaMarkers.set(a.id, marker)
      }
    })
    
    // ajustar bounds
    if (visibles.length > 0) {
      const bounds = new mapboxgl.LngLatBounds()
      visibles.forEach(a => bounds.extend([a.lng, a.lat]))
      if (Number.isFinite(this.currentLng) && Number.isFinite(this.currentLat)) {
        bounds.extend([this.currentLng, this.currentLat])
      }
      try {
        map.fitBounds(bounds, { padding: 50, maxZoom: 14, duration: 300 })
      } catch(e) {}
    }
  }

  // Utilidad debounce para evitar recálculos excesivos
  debounce(fn, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        fn(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  // Preparar formulario antes del submit para asegurar que los campos hidden estén habilitados
  prepareSubmit() {
    // Asegura que hidden fields existen y no están deshabilitados
    ['duel_country','duel_city','duel_address','duel_neighborhood','duel_latitude','duel_longitude']
      .forEach(id => {
        const el = document.getElementById(id);
        if (el) el.removeAttribute('disabled');
      });
  }
}
