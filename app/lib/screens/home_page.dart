import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

const String openWeatherApiKey = 'YOUR_API_KEY_HERE';

class AqiDataPoint {
  final String stationId;
  final DateTime time;
  final double latitude;
  final double longitude;
  final int aqi;
  final String category;
  final String dominantPollutant;

  AqiDataPoint({
    required this.stationId,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.aqi,
    required this.category,
    required this.dominantPollutant,
  });

  factory AqiDataPoint.fromJson(Map<String, dynamic> json) {
    try {
      return AqiDataPoint(
        stationId: json['station_id']?.toString() ?? 'unknown',
        time:
            DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
        latitude:
            double.tryParse(json['latitude']?.toString().trim() ?? '0') ?? 0.0,
        longitude:
            double.tryParse(json['longitude']?.toString().trim() ?? '0') ?? 0.0,
        aqi: int.tryParse(json['aqi']?.toString() ?? '0') ?? 0,
        category: json['category']?.toString() ?? 'Unknown',
        dominantPollutant: json['dominant_pollutant']?.toString() ?? 'unknown',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing AQI data point: $e');
      }
      return AqiDataPoint(
        stationId: 'error',
        time: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        aqi: 0,
        category: 'Unknown',
        dominantPollutant: 'unknown',
      );
    }
  }

  bool get isValid {
    return stationId != 'error' &&
        latitude != 0.0 &&
        longitude != 0.0 &&
        aqi > 0;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'India AQI Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
  final MapController _heatmapMapController = MapController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingAirData = false;
  bool _isLoadingApiData = false;
  List<Map<String, dynamic>> _forecastData = [];
  Map<String, double> _pollutionSources = {
    'traffic': 35,
    'factories': 60,
    'wildfires': 15,
  };

  // Dynamic AQI data from API
  List<AqiDataPoint> _apiAqiData = [];
  String _lastFetchTime = '';
  int _failedStations = 0;
  String _apiError = '';

// Highly detailed and accurate India boundary coordinates
  final List<LatLng> _indiaBoundary = [
    // Starting from Kashmir (Siachen Glacier) and going clockwise
    const LatLng(35.869140, 76.513672), // Siachen Glacier (northernmost point)
    const LatLng(35.664170, 76.923828), // Siachen-Karakoram
    const LatLng(35.460670, 77.695312), // Ladakh-China border
    const LatLng(35.173808, 78.222656), // Ladakh
    const LatLng(34.885931, 78.750000), // Ladakh-China border
    const LatLng(34.379713, 79.101562), // Ladakh-China border
    const LatLng(33.943360, 78.925781), // Ladakh
    const LatLng(33.578015, 78.574219), // Ladakh-China border
    const LatLng(33.284620, 78.925781), // Ladakh
    const LatLng(32.842674, 78.662109), // Himachal-Tibet border
    const LatLng(32.324276, 78.486328), // Himachal-Tibet border
    const LatLng(31.728167, 78.662109), // Uttarakhand-Tibet border
    const LatLng(31.203405, 79.013672), // Uttarakhand-Tibet border
    const LatLng(30.600094, 79.716797), // Uttarakhand-Nepal border
    const LatLng(30.088108, 80.419922), // Nepal border
    const LatLng(29.535230, 81.123047), // Nepal border
    const LatLng(28.921631, 82.001953), // Nepal border
    const LatLng(28.304381, 82.968750), // Nepal border
    const LatLng(27.683528, 83.671875), // Nepal-Sikkim border
    const LatLng(27.371767, 84.199219), // Sikkim-Nepal border
    const LatLng(27.059126, 84.726562), // Sikkim
    const LatLng(26.902477, 85.253906), // Sikkim-Nepal border
    const LatLng(26.824071, 85.781250), // Sikkim
    const LatLng(26.824071, 86.484375), // Sikkim-Bhutan border
    const LatLng(26.902477, 87.187500), // Sikkim-Bhutan border
    const LatLng(27.059126, 87.890625), // West Bengal-Bhutan border
    const LatLng(27.215556, 88.593750), // West Bengal-Bhutan border
    const LatLng(27.371767, 89.121094), // West Bengal-Bhutan border
    const LatLng(27.449790, 89.648438), // Assam-Bhutan border
    const LatLng(27.371767, 90.175781), // Assam-Bhutan border
    const LatLng(27.215556, 90.703125), // Assam-Bhutan border
    const LatLng(27.137368, 91.230469), // Assam
    const LatLng(27.215556, 91.757812), // Assam-Bhutan border
    const LatLng(27.371767, 92.285156), // Assam
    const LatLng(27.527758, 92.812500), // Arunachal Pradesh-Bhutan border
    const LatLng(27.761329, 93.339844), // Arunachal Pradesh
    const LatLng(28.071980, 93.867188), // Arunachal Pradesh-China border
    const LatLng(28.304381, 94.394531), // Arunachal Pradesh-China border
    const LatLng(28.459033, 94.921875), // Arunachal Pradesh-China border
    const LatLng(28.536275, 95.449219), // Arunachal Pradesh-China border
    const LatLng(28.613459, 95.976562), // Arunachal Pradesh-China border
    const LatLng(28.536275, 96.503906), // Arunachal Pradesh-China border
    const LatLng(28.304381, 97.031250), // Arunachal Pradesh-Myanmar border
    const LatLng(27.994401, 97.382812), // Arunachal Pradesh-Myanmar border
    const LatLng(27.683528, 97.558594), // Arunachal Pradesh-Myanmar border
    const LatLng(27.371767, 97.734375), // Nagaland-Myanmar border
    const LatLng(26.902477, 97.734375), // Nagaland-Myanmar border
    const LatLng(26.431228, 97.558594), // Nagaland-Myanmar border
    const LatLng(25.958045, 97.382812), // Manipur-Myanmar border
    const LatLng(25.482951, 97.207031), // Manipur-Myanmar border
    const LatLng(25.005973, 96.855469), // Manipur-Myanmar border
    const LatLng(24.527135, 96.503906), // Manipur-Myanmar border
    const LatLng(24.046464, 95.976562), // Manipur-Myanmar border
    const LatLng(23.563987, 95.449219), // Mizoram-Myanmar border
    const LatLng(23.079732, 94.921875), // Mizoram-Myanmar border
    const LatLng(22.593726, 94.394531), // Mizoram-Myanmar border
    const LatLng(22.105999, 93.867188), // Mizoram-Myanmar border
    const LatLng(21.616579, 93.339844), // Mizoram-Myanmar border
    const LatLng(21.289374, 92.988281), // Mizoram-Bangladesh border
    const LatLng(21.125498, 92.636719), // Tripura-Bangladesh border
    const LatLng(21.043491, 92.285156), // Tripura-Bangladesh border
    const LatLng(21.125498, 91.933594), // Tripura-Bangladesh border
    const LatLng(21.289374, 91.582031), // Tripura-Bangladesh border
    const LatLng(21.534847, 91.230469), // Bangladesh border
    const LatLng(21.861499, 90.878906), // Bangladesh border
    const LatLng(22.187405, 90.527344), // Bangladesh-West Bengal border
    const LatLng(22.512557, 90.175781), // Bangladesh-West Bengal border
    const LatLng(22.836946, 89.824219), // Bangladesh-West Bengal border
    const LatLng(23.160563, 89.472656), // Bangladesh-West Bengal border
    const LatLng(23.483401, 89.121094), // Bangladesh-West Bengal border
    const LatLng(23.805450, 88.769531), // Bangladesh-West Bengal border
    const LatLng(24.126701, 88.417969), // Bangladesh-West Bengal border
    const LatLng(24.447150, 88.066406), // Bangladesh-West Bengal border
    const LatLng(24.766785, 87.714844), // Bangladesh-West Bengal border
    const LatLng(25.085599, 87.363281), // Bangladesh-West Bengal border
    const LatLng(25.403584, 87.011719), // Bangladesh-West Bengal border
    const LatLng(25.720735, 86.660156), // Bangladesh-West Bengal border
    const LatLng(26.037042, 86.308594), // Bangladesh-West Bengal border
    const LatLng(26.352497, 85.957031), // Bangladesh-West Bengal border
    const LatLng(26.667096, 85.605469), // Bangladesh-West Bengal border
    const LatLng(26.824071, 85.253906), // Back to Sikkim area

    // Now going south along the eastern coast
    const LatLng(26.352497, 85.957031), // West Bengal
    const LatLng(25.958045, 86.484375), // West Bengal
    const LatLng(25.482951, 87.011719), // West Bengal
    const LatLng(25.005973, 87.539062), // West Bengal
    const LatLng(24.527135, 87.890625), // West Bengal
    const LatLng(24.046464, 88.242188), // West Bengal
    const LatLng(23.563987, 88.417969), // West Bengal
    const LatLng(23.079732, 88.593750), // West Bengal
    const LatLng(22.593726, 88.769531), // West Bengal
    const LatLng(22.105999, 88.769531), // West Bengal
    const LatLng(21.616579, 88.593750), // West Bengal-Odisha border
    const LatLng(21.125498, 88.417969), // Odisha
    const LatLng(20.632784, 88.242188), // Odisha
    const LatLng(20.138470, 87.890625), // Odisha coast
    const LatLng(19.642588, 87.539062), // Odisha coast
    const LatLng(19.145168, 87.187500), // Odisha coast
    const LatLng(18.646245, 86.835938), // Odisha coast
    const LatLng(18.145852, 86.484375), // Odisha coast
    const LatLng(17.644022, 86.132812), // Odisha-Andhra Pradesh coast
    const LatLng(17.140790, 85.781250), // Andhra Pradesh coast
    const LatLng(16.636192, 85.429688), // Andhra Pradesh coast
    const LatLng(16.130262, 85.078125), // Andhra Pradesh coast
    const LatLng(15.623037, 84.726562), // Andhra Pradesh coast
    const LatLng(15.114553, 84.375000), // Andhra Pradesh coast
    const LatLng(14.604847, 84.023438), // Andhra Pradesh coast
    const LatLng(14.093957, 83.671875), // Andhra Pradesh coast
    const LatLng(13.581921, 83.320312), // Andhra Pradesh coast
    const LatLng(13.068777, 82.968750), // Andhra Pradesh coast
    const LatLng(12.554564, 82.617188), // Tamil Nadu coast
    const LatLng(12.039321, 82.265625), // Tamil Nadu coast
    const LatLng(11.523088, 81.914062), // Tamil Nadu coast
    const LatLng(11.005904, 81.562500), // Tamil Nadu coast
    const LatLng(10.487812, 81.210938), // Tamil Nadu coast
    const LatLng(9.968851, 80.859375), // Tamil Nadu coast
    const LatLng(9.449062, 80.507812), // Tamil Nadu coast
    const LatLng(8.928487, 80.156250), // Tamil Nadu coast
    const LatLng(8.407168, 79.804688), // Tamil Nadu-Kerala coast

    // Southern tip and western coast
    const LatLng(8.059230, 77.695312), // Kerala coast (Kanyakumari area)
    const LatLng(8.233237, 77.167969), // Kerala coast
    const LatLng(8.581021, 76.640625), // Kerala coast
    const LatLng(8.928487, 76.113281), // Kerala coast
    const LatLng(9.275622, 75.585938), // Kerala coast
    const LatLng(9.622414, 75.058594), // Kerala coast
    const LatLng(9.968851, 74.531250), // Kerala-Karnataka coast
    const LatLng(10.314919, 74.179688), // Karnataka coast
    const LatLng(10.660608, 73.828125), // Karnataka coast
    const LatLng(11.005904, 73.476562), // Karnataka coast
    const LatLng(11.350797, 73.125000), // Karnataka coast
    const LatLng(11.695273, 72.773438), // Karnataka-Goa coast
    const LatLng(12.039321, 72.421875), // Goa coast
    const LatLng(12.382928, 72.070312), // Goa-Maharashtra coast
    const LatLng(12.726084, 71.718750), // Maharashtra coast
    const LatLng(13.068777, 71.367188), // Maharashtra coast
    const LatLng(13.581921, 71.191406), // Maharashtra coast
    const LatLng(14.093957, 71.015625), // Maharashtra coast
    const LatLng(14.604847, 70.839844), // Maharashtra coast
    const LatLng(15.114553, 70.664062), // Maharashtra coast
    const LatLng(15.623037, 70.488281), // Maharashtra coast
    const LatLng(16.130262, 70.312500), // Maharashtra coast
    const LatLng(16.636192, 70.136719), // Maharashtra coast
    const LatLng(17.140790, 69.960938), // Maharashtra coast
    const LatLng(17.644022, 69.785156), // Maharashtra-Gujarat coast
    const LatLng(18.145852, 69.609375), // Gujarat coast
    const LatLng(18.646245, 69.433594), // Gujarat coast
    const LatLng(19.145168, 69.257812), // Gujarat coast
    const LatLng(19.642588, 69.082031), // Gujarat coast
    const LatLng(20.138470, 68.906250), // Gujarat coast
    const LatLng(20.632784, 68.730469), // Gujarat coast
    const LatLng(21.125498, 68.554688), // Gujarat coast
    const LatLng(21.616579, 68.378906), // Gujarat coast
    const LatLng(22.105999, 68.203125), // Gujarat coast
    const LatLng(22.593726, 68.027344), // Gujarat coast (Rann of Kutch)
    const LatLng(
        23.079732, 68.203125), // Gujarat-Pakistan border (Rann of Kutch)
    const LatLng(23.563987, 68.378906), // Gujarat-Pakistan border
    const LatLng(24.046464, 68.554688), // Gujarat-Pakistan border
    const LatLng(24.527135, 68.730469), // Pakistan border
    const LatLng(25.005973, 69.082031), // Pakistan border
    const LatLng(25.482951, 69.433594), // Pakistan border
    const LatLng(25.958045, 69.785156), // Pakistan border
    const LatLng(26.431228, 70.136719), // Pakistan border
    const LatLng(26.902477, 70.488281), // Pakistan border
    const LatLng(27.371767, 70.839844), // Pakistan border
    const LatLng(27.839076, 71.191406), // Pakistan border
    const LatLng(28.304381, 71.542969), // Pakistan border
    const LatLng(28.767659, 71.894531), // Pakistan border
    const LatLng(29.228890, 72.246094), // Pakistan border
    const LatLng(29.688053, 72.597656), // Pakistan border
    const LatLng(30.145127, 72.949219), // Pakistan border
    const LatLng(30.600094, 73.300781), // Pakistan border
    const LatLng(31.052934, 73.652344), // Pakistan border
    const LatLng(31.503629, 74.003906), // Pakistan border
    const LatLng(31.952162, 74.355469), // Pakistan border
    const LatLng(32.398516, 74.707031), // Pakistan border
    const LatLng(32.842674, 75.058594), // Pakistan border
    const LatLng(33.284620, 75.410156), // Pakistan-Kashmir border
    const LatLng(33.724340, 75.761719), // Kashmir-Pakistan border
    const LatLng(34.161818, 76.113281), // Kashmir
    const LatLng(34.597042, 76.464844), // Kashmir
    const LatLng(35.029996, 76.816406), // Kashmir-Siachen
    const LatLng(35.460670, 77.167969), // Back towards Siachen
    const LatLng(35.869140, 76.513672), // Back to start (Siachen)
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchApiAqiData();
  }

  // Point-in-polygon algorithm to check if a point is inside India
  bool _isPointInIndia(LatLng point) {
    return _isPointInPolygon(point, _indiaBoundary);
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = polygon.length - 1, i = 0; i < polygon.length; j = i++) {
      if (((polygon[i].latitude <= point.latitude) &&
              (point.latitude < polygon[j].latitude)) ||
          ((polygon[j].latitude <= point.latitude) &&
              (point.latitude < polygon[i].latitude))) {
        if (point.longitude <
            (polygon[j].longitude - polygon[i].longitude) *
                    (point.latitude - polygon[i].latitude) /
                    (polygon[j].latitude - polygon[i].latitude) +
                polygon[i].longitude) {
          intersectCount++;
        }
      }
    }
    return (intersectCount % 2) == 1;
  }

  // Enhanced bounding box check for performance
  bool _isWithinIndiaBounds(LatLng point) {
    // First do a quick bounding box check
    if (point.latitude < 6.0 ||
        point.latitude > 37.6 ||
        point.longitude < 68.0 ||
        point.longitude > 97.5) {
      return false;
    }
    // Then do the precise polygon check
    return _isPointInIndia(point);
  }

  Future<void> _fetchApiAqiData() async {
    setState(() {
      _isLoadingApiData = true;
      _failedStations = 0;
      _apiError = '';
    });

    try {
      if (kDebugMode) {
        print('Fetching AQI data from API...');
      }
      final List<String> apiUrls = [
        'http://localhost:8080/api/aqidata',
        'http://127.0.0.1:8080/api/aqidata',
      ];

      http.Response? response;
      String? workingUrl;

      for (String url in apiUrls) {
        try {
          if (kDebugMode) {
            print('Trying API URL: $url');
          }
          response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type',
            },
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            workingUrl = url;
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to fetch from $url: $e');
          }
          continue;
        }
      }

      if (response == null || response.statusCode != 200) {
        throw Exception(
            'All API endpoints failed. Status: ${response?.statusCode ?? 'No response'}');
      }

      if (kDebugMode) {
        print('Successfully connected to: $workingUrl');
      }
      final dynamic responseBody = json.decode(response.body);

      if (responseBody is List) {
        List<AqiDataPoint> fetchedData = [];
        for (var item in responseBody) {
          try {
            if (item is Map<String, dynamic>) {
              AqiDataPoint dataPoint = AqiDataPoint.fromJson(item);
              // Only include data points that are within India's boundaries
              if (dataPoint.isValid &&
                  _isWithinIndiaBounds(
                      LatLng(dataPoint.latitude, dataPoint.longitude))) {
                fetchedData.add(dataPoint);
              } else if (dataPoint.isValid) {
                _failedStations++;
                if (kDebugMode) {
                  print(
                      'Data point outside India boundary: ${dataPoint.stationId} at ${dataPoint.latitude}, ${dataPoint.longitude}');
                }
              } else {
                _failedStations++;
                if (kDebugMode) {
                  print('Invalid data point: ${dataPoint.stationId}');
                }
              }
            }
          } catch (e) {
            _failedStations++;
            if (kDebugMode) {
              print('Error parsing individual data point: $e');
            }
          }
        }

        setState(() {
          _apiAqiData = fetchedData;
          _lastFetchTime = DateTime.now().toString().substring(0, 16);
          _apiError = '';
        });

        if (kDebugMode) {
          print(
              'Successfully fetched ${_apiAqiData.length} valid AQI data points within India');
        }
        if (kDebugMode) {
          print(
              'Filtered out $_failedStations stations (outside India or invalid)');
        }

        if (_currentLocation != null &&
            _isWithinIndiaBounds(_currentLocation!)) {
          setState(() {
            _currentAqi = _calculateInterpolatedAqi(_currentLocation!);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Successfully loaded ${_apiAqiData.length} monitoring stations within India'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('API response is not a list');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching AQI data: $e');
      }
      setState(() {
        _apiError = e.toString();
      });

      String errorMessage = 'Failed to fetch live data';
      if (e.toString().contains('CORS')) {
        errorMessage =
            'CORS Error: Please configure your API server to allow cross-origin requests';
      } else if (e.toString().contains('Failed to fetch')) {
        errorMessage =
            'Network Error: Cannot connect to API server. Is it running on localhost:8080?';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage =
            'Connection Error: API server is not responding on localhost:8080';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _fetchApiAqiData,
              textColor: Colors.white,
            ),
          ),
        );
      }

      if (_apiAqiData.isEmpty) {
        _loadSampleData();
      }
    } finally {
      setState(() {
        _isLoadingApiData = false;
      });
    }
  }

  void _loadSampleData() {
    if (kDebugMode) {
      print('Loading sample data as fallback...');
    }
    // Enhanced sample data covering more of India - all within boundaries
    List<AqiDataPoint> sampleData = [
      // North India
      AqiDataPoint(
          stationId: 'delhi-1',
          time: DateTime.now(),
          latitude: 28.6139,
          longitude: 77.2090,
          aqi: 306,
          category: 'Very Poor',
          dominantPollutant: 'co'),
      AqiDataPoint(
          stationId: 'delhi-2',
          time: DateTime.now(),
          latitude: 28.7041,
          longitude: 77.1025,
          aqi: 280,
          category: 'Poor',
          dominantPollutant: 'pm2.5'),
      AqiDataPoint(
          stationId: 'gurgaon',
          time: DateTime.now(),
          latitude: 28.4595,
          longitude: 77.0266,
          aqi: 320,
          category: 'Very Poor',
          dominantPollutant: 'co'),
      AqiDataPoint(
          stationId: 'noida',
          time: DateTime.now(),
          latitude: 28.5355,
          longitude: 77.3910,
          aqi: 290,
          category: 'Poor',
          dominantPollutant: 'pm10'),
      // West India
      AqiDataPoint(
          stationId: 'mumbai-1',
          time: DateTime.now(),
          latitude: 19.0760,
          longitude: 72.8777,
          aqi: 180,
          category: 'Moderate',
          dominantPollutant: 'pm2.5'),
      AqiDataPoint(
          stationId: 'mumbai-2',
          time: DateTime.now(),
          latitude: 19.0176,
          longitude: 72.8562,
          aqi: 165,
          category: 'Moderate',
          dominantPollutant: 'no2'),
      AqiDataPoint(
          stationId: 'pune',
          time: DateTime.now(),
          latitude: 18.5204,
          longitude: 73.8567,
          aqi: 140,
          category: 'Moderate',
          dominantPollutant: 'pm10'),
      AqiDataPoint(
          stationId: 'ahmedabad',
          time: DateTime.now(),
          latitude: 23.0225,
          longitude: 72.5714,
          aqi: 200,
          category: 'Moderate',
          dominantPollutant: 'co'),
      // South India
      AqiDataPoint(
          stationId: 'bangalore',
          time: DateTime.now(),
          latitude: 12.9716,
          longitude: 77.5946,
          aqi: 90,
          category: 'Satisfactory',
          dominantPollutant: 'no2'),
      AqiDataPoint(
          stationId: 'chennai',
          time: DateTime.now(),
          latitude: 13.0827,
          longitude: 80.2707,
          aqi: 120,
          category: 'Moderate',
          dominantPollutant: 'co'),
      AqiDataPoint(
          stationId: 'hyderabad',
          time: DateTime.now(),
          latitude: 17.3850,
          longitude: 78.4867,
          aqi: 110,
          category: 'Moderate',
          dominantPollutant: 'pm2.5'),
      AqiDataPoint(
          stationId: 'kochi',
          time: DateTime.now(),
          latitude: 9.9312,
          longitude: 76.2673,
          aqi: 60,
          category: 'Satisfactory',
          dominantPollutant: 'pm10'),
      // East India
      AqiDataPoint(
          stationId: 'kolkata',
          time: DateTime.now(),
          latitude: 22.5726,
          longitude: 88.3639,
          aqi: 250,
          category: 'Poor',
          dominantPollutant: 'so2'),
      AqiDataPoint(
          stationId: 'bhubaneswar',
          time: DateTime.now(),
          latitude: 20.2961,
          longitude: 85.8245,
          aqi: 85,
          category: 'Satisfactory',
          dominantPollutant: 'pm2.5'),
      // Central India
      AqiDataPoint(
          stationId: 'bhopal',
          time: DateTime.now(),
          latitude: 23.2599,
          longitude: 77.4126,
          aqi: 160,
          category: 'Moderate',
          dominantPollutant: 'co'),
      AqiDataPoint(
          stationId: 'nagpur',
          time: DateTime.now(),
          latitude: 21.1458,
          longitude: 79.0882,
          aqi: 130,
          category: 'Moderate',
          dominantPollutant: 'pm10'),
      // Northeast India
      AqiDataPoint(
          stationId: 'guwahati',
          time: DateTime.now(),
          latitude: 26.1445,
          longitude: 91.7362,
          aqi: 95,
          category: 'Satisfactory',
          dominantPollutant: 'no2'),
      // Additional points for better coverage
      AqiDataPoint(
          stationId: 'jaipur',
          time: DateTime.now(),
          latitude: 26.9124,
          longitude: 75.7873,
          aqi: 180,
          category: 'Moderate',
          dominantPollutant: 'pm2.5'),
      AqiDataPoint(
          stationId: 'lucknow',
          time: DateTime.now(),
          latitude: 26.8467,
          longitude: 80.9462,
          aqi: 220,
          category: 'Poor',
          dominantPollutant: 'co'),
      AqiDataPoint(
          stationId: 'patna',
          time: DateTime.now(),
          latitude: 25.5941,
          longitude: 85.1376,
          aqi: 240,
          category: 'Poor',
          dominantPollutant: 'pm10'),
    ];

    // Filter sample data to ensure all points are within India boundaries
    _apiAqiData = sampleData
        .where((dataPoint) => _isWithinIndiaBounds(
            LatLng(dataPoint.latitude, dataPoint.longitude)))
        .toList();

    setState(() {
      _lastFetchTime = 'Sample Data (India Only)';
    });
  }

  double _calculateInterpolatedAqi(LatLng point) {
    if (_apiAqiData.isEmpty || !_isWithinIndiaBounds(point)) return 100.0;

    List<MapEntry<AqiDataPoint, double>> distances = [];
    for (var dataPoint in _apiAqiData) {
      double distance = _calculateDistance(
        point,
        LatLng(dataPoint.latitude, dataPoint.longitude),
      );
      distances.add(MapEntry(dataPoint, distance));
    }

    distances.sort((a, b) => a.value.compareTo(b.value));

    if (distances.first.value < 0.01) {
      return distances.first.key.aqi.toDouble();
    }

    double weightedSum = 0.0;
    double weightSum = 0.0;
    int pointsToUse = math.min(12, distances.length);

    for (int i = 0; i < pointsToUse; i++) {
      double distance = distances[i].value;
      double weight = 1.0 / (math.pow(distance + 0.05, 2.5));
      weightedSum += distances[i].key.aqi * weight;
      weightSum += weight;
    }

    return weightSum > 0 ? weightedSum / weightSum : 100.0;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km
    double lat1Rad = point1.latitude * math.pi / 180;
    double lat2Rad = point2.latitude * math.pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    double deltaLon = (point2.longitude - point1.longitude) * math.pi / 180;

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

      // Check if current location is within India
      if (!_isWithinIndiaBounds(latLng)) {
        // If outside India, set to center of India
        setState(() {
          _currentLocation = const LatLng(20.5937, 78.9629); // Center of India
          _locationName = "Outside India - Showing India Center";
          _currentAqi = _calculateInterpolatedAqi(_currentLocation!);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your location is outside India. Showing data for India center.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _currentLocation = latLng;
          _currentAqi = _calculateInterpolatedAqi(latLng);
        });
      }

      await Future.wait([
        _reverseGeocode(_currentLocation!),
        _fetchAirPollutionData(_currentLocation!),
        _fetchForecastData(_currentLocation!),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Location error: $e');
      }
      setState(() {
        _locationName = "Location unavailable";
        _currentLocation = const LatLng(20.5937, 78.9629); // Center of India
        _currentAqi = _calculateInterpolatedAqi(_currentLocation!);
      });
    }
  }

  Future<void> _fetchAirPollutionData(LatLng latLng) async {
    setState(() {
      _isLoadingAirData = true;
    });

    if (openWeatherApiKey == 'YOUR_API_KEY_HERE') {
      setState(() {
        _currentAqi = _calculateInterpolatedAqi(latLng);
        _pollutionSources = {
          'traffic': 35.0 + (math.Random().nextDouble() * 30),
          'factories': 40.0 + (math.Random().nextDouble() * 40),
          'wildfires': 10.0 + (math.Random().nextDouble() * 20),
        };
      });
      setState(() {
        _isLoadingAirData = false;
      });
      return;
    }

    final url = Uri.parse(
      'http://api.openweathermap.org/data/2.5/air_pollution?'
      'lat=${latLng.latitude}&lon=${latLng.longitude}&appid=$openWeatherApiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data['list'] != null && data['list'].isNotEmpty) {
            final mainData = data['list'][0]['main'];
            final components = data['list'][0]['components'];
            _currentAqi = (mainData['aqi'] ?? 1) * 25.0;
            _pollutionSources = {
              'traffic': ((components['no2'] ?? 0) * 2.0).clamp(5.0, 95.0),
              'factories': ((components['so2'] ?? 0) * 5.0).clamp(5.0, 95.0),
              'wildfires': ((components['pm10'] ?? 0) * 0.8).clamp(5.0, 95.0),
            };
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching air pollution data: $e');
      }
      setState(() {
        _currentAqi = _calculateInterpolatedAqi(latLng);
      });
    } finally {
      setState(() {
        _isLoadingAirData = false;
      });
    }
  }

  Future<void> _fetchForecastData(LatLng latLng) async {
    if (openWeatherApiKey == 'YOUR_API_KEY_HERE') {
      setState(() {
        _forecastData = List.generate(4, (index) {
          return {
            'aqi': _currentAqi + (math.Random().nextDouble() * 40 - 20),
            'time': DateTime.now().add(Duration(hours: (index + 1) * 24)),
          };
        });
      });
      return;
    }

    final url = Uri.parse(
      'http://api.openweathermap.org/data/2.5/air_pollution/forecast?'
      'lat=${latLng.latitude}&lon=${latLng.longitude}&appid=$openWeatherApiKey',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          final forecast = data['list'].take(4).toList();
          setState(() {
            _forecastData = forecast.map((item) {
              return {
                'aqi': (item['main']['aqi'] ?? 1) * 25.0,
                'time': DateTime.fromMillisecondsSinceEpoch(
                    (item['dt'] ?? 0) * 1000),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching forecast data: $e');
      }
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=$query&countrycodes=in',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data
              .map((item) {
                double lat =
                    double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
                double lon =
                    double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;

                // Only include results within India
                if (_isWithinIndiaBounds(LatLng(lat, lon))) {
                  return {
                    'name': item['display_name'] ?? 'Unknown',
                    'lat': lat,
                    'lon': lon,
                  };
                }
                return null;
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Search error: $e');
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _handleLocationChange(LatLng latLng) async {
    // Check if the selected location is within India
    if (!_isWithinIndiaBounds(latLng)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Selected location is outside India. Please select a location within India.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _currentLocation = latLng;
      _currentAqi = _calculateInterpolatedAqi(latLng);
      _searchResults.clear();
      _searchController.clear();
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
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locationName = data['display_name'] ?? "Unknown location";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Reverse geocode error: $e');
      }
      setState(() {
        _locationName =
            "Location: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A043C),
      body: Stack(
        children: [
          _buildNebulaBackground(),
          if (_currentIndex == 0)
            _buildDashboardContent()
          else if (_currentIndex == 1)
            _buildMapContent()
          else
            _buildHeatmapContent(),
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
          _buildApiDataSummary(),
        ],
      ),
    );
  }

  Widget _buildApiDataSummary() {
    int goodStations = _apiAqiData.where((d) => d.aqi <= 50).length;
    int moderateStations =
        _apiAqiData.where((d) => d.aqi > 50 && d.aqi <= 100).length;
    int poorStations =
        _apiAqiData.where((d) => d.aqi > 100 && d.aqi <= 200).length;
    int veryPoorStations =
        _apiAqiData.where((d) => d.aqi > 200 && d.aqi <= 300).length;
    int severeStations = _apiAqiData.where((d) => d.aqi > 300).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.4 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.tealAccent.withAlpha((0.3 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, color: Colors.tealAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                "INDIA MONITORING STATIONS (${_apiAqiData.length})",
                style: const TextStyle(color: Colors.tealAccent, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchApiAqiData,
                child: _isLoadingApiData
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Colors.tealAccent,
                        size: 16,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_apiError.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "API Connection Issue",
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _apiError.contains('CORS')
                        ? "CORS Error: Configure your API server with proper headers"
                        : "Cannot connect to localhost:8080. Using sample data for India.",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_apiAqiData.isNotEmpty) ...[
            Text(
              "Last Update: $_lastFetchTime",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (_failedStations > 0)
              Text(
                "Filtered out: $_failedStations stations (outside India or invalid)",
                style: const TextStyle(color: Colors.orange, fontSize: 10),
              ),
            const SizedBox(height: 12),
            const Text(
              "Station Distribution:",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (goodStations > 0)
                  _buildStationStat(
                      "Good", goodStations, const Color(0xFF00B050)),
                if (moderateStations > 0)
                  _buildStationStat(
                      "Moderate", moderateStations, const Color(0xFF92D050)),
                if (poorStations > 0)
                  _buildStationStat(
                      "Poor", poorStations, const Color(0xFFFFFF00)),
                if (veryPoorStations > 0)
                  _buildStationStat(
                      "Very Poor", veryPoorStations, const Color(0xFFFF9900)),
                if (severeStations > 0)
                  _buildStationStat(
                      "Severe", severeStations, const Color(0xFFFF0000)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Recent Readings (Sample):",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _apiAqiData.take(15).map((data) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAqiColor(data.aqi.toDouble())
                        .withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAqiColor(data.aqi.toDouble()),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "${data.aqi}",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ] else
            const Text(
              "Loading live data for India...",
              style: TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildStationStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        "$label: $count",
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildMapContent() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation ?? const LatLng(20.5937, 78.9629),
            initialZoom: _currentLocation != null ? 13.0 : 5.0,
            onTap: (tapPosition, latLng) {
              _handleLocationChange(latLng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            // India boundary overlay
            PolygonLayer(
              polygons: [
                Polygon(
                  points: _indiaBoundary,
                  color: Colors.tealAccent.withAlpha((0.1 * 255).toInt()),
                  borderColor: Colors.tealAccent,
                  borderStrokeWidth: 2.0,
                ),
              ],
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

  Widget _buildHeatmapContent() {
    return Stack(
      children: [
        _buildNebulaBackground(),
        FlutterMap(
          mapController: _heatmapMapController,
          options: MapOptions(
            initialCenter: const LatLng(22.0, 79.0),
            initialZoom: 5.0,
            onTap: (tapPosition, latLng) {
              _handleHeatmapTap(latLng);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            // India boundary
            PolygonLayer(
              polygons: [
                Polygon(
                  points: _indiaBoundary,
                  color: Colors.transparent,
                  borderColor: Colors.tealAccent.withAlpha((0.8 * 255).toInt()),
                  borderStrokeWidth: 2.0,
                ),
              ],
            ),
            // Smooth gradient overlay only within India
            _buildSmoothGradientOverlay(),
            // All API data points as clickable markers
            MarkerLayer(
              markers: _apiAqiData.map((dataPoint) {
                return Marker(
                  point: LatLng(dataPoint.latitude, dataPoint.longitude),
                  width: 24,
                  height: 24,
                  child: GestureDetector(
                    onTap: () => _showApiDataDetails(dataPoint),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAqiColor(dataPoint.aqi.toDouble()),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _getAqiColor(dataPoint.aqi.toDouble())
                                .withAlpha((0.8 * 255).toInt()),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          dataPoint.aqi > 999
                              ? "999+"
                              : dataPoint.aqi.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: _buildHeatmapHeader(),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildHeatmapLegend(),
        ),
      ],
    );
  }

  Widget _buildSmoothGradientOverlay() {
    List<Marker> gradientMarkers = [];

    // Create a dense grid for smooth gradient effect, but only within India
    for (double lat = 6.0; lat <= 37.6; lat += 0.8) {
      for (double lon = 68.0; lon <= 97.5; lon += 0.8) {
        LatLng point = LatLng(lat, lon);
        // Only add points within India bounds
        if (_isWithinIndiaBounds(point)) {
          double interpolatedAqi = _calculateInterpolatedAqi(point);
          Color aqiColor = _getAqiColor(interpolatedAqi);
          gradientMarkers.add(
            Marker(
              point: point,
              width: 60,
              height: 60,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: aqiColor.withAlpha((0.15 * 255).toInt()),
                ),
              ),
            ),
          );
        }
      }
    }
    return MarkerLayer(markers: gradientMarkers);
  }

  Widget _buildHeatmapHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.7 * 255).toInt()),
        borderRadius: BorderRadius.circular(15),
        border:
            Border.all(color: Colors.tealAccent.withAlpha((0.5 * 255).toInt())),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Colors.tealAccent),
              const SizedBox(width: 8),
              const Text(
                "INDIA AQI HEATMAP",
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoadingApiData)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Live stations: ${_apiAqiData.length} • Tap stations for details • India boundary enforced",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (_failedStations > 0)
            Text(
              "Note: $_failedStations stations outside India were filtered out",
              style: const TextStyle(color: Colors.orange, fontSize: 10),
            ),
        ],
      ),
    );
  }

  void _handleHeatmapTap(LatLng latLng) {
    if (_isWithinIndiaBounds(latLng)) {
      double interpolatedAqi = _calculateInterpolatedAqi(latLng);
      _showInterpolatedAqiDetails(latLng, interpolatedAqi);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Selected location is outside India. No AQI data available.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showApiDataDetails(AqiDataPoint dataPoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withAlpha((0.9 * 255).toInt()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.tealAccent),
        ),
        title: const Row(
          children: [
            Icon(Icons.sensors, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              "Live Station Data",
              style: TextStyle(color: Colors.tealAccent),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AQI: ${dataPoint.aqi}",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _getAqiColor(dataPoint.aqi.toDouble()),
              ),
            ),
            Text(
              dataPoint.category,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                "Station ID",
                dataPoint.stationId.length > 12
                    ? "${dataPoint.stationId.substring(0, 12)}..."
                    : dataPoint.stationId),
            _buildDetailRow("Location",
                "${dataPoint.latitude.toStringAsFixed(4)}, ${dataPoint.longitude.toStringAsFixed(4)}"),
            _buildDetailRow("Dominant Pollutant",
                dataPoint.dominantPollutant.toUpperCase()),
            _buildDetailRow(
                "Last Updated", dataPoint.time.toString().substring(0, 16)),
            const SizedBox(height: 16),
            Text(
              _getHealthImpact(dataPoint.aqi.toDouble()),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLocationChange(
                  LatLng(dataPoint.latitude, dataPoint.longitude));
            },
            child: const Text(
              "GO TO LOCATION",
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showInterpolatedAqiDetails(LatLng latLng, double aqi) {
    List<AqiDataPoint> closestStations = List.from(_apiAqiData);
    closestStations.sort((a, b) {
      double distA =
          _calculateDistance(latLng, LatLng(a.latitude, a.longitude));
      double distB =
          _calculateDistance(latLng, LatLng(b.latitude, b.longitude));
      return distA.compareTo(distB);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withAlpha((0.9 * 255).toInt()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.tealAccent),
        ),
        title: const Row(
          children: [
            Icon(Icons.calculate, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              "Estimated AQI (India)",
              style: TextStyle(color: Colors.tealAccent),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AQI: ${aqi.round()}",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _getAqiColor(aqi),
              ),
            ),
            Text(
              _getAqiStatus(aqi),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow("Location",
                "${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}"),
            _buildDetailRow("Calculation",
                "Interpolated from ${math.min(12, _apiAqiData.length)} nearest stations in India"),
            const SizedBox(height: 12),
            if (closestStations.isNotEmpty) ...[
              const Text(
                "Nearest Stations:",
                style: TextStyle(
                    color: Colors.tealAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...closestStations.take(3).map((station) {
                double distance = _calculateDistance(
                    latLng, LatLng(station.latitude, station.longitude));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    "• AQI ${station.aqi} (${distance.toStringAsFixed(1)} km away)",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            Text(
              _getHealthImpact(aqi),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLocationChange(latLng);
            },
            child: const Text(
              "SET AS CURRENT",
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNebulaBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A043C), Color(0xFF021C3A), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomPaint(
          painter: NebulaBackgroundPainter(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CURRENT LOCATION (INDIA)",
                  style: TextStyle(
                    color: Colors.tealAccent.withAlpha((0.8 * 255).toInt()),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchApiAqiData,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.tealAccent.withAlpha((0.3 * 255).toInt()),
              child: _isLoadingApiData
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.tealAccent,
                    )
                  : const Icon(
                      Icons.refresh,
                      color: Colors.tealAccent,
                      size: 24,
                    ),
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
                        color: planetColor.withAlpha((0.6 * 255).toInt()),
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
                        planetColor.withAlpha((0.9 * 255).toInt()),
                        planetColor.withAlpha((0.4 * 255).toInt()),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: planetColor.withAlpha((0.7 * 255).toInt()),
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
        color: Colors.black.withAlpha((0.4 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.tealAccent.withAlpha((0.3 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withAlpha((0.05 * 255).toInt()),
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
    final spots = _forecastData.isNotEmpty
        ? _forecastData.asMap().entries.map((entry) {
            return FlSpot(
                entry.key.toDouble(), entry.value['aqi']?.toDouble() ?? 0.0);
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
        color: Colors.black.withAlpha((0.4 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.tealAccent.withAlpha((0.3 * 255).toInt())),
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
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
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
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.tealAccent.withAlpha((0.3 * 255).toInt()),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Now", style: TextStyle(color: Colors.white70)),
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
        color: Colors.black.withAlpha((0.4 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.tealAccent.withAlpha((0.3 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.tealAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "HEALTH ADVISORY",
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

  Widget _buildMapSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.7 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.tealAccent.withAlpha((0.5 * 255).toInt())),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location in India...',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              if (value.length > 2) {
                _searchPlace(value);
              } else {
                setState(() {
                  _searchResults.clear();
                });
              }
            },
          ),
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.8 * 255).toInt()),
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
                      location['name'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading:
                        const Icon(Icons.location_on, color: Colors.tealAccent),
                    onTap: () => _handleLocationChange(
                      LatLng(location['lat'] ?? 0.0, location['lon'] ?? 0.0),
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
      color: Colors.black.withAlpha((0.7 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side:
            BorderSide(color: Colors.tealAccent.withAlpha((0.5 * 255).toInt())),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.air, color: Colors.tealAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  'AQI: ${_currentAqi.round()} (${_getAqiStatus(_currentAqi)})',
                  style: TextStyle(
                    color: _getAqiColor(_currentAqi),
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildHeatmapLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.8 * 255).toInt()),
        borderRadius: BorderRadius.circular(15),
        border:
            Border.all(color: Colors.tealAccent.withAlpha((0.3 * 255).toInt())),
      ),
      child: Column(
        children: [
          const Text(
            "INDIA AQI SCALE",
            style: TextStyle(color: Colors.tealAccent, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 5,
            children: [
              _buildLegendItem("0-50", "Good", const Color(0xFF00B050)),
              _buildLegendItem(
                  "51-100", "Satisfactory", const Color(0xFF92D050)),
              _buildLegendItem("101-200", "Moderate", const Color(0xFFFFFF00)),
              _buildLegendItem("201-300", "Poor", const Color(0xFFFF9900)),
              _buildLegendItem("301-400", "Very Poor", const Color(0xFFFF0000)),
              _buildLegendItem("401-500", "Severe", const Color(0xFFC00000)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.tealAccent,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                "Live Station",
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withAlpha((0.6 * 255).toInt()),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                "India Boundary",
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String range, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.7 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$range: $label",
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildSpaceNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A043C).withAlpha((0.95 * 255).toInt()),
            const Color(0xFF03506F).withAlpha((0.95 * 255).toInt()),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withAlpha((0.2 * 255).toInt()),
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
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'India Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.whatshot), label: 'India Heatmap'),
        ],
      ),
    );
  }

  Color _getAqiColor(double aqi) {
    if (aqi < 50) return const Color(0xFF00B050);
    if (aqi < 100) return const Color(0xFF92D050);
    if (aqi < 200) return const Color(0xFFFFFF00);
    if (aqi < 300) return const Color(0xFFFF9900);
    if (aqi < 400) return const Color(0xFFFF0000);
    return const Color(0xFFC00000);
  }

  String _getAqiStatus(double aqi) {
    if (aqi < 50) return "GOOD";
    if (aqi < 100) return "SATISFACTORY";
    if (aqi < 200) return "MODERATE";
    if (aqi < 300) return "POOR";
    if (aqi < 400) return "VERY POOR";
    return "SEVERE";
  }

  String _getHealthImpact(double aqi) {
    if (aqi < 50) return "Minimal health impact";
    if (aqi < 100) return "Minor breathing discomfort to sensitive people";
    if (aqi < 200) {
      return "Breathing discomfort to people with lung/heart conditions";
    }
    if (aqi < 300) {
      return "Breathing discomfort to most people on prolonged exposure";
    }
    if (aqi < 400) return "Respiratory illness on prolonged exposure";
    return "Affects healthy people and seriously impacts those with existing diseases";
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
                  Expanded(
                    child: Text(tip,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class NebulaBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.tealAccent.withAlpha(25), // 0.1 * 255
          Colors.purple.withAlpha(12), // 0.05 * 255
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.1), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
