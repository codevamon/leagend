import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step1","step2","step3","country","city","neighborhood","address","lat","lng","map"]

  connect() {
    console.debug("[arena-location] connected")
    this.currentStep = 1
    this.map = null
    this.marker = null
    this.mbToken = document.querySelector("meta[name='mapbox-token']")?.content
    this.defaultCenter = [-74.072090, 4.710989] // Bogotá fallback [lng,lat]
    this.showStep(1)
  }

  showStep(n) {
    ;[this.step1Target, this.step2Target, this.step3Target].forEach((el,i)=>el.classList.toggle("d-none", i !== (n-1)))
    this.currentStep = n
    if (n === 3) this.ensureMap()
  }

  nextFromCountry() {
    const country = this.countryTarget.value?.trim()
    if (!country) return
    this.tryGeocode(`country ${country}`, () => this.showStep(2))
  }

  nextFromCity() {
    const city = this.cityTarget.value?.trim()
    const country = this.countryTarget.value?.trim()
    if (!city || !country) return
    this.tryGeocode(`${city}, ${country}`, () => this.showStep(3))
  }

  backTo1(){ this.showStep(1) }
  backTo2(){ this.showStep(2) }

  closeModal() {
    // Cierra el modal removiendo el turbo-frame
    const frame = document.getElementById('arena_quick_new')
    if (frame) {
      frame.remove()
    }
  }

  ensureMap() {
    if (this.map || !window.mapboxgl) return
    const lat = parseFloat(this.latTarget.value || this.defaultCenter[1])
    const lng = parseFloat(this.lngTarget.value || this.defaultCenter[0])
    this.map = new mapboxgl.Map({
      container: this.mapTarget,
      style: "mapbox://styles/mapbox/streets-v11",
      center: [lng, lat],
      zoom: 13,
      accessToken: this.mbToken
    })
    this.marker = new mapboxgl.Marker({ draggable: true }).setLngLat([lng, lat]).addTo(this.map)
    this.marker.on("dragend", () => {
      const { lat, lng } = this.marker.getLngLat()
      this.latTarget.value = lat
      this.lngTarget.value = lng
    })
  }

  addressChanged() {
    const address = this.addressTarget.value?.trim()
    const city = this.cityTarget.value?.trim() || ""
    const country = this.countryTarget.value?.trim() || ""
    if (!address) return
    const query = `${address}, ${city}, ${country}`
    this.tryGeocode(query)
  }

  // Helpers
  tryGeocode(query, then = null) {
    const onDone = () => { if (then) then() }
    if (!this.mbToken) { // sin token → fallback
      const [lng, lat] = this.defaultCenter
      this.setCoords([lng, lat])
      onDone()
      return
    }
    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?access_token=${this.mbToken}&limit=1`
    fetch(url)
      .then(r => r.ok ? r.json() : Promise.reject(r.status))
      .then(data => {
        const center = data?.features?.[0]?.center || this.defaultCenter
        this.setCoords(center)
        if (this.map) { this.map.flyTo({ center, zoom: 15 }); this.marker?.setLngLat(center) }
        onDone()
      })
      .catch(() => { // fallo geocode → fallback y continuar
        this.setCoords(this.defaultCenter); onDone()
      })
  }

  setCoords(center) {
    const [lng, lat] = center
    this.latTarget.value = lat
    this.lngTarget.value = lng
  }
}
