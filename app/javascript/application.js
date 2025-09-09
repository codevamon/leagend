// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import Rails from "@rails/ujs"
import "controllers"

// FullCalendar imports
import "fullcalendar"
import "@fullcalendar/daygrid"
import "@fullcalendar/interaction"

// Exponer objetos FullCalendar en window para uso global
window.Calendar = window.FullCalendar.Calendar
window.dayGridPlugin = window.FullCalendarDayGrid
window.interactionPlugin = window.FullCalendarInteraction

// Inicializar Rails UJS para que method: :delete funcione correctamente
Rails.start()
