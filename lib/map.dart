import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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

  final String _googleApiKey = 'AIzaSyB2uJz4ZPuWmHZ0O9VSf95K2dqyn2Y-un8';

  final int radiusInMeters = 100000; // 100 km

  Map<String, dynamic>? _selectedSite;
  double? _distanceToSelectedSite;
  StreamSubscription<Position>? _positionStream;

  bool _loadingSchools = false;
  String _statusMessage = "Loading current location...";

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _statusMessage = "Fetching nearby schools...";
          _loadingSchools = true;
        });
        await _fetchNearbySchools();
        // We do NOT start tracking until user selects a site
      } catch (e) {
        setState(() {
          _statusMessage = "Failed to get location: $e";
          _loadingSchools = false;
        });
      }
    } else {
      setState(() {
        _statusMessage =
            "Location permission denied. Please enable it in settings.";
      });
      await openAppSettings();
    }
  }

  Future<void> _fetchNearbySchools() async {
    if (_currentLocation == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentLocation!.latitude},${_currentLocation!.longitude}&radius=$radiusInMeters&type=school&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        _markers.clear();

        for (var school in results) {
          final name = school['name'];
          final lat = school['geometry']['location']['lat'];
          final lng = school['geometry']['location']['lng'];

          _markers.add(
            Marker(
              markerId: MarkerId(name),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(title: name, snippet: "Tap to select"),
              onTap: () => _showEvacuationSiteSheet(school),
            ),
          );
        }
        setState(() {
          _loadingSchools = false;
          _statusMessage = "Select an evacuation site by tapping a marker.";
        });
      } else {
        setState(() {
          _loadingSchools = false;
          _statusMessage = "Failed to fetch nearby schools.";
        });
      }
    } catch (e) {
      setState(() {
        _loadingSchools = false;
        _statusMessage = "Error fetching schools: $e";
      });
    }
  }

  void _showEvacuationSiteSheet(Map<String, dynamic> school) {
    _selectedSite = school;
    _distanceToSelectedSite = null;

    final LatLng schoolLoc = LatLng(
      school['geometry']['location']['lat'],
      school['geometry']['location']['lng'],
    );

    _mapController.animateCamera(CameraUpdate.newLatLngZoom(schoolLoc, 14));

    _startTrackingDistance();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Transparent for nice rounded corners
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Update distance live inside modal
            _positionStream?.onData((position) {
              final LatLng userLoc = LatLng(
                position.latitude,
                position.longitude,
              );
              final distance = Geolocator.distanceBetween(
                userLoc.latitude,
                userLoc.longitude,
                schoolLoc.latitude,
                schoolLoc.longitude,
              );
              setModalState(() {
                _distanceToSelectedSite = distance;
                _currentLocation = userLoc;
              });
            });

            String distanceText = _distanceToSelectedSite == null
                ? "Calculating distance..."
                : _formatDistance(_distanceToSelectedSite!);

            return DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.25,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, controller) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade900.withOpacity(0.6),
                      blurRadius: 25,
                      offset: const Offset(0, -8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: ListView(
                      controller: controller,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                school['name'],
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red.shade800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.red.shade700,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _positionStream?.cancel();
                                  setState(() {
                                    _selectedSite = null;
                                    _distanceToSelectedSite = null;
                                    _statusMessage =
                                        "Select an evacuation site by tapping a marker.";
                                  });
                                },
                                tooltip: "Close",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade200.withOpacity(0.8),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            school['vicinity'] ??
                                "Location information unavailable.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "Distance from you:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade400,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade300.withOpacity(0.7),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              distanceText,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _positionStream?.cancel();
                            setState(() {
                              _selectedSite = null;
                              _distanceToSelectedSite = null;
                              _statusMessage =
                                  "Select an evacuation site by tapping a marker.";
                            });
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("Close"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: Colors.red.shade900,
                            elevation: 8,
                          ),
                        ),
                        // Extra spacing so content doesn't get cut off in scroll
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startTrackingDistance() {
    _positionStream?.cancel();

    if (_selectedSite == null) return;

    final LatLng schoolLoc = LatLng(
      _selectedSite!['geometry']['location']['lat'],
      _selectedSite!['geometry']['location']['lng'],
    );

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((position) {
          final LatLng userLoc = LatLng(position.latitude, position.longitude);
          final distance = Geolocator.distanceBetween(
            userLoc.latitude,
            userLoc.longitude,
            schoolLoc.latitude,
            schoolLoc.longitude,
          );

          setState(() {
            _distanceToSelectedSite = distance;
            _currentLocation = userLoc;
          });
        });
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(2)} km";
    } else {
      return "${meters.toStringAsFixed(0)} m";
    }
  }

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
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Evacuation Map",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.8,
                fontFamily: 'Roboto',
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: _loadingSchools && _currentLocation == null
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
                    color: Colors.red[50],
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
