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

      // Find all geometries inside the Philippines bounding box
      final phGeometries = <Map<String, dynamic>>[];

      for (var geometry in geometries) {
        try {
          var rawLat = geometry['coordinates'][1];
          var rawLon = geometry['coordinates'][0];
          double lat = rawLat is int ? rawLat.toDouble() : rawLat;
          double lon = rawLon is int ? rawLon.toDouble() : rawLon;

          if (lat >= 4 && lat <= 21 && lon >= 115 && lon <= 127) {
            phGeometries.add(geometry);
          }
        } catch (e) {
          // Ignore invalid coordinates
          continue;
        }
      }

      // Skip events with no geometry in PH
      if (phGeometries.isEmpty) continue;

      // Use the latest geometry inside PH (by date)
      phGeometries.sort(
        (a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
      );
      final latestPHGeometry = phGeometries.first;

      final dateString = latestPHGeometry['date'].toString();
      final date = dateString.split('T')[0];

      final lat = latestPHGeometry['coordinates'][1];
      final lon = latestPHGeometry['coordinates'][0];
      final location = "$lat, $lon";

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
