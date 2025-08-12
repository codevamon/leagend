import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    // Asegurar que el enlace de cierre de sesión funcione correctamente
    this.linkTarget.addEventListener('click', this.handleSignOut.bind(this))
  }

  handleSignOut(event) {
    // Prevenir el comportamiento por defecto
    event.preventDefault()
    
    // Obtener el token CSRF
    const token = document.querySelector('meta[name="csrf-token"]').content
    
    // Crear y enviar la petición DELETE
    fetch(this.linkTarget.href, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': token,
        'Content-Type': 'application/json'
      },
      credentials: 'same-origin'
    }).then(response => {
      if (response.ok) {
        // Redirigir a la página principal después del cierre de sesión
        window.location.href = '/'
      } else {
        console.error('Error al cerrar sesión:', response.statusText)
      }
    }).catch(error => {
      console.error('Error al cerrar sesión:', error)
    })
  }

  disconnect() {
    if (this.hasLinkTarget) {
      this.linkTarget.removeEventListener('click', this.handleSignOut.bind(this))
    }
  }
}
