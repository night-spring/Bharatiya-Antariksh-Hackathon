import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

const String openWeatherApiKey = 'YOUR_API_KEY_HERE';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  double _currentAqi = 84.0;
  LatLng? _currentLocation;
  String _locationName = "Searching...";
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingAirData = false;
  Map<String, dynamic> _airPollutionData = {};
  List<Map<String, dynamic>> _forecastData = [];
  Map<String, double> _pollutionSources = {
    'traffic': 35,
    'factories': 60,
    'wildfires': 15,
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
      });
      await Future.wait([
        _reverseGeocode(latLng),
        _fetchAirPollutionData(latLng),
        _fetchForecastData(latLng),
      ]);
    } catch (e) {
      setState(() {
        _locationName = "Location unavailable";
      });
    }
  }

  Future<void> _fetchAirPollutionData(LatLng latLng) async {
    setState(() {
      _isLoadingAirData = true;
    });

    final url = Uri.parse(
      'http://api.openweathermap.org/data/2.5/air_pollution?'
      'lat=${latLng.latitude}&lon=${latLng.longitude}&appid=$openWeatherApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _airPollutionData = data;
          if (data['list'] != null && data['list'].isNotEmpty) {
            final mainData = data['list'][0]['main'];
            final components = data['list'][0]['components'];
            _currentAqi = mainData['aqi'] * 25.0; // Convert 1-5 scale to 0-125

            // Calculate pollution sources
            _pollutionSources = {
              'traffic': (components['no2'] ?? 0) * 2.0,
              'factories': (components['so2'] ?? 0) * 5.0,
              'wildfires': (components['pm10'] ?? 0) * 0.8,
            };

            // Normalize values to sum to 100
            final total =
                _pollutionSources.values.fold(0.0, (sum, value) => sum + value);
            _pollutionSources = _pollutionSources.map((key, value) =>
                MapEntry(key, (value / total * 100).clamp(5, 95)));
          }
        });
      }
    } catch (e) {
      print('Error fetching air pollution data: $e');
    } finally {
      setState(() {
        _isLoadingAirData = false;
      });
    }
  }

  Future<void> _fetchForecastData(LatLng latLng) async {
    final url = Uri.parse(
      'http://api.openweathermap.org/data/2.5/air_pollution/forecast?'
      'lat=${latLng.latitude}&lon=${latLng.longitude}&appid=$openWeatherApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          // Get next 4 data points (0, 24, 48, 72 hours)
          final forecast = data['list'].take(4).toList();
          setState(() {
            _forecastData = forecast.map((item) {
              return {
                'aqi': item['main']['aqi'] * 25.0,
                'time': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching forecast data: $e');
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=$query',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            return {
              'name': item['display_name'],
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _handleLocationChange(LatLng latLng) async {
    setState(() {
      _currentLocation = latLng;
    });
    await Future.wait([
      _reverseGeocode(latLng),
      _fetchAirPollutionData(latLng),
      _fetchForecastData(latLng),
    ]);
    _mapController.move(latLng, 13.0);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locationName = data['display_name'] ?? "Unknown location";
        });
      }
    } catch (e) {
      print('Reverse geocode error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A043C),
      body: Stack(
        children: [
          _buildNebulaBackground(),
          _currentIndex == 0 ? _buildDashboardContent() : _buildMapContent(),
        ],
      ),
      bottomNavigationBar: _buildSpaceNavBar(),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildAppBar(),
          _buildAqiPlanet(),
          _buildPollutionSources(),
          _buildForecastTimeline(),
          _buildHealthAdvisory(),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentLocation ?? const LatLng(28.6139, 77.2090),
            zoom: _currentLocation != null ? 13.0 : 10.0,
            onTap: (tapPosition, latLng) {
              _handleLocationChange(latLng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: _buildMapSearchBar(),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _buildLocationCard(),
        ),
      ],
    );
  }

  Widget _buildMapSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.tealAccent),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              if (value.length > 2) {
                _searchPlace(value);
              }
            },
          ),
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    title: Text(
                      location['name'],
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading:
                        const Icon(Icons.location_on, color: Colors.tealAccent),
                    onTap: () => _handleLocationChange(
                      LatLng(location['lat'], location['lon']),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      color: Colors.black.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.tealAccent.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _locationName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (_currentLocation != null)
              Row(
                children: [
                  const Icon(Icons.location_pin,
                      color: Colors.tealAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            if (_isLoadingAirData)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: Colors.tealAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNebulaBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A043C), Color(0xFF021C3A), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "CURRENT LOCATION",
                style: TextStyle(
                  color: Colors.tealAccent.withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _locationName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.tealAccent.withOpacity(0.3),
            child: const CircleAvatar(
              backgroundImage: AssetImage("assets/astronaut.png"),
              radius: 24,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAqiPlanet() {
    Color planetColor = _getAqiColor(_currentAqi);

    return _isLoadingAirData
        ? const SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.tealAccent,
              ),
            ),
          )
        : Container(
            margin: const EdgeInsets.all(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: planetColor.withOpacity(0.6),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        planetColor.withOpacity(0.9),
                        planetColor.withOpacity(0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: planetColor.withOpacity(0.7),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentAqi.round().toString(),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black),
                          ],
                        ),
                      ),
                      Text(
                        _getAqiStatus(_currentAqi),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildPollutionSources() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.tealAccent.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "POLLUTION SOURCES NEARBY",
            style: TextStyle(color: Colors.tealAccent, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSourceIcon(Icons.factory, "Factories",
                  _pollutionSources['factories']?.round() ?? 35),
              _buildSourceIcon(Icons.directions_car, "Traffic",
                  _pollutionSources['traffic']?.round() ?? 60),
              _buildSourceIcon(Icons.fireplace, "Wildfires",
                  _pollutionSources['wildfires']?.round() ?? 15),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceIcon(IconData icon, String label, int intensity) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white),
            if (intensity > 30)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: Text(
                    intensity.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildForecastTimeline() {
    // Use forecast data if available, otherwise use default values
    final spots = _forecastData.isNotEmpty
        ? _forecastData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value['aqi']);
          }).toList()
        : const [
            FlSpot(0, 84),
            FlSpot(1, 92),
            FlSpot(2, 110),
            FlSpot(3, 98),
          ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "72-HOUR FORECAST",
            style: TextStyle(color: Colors.tealAccent, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 3,
                minY: 0,
                maxY: 150,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.tealAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.tealAccent.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(_forecastData.isNotEmpty ? "Now" : "Today",
                  style: const TextStyle(color: Colors.white70)),
              Text(_forecastData.isNotEmpty ? "+24h" : "+24h",
                  style: const TextStyle(color: Colors.white70)),
              Text(_forecastData.isNotEmpty ? "+48h" : "+48h",
                  style: const TextStyle(color: Colors.white70)),
              Text(_forecastData.isNotEmpty ? "+72h" : "+72h",
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAdvisory() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medical_services, color: Colors.tealAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "ASTRONAUT HEALTH ADVISORY",
                style: TextStyle(color: Colors.tealAccent, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._generateHealthTips(_currentAqi),
        ],
      ),
    );
  }

  Widget _buildSpaceNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A043C).withOpacity(0.95),
            const Color(0xFF03506F).withOpacity(0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white70,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Orbit Map'),
        ],
      ),
    );
  }

  Color _getAqiColor(double aqi) {
    if (aqi < 50) return Colors.green;
    if (aqi < 100) return Colors.yellow;
    if (aqi < 150) return Colors.orange;
    return Colors.red;
  }

  String _getAqiStatus(double aqi) {
    if (aqi < 50) return "GOOD";
    if (aqi < 100) return "MODERATE";
    if (aqi < 150) return "UNHEALTHY";
    return "HAZARDOUS";
  }

  List<Widget> _generateHealthTips(double aqi) {
    List<String> tips = [];
    if (aqi < 50) {
      tips = [
        "Safe for outdoor activities",
        "No mask required",
        "Ideal for exercise"
      ];
    } else if (aqi < 100) {
      tips = [
        "Sensitive groups: Limit outdoor exposure",
        "Consider N95 masks in crowded areas",
        "Close windows if near traffic"
      ];
    } else {
      tips = [
        "Avoid prolonged outdoor stays",
        "Wear N95 masks at all times",
        "Use air purifiers indoors",
        "Asthma patients: Keep inhalers ready"
      ];
    }
    return tips
        .map((tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.tealAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(tip, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ))
        .toList();
  }
}
