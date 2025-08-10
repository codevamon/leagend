import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateInput", "slotsContainer", "reserveBtn", "modalDate", "modalTime", "modalPrice", "confirmBtn"]
  static values = { 
    arenaSlug: String,
    pricePerHour: { type: Number, default: 0 }
  }

  connect() {
    this.setupEventListeners()
  }

  disconnect() {
    // Cleanup si es necesario
  }

  setupEventListeners() {
    if (this.hasDateInputTarget) {
      this.dateInputTarget.addEventListener('change', (e) => this.handleDateChange(e))
    }

    if (this.hasConfirmBtnTarget) {
      this.confirmBtnTarget.addEventListener('click', (e) => this.handleConfirmReservation(e))
    }
  }

  handleDateChange(event) {
    const date = event.target.value
    if (date) {
      this.fetchAvailability(date)
    }
  }

  async fetchAvailability(date) {
    try {
      const response = await fetch(`/arenas/${this.arenaSlugValue}/availability?date=${date}`)
      const data = await response.json()
      this.displaySlots(data.slots)
    } catch (error) {
      console.error('Error fetching availability:', error)
    }
  }

  displaySlots(slots) {
    if (slots.length === 0) {
      this.slotsContainerTarget.innerHTML = '<div class="text-muted">No hay horarios disponibles para esta fecha</div>'
      this.reserveBtnTarget.disabled = true
      return
    }

    const slotsHtml = slots.map(slot => {
      const time = new Date(slot).toLocaleTimeString('es-ES', { 
        hour: '2-digit', 
        minute: '2-digit' 
      })
      return `<button class="btn btn-outline-primary btn-sm me-2 mb-2" data-action="click->arena-reservation#selectSlot" data-slot="${slot}">${time}</button>`
    }).join('')

    this.slotsContainerTarget.innerHTML = slotsHtml
  }

  selectSlot(event) {
    const slot = event.currentTarget.dataset.slot
    const date = this.dateInputTarget.value
    const time = new Date(slot).toLocaleTimeString('es-ES', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
    
    // Actualizar modal
    this.modalDateTarget.value = new Date(date).toLocaleDateString('es-ES')
    this.modalTimeTarget.value = time
    this.modalPriceTarget.value = `$${this.pricePerHourValue.toLocaleString()}`
    
    // Mostrar modal
    const modal = new bootstrap.Modal(document.getElementById('reservationModal'))
    modal.show()
  }

  async handleConfirmReservation(event) {
    const date = this.dateInputTarget.value
    const selectedSlot = document.querySelector('.btn-outline-primary.active')
    
    if (!date || !selectedSlot) return
    
    const startsAt = new Date(selectedSlot.dataset.slot)
    const endsAt = new Date(startsAt.getTime() + 60 * 60 * 1000) // 1 hora
    
    try {
      const response = await fetch(`/arenas/${this.arenaSlugValue}/reservations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          reservation: {
            starts_at: startsAt.toISOString(),
            ends_at: endsAt.toISOString()
          }
        })
      })
      
      const data = await response.json()
      
      if (data.error) {
        alert(data.error)
      } else {
        window.location.href = `/reservations/${data.id}`
      }
    } catch (error) {
      console.error('Error creating reservation:', error)
      alert('Error al crear la reserva')
    }
  }
}
