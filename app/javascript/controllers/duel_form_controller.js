import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startsAt", "duration", "endsAt", "form"]

  connect() {
    this.setupEventListeners()
    this.updateEndTime()
  }

  disconnect() {
    // Cleanup si es necesario
  }

  setupEventListeners() {
    if (this.hasStartsAtTarget) {
      this.startsAtTarget.addEventListener('change', () => this.updateEndTime())
    }
    
    if (this.hasDurationTarget) {
      this.durationTarget.addEventListener('change', () => this.updateEndTime())
    }
    
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', (event) => this.validateForm(event))
    }
  }

  updateEndTime() {
    if (this.hasStartsAtTarget && this.hasDurationTarget && 
        this.startsAtTarget.value && this.durationTarget.value) {
      
      const startTime = new Date(this.startsAtTarget.value)
      const duration = parseInt(this.durationTarget.value)
      const endTime = new Date(startTime.getTime() + (duration * 60 * 60 * 1000))
      
      // Crear o actualizar campo hidden para ends_at
      let endsAtField = this.endsAtTarget
      if (!endsAtField) {
        endsAtField = document.createElement('input')
        endsAtField.type = 'hidden'
        endsAtField.name = 'duel[ends_at]'
        endsAtField.id = 'duel_ends_at'
        this.startsAtTarget.parentNode.appendChild(endsAtField)
        this.endsAtTarget = endsAtField
      }
      
      endsAtField.value = endTime.toISOString().slice(0, 16)
    }
  }

  validateForm(event) {
    if (!this.formTarget.checkValidity()) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.formTarget.classList.add('was-validated')
  }

  // Método para resetear el formulario
  reset() {
    if (this.hasFormTarget) {
      this.formTarget.reset()
      this.formTarget.classList.remove('was-validated')
      this.updateEndTime()
    }
  }
}
