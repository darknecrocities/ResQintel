import 'dart:async';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _loadingSchools = false;
  String _statusMessage = "Getting location...";
  Map<String, dynamic>? _selectedSchool;
  double? _distanceToSchool;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationAndLoad();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndLoad() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() => _statusMessage = "Location permission denied.");
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _statusMessage = "Loading evacuation sites...";
        _loadingSchools = true;
      });
      await _loadExcelInIsolate();
    } catch (e) {
      setState(() => _statusMessage = "Failed to get location: $e");
    }
  }

  Future<void> _loadExcelInIsolate() async {
    try {
      final bytes = await rootBundle.load('lib/data/publicschool.xlsx');
      final result = await compute(_parseExcelRows, bytes.buffer.asUint8List());

      final nearby = result.where((school) {
        return _currentLocation != null &&
            _isNearby(_currentLocation!, school['lat'], school['lng'], 30000);
      }).toList();

      final tempMarkers = <Marker>{};

      for (var s in nearby) {
        final school = Map<String, dynamic>.from(
          s,
        ); // Create new scoped reference
        final LatLng pos = LatLng(school['lat'], school['lng']);
        tempMarkers.add(
          Marker(
            markerId: MarkerId(school['name']),
            position: pos,
            infoWindow: InfoWindow(
              title: school['name'],
              snippet: school['vicinity'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            onTap: () => _showSchoolSheet(school),
          ),
        );
      }

      setState(() {
        _markers = tempMarkers;
        _loadingSchools = false;
        _statusMessage = "Tap a marker to view evacuation site info.";
      });
    } catch (e) {
      setState(() {
        _loadingSchools = false;
        _statusMessage = "Failed to load sites: $e";
      });
    }
  }

  static List<Map<String, dynamic>> _parseExcelRows(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows;
    final header = rows.first;

    int idx(String col) =>
        header.indexWhere((c) => c?.value.toString().trim() == col);

    final idxName = idx('name');
    final idxLat = idx('latitude');
    final idxLng = idx('longitude');
    final idxRegion = idx('addr:region');
    final idxProv = idx('addr:province');
    final idxCity = idx('addr:city');
    final idxTown = idx('addr:town');

    if ([idxName, idxLat, idxLng].contains(-1)) return [];

    final List<Map<String, dynamic>> list = [];

    for (var row in rows.skip(1)) {
      if (row.length < idxLng + 1) continue;

      final name = row[idxName]?.value.toString();
      final lat = double.tryParse(row[idxLat]?.value.toString() ?? '');
      final lng = double.tryParse(row[idxLng]?.value.toString() ?? '');
      final region = row[idxRegion]?.value.toString() ?? '';
      final prov = row[idxProv]?.value.toString() ?? '';
      final city = row[idxCity]?.value.toString() ?? '';
      final town = row[idxTown]?.value.toString() ?? '';

      if (name == null || lat == null || lng == null) continue;

      list.add({
        'name': name,
        'lat': lat,
        'lng': lng,
        'vicinity': "$region, $prov, ${city.isNotEmpty ? city : town}",
      });
    }

    return list;
  }

  bool _isNearby(LatLng user, double lat, double lng, double radius) {
    final d = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      lat,
      lng,
    );
    return d <= radius;
  }

  void _showSchoolSheet(Map<String, dynamic> school) {
    _selectedSchool = school;
    _startDistanceTracking(school['lat'], school['lng']);

    final LatLng pos = LatLng(school['lat'], school['lng']);
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 14));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            _positionStream?.onData((position) {
              final user = LatLng(position.latitude, position.longitude);
              final dist = Geolocator.distanceBetween(
                user.latitude,
                user.longitude,
                school['lat'],
                school['lng'],
              );
              setSheetState(() => _distanceToSchool = dist);
            });

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, controller) => Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  controller: controller,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.school, size: 32, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            school['name'] ?? 'Unknown School',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          size: 20,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            school['vicinity'] ?? "Address not available",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Distance from your location:",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _distanceToSchool == null
                                ? "Calculating..."
                                : _formatDistance(_distanceToSchool!),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _positionStream?.cancel();
                        _selectedSchool = null;
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _positionStream?.cancel();
      _distanceToSchool = null;
      _selectedSchool = null;
      setState(() {
        _statusMessage = "Tap a marker to view evacuation site info.";
      });
    });
  }

  void _startDistanceTracking(double lat, double lng) {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((_) {});
  }

  String _formatDistance(double m) => m >= 1000
      ? "${(m / 1000).toStringAsFixed(2)} km"
      : "${m.toStringAsFixed(0)} m";

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        centerTitle: true,
        elevation: 3,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Evacuation Map",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: _loadingSchools
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(14.5995, 120.9842),
                    zoom: 12,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
