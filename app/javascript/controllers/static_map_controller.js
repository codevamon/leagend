import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { lat: Number, lng: Number, zoom: { type: Number, default: 14 } }

  connect() {
    if (!window.mapboxgl) { console.error("Mapbox GL no está cargado"); return; }
    const lat = Number(this.latValue);
    const lng = Number(this.lngValue);
    if (isNaN(lat) || isNaN(lng)) { console.warn("Coordenadas inválidas", { lat, lng }); return; }

    const tokenMeta = document.querySelector('meta[name="mapbox-token"]');
    if (tokenMeta) mapboxgl.accessToken = tokenMeta.content;

    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v11",
      center: [lng, lat], // ORDEN CORRECTO
      zoom: this.zoomValue
    });

    new mapboxgl.Marker().setLngLat([lng, lat]).addTo(this.map);
  }
}
