import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  
  connect() {
    // Escuchar eventos de actualización de ubicación
    document.addEventListener('locationUpdated', this.handleLocationUpdate.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('locationUpdated', this.handleLocationUpdate.bind(this))
  }
  
  // Maneja actualizaciones de ubicación
  handleLocationUpdate(event) {
    const { lat, lng, zip, timezone } = event.detail
    
    // Actualizar la información mostrada
    this.updateLocationDisplay(lat, lng)
    
    // Hacer un pequeño efecto visual
    this.element.classList.add('location-updated')
    setTimeout(() => {
      this.element.classList.remove('location-updated')
    }, 2000)
  }
  
  // Actualiza la información de ubicación mostrada
  updateLocationDisplay(lat, lng) {
    if (this.hasDisplayTarget) {
      // Buscar el elemento de ubicación en el layout
      const locationBar = document.querySelector('.location-info-bar')
      if (locationBar) {
        const locationText = locationBar.querySelector('.text-muted')
        if (locationText) {
          // Extraer la información actual
          const currentText = locationText.textContent
          if (currentText.includes('Detectando ubicación')) {
            // Si estaba detectando, mostrar la nueva ubicación
            locationText.innerHTML = `
              <i class="fas fa-map-marker-alt me-1"></i>
              Ubicación: Coordenadas obtenidas (Lat: ${lat}, Lng: ${lng})
            `
          } else if (currentText.includes('Ubicación:')) {
            // Si ya tenía ubicación, añadir las coordenadas
            const baseLocation = currentText.replace(/\(Lat:.*?\)/, '').trim()
            locationText.innerHTML = `
              <i class="fas fa-map-marker-alt me-1"></i>
              ${baseLocation} (Lat: ${lat}, Lng: ${lng})
            `
          }
        }
      }
    }
  }
  
  // Método para refrescar la información de ubicación
  refresh() {
    // Hacer una petición al servidor para obtener la ubicación actual
    fetch('/geo/current')
      .then(response => response.json())
      .then(data => {
        if (data.success && data.location) {
          this.updateLocationDisplay(
            data.location.latitude || 'N/A',
            data.location.longitude || 'N/A'
          )
        }
      })
      .catch(error => {
        console.log('Error refrescando ubicación:', error)
      })
  }
}
