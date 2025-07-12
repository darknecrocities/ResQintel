import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  String city = "Fetching Location...";
  double? temperature;
  double? windspeed;
  String dangerLevel = "Unknown";
  String currentTime = "";
  int? weatherCode;
  String weatherDescription = "";
  bool isLoading = true;

  Map<String, String> descriptions = {}; // Loaded from JSON

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
    _controller.forward();
    loadDescriptions();
    fetchWeather();
  }

  Future<void> loadDescriptions() async {
    final String jsonStr = await rootBundle.loadString(
      'lib/assets/weather.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonStr);
    setState(() {
      descriptions = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    });
  }

  Future<String> getPlaceName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
      } else {
        return "Unknown location";
      }
    } catch (e) {
      return "Location error";
    }
  }

  String getWeatherDescription(int code) {
    if ([0].contains(code)) return "Clear Sky";
    if ([1, 2, 3].contains(code)) return "Cloudy";
    if ([45, 48].contains(code)) return "Foggy";
    if ([51, 53, 55].contains(code)) return "Drizzle";
    if ([61, 63, 65].contains(code)) return "Rainy";
    if ([66, 67].contains(code)) return "Freezing Rain";
    if ([71, 73, 75].contains(code)) return "Snowfall";
    if ([77].contains(code)) return "Snow Grains";
    if ([80, 81, 82].contains(code)) return "Rain Showers";
    if ([85, 86].contains(code)) return "Snow Showers";
    if ([95].contains(code)) return "Thunderstorm";
    if ([96, 99].contains(code)) return "Thunderstorm with Hail";
    return "Unknown";
  }

  Future<void> fetchWeather() async {
    LocationPermission hasPermission = await Geolocator.checkPermission();
    if (hasPermission == LocationPermission.denied ||
        hasPermission == LocationPermission.deniedForever) {
      hasPermission = await Geolocator.requestPermission();
      if (hasPermission != LocationPermission.always &&
          hasPermission != LocationPermission.whileInUse) {
        setState(() {
          city = "Location permission denied";
          isLoading = false;
        });
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    final lat = position.latitude;
    final lon = position.longitude;

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weather = data['current_weather'];

        weatherCode = weather['weathercode'];
        weatherDescription = getWeatherDescription(weatherCode ?? -1);

        final now = DateTime.parse(weather['time']).toLocal();
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        final formattedTime = formatter.format(now);

        final placeName = await getPlaceName(lat, lon);

        setState(() {
          temperature = weather['temperature'];
          windspeed = weather['windspeed'];
          city = placeName;
          currentTime = formattedTime;
          dangerLevel = _calculateDangerLevel(temperature!, windspeed!);
          isLoading = false;
        });
      } else {
        setState(() {
          city = "Failed to fetch weather data";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        city = "Error fetching weather data";
        isLoading = false;
      });
    }
  }

  String _calculateDangerLevel(double temp, double wind) {
    if (temp >= 40 || wind >= 50) {
      return "Extreme";
    } else if (temp >= 32 || wind >= 30) {
      return "High";
    } else {
      return "Safe";
    }
  }

  void showDescription(String title) {
    final description = descriptions[title] ?? "No description available.";
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () => showDescription(title),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Weather Status'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(Icons.cloud, size: 80, color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      title: "Your Location",
                      value: city,
                      icon: Icons.location_on,
                      color: Colors.red.shade50,
                    ),
                    _infoCard(
                      title: "Current Time",
                      value: currentTime,
                      icon: Icons.access_time,
                      color: Colors.red.shade50,
                    ),
                    _infoCard(
                      title: "Temperature",
                      value: "${temperature?.toStringAsFixed(1)} °C",
                      icon: Icons.thermostat,
                    ),
                    _infoCard(
                      title: "Wind Speed",
                      value: "${windspeed?.toStringAsFixed(1)} km/h",
                      icon: Icons.air,
                    ),
                    _infoCard(
                      title: "Condition",
                      value: weatherDescription,
                      icon: Icons.cloud_queue,
                    ),
                    _infoCard(
                      title: "Danger Level",
                      value: dangerLevel,
                      icon: Icons.warning,
                      color: dangerLevel == "Safe"
                          ? Colors.green.shade100
                          : (dangerLevel == "High"
                                ? Colors.orange.shade100
                                : Colors.red.shade100),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
