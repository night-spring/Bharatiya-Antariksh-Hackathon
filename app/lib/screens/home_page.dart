import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final double _currentAqi = 84.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A043C),
      body: Stack(
        children: [
          _buildNebulaBackground(),
          SingleChildScrollView(
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
          ),
        ],
      ),
      bottomNavigationBar: _buildSpaceNavBar(),
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
          image: const DecorationImage(
            image: AssetImage('assets/nebula_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.15,
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
              const Text(
                "New Delhi, India",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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

    return Container(
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
              _buildSourceIcon(Icons.factory, "Factories", 35),
              _buildSourceIcon(Icons.directions_car, "Traffic", 60),
              _buildSourceIcon(Icons.fireplace, "Wildfires", 15),
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
                    spots: const [
                      FlSpot(0, 84),
                      FlSpot(1, 92),
                      FlSpot(2, 110),
                      FlSpot(3, 98),
                    ],
                    isCurved: true,
                    color: Colors.tealAccent,
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
            children: const [
              Text("Today", style: TextStyle(color: Colors.white70)),
              Text("+24h", style: TextStyle(color: Colors.white70)),
              Text("+48h", style: TextStyle(color: Colors.white70)),
              Text("+72h", style: TextStyle(color: Colors.white70)),
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
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Data'),
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
