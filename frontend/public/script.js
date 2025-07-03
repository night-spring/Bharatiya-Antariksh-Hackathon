  const map = L.map('map').setView([20.5937, 78.9629], 3);
  
  let currentTheme = 'dark';
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 19
  }).addTo(map);

  let marker = null;
  let circle = null;

  const themeToggle = document.getElementById('themeToggle');
  const body = document.body;
  
  themeToggle.addEventListener('click', () => {
    if (body.classList.contains('light-mode')) {
      body.classList.remove('light-mode');
      body.classList.add('dark-mode');
      themeToggle.innerHTML = '<i class="fas fa-moon"></i>';
      updateMapTiles('dark');
      currentTheme = 'dark';
    } else {
      body.classList.remove('dark-mode');
      body.classList.add('light-mode');
      themeToggle.innerHTML = '<i class="fas fa-sun"></i>';
      updateMapTiles('light');
      currentTheme = 'light';
    }
  });

  function updateMapTiles(theme) {
    map.eachLayer(layer => {
      if (layer instanceof L.TileLayer) {
        map.removeLayer(layer);
      }
    });
    
    if (theme === 'dark') {
      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 19
      }).addTo(map);
    } else {
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        maxZoom: 19
      }).addTo(map);
    }
    if (marker) {
      marker.addTo(map);
      if (circle) circle.addTo(map);
    }
  }

  map.on('click', function(e) {
    const { lat, lng } = e.latlng;
    updateCoordinates(lat, lng);
    updateMapMarker(lat, lng);
    reverseGeocode(lat, lng);
    showNotification(`Location selected at ${lat.toFixed(4)}, ${lng.toFixed(4)}`, 'success');
  });

  function searchPlace() {
    const place = document.getElementById('placeInput').value.trim();
    
    if (!place) {
      showNotification('Please enter a place name', 'error');
      return;
    }
    
    document.getElementById('loading').style.display = 'flex';
    
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(place)}`;
    
    fetch(url)
      .then(res => res.json())
      .then(data => {
        document.getElementById('loading').style.display = 'none';
        
        if (data.length === 0) {
          showNotification('Place not found! Try another location.', 'error');
          return;
        }
        
        const { lat, lon, display_name, type } = data[0];
        updateCoordinates(lat, lon);
        updateMapMarker(lat, lon);
        updateLocationInfo(display_name, type);
        showNotification(`Location found: ${display_name}`, 'success');
      })
      .catch(err => {
        document.getElementById('loading').style.display = 'none';
        console.error(err);
        showNotification('Error fetching location data', 'error');
      });
  }
  
  function updateCoordinates(lat, lon) {
    document.getElementById('lat').textContent = parseFloat(lat).toFixed(6);
    document.getElementById('lon').textContent = parseFloat(lon).toFixed(6);
  }
  
  function updateMapMarker(lat, lon) {
    const latLng = [lat, lon];
    
    if (marker) map.removeLayer(marker);
    if (circle) map.removeLayer(circle);
    
    marker = L.marker(latLng, {
      icon: L.divIcon({
        html: '<div style="color: #4f46e5; font-size: 32px;"><i class="fas fa-map-pin"></i></div>',
        iconSize: [40, 40],
        className: 'pulse-icon',
        iconAnchor: [20, 40]
      })
    }).addTo(map);
    
    circle = L.circle(latLng, {
      color: '#6366f1',
      fillColor: '#6366f1',
      fillOpacity: 0.2,
      radius: 1000
    }).addTo(map);
    
    map.flyTo(latLng, 13, {
      animate: true,
      duration: 1.5
    });
    
    marker.bindPopup(`<b>Selected Location</b><br>Lat: ${lat}<br>Lon: ${lon}`).openPopup();
  }
  
  function updateLocationInfo(name, type) {
    document.querySelector('.location-name').textContent = name;
    document.querySelector('.location-type').textContent = type || 'Location';
  }
  
  function reverseGeocode(lat, lon) {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`;
    
    fetch(url)
      .then(res => res.json())
      .then(data => {
        if (data.display_name) {
          updateLocationInfo(data.display_name, data.type || data.category);
        }
      })
      .catch(err => {
        console.error('Reverse geocoding error:', err);
      });
  }
  
  function showNotification(message, type) {
    const notification = document.getElementById('notification');
    notification.innerHTML = `<i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'}"></i><span>${message}</span>`;
    notification.className = `notification ${type} show`;
    
    setTimeout(() => {
      notification.classList.remove('show');
    }, 3000);
  }
  
  function searchRecent(place) {
    document.getElementById('placeInput').value = place;
    searchPlace();
  }
  
  function locateUser() {
    if (!navigator.geolocation) {
      showNotification('Geolocation is not supported by your browser', 'error');
      return;
    }
    
    showNotification('Locating...', 'success');
    
    navigator.geolocation.getCurrentPosition(
      position => {
        const { latitude, longitude } = position.coords;
        updateCoordinates(latitude, longitude);
        updateMapMarker(latitude, longitude);
        reverseGeocode(latitude, longitude);
        showNotification('Your location found!', 'success');
      },
      error => {
        showNotification('Unable to retrieve your location', 'error');
      }
    );
  }
  
  function resetMap() {
    map.setView([20.5937, 78.9629], 3);
    if (marker) map.removeLayer(marker);
    if (circle) map.removeLayer(circle);
    document.getElementById('lat').textContent = '-';
    document.getElementById('lon').textContent = '-';
    document.querySelector('.location-name').textContent = 'Search for a location to see details';
    document.querySelector('.location-type').textContent = 'Location details will appear here';
    showNotification('Map view reset', 'success');
  }
  
  setTimeout(() => {
    searchRecent('Birati, Kolkata');
  }, 1000);