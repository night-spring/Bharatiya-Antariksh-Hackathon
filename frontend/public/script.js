const map = L.map('map').setView([20.5937, 78.9629], 5); // Default view: India

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; OpenStreetMap contributors'
}).addTo(map);

let marker = null;

function searchPlace() {
  const place = document.getElementById('placeInput').value;

  if (!place) {
    alert("Please enter a place name.");
    return;
  }

  const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(place)}`;

  fetch(url)
    .then(res => res.json())
    .then(data => {
      if (data.length === 0) {
        alert('Place not found!');
        return;
      }
      const { lat, lon, display_name } = data[0];
      document.getElementById('lat').textContent = lat;
      document.getElementById('lon').textContent = lon;

      if (marker) {
        map.removeLayer(marker);
      }

      map.setView([lat, lon], 13);
      marker = L.marker([lat, lon]).addTo(map)
        .bindPopup(`<b>${display_name}</b><br>Lat: ${lat}<br>Lon: ${lon}`)
        .openPopup();
    })
    .catch(err => {
      console.error(err);
      alert('Error fetching location data.');
    });
}
