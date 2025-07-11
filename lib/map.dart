import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};

  // Expanded list of some public schools in PH (example only)
  final List<Map<String, dynamic>> allPublicSchools = [
    {'name': 'Manila High School', 'location': const LatLng(14.5894, 120.9810)},
    {'name': 'Tondo High School', 'location': const LatLng(14.6091, 120.9706)},
    {'name': 'Quezon City High School', 'location': const LatLng(14.6325, 121.0369)},
    {'name': 'Cebu City High School', 'location': const LatLng(10.3157, 123.8854)},
    {'name': 'Davao City High School', 'location': const LatLng(7.1907, 125.4553)},
    {'name': 'Baguio City High School', 'location': const LatLng(16.4023, 120.5960)},
    {'name': 'Zamboanga City High School', 'location': const LatLng(6.9214, 122.0790)},
    {'name': 'Iloilo City High School', 'location': const LatLng(10.7202, 122.5621)},
    // Add more schools as needed...
  ];

  // Filtered schools near current location within this radius (km)
  final double radiusInKm = 20;

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndFetch();
  }

  Future<void> _requestLocationPermissionAndFetch() async {
    var status = await Permission.location.status;

    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);

      // After getting location, set nearby markers
      _setNearbySchoolMarkers();

      setState(() {});
    } else if (status.isDenied) {
      debugPrint('Location permission denied.');
    } else if (status.isPermanentlyDenied) {
      debugPrint('Location permission permanently denied. Please enable it from settings.');
      await openAppSettings();
    }
  }

  void _setNearbySchoolMarkers() {
    if (_currentLocation == null) return;

    final nearbySchools = allPublicSchools.where((school) {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        school['location'].latitude,
        school['location'].longitude,
      ); // distance in meters

      return distance <= radiusInKm * 1000;
    }).toList();

    final newMarkers = nearbySchools.map((school) {
      return Marker(
        markerId: MarkerId(school['name']),
        position: school['location'],
        infoWindow: InfoWindow(
          title: school['name'],
          snippet: "Evacuation Site",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();

    _markers.clear();
    _markers.addAll(newMarkers);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Optionally, animate camera to current location on map creation
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
        title: const Text("Evacuation Sites Map"),
        backgroundColor: Colors.red,
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.red[50],
            child: Text(
              "Public Schools within $radiusInKm km of your location are marked as Evacuation Sites.",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 12,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
            ),
          ),
        ],
      ),
    );
  }
}
