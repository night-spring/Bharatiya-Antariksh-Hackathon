# 🌍 Atmospheric Quality Intelligence (AQI) Monitor

**A Space-Themed Air Quality Monitoring System for the Bharatiya Antariksh Hackathon**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://vercel.com)

## 🚀 Overview

The **Atmospheric Quality Intelligence (AQI) Monitor** is a comprehensive air quality monitoring solution developed for the Bharatiya Antariksh Hackathon. This project combines a space-themed Flutter mobile application with a robust Node.js backend to provide real-time air quality data across India using satellite-grade precision and government APIs.

### 🌟 Key Features

- **🛰️ Space-Themed UI**: Immersive space-inspired design with animated stars, nebula backgrounds, and cosmic aesthetics
- **📍 Real-Time Location Tracking**: GPS-based location services for precise air quality monitoring
- **🗺️ Interactive Maps**: Integration with Google Maps and Flutter Map for visual data representation
- **📊 Data Visualization**: Beautiful charts and graphs using FL Chart for AQI trends
- **🔔 Smart Notifications**: Local notifications for air quality alerts and updates
- **🌡️ Multi-Pollutant Monitoring**: Tracks PM2.5, PM10, NO2, SO2, CO, Ozone, and NH3 levels
- **📱 Cross-Platform**: Flutter app supporting Android, iOS, Web, Windows, macOS, and Linux
- **🌐 Web Interface**: Additional web-based GeoFinder tool for location discovery

## 🏗️ Architecture

### 📱 Frontend (Flutter App)
```
app/
├── lib/
│   ├── main.dart              # Entry point with space-themed splash screen
│   ├── screens/
│   │   └── home_page.dart     # Main dashboard with AQI data and maps
│   ├── models/               # Data models (to be implemented)
│   ├── services/             # API services (to be implemented)
│   ├── utils/                # Utility functions (to be implemented)
│   └── widgets/              # Reusable UI components (to be implemented)
├── assets/
│   ├── astronaut.webp        # Space-themed imagery
│   ├── India-map.svg         # Indian map visualization
│   └── logo.png              # App logo
└── pubspec.yaml              # Dependencies and project configuration
```

### 🖥️ Backend (Node.js API)
```
backend/
├── index.js                  # Express server with CORS and API endpoints
├── data.js                   # Government API data fetching
├── db.js                     # PostgreSQL database operations
├── aqiCalculator.js          # AQI calculation algorithms
├── connection.js             # Database connection management
├── package.json              # Node.js dependencies
└── vercel.json               # Deployment configuration
```



## 🛠️ Technology Stack

### Mobile Application
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Maps**: Google Maps Flutter, Flutter Map
- **Location**: Geolocator
- **Charts**: FL Chart
- **Animations**: Animated Text Kit, Shimmer
- **HTTP**: HTTP package for API calls
- **State Management**: Provider
- **Notifications**: Flutter Local Notifications

### Backend API
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Scheduler**: Node-Cron
- **Environment**: Dotenv
- **HTTP Client**: Node-Fetch
- **Deployment**: Vercel

### Data Sources
- **Government API**: data.gov.in AQI datasets
- **Weather API**: OpenWeather integration (configured)
- **Mapping**: Leaflet.js, Google Maps

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK (3.0 or higher)
- Node.js (16 or higher)
- PostgreSQL database
- Android Studio / Xcode (for mobile development)
- API keys for data.gov.in and OpenWeather

### 🚀 Quick Start

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/Bharatiya-Antariksh-Hackathon.git
cd Bharatiya-Antariksh-Hackathon
```

#### 2. Backend Setup
```bash
cd backend
npm install

# Create .env file
echo "AQI_API_KEY=your_data_gov_in_api_key" > .env
echo "DATABASE_URL=your_postgresql_connection_string" >> .env

# Start the server
npm start
```

#### 3. Flutter App Setup
```bash
cd app
flutter pub get

# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```


## 🔧 Configuration

### Environment Variables (.env)
```env
AQI_API_KEY=your_data_gov_in_api_key
DATABASE_URL=postgresql://user:password@localhost:5432/aqi_db
NODE_ENV=production
```

### Flutter Configuration
Update the API endpoint in the Flutter app:
```dart
// In lib/screens/home_page.dart
const String API_BASE_URL = 'https://your-api-domain.vercel.app';
```

### Database Schema
The PostgreSQL database includes tables for:
- `stations` - Air quality monitoring stations
- `pollutant_data` - Raw pollutant measurements
- `aqi_data` - Calculated AQI values with categories

## 📊 API Endpoints

### Base URL: `https://your-api-domain.vercel.app/api`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Server health check |
| `/aqidata` | GET | Retrieve all AQI data points |
| `/pollutants` | GET | Get pollutant measurements |
| `/stations` | GET | List monitoring stations |

### Sample API Response
```json
{
  "status": "success",
  "data": [
    {
      "station_id": "DELHI001",
      "time": "2025-07-10T12:00:00Z",
      "latitude": 28.6139,
      "longitude": 77.2090,
      "aqi": 156,
      "category": "Moderate",
      "dominant_pollutant": "PM2.5"
    }
  ]
}
```

## 🎨 Design Features

### Space Theme Elements
- **Cosmic Color Palette**: Deep space blues (#0A043C) with teal accents
- **Animated Stars**: Randomly positioned twinkling star field
- **Nebula Backgrounds**: SVG-based cosmic imagery
- **Astronaut Graphics**: Space exploration themed assets
- **Floating Animations**: Scale and opacity transitions
- **Cosmic Typography**: Animated text with space-grade terminology

### AQI Visualization
- **Color-Coded Categories**: 
  - 🟢 Good (0-50)
  - 🟡 Satisfactory (51-100)
  - 🟠 Moderate (101-200)
  - 🔴 Poor (201-300)
  - 🟣 Very Poor (301-400)
  - 🔴 Severe (400+)

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web (Modern browsers)
- ✅ Windows (Windows 10+)
- ✅ macOS (macOS 10.14+)
- ✅ Linux (Ubuntu 18.04+)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Use meaningful commit messages
- Add comments for complex algorithms
- Test on multiple platforms
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Hackathon Context

Developed for the **Bharatiya Antariksh Hackathon**, this project demonstrates:
- **Space Technology Integration**: Satellite-grade precision in air quality monitoring
- **Government Data Utilization**: Leveraging data.gov.in APIs
- **Cross-Platform Development**: Unified solution across all major platforms
- **Real-Time Monitoring**: Live data processing and visualization
- **User-Centric Design**: Intuitive space-themed interface

## 🌟 Future Enhancements

- [ ] Machine Learning predictions for AQI trends
- [ ] Satellite imagery integration
- [ ] Social sharing of air quality reports
- [ ] Health recommendations based on AQI levels
- [ ] Multiple language support
- [ ] Offline data caching
- [ ] Push notifications for severe pollution alerts
- [ ] Integration with wearable devices

## 👥 Team

- **Frontend Development**: Flutter mobile & web applications
- **Backend Development**: Node.js API and database management
- **UI/UX Design**: Space-themed interface design
- **Data Integration**: Government API integration and processing

## 📞 Support

For support, create an issue in the GitHub repository.

---

**🛰️ "Monitoring Earth's Atmosphere with Space-Grade Precision" 🛰️**

*Built with ❤️ for the Bharatiya Antariksh Hackathon*