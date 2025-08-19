import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // VERSION TAG: DUEL-STEP v2025-08-15T10:45Z - VERIFICAR QUE SE EJECUTA ESTE CÓDIGO
  static targets = ["step", "progress", "nextBtn", "prevBtn", "submitBtn", "arenaId", "mapContainer", "arenaList", "arenaGrid", "arenaSearch", "latitude", "longitude", "summaryMap"]
  static values = { 
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 4 }
  }

  // Helpers seguros para acceder a campos del formulario
  getInput(name) { 
    return document.querySelector(`[name="duel[${name}]"]`); 
  }
  
  getValue(name) { 
    const el = this.getInput(name); 
    return el ? el.value?.trim() : ""; 
  }

  // Localizador robusto de contenedores de paso (scope = this.element)
  getStepElement(n) {
    // 1) Preferir Stimulus targets en orden
    if (this.stepTargets && this.stepTargets[n - 1]) return this.stepTargets[n - 1];

    const scope = this.element;

    // 2) Probar variantes comunes dentro del scope del controller
    let el =
      scope.querySelector(`[data-duel-steps-target="step"][data-step="${n}"]`) ||
      scope.querySelector(`.duel-step[data-step="${n}"]`) ||
      scope.querySelector(`[data-step="${n}"]`);

    if (el) return el;

    // 3) Si no hay data-step en el DOM, asumir orden visual
    const candidates = scope.querySelectorAll('[data-duel-steps-target="step"], .duel-step, [data-step]');
    if (candidates && candidates.length >= n) return candidates[n - 1];

    // 4) Fallback: el visible/activo
    el = scope.querySelector('.step-active') || scope.querySelector('[data-step]:not(.d-none)');
    return el || null;
  }



  // Campos/estado internos
  arenas = []
  arenaMarkers = new Map()
  currentLat = null
  currentLng = null
  debouncedRecompute = null
  searchDebounceTimer = null
  
  // Estado de navegación corregido
  totalSteps = 3
  currentStep = null

  connect() {
    // VERSION TAG: DUEL-STEP v2025-08-15T10:45Z - VERIFICAR QUE SE EJECUTA ESTE CÓDIGO
    console.info("🚀 DUEL-STEP v2025-08-15T10:45Z - Controller conectado")
    console.info("📁 Archivo fuente:", import.meta.url)
    
    // Inicializar estado de navegación
    if (this.currentStep == null) this.currentStep = 1
    
    // Inicializar debouncedRecompute
    this.debouncedRecompute = this.debounce(this.recomputeAndRenderNearby.bind(this), 250)
    
    // BOOT LIMPIO: Configurar paso y progreso
    this.showStep(this.currentStep)
    this.updateProgress()
    this.updateButtons()
    
    // CONFIGURAR EVENT LISTENERS (sin ejecutar lógica de ubicación)
    this.setupEventListeners()
    
    // Configurar evento de submit del formulario
    const form = this.element.querySelector('form');
    if (form) {
      form.addEventListener('turbo:submit-start', () => this.prepareSubmit());
    }
    
    // BOOT DE UBICACIÓN: Resolver coordenadas iniciales UNA SOLA VEZ
    console.log('🔍 BOOT: Resolviendo coordenadas iniciales...')
    this.resolveInitialCoordinates()
    
    // BOOT DE GEOLOCALIZACIÓN ANTICIPADA: No bloqueante, en paralelo al flujo actual
    console.log('🚀 BOOT: Iniciando geolocalización anticipada...')
    this.attemptGeolocationAnticipated()
    
    // Verificar si hay arenas en el DOM y mostrar mensaje si no las hay
    if (this.hasArenaListTarget) {
      const arenaItems = this.arenaListTarget.querySelectorAll('.arena-item')
      if (arenaItems.length === 0) {
        this.toggleNoArenasMessage(true)
      }
    }
    
    console.log('✅ BOOT: Controller conectado y configurado')
  }

  // BOOT DE UBICACIÓN: Resolver coordenadas iniciales UNA SOLA VEZ
  // Orden de prioridad: hidden → cache → geoloc → reverse geocode
  resolveInitialCoordinates() {
    const startTime = new Date().toISOString()
    console.log(`⏰ [${startTime}] BOOT: resolveInitialCoordinates() - INICIO`)
    console.log('🔍 BOOT: Resolviendo coordenadas iniciales para cálculo de radio de 3km...')
    console.log('NOTA: Solo se usan coordenadas numéricas, NO centroides de país/ciudad/address')
    console.trace('📍 TRACE: resolveInitialCoordinates() llamado desde:')
    
    // PRIORIDAD 1: Valores en campos hidden si ya existen y son numéricos
    let latInput, lngInput
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      latInput = this.latitudeTarget
      lngInput = this.longitudeTarget
    } else {
      // Fallback: usar helpers seguros
      latInput = this.getInput('latitude')
      lngInput = this.getInput('longitude')
      console.debug('duel-steps: latitude/longitude targets not found, using fallback')
    }
    
    console.log('🔍 BOOT: Verificando campos hidden...')
    console.log('🔍 BOOT: duel_latitude =', latInput?.value)
    console.log('🔍 BOOT: duel_longitude =', lngInput?.value)

    if (latInput?.value && lngInput?.value) {
      const lat = parseFloat(latInput.value)
      const lng = parseFloat(lngInput.value)
      
      console.log('🔍 BOOT: Valores parseados:', lat, lng)
      
      if (Number.isFinite(lat) && Number.isFinite(lng)) {
        console.log(`✅ BOOT: Coordenadas encontradas en campos hidden: (${lat}, ${lng})`)
        this.currentLat = lat
        this.currentLng = lng
        
        // BOOT COMPLETO: Escribir en localStorage y disparar evento
        this.persistCoordinates(lat, lng)
        this.dispatchLocationChangedEvent(lat, lng, null, null, null, 'boot')
        
        const endTime = new Date().toISOString()
        console.log(`⏰ [${endTime}] BOOT: resolveInitialCoordinates() - FIN (coordenadas en hidden)`)
        return
      } else {
        console.warn('⚠️ BOOT: Coordenadas en campos hidden no son numéricas válidas:', latInput.value, lngInput.value)
      }
    }

    // PRIORIDAD 2: Ubicación cacheada en localStorage
    console.log('🔍 BOOT: Verificando localStorage...')
    try {
      const cachedLat = localStorage.getItem('leagend:lastLat')
      const cachedLng = localStorage.getItem('leagend:lastLng')
      
      console.log('🔍 BOOT: Cache localStorage:', cachedLat, cachedLng)
      
      if (cachedLat && cachedLng) {
        const lat = parseFloat(cachedLat)
        const lng = parseFloat(cachedLng)
        
        if (Number.isFinite(lat) && Number.isFinite(lng)) {
          console.log(`✅ BOOT: Coordenadas encontradas en localStorage: (${lat}, ${lng})`)
          this.currentLat = lat
          this.currentLng = lng
          
          // BOOT COMPLETO: Escribir en hidden y disparar evento
          this.writeHiddenCoordinates(lat, lng)
          this.persistCoordinates(lat, lng)
          this.dispatchLocationChangedEvent(lat, lng, null, null, null, 'boot')
          
          const endTime = new Date().toISOString()
          console.log(`⏰ [${endTime}] BOOT: resolveInitialCoordinates() - FIN (coordenadas cacheadas)`)
          return
        } else {
          console.warn('⚠️ BOOT: Coordenadas en localStorage no son numéricas válidas:', cachedLat, cachedLng)
        }
      }
    } catch (e) {
      console.warn('⚠️ BOOT: Error al leer coordenadas del localStorage:', e)
    }

    // PRIORIDAD 3: Geolocalización del navegador (asíncrona)
    console.log('🔄 BOOT: No hay coordenadas válidas, intentando geolocalización...')
    this.attemptGeolocation()
    
    const endTime = new Date().toISOString()
    console.log(`⏰ [${endTime}] BOOT: resolveInitialCoordinates() - FIN (geolocalización)`)
  }

  setupEventListeners() {
    console.log('🔧 setupEventListeners() - Configurando event listeners')
    console.trace('📍 TRACE: setupEventListeners() llamado desde:')
    
    // CONFIGURACIÓN DE VALIDACIÓN EN TIEMPO REAL DEL PASO 1:
    // Se configuran listeners para habilitar/deshabilitar el botón "Siguiente"
    // cuando cambien los campos: country, city, address, latitude, longitude
    
    // Escuchar cambios en campos para actualizar resumen
    this.element.addEventListener('change', (e) => {
      if (e.target.matches('input, select')) {
        this.updateSummary()
      }
    })

    // Escuchar cambios en campos de fecha y hora para validación en tiempo real
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('#duel_starts_at, #duel_duration, #duel_duel_type')) {
        this.updateSummary()
        this.validateFieldInRealTime(e.target)
      }
    })

    // Escuchar cambios en campos de ubicación (solo para UI, NO para cálculo de distancia)
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('[name="duel[country]"], [name="duel[city]"], [name="duel[address]"]')) {
        this.updateSummary()
        // NOTA: Los cambios en country/city/address NO afectan el cálculo de radio de 3km
        // El radio se calcula EXCLUSIVAMENTE desde currentLat/currentLng
        console.log('ℹ️ Campo de ubicación cambiado (solo UI, no afecta radio de 3km)')
        
        // Validar Paso 1 en tiempo real para habilitar/deshabilitar botón Siguiente
        // cuando cambien los campos country, city o address
        if (this.currentStep === 1) {
          this.updateButtons()
        }
      }
    })

    // Escuchar cambios en campos de coordenadas para recalcular distancias
    // IMPORTANTE: Solo las coordenadas numéricas afectan el cálculo de radio
    this.element.addEventListener('change', (e) => {
      if (e.target.matches('[name="duel[latitude]"], [name="duel[longitude]"]')) {
        console.log('🔄 Campo de coordenadas cambiado, recalculando distancias')
        this.updateArenaDistances()
        
        // Validar Paso 1 en tiempo real para habilitar/deshabilitar botón Siguiente
        // cuando cambien los campos latitude o longitude (evento change)
        if (this.currentStep === 1) {
          this.updateButtons()
        }
      }
    })
    
    // Escuchar cambios en campos de coordenadas también en input para validación en tiempo real
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('[name="duel[latitude]"], [name="duel[longitude]"]')) {
        // Validar Paso 1 en tiempo real para habilitar/deshabilitar botón Siguiente
        // cuando cambien los campos latitude o longitude (evento input)
        if (this.currentStep === 1) {
          this.updateButtons()
        }
      }
    })

    // Escuchar cambios en campos del Paso 2 para validación en tiempo real
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('input, select, textarea')) {
        // Validar Paso 2 en tiempo real si estamos en ese paso
        if (this.currentStep === 2) {
          this.updateButtons()
        }
      }
    })

    // Escuchar cambios en campos del Paso 2 también en change
    this.element.addEventListener('change', (e) => {
      if (e.target.matches('input, select, textarea')) {
        // Validar Paso 2 en tiempo real si estamos en ese paso
        if (this.currentStep === 2) {
          this.updateButtons()
        }
      }
    })

    // Suscribirse a cambios de ubicación desde arena_location_controller
    // Este evento proporciona coordenadas numéricas válidas para el cálculo de radio
    window.addEventListener("leagend:location_changed", this.onLocationChanged.bind(this))
    
    // Escuchar leagend:location_changed para revalidar Paso 1
    window.addEventListener("leagend:location_changed", () => {
      if (this.currentStep === 1) {
        this.updateButtons()
      }
    })
    
    // Suscribirse a eventos de arena creada desde el modal
    window.addEventListener("leagend:arena_created", this.onArenaCreated.bind(this))
    
    // Suscribirse a eventos de cambio de fecha/hora para validación del Paso 2
    window.addEventListener("leagend:datetime_selected", () => {
      if (this.currentStep === 2) {
        console.log('🔧 Evento leagend:datetime_selected recibido en connect() - revalidando Paso 2')
        this.updateButtons()
      }
    })
    
    // Cargar arenas desde el DOM
    this.buildArenasFromDOM()
    
    // Si hay lat/lng en hidden, disparar evento de ubicación
    // NOTA: Solo se usan coordenadas numéricas, NO centroides de país/ciudad/address
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      const lat = parseFloat(this.latitudeTarget.value)
      const lng = parseFloat(this.longitudeTarget.value)
      if (lat && lng) {
        console.log('🔄 Coordenadas iniciales encontradas, disparando evento de ubicación')
        this.onLocationChanged({ detail: { lat, lng, source: 'setup' } })
      }
    } else {
      // Fallback: usar helpers seguros si no hay targets
      const lat = parseFloat(this.getValue('latitude'))
      const lng = parseFloat(this.getValue('longitude'))
      if (lat && lng) {
        console.debug('duel-steps: latitude/longitude targets not found, using fallback')
        console.log('🔄 Coordenadas iniciales encontradas (fallback), disparando evento de ubicación')
        this.onLocationChanged({ detail: { lat, lng, source: 'setup_fallback' } })
      }
    }
    
    console.log('✅ Event listeners configurados correctamente')
  }

  // Navegar al siguiente paso
  next() {
    console.log(`🔄 next() - Intentando avanzar desde paso ${this.currentStep}`)
    
    // Validar paso actual antes de avanzar
    if (this.currentStep === 1 && !this.validStep1()) {
      console.log('❌ next(): Paso 1 no válido, no se puede avanzar')
      return
    }
    
    if (this.currentStep === 2 && !this.validStep2()) {
      console.log('❌ next(): Paso 2 no válido, no se puede avanzar')
      return
    }
    
    // Si pasa validación, avanzar
    if (this.currentStep < this.totalSteps) {
      this.currentStep++
      console.log(`✅ next(): Avanzando al paso ${this.currentStep}`)
      
      this.showStep(this.currentStep)
      this.updateProgress()
      this.updateButtons()
      this.updateSummary()
      this.scrollToTop()
    } else {
      console.log('ℹ️ next(): Ya estamos en el último paso')
    }
  }

  // Navegar al paso anterior
  previous() {
    console.log(`🔄 previous() - Intentando retroceder desde paso ${this.currentStep}`)
    
    if (this.currentStep > 1) {
      this.currentStep--
      console.log(`✅ previous(): Retrocediendo al paso ${this.currentStep}`)
      
      this.showStep(this.currentStep)
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()
    } else {
      console.log('ℹ️ previous(): Ya estamos en el primer paso')
    }
  }

  // Ir a un paso específico
  goToStep(event) {
    const step = parseInt(event.currentTarget.dataset.step)
    console.log(`🔄 goToStep(${step}) - Intentando ir al paso ${step}`)
    
    if (step >= 1 && step <= this.totalSteps) {
      this.currentStep = step
      console.log(`✅ goToStep(): Cambiando al paso ${this.currentStep}`)
      
      this.showStep(this.currentStep)
      this.updateProgress()
      this.updateButtons()
      this.scrollToTop()
    } else {
      console.warn(`⚠️ goToStep(): Paso ${step} fuera de rango [1..${this.totalSteps}]`)
    }
  }

  // Mostrar paso específico con validación de rango
  showStep(n) {
    // Asegurar que n esté en el rango válido [1..3]
    if (n < 1 || n > this.totalSteps) {
      console.warn(`⚠️ showStep: paso ${n} fuera de rango [1..${this.totalSteps}]`)
      return
    }
    
    console.log(`🔄 showStep(${n}) - Mostrando paso ${n}`)
    
    // Ocultar todos los contenedores de pasos
    this.stepTargets.forEach((step, index) => {
      const stepNumber = index + 1
      if (stepNumber === n) {
        step.classList.remove('d-none')
        step.classList.add('step-active')
      } else {
        step.classList.add('d-none')
        step.classList.remove('step-active')
      }
    })
    
    // Actualizar barra de progreso sin cambiar su HTML (si existe)
    if (this.hasProgressTarget) {
      const percentage = (n / this.totalSteps) * 100
      this.progressTarget.style.width = `${percentage}%`
    }
    
    // Actualizar dots de progreso si existen
    const dots = this.element.querySelectorAll("[data-step-dot]")
    dots.forEach(dot => {
      const stepNumber = parseInt(dot.dataset.stepDot)
      if (stepNumber <= n) {
        dot.classList.add('wizard-dot--active')
      } else {
        dot.classList.remove('wizard-dot--active')
      }
    })

    // Si llegamos al Step 3, disparar callback si existe
    if (n === 3) {
      // Llamar a onEnterStep3() después de hacer visible el contenedor
      setTimeout(() => {
        this.onEnterStep3()
      }, 100)
    }

    // Si estamos en Step 2, configurar validación en tiempo real
    if (n === 2) {
      setTimeout(() => {
        this.setupStep2Validation()
      }, 100)
    }

    // Si estamos en Step 1, forzar resize del mapa que maneja arena_location_controller
    if (n === 1) {
      setTimeout(() => {
        if (window.leagendMap && typeof window.leagendMap.resize === 'function') {
          window.leagendMap.resize()
        }
      }, 100)
    }
    
    console.log(`✅ showStep(${n}) - Paso ${n} mostrado correctamente`)
  }

  // Validador puro para el Paso 1
  validStep1() {
    const fields = ['country', 'city', 'address', 'latitude', 'longitude']
    return fields.every(k => this.getValue(k) !== "")
  }

  // Validador puro para el Paso 2
  validStep2() {
    // Buscar el contenedor del paso 2 dentro del scope del controller
    const step2 = this.getStepElement(2);
    if (!step2) {
      console.warn('⚠️ validStep2: contenedor del paso 2 no encontrado (revisar targets/markup)');
      // Fallback ultra defensivo: intentar validar por ID/global si existen
      const starts = document.getElementById('duel_starts_at') || this.element.querySelector('[name="duel[starts_at]"]');
      if (!starts) return false;
      return !!(starts.value && (starts.checkValidity ? starts.checkValidity() : true));
    }

    // Campos explícitos del paso (no inspeccionar [required] genéricos)
    const starts = step2.querySelector('#duel_starts_at') || step2.querySelector('[name="duel[starts_at]"]') ||
                   this.element.querySelector('#duel_starts_at') || this.element.querySelector('[name="duel[starts_at]"]');

    const dur    = step2.querySelector('#duel_duration') || step2.querySelector('[name="duel[duration_minutes]"], [name="duel[duration]"]');
    const type   = step2.querySelector('#duel_duel_type') || step2.querySelector('[name="duel[duel_type]"], [name="duel[type]"]');

    // starts_at es el único obligatorio
    const okStarts = !!(starts && starts.value && (starts.checkValidity ? starts.checkValidity() : true));

    // Si existen, deben tener valor; si no, no bloquean
    const okDur  = dur  ? (dur.value?.trim() !== '')  : true;
    const okType = type ? (type.value?.trim() !== '') : true;

    const result = !!(okStarts && okDur && okType);
    console.debug('✅ validStep2:', { okStarts, okDur, okType, result, startsValue: starts?.value });
    return result;
  }

  // Configurar validación en tiempo real para el Paso 2
  setupStep2Validation() {
    console.log('🔧 setupStep2Validation() - Configurando validación en tiempo real para Paso 2');

    const step2 = this.getStepElement(2);
    if (!step2) {
      console.warn('⚠️ setupStep2Validation: contenedor del paso 2 no encontrado (revisar targets/markup)');
      return;
    }

    // Localizar el botón "Siguiente"
    let nextButton = null;

    // 1) Si hay target de Stimulus, úsalo
    if (this.hasNextBtnTarget) nextButton = this.nextBtnTarget;

    // 2) Si no, buscar dentro del contenedor del paso 2 por convenciones
    if (!nextButton) {
      nextButton = step2.querySelector('.btn-next, [data-action*="next"]');
    }

    // 3) Si aún no, buscar por texto de forma segura (no usar :contains)
    if (!nextButton) {
      const buttons = (this.element.querySelectorAll('button') || []);
      nextButton = Array.from(buttons).find(btn => {
        const t = (btn.textContent || '').toLowerCase();
        return t.includes('siguiente') || t.includes('next');
      }) || null;
    }

    if (!nextButton) {
      console.warn('⚠️ setupStep2Validation: botón "Siguiente" no encontrado');
      return;
    }

    console.log('✅ Botón "Siguiente" del Paso 2 localizado:', nextButton);

    // Función central de actualización
    const updateNextButtonState = () => {
      const isValid = this.validStep2();
      nextButton.disabled = !isValid;
      nextButton.classList.toggle('btn-primary', isValid);
      nextButton.classList.toggle('btn-secondary', !isValid);
    };

    // Escucha directa al starts_at
    const startsAtEl =
      step2.querySelector('#duel_starts_at') ||
      step2.querySelector('[name="duel[starts_at]"]') ||
      this.element.querySelector('#duel_starts_at') ||
      this.element.querySelector('[name="duel[starts_at]"]');

    ['input', 'change', 'blur'].forEach(evt => startsAtEl?.addEventListener(evt, updateNextButtonState));

    // Si un widget externo setea la fecha/hora
    document.addEventListener('leagend:datetime_selected', updateNextButtonState);

    // Listener genérico a todos los campos del paso 2
    const formFields = step2.querySelectorAll('input, select, textarea');
    formFields.forEach(field => {
      field.addEventListener('input', updateNextButtonState);
      field.addEventListener('change', updateNextButtonState);
    });

    // Evaluación inicial
    updateNextButtonState();

    console.log('✅ Validación en tiempo real del Paso 2 configurada correctamente');
  }
  
  // Forzar revalidación del Paso 2 (útil para widgets externos)
  forceStep2Validation() {
    if (this.currentStep === 2) {
      console.log('🔧 forceStep2Validation() - Forzando revalidación del Paso 2')
      this.updateButtons()
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
      const percentage = (this.currentStep / this.totalSteps) * 100
      this.progressTarget.style.width = `${percentage}%`
    }
  }

  // Actualizar estado de botones
  updateButtons() {
    // Botón anterior
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentStep === 1
      this.prevBtnTarget.classList.toggle('btn-secondary', this.currentStep === 1)
      this.prevBtnTarget.classList.toggle('btn-outline-secondary', this.currentStep > 1)
    }

    // Botón siguiente
    if (this.hasNextBtnTarget) {
      const isLastStep = this.currentStep === this.totalSteps
      this.nextBtnTarget.classList.toggle('d-none', isLastStep)
      
      // Deshabilitar botón si no se puede avanzar
      if (!isLastStep) {
        // Para el Paso 1, usar validación específica en tiempo real
        if (this.currentStep === 1) {
          const hasRequiredData = this.validStep1()
          this.nextBtnTarget.disabled = !hasRequiredData
          this.nextBtnTarget.classList.toggle('btn-primary', hasRequiredData)
          this.nextBtnTarget.classList.toggle('btn-secondary', !hasRequiredData)
        } else if (this.currentStep === 2) {
          // Para el Paso 2, usar validación específica
          const hasRequiredData = this.validStep2()
          this.nextBtnTarget.disabled = !hasRequiredData
          this.nextBtnTarget.classList.toggle('btn-primary', hasRequiredData)
          this.nextBtnTarget.classList.toggle('btn-secondary', !hasRequiredData)
          
          // Si el botón está deshabilitado, asegurar que se actualice la UI
          if (!hasRequiredData) {
            this.nextBtnTarget.classList.add('btn-secondary')
            this.nextBtnTarget.classList.remove('btn-primary')
          }
        } else {
          // Para otros pasos, usar la validación general
          this.nextBtnTarget.disabled = !this.canProceedToNext()
          this.nextBtnTarget.classList.toggle('btn-primary', this.nextBtnTarget.disabled === false)
          this.nextBtnTarget.classList.toggle('btn-secondary', this.nextBtnTarget.disabled === true)
        }
      }
    }

    // Botón submit
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.classList.toggle('d-none', this.currentStep !== this.totalSteps)
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
    const country = this.getValue('country') || '-'
    const city = this.getValue('city') || '-'
    const address = this.getValue('address') || '-'
    const neighborhood = this.getValue('neighborhood') || '-'

    document.getElementById('summary-country').textContent = country
    document.getElementById('summary-city').textContent = city
    document.getElementById('summary-address').textContent = address
    document.getElementById('summary-neighborhood').textContent = neighborhood
    
    // Validar campos de ubicación en tiempo real
    const countryField = this.getInput('country')
    const cityField = this.getInput('city')
    const addressField = this.getInput('address')
    
    if (countryField) this.validateFieldInRealTime(countryField)
    if (cityField) this.validateFieldInRealTime(cityField)
    if (addressField) this.validateFieldInRealTime(addressField)
    
    // Validar campos de coordenadas en tiempo real
    if (this.hasLatitudeTarget) this.validateFieldInRealTime(this.latitudeTarget)
    if (this.hasLongitudeTarget) this.validateFieldInRealTime(this.longitudeTarget)
    
    // Validar que las coordenadas estén presentes
    const lat = this.hasLatitudeTarget ? this.latitudeTarget.value : this.getValue('latitude')
    const lng = this.hasLongitudeTarget ? this.longitudeTarget.value : this.getValue('longitude')
    
    if (!lat || !lng) {
      console.log('⚠️ No hay coordenadas válidas para validar')
    } else {
      console.log(`✅ Coordenadas válidas: (${lat}, ${lng})`)
    }
    
    // Validar que las coordenadas sean numéricas
    if (lat && lng) {
      const latNum = parseFloat(lat)
      const lngNum = parseFloat(lng)
      
      if (Number.isFinite(latNum) && Number.isFinite(lngNum)) {
        console.log(`✅ Coordenadas numéricas válidas: (${latNum}, ${lngNum})`)
        
        // Actualizar coordenadas actuales del controller
        this.currentLat = latNum
        this.currentLng = lngNum
        
        // Recalcular distancias de arenas si es necesario
        if (this.arenas.length > 0) {
          this.updateArenaDistances()
        }
        
        // Actualizar mapa en miniatura si estamos en el paso 3
        if (this.currentStep === 3 && this.hasSummaryMapTarget) {
          this.initSummaryMap()
        }
        
        // Emitir evento de cambio de ubicación
        this.dispatchLocationChangedEvent(latNum, lngNum, null, null, null, 'summary_update')
      } else {
        console.warn('⚠️ Coordenadas no son numéricas válidas')
      }
    }
    
    // Validar que las coordenadas estén en rango válido
    if (lat && lng) {
      const latNum = parseFloat(lat)
      const lngNum = parseFloat(lng)
      
      if (latNum < -90 || latNum > 90) {
        console.warn('⚠️ Latitud fuera de rango válido (-90 a 90)')
      }
      
      if (lngNum < -180 || lngNum > 180) {
        console.warn('⚠️ Longitud fuera de rango válido (-180 a 180)')
      }
    }
    
    // Validar que las coordenadas estén en Colombia (opcional)
    if (lat && lng) {
      const latNum = parseFloat(lat)
      const lngNum = parseFloat(lng)
      
      // Colombia está aproximadamente entre lat: -4.2 a 13.5, lng: -81.7 a -66.9
      if (latNum >= -4.2 && latNum <= 13.5 && lngNum >= -81.7 && lngNum <= -66.9) {
        console.log('✅ Coordenadas dentro de Colombia')
      } else {
        console.log('ℹ️ Coordenadas fuera de Colombia')
      }
    }
    
    // Validar que las coordenadas no estén en el océano (aproximado)
    if (lat && lng) {
      const latNum = parseFloat(lat)
      const lngNum = parseFloat(lng)
      
      // Coordenadas aproximadas de tierra en Colombia
      const isLand = (latNum >= -4.2 && latNum <= 13.5 && lngNum >= -81.7 && lngNum <= -66.9) ||
                     (latNum >= 8.0 && latNum <= 12.0 && lngNum >= -78.0 && lngNum <= -71.0) ||
                     (latNum >= -2.0 && latNum <= 2.0 && lngNum >= -80.0 && lngNum <= -75.0)
      
      if (isLand) {
        console.log('✅ Coordenadas en tierra firme')
      } else {
        console.log('ℹ️ Coordenadas posiblemente en el océano')
      }
    }
    
    // Validar que las coordenadas no estén en el mismo lugar
    if (lat && lng) {
      const latNum = parseFloat(lat)
      const lngNum = parseFloat(lng)
      
      if (this.currentLat === latNum && this.currentLng === lngNum) {
        console.log('ℹ️ Coordenadas no han cambiado')
      } else {
        console.log('🔄 Coordenadas han cambiado')
      }
    }

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
      
      // Validar campo de fecha en tiempo real
      const startsAtField = document.getElementById('duel_starts_at')
      if (startsAtField) this.validateFieldInRealTime(startsAtField)
    } else {
      document.getElementById('summary-date').textContent = 'No seleccionada'
      document.getElementById('summary-time').textContent = 'No seleccionada'
    }

    // Duración
    const duration = document.getElementById('duel_duration')?.value
    if (duration) {
      let durationText
      if (duration === '1.5') {
        durationText = '90 minutos'
      } else if (duration === '2.5') {
        durationText = '2.5 horas'
      } else if (duration === '3.5') {
        durationText = '3.5 horas'
      } else {
        durationText = duration === '1' ? '1 hora' : `${duration} horas`
      }
      document.getElementById('summary-duration').textContent = durationText
      
      // Validar campo de duración en tiempo real
      const durationField = document.getElementById('duel_duration')
      if (durationField) this.validateFieldInRealTime(durationField)
    } else {
      document.getElementById('summary-duration').textContent = '90 minutos (por defecto)'
    }

    // Tipo de duelo
    const duelType = document.getElementById('duel_duel_type')?.value
    if (duelType) {
      const typeText = duelType.charAt(0).toUpperCase() + duelType.slice(1)
      document.getElementById('summary-duel-type').textContent = typeText
      
      // Validar campo de tipo de duelo en tiempo real
      const duelTypeField = document.getElementById('duel_duel_type')
      if (duelTypeField) this.validateFieldInRealTime(duelTypeField)
    } else {
      document.getElementById('summary-duel-type').textContent = 'Amistoso (1 hora)'
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
    
    // Validar campo de arena en tiempo real
    if (this.hasArenaIdTarget) {
      const arenaField = this.arenaIdTarget
      if (arenaField) this.validateFieldInRealTime(arenaField)
    }

    // Árbitro
    const assignReferee = document.getElementById('assign_referee')?.checked
    if (assignReferee) {
      document.getElementById('summary-referee').textContent = 'Asignación automática solicitada'
    } else {
      document.getElementById('summary-referee').textContent = 'Sin árbitro asignado'
    }
    
    // Validar campo de árbitro en tiempo real
    const assignRefereeField = document.getElementById('assign_referee')
    if (assignRefereeField) this.validateFieldInRealTime(assignRefereeField)
    
    // Actualizar estado del botón siguiente
    this.updateButtons()
  }

  // Validar si se puede avanzar al siguiente paso
  canProceedToNext() {
    const currentStepElement = this.stepTargets[this.currentStep - 1]
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
    if (this.currentStep === 1) {
      isValid = this.validateLocationStep()
    } else if (this.currentStep === 2) {
      isValid = this.validateDateTimeStep()
    }

    return isValid
  }

  // Función pura para verificar si el Paso 1 tiene todos los datos requeridos
  // NOTA: El botón "Siguiente" del Paso 1 se encuentra en app/views/duels/new.html.erb línea 392
  hasStep1RequiredData() {
    // Usar helpers seguros para acceder a los campos
    const countryField = this.getInput('country')
    const cityField = this.getInput('city')
    const addressField = this.getInput('address')
    const latitudeField = this.getInput('latitude')
    const longitudeField = this.getInput('longitude')
    
    // Protección: si algún selector no existe, registrar debug y salir
    if (!countryField) {
      console.debug('⚠️ Campo country no encontrado en hasStep1RequiredData()')
      return false
    }
    if (!cityField) {
      console.debug('⚠️ Campo city no encontrado en hasStep1RequiredData()')
      return false
    }
    if (!addressField) {
      console.debug('⚠️ Campo address no encontrado en hasStep1RequiredData()')
      return false
    }
    if (!latitudeField) {
      console.debug('⚠️ Campo latitude no encontrado en hasStep1RequiredData()')
      return false
    }
    if (!longitudeField) {
      console.debug('⚠️ Campo longitude no encontrado en hasStep1RequiredData()')
      return false
    }
    
    // Verificar que todos los campos tengan valores no vacíos
    const hasCountry = countryField.value.trim() !== ''
    const hasCity = cityField.value.trim() !== ''
    const hasAddress = addressField.value.trim() !== ''
    const hasLatitude = latitudeField.value.trim() !== ''
    const hasLongitude = longitudeField.value.trim() !== ''
    
    const allFieldsFilled = hasCountry && hasCity && hasAddress && hasLatitude && hasLongitude
    
    console.debug(`🔍 Paso 1 - Validación: country=${hasCountry}, city=${hasCity}, address=${hasAddress}, lat=${hasLatitude}, lng=${hasLongitude} => ${allFieldsFilled}`)
    
    return allFieldsFilled
  }

  // Validar paso de ubicación
  validateLocationStep() {
    // Usar la nueva función de validación
    return this.hasStep1RequiredData()
  }

  // Validar paso de fecha y hora
  validateDateTimeStep() {
    const startsAt = document.getElementById('duel_starts_at')
    const duration = document.getElementById('duel_duration')
    const duelType = document.getElementById('duel_duel_type')

    if (!startsAt?.value || !duration?.value || !duelType?.value) {
      this.showValidationError('Por favor completa la fecha, hora, duración y tipo de duelo')
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
    
    const currentStep = this.stepTargets[this.currentStep - 1]
    currentStep.appendChild(errorDiv)

    // Auto-remover después de 5 segundos
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  // Validar campo en tiempo real
  validateFieldInRealTime(field) {
    // Remover clases de validación previas
    field.classList.remove('is-valid', 'is-invalid')
    
    // Validar el campo
    if (field.checkValidity()) {
      field.classList.add('is-valid')
    } else {
      field.classList.add('is-invalid')
    }
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
    this.currentStep = 1
    this.showStep(this.currentStep)
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

  // Inicializar Mapbox
  initMapbox() {
    console.log(`⏰ [${new Date().toISOString()}] initMapbox() - INICIO`)
    
    // Verificar que tenemos el token de Mapbox
    const token = this.getMapboxToken()
    if (!token) {
      console.error('❌ Token de Mapbox no encontrado')
      return
    }

    // Configurar token
    mapboxgl.accessToken = token

    // Crear mapa
    this.map = new mapboxgl.Map({
      container: this.mapContainerTarget,
      style: 'mapbox://styles/mapbox/streets-v11',
      center: [-74.006, 4.710], // Bogotá por defecto
      zoom: 10
    })

    // Obtener coordenadas iniciales del formulario
    let initialLat = 4.710
    let initialLng = -74.006
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      const lat = parseFloat(this.latitudeTarget.value)
      const lng = parseFloat(this.longitudeTarget.value)
      if (Number.isFinite(lat) && Number.isFinite(lng)) {
        initialLat = lat
        initialLng = lng
        console.log(`📍 Coordenadas iniciales del formulario (targets): (${initialLat}, ${initialLng})`)
      }
    } else {
      // Fallback: usar helpers seguros
      const lat = parseFloat(this.getValue('latitude'))
      const lng = parseFloat(this.getValue('longitude'))
      if (Number.isFinite(lat) && Number.isFinite(lng)) {
        initialLat = lat
        initialLng = lng
        console.debug('duel-steps: latitude/longitude targets not found, using fallback')
        console.log(`📍 Coordenadas iniciales del formulario (fallback): (${initialLat}, ${initialLng})`)
      }
    }

    // Crear marcador de ubicación
    this.locationMarker = new mapboxgl.Marker({ color: '#007bff' })
      .setLngLat([initialLng, initialLat])
      .addTo(this.map)

    // Cargar arenas y dibujar marcadores
    this.loadArenasFromDOM()
    this.drawArenaMarkers()
    
    // DEPRECATED: updateNearbyList() - reemplazado por recomputeAndRender() con radio de 3km
    // this.updateNearbyList()
    
    // Usar el nuevo motor de filtrado por radio de 3km
    if (Number.isFinite(this.currentLat) && Number.isFinite(this.currentLng)) {
      console.log('initMapbox: Coordenadas válidas, aplicando filtro de radio de 3km')
      this.recomputeAndRender()
    } else {
      console.log('initMapbox: Sin coordenadas válidas, esperando resolución...')
    }
    
    // Si no hay arenas, mostrar mensaje
    if (!this.arenas || this.arenas.length === 0) {
      this.toggleNoArenasMessage(true)
    }
    
    console.log(`⏰ [${new Date().toISOString()}] initMapbox() - FIN`)
  }

  // Crear mapa Mapbox
  createMap() {
    const token = this.mapboxToken()
    if (!token || typeof mapboxgl === 'undefined' || !this.hasMapContainerTarget) return

    // Obtener coordenadas iniciales (de campos hidden o por defecto)
    let initialLat = 0
    let initialLng = 0
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      initialLat = this.latitudeTarget.value ? parseFloat(this.latitudeTarget.value) : 0
      initialLng = this.longitudeTarget.value ? parseFloat(this.longitudeTarget.value) : 0
    } else {
      // Fallback: usar helpers seguros
      initialLat = this.getValue('latitude') ? parseFloat(this.getValue('latitude')) : 0
      initialLng = this.getValue('longitude') ? parseFloat(this.getValue('longitude')) : 0
      console.debug('duel-steps: latitude/longitude targets not found, using fallback')
    }

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
    
    // DEPRECATED: updateNearbyList() - reemplazado por recomputeAndRender() con radio de 3km
    // this.updateNearbyList()
    
    // Usar el nuevo motor de filtrado por radio de 3km
    if (Number.isFinite(this.currentLat) && Number.isFinite(this.currentLng)) {
      console.log('initMapbox: Coordenadas válidas, aplicando filtro de radio de 3km')
      this.recomputeAndRender()
    } else {
      console.log('initMapbox: Sin coordenadas válidas, esperando resolución...')
    }
    
    // Si no hay arenas, mostrar mensaje
    if (!this.arenas || this.arenas.length === 0) {
      this.toggleNoArenasMessage(true)
    }
  }

  // Cargar arenas desde el DOM
  loadArenasFromDOM() {
    console.log('📥 loadArenasFromDOM() - Cargando arenas desde el DOM')
    console.trace('📍 TRACE: loadArenasFromDOM() llamado desde:')
    
    if (!this.hasArenaGridTarget) {
      console.warn('⚠️ No hay arenaGridTarget, no se pueden cargar arenas')
      return
    }

    this.arenas = []
    const arenaCards = this.arenaGridTarget.querySelectorAll('.arena-card')
    
    console.log(`🔍 Encontradas ${arenaCards.length} tarjetas de arena en el DOM`)
    
    arenaCards.forEach((card, index) => {
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
      
      // Verificar que las coordenadas son válidas
      if (Number.isFinite(arena.lat) && Number.isFinite(arena.lng)) {
        console.log(`✅ Arena ${index + 1}: ${arena.name} en (${arena.lat}, ${arena.lng})`)
      } else {
        console.warn(`⚠️ Arena ${index + 1}: ${arena.name} - coordenadas inválidas (${arena.lat}, ${arena.lng})`)
      }
      
      this.arenas.push(arena)
    })
    
    console.log(`✅ ${this.arenas.length} arenas cargadas desde el DOM`)
  }

  // Construir catálogo de arenas desde el DOM (alias para compatibilidad)
  buildArenasFromDOM() {
    console.log('🏗️ buildArenasFromDOM() - Construyendo catálogo de arenas')
    console.trace('📍 TRACE: buildArenasFromDOM() llamado desde:')
    
    this.loadArenasFromDOM()
    
    console.log(`✅ Catálogo construido: ${this.arenas.length} arenas encontradas`)
  }

  // Dibujar marcadores de arenas en el mapa
  drawArenaMarkers() {
    console.log('🎯 drawArenaMarkers() - Dibujando marcadores de arenas')
    console.trace('📍 TRACE: drawArenaMarkers() llamado desde:')
    
    if (!this.map || !this.arenas) {
      console.warn('⚠️ drawArenaMarkers: mapa o arenas no disponibles')
      return
    }

    console.log(`�� Creando marcadores para ${this.arenas.length} arenas`)

    this.arenas.forEach((arena, index) => {
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
      
      console.log(`✅ Marcador ${index + 1} creado para ${arena.name}`)
    })
    
    console.log(`✅ ${this.arenas.length} marcadores de arena creados`)
  }

  // Resaltar arena seleccionada
  highlightArena(arena) {
    console.log(`✨ highlightArena() - Resaltando arena ${arena?.name || 'desconocida'}`)
    console.trace('📍 TRACE: highlightArena() llamado desde:')
    
    if (!arena || !this.map) {
      console.warn('⚠️ highlightArena: arena o mapa no disponibles')
      return
    }

    // Remover clase active de todas las arenas
    this.arenas.forEach(a => {
      if (a.el) {
        a.el.classList.remove('arena-card--selected')
      }
    })

    // Agregar clase active a la arena seleccionada
    if (arena.el) {
      arena.el.classList.add('arena-card--selected')
      console.log(`✅ Arena ${arena.name} resaltada`)
    }

    // Centrar mapa en la arena
    this.map.flyTo({
      center: [arena.lng, arena.lat],
      zoom: 15,
      duration: 1000
    })
    
    console.log(`🗺️ Mapa centrado en arena ${arena.name}`)
  }

  // Llamado cuando cambian las coordenadas de la dirección
  onAddressCoordsChanged() {
    let lat, lng
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      lat = parseFloat(this.latitudeTarget.value)
      lng = parseFloat(this.longitudeTarget.value)
    } else {
      // Fallback: usar helpers seguros
      lat = parseFloat(this.getValue('latitude'))
      lng = parseFloat(this.getValue('longitude'))
      console.debug('duel-steps: latitude/longitude targets not found, using fallback')
    }
    
    if (lat && lng) {

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

  // ÚLTIMA PALABRA: Manejar cambios de ubicación y ejecutar filtro de radio
  // SOLO usa coordenadas numéricas válidas para el cálculo de radio de 3km
  onLocationChanged(e) {
    const startTime = new Date().toISOString()
    console.log(`⏰ [${startTime}] onLocationChanged() - INICIO`)
    console.trace('📍 TRACE: onLocationChanged() llamado desde:')
    
    if (!e?.detail) {
      console.warn('⚠️ Evento leagend:location_changed sin detail')
      return
    }
    
    const newLat = parseFloat(e.detail.lat)
    const newLng = parseFloat(e.detail.lng)
    const source = e.detail.source || 'unknown'
    
    console.log(`🔍 Evento de fuente: ${source}`)
    
    // VERIFICAR que las coordenadas son numéricas válidas
    if (!Number.isFinite(newLat) || !Number.isFinite(newLng)) {
      console.warn('❌ Coordenadas recibidas no son numéricas válidas:', e.detail)
      return
    }
    
    // Solo actualizar si las coordenadas son diferentes
    if (this.currentLat !== newLat || this.currentLng !== newLng) {
      console.log(`🔄 Actualizando coordenadas del duelo: (${this.currentLat}, ${this.currentLng}) → (${newLat}, ${newLng})`)
      
      this.currentLat = newLat
      this.currentLng = newLng
      
      // SIEMPRE actualizar campos hidden
      this.writeHiddenCoordinates(newLat, newLng)
      
      // SIEMPRE persistir en localStorage
      this.persistCoordinates(newLat, newLng)
      
      // Actualizar campos de ubicación si se proporcionan en el evento
      if (e.detail.city) {
        const cityInput = this.getInput('city')
        if (cityInput && cityInput.value !== e.detail.city) {
          cityInput.value = e.detail.city
          console.log(`🏙️ Ciudad actualizada: ${e.detail.city}`)
        }
      }
      
      if (e.detail.country) {
        const countryInput = this.getInput('country')
        if (countryInput && countryInput.value !== e.detail.country) {
          countryInput.value = e.detail.country
          console.log(`🌍 País actualizado: ${e.detail.country}`)
        }
      }
      
      if (e.detail.address) {
        const addressInput = this.getInput('address')
        if (addressInput && addressInput.value !== e.detail.address) {
          addressInput.value = e.detail.address
          console.log(`📍 Dirección actualizada: ${e.detail.address}`)
        }
      }
      
      // ÚLTIMA PALABRA: Ejecutar filtro de radio de 3km
      console.log('🔄 Ejecutando recomputeAndRenderNearby(3) con nuevas coordenadas')
      this.debouncedRecompute()
      
      // Validar Paso 1 en tiempo real para habilitar/deshabilitar botón Siguiente
      // cuando se reciba el evento leagend:location_changed
      if (this.currentStep === 1) {
        this.updateButtons()
      }
    } else {
      console.log('ℹ️ Coordenadas no cambiaron, no se ejecuta recompute')
    }
    
    const endTime = new Date().toISOString()
    console.log(`⏰ [${endTime}] onLocationChanged() - FIN`)
  }

  // Manejar eventos de arena creada desde el modal
  onArenaCreated(e) {
    console.log('🎯 onArenaCreated() - Arena creada desde modal')
    console.trace('📍 TRACE: onArenaCreated() llamado desde:')
    
    if (!e?.detail) {
      console.warn('⚠️ Evento leagend:arena_created sin detail')
      return
    }
    
    const { id, name } = e.detail
    console.log(`🎯 Arena creada: ID ${id}, Nombre: ${name}`)
    
    // Actualizar el campo hidden duel[arena_id]
    if (this.hasArenaIdTarget) {
      this.arenaIdTarget.value = id
      console.log(`✅ Campo duel[arena_id] actualizado con ID: ${id}`)
    }
    
    // Buscar la arena en el DOM y marcarla como seleccionada
    const arenaCard = this.element.querySelector(`.arena-card[data-arena-id="${id}"]`)
    if (arenaCard) {
      // Remover selección previa
      this.element.querySelectorAll('.arena-card--selected').forEach(card => {
        card.classList.remove('arena-card--selected')
      })
      
      // Marcar nueva arena como seleccionada
      arenaCard.classList.add('arena-card--selected')
      console.log(`✅ Arena ${name} marcada como seleccionada en la UI`)
      
      // Actualizar el resumen si existe el método
      if (this.updateSummary) {
        this.updateSummary()
      }
    } else {
      console.warn(`⚠️ No se encontró la arena card con ID ${id} en el DOM`)
    }
  }

  // Búsqueda por texto - integrada con filtro de radio de 3km
  onSearchInput() {
    console.log('🔍 onSearchInput() - Búsqueda por texto')
    console.trace('📍 TRACE: onSearchInput() llamado desde:')
    
    // Ejecutar filtro de radio de 3km con búsqueda
    console.log('🔄 Ejecutando recomputeAndRenderNearby(3) con búsqueda')
    this.debouncedRecompute()
  }

  // ÚNICO MOTOR DE FILTRADO: Radio de 3km exactos basado SOLO en lat/lng
  // NO usa centroides de país/ciudad/address para el cálculo de distancia
  recomputeAndRenderNearby(radiusKm = 3) {
    const startTime = new Date().toISOString()
    console.log(`⏰ [${startTime}] === RECOMPUTE NEARBY - RADIO DE ${radiusKm}KM - INICIO ===`)
    
    // GUARD: Verificar que currentLat/currentLng son finitos
    const hasValidCoords = Number.isFinite(this.currentLat) && Number.isFinite(this.currentLng)
    
    if (!hasValidCoords) {
      console.log('❌ GUARD: Coordenadas no válidas, no se puede calcular radio de 3km')
      console.log('NOTA: El radio se calcula EXCLUSIVAMENTE desde currentLat/currentLng')
      console.log('Estado actual: currentLat =', this.currentLat, 'currentLng =', this.currentLng)
      
      // NO mostrar fallback prematuro - esperar coordenadas válidas
      this.arenas.forEach(a => {
        a.visible = false
        a.distance = null
        a.el.classList.add("d-none")
        a.el.setAttribute('data-out-of-range', 'true')
      })
      
      // Mostrar mensaje de espera
      this.toggleNoArenasMessage(true)
      
      console.log(`⏰ [${new Date().toISOString()}] === RECOMPUTE NEARBY - FIN (sin coordenadas válidas) ===`)
      return
    }
    
    console.log(`✅ GUARD: Coordenadas válidas: (${this.currentLat}, ${this.currentLng})`)
    console.log('NOTA: Radio basado EXCLUSIVAMENTE en coordenadas, NO en centroides de país/ciudad/address')
    
    // texto búsqueda
    const q = (this.arenaSearchTarget?.value || "").trim().toLowerCase()
    console.log('🔍 Búsqueda:', q || '(vacía)')
    
    // CALCULAR DISTANCIA HAVERSINE para cada arena usando SOLO currentLat/currentLng
    console.log('📏 Calculando distancias Haversine...')
    this.arenas.forEach(a => {
      if (Number.isFinite(a.lat) && Number.isFinite(a.lng)) {
        // Usar exclusivamente las coordenadas del duelo, no centroides de país/ciudad/address
        a.distance = this.haversineKm(this.currentLat, this.currentLng, a.lat, a.lng)
        console.log(`Arena ${a.name}: distancia = ${a.distance.toFixed(2)} km`)
      } else {
        a.distance = Infinity
        console.warn(`Arena ${a.name}: coordenadas inválidas (${a.lat}, ${a.lng})`)
      }
      
      // FILTRO DE RADIO FIJO: solo arenas <= 3km
      const inRadius = a.distance <= radiusKm
      const matchesSearch = q.length === 0 || a.name.toLowerCase().includes(q) || (a.city||"").toLowerCase().includes(q)
      
      // Visibilidad: debe estar en radio Y coincidir con búsqueda
      a.visible = inRadius && matchesSearch && Number.isFinite(a.distance)
      
      console.log(`Arena ${a.name}: inRadius=${inRadius}, matchesSearch=${matchesSearch}, visible=${a.visible}`)
    })

    // ORDENAR por distancia ascendente (más cercanas primero)
    this.arenas.sort((a, b) => a.distance - b.distance)
    
    // APLICAR VISIBILIDAD EN DOM - RESPETAR .d-none
    console.log('👁️ Aplicando visibilidad en DOM...')
    this.arenas.forEach(a => {
      if (a.el) {
        // Usar classList.toggle para mantener consistencia con CSS
        a.el.classList.toggle("d-none", !a.visible)
        
        // Marcar arenas fuera de radio para debug
        if (a.distance > radiusKm) {
          a.el.setAttribute('data-out-of-range', 'true')
        } else {
          a.el.removeAttribute('data-out-of-range')
        }
        
        // NO usar style.display para evitar conflictos
        // a.el.style.display = a.visible ? '' : 'none' // ❌ NO USAR
      }
    })
    
    // NO HAY FALLBACK AUTOMÁTICO: Si no hay arenas en radio, mostrar mensaje claro
    const visibles = this.arenas.filter(a => a.visible)
    if (visibles.length === 0) {
      console.log('⚠️ No hay arenas en radio de 3km - MOSTRANDO MENSAJE CLARO')
      console.log('NOTA: NO hay fallback automático para evitar confusión de UX')
      
      // Mostrar mensaje claro
      this.toggleNoArenasMessage(true)
    } else {
      console.log(`✅ ${visibles.length} arenas visibles en radio de 3km`)
      this.toggleNoArenasMessage(false)
    }
    
    // REORDENAR contenedor SOLO las visibles por distancia (más cercanas primero)
    console.log('🔄 Reordenando contenedor...')
    const frag = document.createDocumentFragment()
    visibles.forEach(a => frag.appendChild(a.el))
    if (this.arenaGridTarget) this.arenaGridTarget.appendChild(frag)
    
    // ACTUALIZAR indicadores de distancia en las cards
    this.updateDistanceIndicators(visibles)
    
    // SINCRONIZAR markers con la lista filtrada
    if (this.map) this.refreshMarkers(this.map, visibles)
    
    // MANEJAR arena seleccionada si quedó oculta
    const selectedId = this.arenaIdTarget?.value
    if (selectedId) {
      const sel = this.arenas.find(a => a.id === selectedId)
      this.arenas.forEach(a => a.el.classList.toggle("arena-card--selected", a && sel && a.id === sel.id && a.visible))
    }
    
    // LOG FINAL CON RESUMEN COMPLETO
    const endTime = new Date().toISOString()
    const duration = new Date(endTime) - new Date(startTime)
    console.log(`📊 RESUMEN: ${visibles.length} arenas visibles, Radio: ${radiusKm}km, Coordenadas: (${this.currentLat}, ${this.currentLng})`)
    console.log('NOTA: El cálculo de radio es EXCLUSIVAMENTE por coordenadas, NO por centroides')
    console.log(`⏰ [${endTime}] === RECOMPUTE NEARBY - FIN (duración: ${duration}ms) ===`)
    
    // VERIFICACIÓN FINAL: ninguna arena fuera de radio debe estar visible
    const arenasFueraRadio = this.arenas.filter(a => a.distance > radiusKm && a.visible)
    if (arenasFueraRadio.length > 0) {
      console.error('❌ ERROR: Arenas fuera de radio están visibles:', arenasFueraRadio.map(a => `${a.name} (${a.distance.toFixed(1)} km)`))
      console.trace('📍 TRACE: ERROR - Arenas fuera de radio visibles')
    } else {
      console.log('✅ VERIFICACIÓN: Todas las arenas fuera de radio están correctamente ocultas')
    }
  }

  // Seleccionar arena desde el card
  selectArenaCard(e) {
    const arenaCard = e.currentTarget
    const arenaId = arenaCard.dataset.arenaId
    
    console.log(`🎯 selectArenaCard() - Click en arena ${arenaId}`)
    console.trace('📍 TRACE: selectArenaCard() llamado desde:')
    
    this.selectArenaById(arenaId)
  }

  // Seleccionar arena por ID
  selectArenaById(id) {
    console.log(`🎯 selectArenaById(${id}) - Seleccionando arena`)
    console.trace('📍 TRACE: selectArenaById() llamado desde:')
    
    const a = this.arenas.find(x => x.id === id)
    if (!a) {
      console.warn(`⚠️ Arena con ID ${id} no encontrada`)
      return
    }
    
    if (this.arenaIdTarget) this.arenaIdTarget.value = id
    
    // Actualizar clases de selección
    this.arenas.forEach(x => x.el.classList.toggle("arena-card--selected", x.id === id))
    
    console.log(`✅ Arena ${a.name} seleccionada`)
    
    // opcional: centrar mapa en el marker si existe
    const m = this.arenaMarkers.get(id)
    if (m && this.map) {
      try {
        this.map.flyTo({ 
          center: m.getLngLat(), 
          zoom: Math.max(this.map.getZoom(), 13), 
          speed: 0.6 
        })
        console.log(`🗺️ Mapa centrado en arena ${a.name}`)
      } catch(e) {
        console.warn('⚠️ Error al centrar mapa:', e)
      }
    }
    
    // refrescar resumen si ya tienes updateSummary()
    if (this.updateSummary) this.updateSummary()
    
    // Actualizar campos de ubicación si la arena tiene ubicación
    if (a.country || a.city || a.address) {
      const countryField = this.getInput('country')
      const cityField = this.getInput('city')
      const addressField = this.getInput('address')
      const neighborhoodField = this.getInput('neighborhood')
      
      if (countryField && a.country) countryField.value = a.country
      if (cityField && a.city) cityField.value = a.city
      if (addressField && a.address) addressField.value = a.address
      if (neighborhoodField && a.neighborhood) neighborhoodField.value = a.neighborhood
      
      // Actualizar coordenadas si la arena las tiene
      if (a.lat && a.lng) {
        if (this.hasLatitudeTarget) {
          this.latitudeTarget.value = a.lat
        } else {
          // Fallback: usar helper seguro
          const latInput = this.getInput('latitude')
          if (latInput) latInput.value = a.lat
        }
        
        if (this.hasLongitudeTarget) {
          this.longitudeTarget.value = a.lng
        } else {
          // Fallback: usar helper seguro
          const lngInput = this.getInput('longitude')
          if (lngInput) lngInput.value = a.lng
        }
      }
      
      console.log(`📍 Ubicación de arena ${a.name} copiada al formulario`)
    }
  }

  // Actualizar distancias de arenas y ejecutar filtro de radio
  updateArenaDistances() {
    console.log('📏 updateArenaDistances() - Actualizando distancias de arenas')
    console.trace('📍 TRACE: updateArenaDistances() llamado desde:')
    
    if (!Number.isFinite(this.currentLat) || !Number.isFinite(this.currentLng)) {
      console.warn('⚠️ No hay coordenadas válidas para calcular distancias')
      return
    }
    
    console.log(`📍 Calculando distancias desde (${this.currentLat}, ${this.currentLng})`)
    
    // Calcular distancias y ejecutar filtro de radio
    this.debouncedRecompute()
    
    console.log('✅ Distancias de arenas actualizadas y filtro ejecutado')
  }

  // Actualizar indicadores de distancia en las cards - SOLO cuando hay coordenadas válidas
  updateDistanceIndicators(visibleArenas) {
    // Verificar que tenemos coordenadas válidas para mostrar distancias
    if (!Number.isFinite(this.currentLat) || !Number.isFinite(this.currentLng)) {
      console.log('❌ No hay coordenadas válidas, no se muestran indicadores de distancia')
      return
    }
    
    console.log(`📏 Actualizando indicadores de distancia para ${visibleArenas.length} arenas visibles`)
    
    visibleArenas.forEach(arena => {
      if (arena.el && Number.isFinite(arena.distance)) {
        // Buscar o crear elemento de distancia
        let distanceEl = arena.el.querySelector('[data-distance]')
        if (!distanceEl) {
          // Crear elemento de distancia si no existe
          const locationEl = arena.el.querySelector('.arena-card__location')
          if (locationEl) {
            distanceEl = document.createElement('small')
            distanceEl.className = 'text-muted d-block mt-1'
            distanceEl.setAttribute('data-distance', '')
            locationEl.appendChild(distanceEl)
          }
        }
        
        if (distanceEl) {
          const distanceText = arena.fallback ? 
            `<i class="fas fa-ruler me-1 text-warning"></i>~ ${arena.distance.toFixed(1)} km (fuera de radio)` :
            `<i class="fas fa-ruler me-1"></i>~ ${arena.distance.toFixed(1)} km`
          
          distanceEl.innerHTML = distanceText
          console.log(`✅ Arena ${arena.name}: distancia = ${arena.distance.toFixed(1)} km`)
        }
      } else {
        console.warn(`⚠️ Arena ${arena.name}: sin coordenadas válidas o elemento DOM`)
      }
    })
  }

  // Helper para obtener token de Mapbox
  getMapboxToken() {
    console.log('🔑 getMapboxToken() - Obteniendo token de Mapbox')
    console.trace('📍 TRACE: getMapboxToken() llamado desde:')
    
    // Prioridad 1: data-mapbox-token del elemento del controlador
    if (this.element.dataset.mapboxToken) {
      console.log('✅ Token encontrado en data-mapbox-token del controlador')
      return this.element.dataset.mapboxToken
    }
    
    // Prioridad 2: meta tag en el documento actual
    const metaTag = document.querySelector('meta[name="mapbox-token"]')
    if (metaTag?.content) {
      console.log('✅ Token encontrado en meta tag')
      return metaTag.content
    }
    
    // Prioridad 3: buscar en el turbo-frame modal si estamos en uno
    const modalFrame = document.querySelector('turbo-frame[src*="modal"]')
    if (modalFrame) {
      const modalMetaTag = modalFrame.querySelector('meta[name="mapbox-token"]')
      if (modalMetaTag?.content) {
        console.log('✅ Token encontrado en meta tag del modal')
        return modalMetaTag.content
      }
    }
    
    console.warn('⚠️ No se encontró token de Mapbox')
    return null
  }

  // Intentar geolocalización del navegador
  attemptGeolocation() {
    console.log('📍 attemptGeolocation() - Intentando geolocalización del navegador')
    console.trace('📍 TRACE: attemptGeolocation() llamado desde:')
    
    if (!navigator.geolocation) {
      console.warn('⚠️ Geolocalización no soportada por el navegador')
      return
    }
    
    console.log('🔄 Solicitando permisos de geolocalización...')
    
    navigator.geolocation.getCurrentPosition(
      this.onGeolocationSuccess.bind(this),
      this.onGeolocationError.bind(this),
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 60000
      }
    )
  }

  // Éxito en geolocalización - SIEMPRE completa ubicación
  onGeolocationSuccess(position) {
    const startTime = new Date().toISOString()
    console.log(`⏰ [${startTime}] onGeolocationSuccess() - INICIO`)
    console.trace('📍 TRACE: onGeolocationSuccess() llamado desde:')
    
    const { latitude, longitude } = position.coords
    
    // VERIFICAR que las coordenadas son numéricas válidas
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      console.warn('❌ Geolocalización devolvió coordenadas no válidas:', position.coords)
      return
    }
    
    console.log(`✅ Geolocalización exitosa: (${latitude}, ${longitude})`)
    
    // SIEMPRE actualizar coordenadas actuales del controller
    this.currentLat = latitude
    this.currentLng = longitude
    
    // SIEMPRE escribir en campos hidden
    this.writeHiddenCoordinates(latitude, longitude)
    
    // SIEMPRE persistir en localStorage
    this.persistCoordinates(latitude, longitude)
    
    // SIEMPRE hacer reverse geocoding para completar country/city/address
    this.reverseGeocode(latitude, longitude)
    
    // ÚLTIMA PALABRA: Ejecutar filtro de radio de 3km
    console.log('🔄 Ejecutando recomputeAndRenderNearby(3) tras geolocalización')
    this.debouncedRecompute()
    
    const endTime = new Date().toISOString()
    console.log(`⏰ [${endTime}] onGeolocationSuccess() - FIN`)
  }

  // Error en geolocalización
  onGeolocationError(error) {
    console.log('❌ onGeolocationError() - Error en geolocalización')
    console.trace('📍 TRACE: onGeolocationError() llamado desde:')
    
    console.warn('❌ Error en geolocalización:', error.message || 'Error desconocido')
    console.log('ℹ️ Continuando sin coordenadas de geolocalización')
  }

  // Reverse geocoding con Mapbox - SIEMPRE completa country/city/address
  reverseGeocode(lat, lng) {
    console.log('🔄 reverseGeocode() - Reverse geocoding con Mapbox')
    console.trace('📍 TRACE: reverseGeocode() llamado desde:')
    
    const token = this.getMapboxToken()
    if (!token) {
      console.warn('⚠️ No hay token de Mapbox para reverse geocoding')
      return
    }
    
    console.log(`📍 Reverse geocoding para (${lat}, ${lng})`)
    
    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${token}&language=es&types=address,poi,place`
    
    fetch(url)
      .then(response => response.json())
      .then(data => {
        if (data.features && data.features.length > 0) {
          const feature = data.features[0]
          console.log(`✅ Reverse geocoding exitoso: ${feature.place_name}`)
          
          // Extraer información de ubicación con prioridades robustas
          const context = feature.context || []
          
          // PRIORIDAD: country → place → locality → region
          const country = context.find(c => c.id?.startsWith('country'))?.text || ''
          let city = context.find(c => c.id?.startsWith('place'))?.text || ''
          if (!city) {
            city = context.find(c => c.id?.startsWith('locality'))?.text || ''
          }
          if (!city) {
            city = context.find(c => c.id?.startsWith('region'))?.text || ''
          }
          
          const address = feature.place_name || feature.text || ''
          
          console.log(`🏙️ Ciudad extraída: ${city} (prioridad: place → locality → region)`)
          console.log(`🌍 País: ${country}`)
          console.log(`📍 Dirección: ${address}`)
          
          // SIEMPRE actualizar campos del formulario
          this.updateLocationFields(country, city, address)
          
          // SIEMPRE escribir coordenadas en hidden
          this.writeHiddenCoordinates(lat, lng)
          
          // SIEMPRE persistir en localStorage
          this.persistCoordinates(lat, lng)
          
          // SIEMPRE disparar evento de cambio de ubicación
          this.dispatchLocationChangedEvent(lat, lng, city, country, address, 'reverse_geocode')
          
          console.log('✅ BOOT: Ubicación completamente actualizada')
        } else {
          console.warn('⚠️ No se encontraron resultados en reverse geocoding')
        }
      })
      .catch(error => {
        console.error('❌ Error en reverse geocoding:', error)
      })
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
    
    // Disparar evento de cambio de ubicación para sincronizar con otros controllers
    window.dispatchEvent(new CustomEvent("leagend:location_changed", {
      detail: { lat: lat, lng: lng }
    }))
  }

  // Rellenar campos de ubicación
  fillLocationInputs(country, city, address, lat, lng) {
    const countryInput = this.getInput('country')
    const cityInput = this.getInput('city')
    const addressInput = this.getInput('address')

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
    console.log('🔌 disconnect() - Desconectando controller')
    
    // Limpiar timers
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer)
    }
    
    // Limpiar event listeners
    window.removeEventListener("leagend:location_changed", this.onLocationChanged.bind(this))
    window.removeEventListener("leagend:arena_created", this.onArenaCreated.bind(this))
    
    // Limpiar markers del mapa
    if (this.arenaMarkers) {
      for (const marker of this.arenaMarkers.values()) {
        marker.remove()
      }
      this.arenaMarkers.clear()
    }
    
    console.log('✅ Controller desconectado correctamente')
  }

  // DEPRECATED: Este método usa radio de 20km y pisaba el filtro de 3km
  // NO USAR: Radio ahora es 3km exactos y solo por lat/lng
  // Reemplazado por recomputeAndRender() que usa exclusivamente currentLat/currentLng
  updateNearbyList(radiusKm = 20, limit = 20) {
    console.warn('DEPRECATED: updateNearbyList() no debe usarse. Radio ahora es 3km exactos por lat/lng')
    console.warn('Usar recomputeAndRender() en su lugar')
    console.trace('❌ TRACE: updateNearbyList() fue llamado desde:')
    return // Bloquear ejecución
    
    /* CÓDIGO LEGACY COMENTADO - NO USAR
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
          // arena.el.style.display = '' // ❌ COMENTADO: NO USAR style.display
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
          // arena.el.style.display = '' // ❌ COMENTADO: NO USAR style.display
          visibleCount++
          
          // Actualizar texto de distancia
          const distanceEl = arena.el.querySelector('[data-distance]')
          if (distanceEl) {
            distanceEl.textContent = `~ ${arena.distance.toFixed(1)} km`
          }
        } else {
          // arena.el.style.display = 'none' // ❌ COMENTADO: NO USAR style.display
        }
      }
    })

    // Si ninguna arena está dentro del radio, mostrar las N más cercanas
    if (visibleCount === 0) {
      this.arenas.slice(0, limit).forEach((arena, index) => {
        if (arena.el) {
          // arena.el.style.display = '' // ❌ COMENTADO: NO USAR style.display
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
    */
  }

  // Mostrar/ocultar mensaje de "no hay arenas"
  toggleNoArenasMessage(show) {
    console.log(`📢 toggleNoArenasMessage(${show}) - ${show ? 'MOSTRAR' : 'OCULTAR'} mensaje`)
    console.trace('📍 TRACE: toggleNoArenasMessage() llamado desde:')
    
    const noArenasMessage = document.getElementById('no-arenas-message')
    if (noArenasMessage) {
      if (show) {
        noArenasMessage.classList.remove('d-none')
        console.log('✅ Mensaje "no hay arenas" mostrado')
      } else {
        noArenasMessage.classList.add('d-none')
        console.log('✅ Mensaje "no hay arenas" ocultado')
      }
    } else {
      console.warn('⚠️ Elemento #no-arenas-message no encontrado')
    }
  }

  // Refrescar marcadores en el mapa basado en visibilidad - SOLO usa currentLat/currentLng
  refreshMarkers(map, visibles) {
    console.log(`🗺️ Refrescando marcadores: ${visibles.length} arenas visibles`)
    
    // eliminar markers que ya no están visibles
    for (const [id, m] of this.arenaMarkers.entries()) {
      if (!visibles.find(a => a.id === id)) {
        console.log(`🗑️ Removiendo marker de arena ${id} (ya no visible)`)
        m.remove()
        this.arenaMarkers.delete(id)
      }
    }
    
    // crear/update markers visibles
    visibles.forEach(a => {
      if (!this.arenaMarkers.has(a.id) && Number.isFinite(a.lat) && Number.isFinite(a.lng)) {
        console.log(`📍 Creando marker para arena ${a.name} en (${a.lat}, ${a.lng})`)
        
        const marker = new mapboxgl.Marker({ color: '#28a745' }).setLngLat([a.lng, a.lat]).addTo(map)
        
        // Crear popup para el marker
        const popup = new mapboxgl.Popup({ offset: 25 })
          .setHTML(`
            <div class="text-center">
              <h6 class="mb-1">${a.name}</h6>
              <small class="text-muted">${a.city || ''}</small>
              ${Number.isFinite(a.distance) ? `<br><small class="text-primary">~ ${a.distance.toFixed(1)} km</small>` : ''}
              ${a.fallback ? '<br><small class="text-warning">(fuera de radio de 3km)</small>' : ''}
            </div>
          `)
        marker.setPopup(popup)
        
        marker.getElement().addEventListener('click', () => this.selectArenaById(a.id))
        this.arenaMarkers.set(a.id, marker)
      }
    })
    
    // ajustar bounds para incluir todas las arenas visibles + ubicación del usuario
    if (visibles.length > 0) {
      const bounds = new mapboxgl.LngLatBounds()
      
      // Agregar todas las arenas visibles
      visibles.forEach(a => bounds.extend([a.lng, a.lat]))
      
      // Agregar ubicación del usuario SOLO si está disponible y es válida
      if (Number.isFinite(this.currentLng) && Number.isFinite(this.currentLat)) {
        bounds.extend([this.currentLng, this.currentLat])
        console.log(`📍 Ajustando bounds incluyendo ubicación del usuario: (${this.currentLat}, ${this.currentLng})`)
      } else {
        console.log('⚠️ No hay coordenadas válidas del usuario, ajustando bounds solo para arenas visibles')
      }
      
      try {
        map.fitBounds(bounds, { 
          padding: 50, 
          maxZoom: 14, 
          duration: 300 
        })
        console.log('✅ Bounds ajustados correctamente')
      } catch(e) {
        console.warn('❌ Error al ajustar bounds del mapa:', e)
      }
    } else {
      console.log('⚠️ No hay arenas visibles, no se ajustan bounds')
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
    // Si por alguna razón quedaron vacíos, no envíes strings vacíos.
    ['duel_country','duel_city','duel_address','duel_neighborhood'].forEach(id => {
      const el = document.getElementById(id);
      if (el && el.value.trim() === '') el.value = '';
      if (el) el.removeAttribute('disabled');
    });

    // Asegura números y 6 decimales
    const n = (id) => {
      const el = document.getElementById(id);
      if (!el) return;
      const val = parseFloat(el.value);
      if (!isNaN(val)) el.value = val.toFixed(6);
    };
    n('duel_latitude');
    n('duel_longitude');
  }

  // Resolver coordenadas iniciales con prioridad - SOLO coordenadas numéricas válidas
  // NO usa centroides de país/ciudad/address para el cálculo de distancia
  // El radio de 3km se calcula EXCLUSIVAMENTE desde estas coordenadas
  resolveInitialCoordinates() {
    const startTime = new Date().toISOString()
    console.log(`⏰ [${startTime}] resolveInitialCoordinates() - INICIO`)
    console.log('🔍 Resolviendo coordenadas iniciales para cálculo de radio de 3km...')
    console.log('NOTA: Solo se usan coordenadas numéricas, NO centroides de país/ciudad/address')
    console.trace('📍 TRACE: resolveInitialCoordinates() llamado desde:')
    
    // Prioridad 1: Valores en campos hidden si ya existen y son numéricos
    let latInput, lngInput
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      latInput = this.latitudeTarget
      lngInput = this.longitudeTarget
    } else {
      // Fallback: usar helpers seguros
      latInput = this.getInput('latitude')
      lngInput = this.getInput('longitude')
      console.debug('duel-steps: latitude/longitude targets not found, using fallback')
    }

    if (latInput?.value && lngInput?.value) {
      const lat = parseFloat(latInput.value)
      const lng = parseFloat(lngInput.value)
      if (Number.isFinite(lat) && Number.isFinite(lng)) {
        console.log(`✅ Coordenadas encontradas en campos hidden: (${lat}, ${lng})`)
        this.currentLat = lat
        this.currentLng = lng
        console.log('🔄 Ejecutando recomputeAndRender() con coordenadas iniciales')
        this.debouncedRecompute()
        
        const endTime = new Date().toISOString()
        console.log(`⏰ [${endTime}] resolveInitialCoordinates() - FIN (coordenadas en hidden)`)
        return
      } else {
        console.warn('⚠️ Coordenadas en campos hidden no son numéricas válidas:', latInput.value, lngInput.value)
      }
    }

    // Prioridad 2: Ubicación cacheada en localStorage
    try {
      const cachedLat = localStorage.getItem('leagend:lastLat')
      const cachedLng = localStorage.getItem('leagend:lastLng')
      if (cachedLat && cachedLng) {
        const lat = parseFloat(cachedLat)
        const lng = parseFloat(cachedLng)
        if (Number.isFinite(lat) && Number.isFinite(lng)) {
          console.log(`✅ Coordenadas encontradas en localStorage: (${lat}, ${lng})`)
          this.currentLat = lat
          this.currentLng = lng
          
          // Actualizar campos hidden si existen
          if (latInput && lngInput) {
            latInput.value = lat.toFixed(6)
            lngInput.value = lng.toFixed(6)
          }
          
          console.log('🔄 Ejecutando recomputeAndRender() con coordenadas cacheadas')
          this.debouncedRecompute()
          
          const endTime = new Date().toISOString()
          console.log(`⏰ [${endTime}] resolveInitialCoordinates() - FIN (coordenadas cacheadas)`)
          return
        } else {
          console.warn('⚠️ Coordenadas en localStorage no son numéricas válidas:', cachedLat, cachedLng)
        }
      }
    } catch (e) {
      console.warn('⚠️ Error al leer coordenadas del localStorage:', e)
    }

    // Prioridad 3: Geolocalización del navegador (asíncrona)
    console.log('🔄 No hay coordenadas válidas, intentando geolocalización...')
    this.attemptGeolocation()
    
    const endTime = new Date().toISOString()
    console.log(`⏰ [${endTime}] resolveInitialCoordinates() - FIN (geolocalización)`)
  }

  // Actualizar campos de ubicación del formulario
  updateLocationFields(country, city, address) {
    console.log('📝 updateLocationFields() - Actualizando campos de ubicación')
    console.trace('📍 TRACE: updateLocationFields() llamado desde:')
    
    console.log(`🌍 País: ${country}`)
    console.log(`🏙️ Ciudad: ${city}`)
    console.log(`📍 Dirección: ${address}`)
    
    // Actualizar campo de país
    if (country) {
      const countryInput = this.getInput('country')
      if (countryInput) {
        countryInput.value = country
        console.log('✅ Campo país actualizado')
      }
    }
    
    // Actualizar campo de ciudad
    if (city) {
      const cityInput = this.getInput('city')
      if (cityInput) {
        cityInput.value = city
        console.log('✅ Campo ciudad actualizado')
      }
    }
    
    // Actualizar campo de dirección
    if (address) {
      const addressInput = this.getInput('address')
      if (addressInput) {
        addressInput.value = address
        console.log('✅ Campo dirección actualizado')
      }
    }
    
    console.log('✅ Campos de ubicación actualizados')
  }

  // Disparar evento de cambio de ubicación con source
  dispatchLocationChangedEvent(lat, lng, city = null, country = null, address = null, source = 'unknown') {
    console.log('📡 dispatchLocationChangedEvent() - Disparando evento de cambio de ubicación')
    console.trace('📍 TRACE: dispatchLocationChangedEvent() llamado desde:')
    
    const eventData = {
      lat: lat,
      lng: lng,
      city: city,
      country: country,
      address: address,
      source: source
    }
    
    console.log('📡 Datos del evento:', eventData)
    
    window.dispatchEvent(new CustomEvent("leagend:location_changed", {
      detail: eventData
    }))
    
    console.log('✅ Evento leagend:location_changed disparado')
  }

  // BOOT COMPLETO: Escribir coordenadas en campos hidden
  writeHiddenCoordinates(lat, lng) {
    console.log('📝 BOOT: Escribiendo coordenadas en campos hidden')
    
    let latInput, lngInput
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      latInput = this.latitudeTarget
      lngInput = this.longitudeTarget
    } else {
      // Fallback: usar helpers seguros
      latInput = this.getInput('latitude')
      lngInput = this.getInput('longitude')
      console.debug('duel-steps: latitude/longitude targets not found, using fallback')
    }
    
    if (latInput && lngInput) {
      latInput.value = lat.toFixed(6)
      lngInput.value = lng.toFixed(6)
      console.log('✅ BOOT: Coordenadas escritas en campos hidden')
    } else {
      console.warn('⚠️ BOOT: Campos hidden no encontrados')
    }
  }

  // BOOT COMPLETO: Persistir coordenadas en localStorage
  persistCoordinates(lat, lng) {
    console.log('💾 BOOT: Persistiendo coordenadas en localStorage')
    
    try {
      localStorage.setItem('leagend:lastLat', lat.toString())
      localStorage.setItem('leagend:lastLng', lng.toString())
      console.log('✅ BOOT: Coordenadas persistidas en localStorage')
    } catch (e) {
      console.warn('⚠️ BOOT: Error al persistir coordenadas:', e)
    }
  }

  // BOOT DE GEOLOCALIZACIÓN ANTICIPADA: No bloqueante, en paralelo al flujo actual
  attemptGeolocationAnticipated() {
    console.log('🚀 BOOT: Iniciando geolocalización anticipada...')
    console.trace('📍 TRACE: attemptGeolocationAnticipated() llamado desde:')
    
    // Verificar que el navegador soporte geolocalización
    if (!navigator.geolocation) {
      console.warn('⚠️ BOOT: Navegador no soporta geolocalización')
      return
    }
    
    // Mostrar estado de carga suave
    this.showGeolocationStatus('Buscando tu ubicación...')
    
    // Configuración de alta precisión con timeout razonable
    const options = {
      enableHighAccuracy: true,
      timeout: 10000, // 10 segundos
      maximumAge: 0 // No usar cache, siempre obtener posición fresca
    }
    
    console.log('📍 BOOT: Solicitando geolocalización con opciones:', options)
    
    // Solicitar geolocalización de forma no bloqueante
    navigator.geolocation.getCurrentPosition(
      (position) => this.onGeolocationAnticipatedSuccess(position),
      (error) => this.onGeolocationAnticipatedError(error),
      options
    )
    
    console.log('✅ BOOT: Solicitud de geolocalización enviada (no bloqueante)')
  }
  
  // Éxito en geolocalización anticipada - SIEMPRE completa ubicación
  onGeolocationAnticipatedSuccess(position) {
    const startTime = new Date().toISOString()
    console.log(`⏰ [${startTime}] BOOT: onGeolocationAnticipatedSuccess() - INICIO`)
    console.trace('📍 TRACE: onGeolocationAnticipatedSuccess() llamado desde:')
    
    const { latitude, longitude } = position.coords
    
    // VERIFICAR que las coordenadas son numéricas válidas
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      console.warn('❌ BOOT: Geolocalización anticipada devolvió coordenadas no válidas:', position.coords)
      this.hideGeolocationStatus()
      return
    }
    
    console.log(`✅ BOOT: Geolocalización anticipada exitosa: (${latitude}, ${longitude})`)
    
    // SIEMPRE actualizar coordenadas actuales del controller
    this.currentLat = latitude
    this.currentLng = longitude
    
    // SIEMPRE escribir en campos hidden
    this.writeHiddenCoordinates(latitude, longitude)
    
    // SIEMPRE persistir en localStorage
    this.persistCoordinates(latitude, longitude)
    
    // SIEMPRE hacer reverse geocoding para completar country/city/address
    this.reverseGeocode(latitude, longitude)
    
    // ÚLTIMA PALABRA: Emitir evento para que el mapa se centre y se ejecute el filtro de 3km
    console.log('🔄 BOOT: Emitiendo evento leagend:location_changed tras geolocalización anticipada')
    this.dispatchLocationChangedEvent(latitude, longitude, null, null, null, 'geoloc_anticipated')
    
    // Ocultar estado de carga
    this.hideGeolocationStatus()
    
    const endTime = new Date().toISOString()
    console.log(`⏰ [${endTime}] BOOT: onGeolocationAnticipatedSuccess() - FIN`)
  }
  
  // Error en geolocalización anticipada - NO romper flujo actual
  onGeolocationAnticipatedError(error) {
    console.log('⚠️ BOOT: Error en geolocalización anticipada:', error.message)
    console.log('ℹ️ BOOT: Continuando con flujo normal (cache/hidden)')
    
    // Ocultar estado de carga
    this.hideGeolocationStatus()
    
    // NO romper nada - el flujo actual (resolveInitialCoordinates) maneja fallbacks
    switch (error.code) {
      case error.PERMISSION_DENIED:
        console.log('ℹ️ BOOT: Usuario denegó permisos de geolocalización')
        break
      case error.POSITION_UNAVAILABLE:
        console.log('ℹ️ BOOT: Información de ubicación no disponible')
        break
      case error.TIMEOUT:
        console.log('ℹ️ BOOT: Timeout en geolocalización anticipada')
        break
      default:
        console.log('ℹ️ BOOT: Error desconocido en geolocalización anticipada')
    }
  }
  
  // Mostrar estado de carga de geolocalización
  showGeolocationStatus(message) {
    console.log('📱 BOOT: Mostrando estado de geolocalización:', message)
    
    // Buscar o crear elemento de estado
    let statusEl = document.getElementById('geolocation-status')
    if (!statusEl) {
      statusEl = document.createElement('div')
      statusEl.id = 'geolocation-status'
      statusEl.className = 'alert alert-info text-center mt-2'
      statusEl.innerHTML = `
        <i class="fas fa-spinner fa-spin me-2"></i>
        <small>${message}</small>
      `
      
      // Insertar después del header del paso
      const stepHeader = this.element.querySelector('.step-header')
      if (stepHeader) {
        stepHeader.parentNode.insertBefore(statusEl, stepHeader.nextSibling)
      }
    } else {
      statusEl.innerHTML = `
        <i class="fas fa-spinner fa-spin me-2"></i>
        <small>${message}</small>
      `
      statusEl.classList.remove('d-none')
    }
  }
  
  // Ocultar estado de carga de geolocalización
  hideGeolocationStatus() {
    console.log('📱 BOOT: Ocultando estado de geolocalización')
    
    const statusEl = document.getElementById('geolocation-status')
    if (statusEl) {
      statusEl.classList.add('d-none')
    }
  }

  // Inicializar mapa en miniatura para el resumen
  initSummaryMap() {
    if (!this.hasSummaryMapTarget) return
    
    console.log('🗺️ Inicializando mapa en miniatura para el resumen')
    
    // Verificar si ya hay un mapa en este elemento
    if (this.summaryMapTarget._mapboxgl) {
      console.log('✅ Mapa en miniatura ya inicializado')
      return
    }
    
    // Obtener coordenadas del duelo
    let lat, lng
    
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      lat = parseFloat(this.latitudeTarget.value || 0)
      lng = parseFloat(this.longitudeTarget.value || 0)
    } else {
      // Fallback: usar helpers seguros
      lat = parseFloat(this.getValue('latitude') || 0)
      lng = parseFloat(this.getValue('longitude') || 0)
      console.debug('duel-steps: latitude/longitude targets not found, using fallback')
    }
    
    if (!lat || !lng) {
      console.log('⚠️ No hay coordenadas para mostrar en el mapa en miniatura')
      return
    }
    
    // Crear mapa en miniatura simple
    try {
      const map = new mapboxgl.Map({
        container: this.summaryMapTarget,
        style: 'mapbox://styles/mapbox/streets-v12',
        center: [lng, lat],
        zoom: 12,
        interactive: false,
        attributionControl: false
      })
      
      // Agregar marcador
      new mapboxgl.Marker()
        .setLngLat([lng, lat])
        .addTo(map)
      
      // Guardar referencia
      this.summaryMapTarget._mapboxgl = map
      
      console.log('✅ Mapa en miniatura inicializado correctamente')
    } catch (error) {
      console.warn('⚠️ Error al inicializar mapa en miniatura:', error)
    }
  }

  // Función llamada al entrar al Paso 3 para manejar el mapa
  onEnterStep3() {
    console.log('🗺️ onEnterStep3() - Entrando al Paso 3, configurando mapa')
    
    // Obtener coordenadas del duelo
    const lat = parseFloat(this.getValue('latitude'))
    const lng = parseFloat(this.getValue('longitude'))
    
    // Obtener el contenedor del mapa del resumen
    const el = document.getElementById('summary-map')
    
    if (!el || isNaN(lat) || isNaN(lng)) {
      console.warn('⚠️ onEnterStep3: Contenedor del mapa no encontrado o coordenadas inválidas')
      return
    }
    
    console.log(`📍 onEnterStep3: Coordenadas obtenidas (${lat}, ${lng})`)
    
    // Si ya existe window.leagendMap, solo centra y resizea
    if (window.leagendMap && window.leagendMap.jumpTo) {
      console.log('🗺️ onEnterStep3: Usando window.leagendMap existente')
      window.leagendMap.jumpTo({ center: [lng, lat], zoom: 14 })
      setTimeout(() => {
        if (window.leagendMap.resize) {
          window.leagendMap.resize()
          console.log('✅ onEnterStep3: Mapa centrado y resizeado correctamente')
        }
      }, 50)
    } else {
      // Si no existe window.leagendMap, usar el mapa propio del resumen
      console.log('🗺️ onEnterStep3: Inicializando mapa propio del resumen')
      
      // Verificar si ya existe un mapa en el contenedor
      if (el._mapboxgl) {
        console.log('🗺️ onEnterStep3: Mapa existente encontrado, centrando y resizeando')
        const map = el._mapboxgl
        map.jumpTo({ center: [lng, lat], zoom: 14 })
        setTimeout(() => {
          map.resize()
          console.log('✅ onEnterStep3: Mapa propio centrado y resizeado correctamente')
        }, 50)
      } else {
        // Inicializar nuevo mapa del resumen
        console.log('🗺️ onEnterStep3: Creando nuevo mapa del resumen')
        this.initSummaryMap()
        
        // Después de inicializar, centrar y resizear
        setTimeout(() => {
          if (el._mapboxgl) {
            const map = el._mapboxgl
            map.jumpTo({ center: [lng, lat], zoom: 14 })
            map.resize()
            console.log('✅ onEnterStep3: Nuevo mapa del resumen centrado y resizeado correctamente')
          }
        }, 100)
      }
    }
  }
}