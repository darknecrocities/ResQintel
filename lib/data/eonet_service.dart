import 'dart:convert';

import 'package:http/http.dart' as http;

class EonetService {
  static Future<List<Map<String, dynamic>>> fetchPHEvents() async {
    final response = await http.get(
      Uri.parse('https://eonet.gsfc.nasa.gov/api/v3/events?status=open'),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load EONET data");
    }

    final data = jsonDecode(response.body);
    final events = data['events'] as List;

    final List<Map<String, dynamic>> phEvents = [];

    for (var event in events) {
      final categories = (event['categories'] as List)
          .map((c) => c['title'])
          .toList();

      final sources =
          event['sources']?[0]?['url'] ?? 'https://eonet.gsfc.nasa.gov/';
      final geometries = event['geometry'] as List;

      final latestGeometry = geometries.isNotEmpty ? geometries.last : null;

      if (latestGeometry == null) continue;

      // Safely convert coordinate values to double
      double lat;
      double lon;

      try {
        var rawLat = latestGeometry['coordinates'][1];
        var rawLon = latestGeometry['coordinates'][0];
        lat = rawLat is int ? rawLat.toDouble() : rawLat;
        lon = rawLon is int ? rawLon.toDouble() : rawLon;
      } catch (e) {
        continue; // skip if coordinates are invalid
      }

      // Check if coordinates are inside Philippines bounding box
      final bool inPhilippines =
          lat >= 4 && lat <= 21 && lon >= 115 && lon <= 127;

      if (!inPhilippines) continue;

      final location = "$lat, $lon";

      final dateString = latestGeometry['date'].toString();
      final date = dateString.split('T')[0];

      phEvents.add({
        'title': event['title'],
        'category': categories.join(', '),
        'location': location,
        'date': date,
        'dateTime': DateTime.tryParse(dateString) ?? DateTime(1970),
        'source': sources,
      });
    }

    // Sort events by dateTime descending (most recent first)
    phEvents.sort((a, b) => b['dateTime'].compareTo(a['dateTime']));

    return phEvents;
  }
}
