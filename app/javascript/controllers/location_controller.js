import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "button"]
  static values = { 
    enabled: Boolean,
    userSignedIn: Boolean 
  }

  connect() {
    // Solo inicializar si no está ya habilitado
    if (!this.enabledValue) {
      this.checkLocationPermission()
    }
  }

  // Verifica si el usuario ya dio permiso de ubicación
  checkLocationPermission() {
    if (!navigator.geolocation) {
      this.updateStatus("Geolocalización no soportada en este navegador", "warning")
      return
    }

    // Verificar si ya tenemos permisos
    navigator.permissions.query({ name: 'geolocation' }).then((result) => {
      if (result.state === 'granted') {
        this.enabledValue = true
        this.updateStatus("Ubicación habilitada", "success")
        this.getCurrentLocation()
      } else if (result.state === 'denied') {
        this.updateStatus("Permiso de ubicación denegado", "error")
      } else {
        this.updateStatus("Permiso de ubicación no solicitado", "info")
      }
    }).catch(() => {
      // Fallback para navegadores que no soportan permissions API
      this.updateStatus("Haz clic para habilitar ubicación", "info")
    })
  }

  // Solicita permiso y obtiene ubicación
  requestLocation() {
    if (!navigator.geolocation) {
      this.updateStatus("Geolocalización no soportada", "error")
      return
    }

    this.updateStatus("Solicitando ubicación...", "info")
    
    navigator.geolocation.getCurrentPosition(
      (position) => this.handleLocationSuccess(position),
      (error) => this.handleLocationError(error),
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000 // 5 minutos
      }
    )
  }

  // Maneja éxito en obtención de ubicación
  handleLocationSuccess(position) {
    const { latitude, longitude } = position.coords
    
    this.updateStatus("Ubicación obtenida, actualizando...", "info")
    
    // Obtener timezone del navegador
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
    
    // Enviar al servidor
    this.updateLocationOnServer(latitude, longitude, null, timezone)
  }

  // Maneja errores de geolocalización
  handleLocationError(error) {
    let message = "Error obteniendo ubicación"
    
    switch(error.code) {
      case error.PERMISSION_DENIED:
        message = "Permiso de ubicación denegado"
        break
      case error.POSITION_UNAVAILABLE:
        message = "Información de ubicación no disponible"
        break
      case error.TIMEOUT:
        message = "Tiempo de espera agotado"
        break
      default:
        message = `Error: ${error.message}`
    }
    
    this.updateStatus(message, "error")
  }

  // Actualiza ubicación en el servidor
  async updateLocationOnServer(lat, lng, zip, timezone) {
    try {
      const response = await fetch('/geo/update', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          latitude: lat,
          longitude: lng,
          zip: zip,
          timezone: timezone
        })
      })

      const data = await response.json()
      
      if (data.success) {
        this.enabledValue = true
        this.updateStatus("Ubicación actualizada correctamente", "success")
        
        // Disparar evento para que otros componentes sepan que la ubicación cambió
        this.dispatch('locationUpdated', { detail: { lat, lng, zip, timezone } })
      } else {
        this.updateStatus(data.message || "Error actualizando ubicación", "error")
      }
    } catch (error) {
      console.error('Error actualizando ubicación:', error)
      this.updateStatus("Error de conexión", "error")
    }
  }

  // Actualiza el estado mostrado al usuario
  updateStatus(message, type = "info") {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = `location-status location-status--${type}`
    }
    
    // También actualizar el botón si existe
    if (this.hasButtonTarget) {
      if (type === "success") {
        this.buttonTarget.textContent = "Ubicación habilitada"
        this.buttonTarget.disabled = true
        this.buttonTarget.classList.add("btn-success")
        this.buttonTarget.classList.remove("btn-primary")
      }
    }
  }

  // Método público para obtener ubicación actual
  getCurrentLocation() {
    if (this.enabledValue) {
      this.requestLocation()
    } else {
      this.updateStatus("Haz clic en el botón para habilitar ubicación", "info")
    }
  }

  // Método público para resetear estado
  reset() {
    this.enabledValue = false
    this.updateStatus("Haz clic para habilitar ubicación", "info")
    
    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = "Habilitar ubicación"
      this.buttonTarget.disabled = false
      this.buttonTarget.classList.remove("btn-success")
      this.buttonTarget.classList.add("btn-primary")
    }
  }
}
