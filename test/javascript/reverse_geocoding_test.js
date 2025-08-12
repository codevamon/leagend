// Test simple para verificar la funcionalidad del reverse geocoding
// Este archivo puede ser ejecutado en el navegador para debug

console.log('=== Test de Reverse Geocoding ===');

// Verificar que las variables globales estén definidas
console.log('LEAGEND_USER_SIGNED_IN:', window.LEAGEND_USER_SIGNED_IN);
console.log('LEAGEND_USER_LAT:', window.LEAGEND_USER_LAT);
console.log('LEAGEND_USER_LNG:', window.LEAGEND_USER_LNG);

// Verificar que el span existe
const locationSpan = document.getElementById('leagend-header-location');
if (locationSpan) {
  console.log('Span encontrado:', locationSpan);
  console.log('Data attributes:', {
    city: locationSpan.dataset.city,
    country: locationSpan.dataset.country,
    lat: locationSpan.dataset.lat,
    lng: locationSpan.dataset.lng
  });
  console.log('Contenido actual:', locationSpan.textContent);
} else {
  console.log('Span NO encontrado');
}

// Verificar token de Mapbox
const mapboxToken = document.querySelector('meta[name="mapbox-token"]')?.content;
console.log('Token de Mapbox:', mapboxToken ? 'Presente' : 'NO encontrado');

// Verificar token de CSRF
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
console.log('Token de CSRF:', csrfToken ? 'Presente' : 'NO encontrado');

// Verificar localStorage
console.log('localStorage leagend.city:', localStorage.getItem('leagend.city'));
console.log('localStorage leagend.country:', localStorage.getItem('leagend.country'));

// Verificar sessionStorage
console.log('sessionStorage leagend.geo_revgeo_done:', sessionStorage.getItem('leagend.geo_revgeo_done'));

console.log('=== Fin del Test ===');
