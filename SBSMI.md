# 🏟️ Leagend — SBSMI (Sistema de Búsqueda Sincronizada con Mapas Interactivos)

## 📌 Introducción
El proyecto **Leagend** implementa el **SBSMI (Sistema de Búsqueda Sincronizada con Mapas Interactivos)**, un módulo transversal que centraliza el manejo de localización y mapas en todas las entidades del sistema.  

Este sistema asegura que todos los formularios (`duels`, `arenas`, `referees`, `clubs`, `clans`, `tournaments`) mantengan una experiencia unificada de búsqueda, selección y sincronización de ubicaciones, tanto en páginas completas como en modales.

---

## 🎯 Objetivo
- Ofrecer **inputs jerarquizados** para país, ciudad y dirección.  
- Sincronizar datos de ubicación (`latitude`, `longitude`) con un mapa interactivo de **Mapbox**.  
- Extender la experiencia de búsqueda con **autocompletado especializado** según el campo (`country`, `city`, `address`).  
- Permitir la selección de entidades cercanas en un **listado de cards** o directamente en el mapa.  
- Garantizar **compatibilidad con múltiples instancias** (ej: modal abierto sobre página principal).  

---

## 🧩 Componentes del SBSMI
### 1. Zona de Typing
Inputs sincronizados en todos los formularios:
- `country` → Autocomplete con países (`types: country`)
- `city` → Autocomplete con ciudades (`types: place,locality`), restringido al país
- `address` → Autocomplete completo (`types: address,street,poi`), restringido a país + ciudad
- `latitude`, `longitude` → Campos ocultos para persistencia
- `neighborhood` → Campo opcional

### 2. Zona de Mapping
- Mapa de **Mapbox GL JS**.  
- Marcador draggable.  
- Bias dinámico: restringe sugerencias a país/ciudad seleccionados.  
- Eventos `leagend:location_changed` para sincronizar mapa ↔ inputs.  

### 3. Zona de Collecting
- Listado de entidades cercanas (ej. arenas en radio de 3km).  
- Representación visual en cards (`_arena_card.html.erb`).  
- Selección y deselección sincronizada entre lista y mapa.  
- Arquitectura extensible para clubs, clans, referees, tournaments.

---

## 🔄 Jerarquía de Inputs
El SBSMI establece un orden jerárquico que evita conflictos entre campos:
1. **Country** → Al cambiar, limpia `city` y `address`.
2. **City** → Al cambiar, limpia `address`.
3. **Address** → Nunca sobrescribe `city` si fue escrita manualmente.

---

## 🛠️ Implementación Técnica
### Vistas
- Contenedores de sugerencias con IDs dinámicos por contexto (`duel`, `arena`, `arena-quick`):
  - `country-suggestions-<context_id>`
  - `city-suggestions-<context_id>`
  - `address-suggestions-<context_id>`
- Compatible con:
  - `duels/new.html.erb`
  - `arenas/_form.html.erb`
  - `arenas/_form_quick.html.erb` (modal Turbo Frame)

### Controlador Stimulus
`app/javascript/controllers/arena_location_controller.js`
- Métodos implementados:
  - `fetchCountrySuggestions`, `displayCountrySuggestions`, `clearCountrySuggestions`, `selectCountrySuggestion`
  - `fetchCitySuggestions`, `displayCitySuggestions`, `clearCitySuggestions`, `selectCitySuggestion`
  - `fetchAddressSuggestions`, `displayAddressSuggestions`, `clearAddressSuggestions`, `selectAddressSuggestion`
- Uso de `this.element.querySelector` para aislar instancias.  
- Debounce de 300ms en inputs para optimizar llamadas a Mapbox API.  

---

## 🚀 Beneficios
- **Independencia de instancias:** cada formulario (página o modal) opera sin interferir en los demás.  
- **Experiencia de usuario clara:** autocomplete especializado por campo.  
- **Consistencia transversal:** mismo flujo en todas las entidades.  
- **Extensibilidad:** fácilmente aplicable a nuevas entidades (`tournaments`, etc.).  

---

## 📖 Estado Actual
- ✅ Integración completa en **duels/new**.  
- ✅ Integración completa en **arenas/new**.  
- ✅ Integración completa en **arenas/_form_quick.html.erb** (modal).  
- 🔜 Próxima extensión a **referees**, **clubs**, **clans**, **tournaments**.  

---

## 🧭 Notas para desarrollo futuro
- Mantener el patrón de **IDs dinámicos** (`context_id`) en todos los formularios que usen SBSMI.  
- Reutilizar los métodos de `arena_location_controller.js` para nuevas entidades.  
- Ampliar la zona de collecting para soportar filtros más complejos (ej. disponibilidad, verificación).  
