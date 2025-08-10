import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map"]
  static values = { 
    editable: { type: Boolean, default: false },
    centerLat: { type: Number, default: 4.7110 },
    centerLng: { type: Number, default: -74.0721 },
    zoom: { type: Number, default: 13 }
  }

  connect() {
    this.map = null
    this.marker = null
    this.mapboxRetryCount = 0
    this.maxRetries = 20
    
    // Esperar a que Mapbox GL esté disponible (sin Geocoder)
    this.waitForMapbox()
  }

  disconnect() {
    this.cleanupMap()
  }

  // Esperar a que Mapbox GL esté disponible antes de inicializar
  waitForMapbox() {
    console.log('waitForMapbox: verificando disponibilidad...');
    console.log('mapboxgl disponible:', typeof mapboxgl !== 'undefined');
    
    if (typeof mapboxgl !== 'undefined') {
      console.log('Mapbox GL disponible, inicializando mapa de solo lectura...');
      this.initializeMap()
    } else if (this.mapboxRetryCount < this.maxRetries) {
      console.log(`Mapbox GL no disponible, reintento ${this.mapboxRetryCount + 1}/${this.maxRetries}...`);
      this.mapboxRetryCount++
      
      // Escuchar eventos personalizados de carga
      const checkAvailability = () => {
        if (typeof mapboxgl !== 'undefined') {
          console.log('Mapbox GL disponible después de esperar eventos, inicializando...');
          this.initializeMap()
          return true
        }
        return false
      }
      
      // Escuchar evento de carga
      window.addEventListener('mapboxgl:loaded', () => {
        if (checkAvailability()) {
          window.removeEventListener('mapboxgl:loaded', checkAvailability)
        }
      })
      
      // Reintentar después de un delay
      setTimeout(() => {
        if (!checkAvailability()) {
          this.waitForMapbox()
        }
      }, 100)
    } else {
      console.error('Mapbox GL no disponible después de múltiples intentos');
    }
  }

  // Limpiar recursos del mapa
  cleanupMap() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
    if (this.marker) {
      this.marker.remove()
      this.marker = null
    }
  }

  // Inicializar el mapa de solo lectura
  initializeMap() {
    try {
      const token = this.getMapboxToken()
      if (!token) {
        console.error('Token de Mapbox no encontrado')
        return
      }

      // Configurar token
      mapboxgl.accessToken = token

      // Crear mapa
      this.map = new mapboxgl.Map({
        container: this.mapTarget,
        style: 'mapbox://styles/mapbox/streets-v12',
        center: [this.centerLngValue, this.centerLatValue],
        zoom: this.zoomValue,
        attributionControl: true,
        customAttribution: '© Mapbox © OpenStreetMap'
      })

      // Agregar controles de navegación
      this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')

      // Configurar eventos del mapa
      this.setupMapEvents()

      // Agregar marcador cuando el mapa esté listo
      this.map.on('load', () => {
        this.addMarker()
        // Resize para asegurar renderizado correcto
        this.map.resize()
      })

      console.log('Mapa de solo lectura inicializado correctamente')
    } catch (error) {
      console.error('Error al inicializar mapa:', error)
    }
  }

  // Configurar eventos del mapa
  setupMapEvents() {
    // Solo eventos básicos para visualización
    this.map.on('error', (e) => {
      console.error('Error del mapa:', e)
    })
  }

  // Agregar marcador fijo (no draggable)
  addMarker() {
    if (this.marker) {
      this.marker.remove()
    }

    this.marker = new mapboxgl.Marker({
      color: '#007bff',
      draggable: false // Marcador fijo para visualización
    })
      .setLngLat([this.centerLngValue, this.centerLatValue])
      .addTo(this.map)

    // Agregar popup con información básica
    const popup = new mapboxgl.Popup({ offset: 25 })
      .setHTML(`
        <div class="text-center">
          <strong>Arena</strong><br>
          <small>Ubicación del duelo</small>
        </div>
      `)

    this.marker.setPopup(popup)
  }

  // Obtener token de Mapbox desde meta tag
  getMapboxToken() {
    const metaTag = document.querySelector('meta[name="mapbox-token"]')
    if (metaTag) {
      return metaTag.getAttribute('content')
    }
    
    // Fallback: buscar en el layout principal
    const mainMetaTag = document.querySelector('meta[name="mapbox-token"]')
    if (mainMetaTag) {
      return mainMetaTag.getAttribute('content')
    }
    
    console.warn('Token de Mapbox no encontrado en meta tags')
    return null
  }
}
