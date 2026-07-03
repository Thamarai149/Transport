import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/constants/api_constants.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen>
    with TickerProviderStateMixin {
  late io.Socket _socket;
  final MapController _mapController = MapController();

  // Bus location from server (falls back to device GPS until live data arrives)
  LatLng? _busLocation;

  // Device current location
  LatLng? _myLocation;
  bool _hasLiveBusUpdate = false;
  StreamSubscription<Position>? _positionStream;

  bool _isConnected = false;
  String _statusMessage = 'Connecting to live location stream...';
  final String _busId = 'BUS-402';
  String _eta = '12 mins';
  double _speed = 0.0;

  // Animation controller for the "You are here" pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _initSocket();
    _initLocation();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  // ──────────────────── GPS / Location ────────────────────

  Future<void> _initLocation() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Please enable location services to see your position on the map.'),
          ),
        );
      }
      return;
    }

    // Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Location permission denied. Your position will not be shown on the map.'),
          ),
        );
      }
      return;
    }

    // Get initial position
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    if (mounted) {
      final location = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _myLocation = location;
        if (!_hasLiveBusUpdate) {
          _busLocation = location;
        }
      });
      _mapController.move(location, 15.0);
    }

    // Keep bus marker on current location until a live update arrives
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _myLocation = location;
        if (!_hasLiveBusUpdate) {
          _busLocation = location;
        }
      });
    });
  }

  void _centreOnMyLocation() {
    if (_myLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your location is not available yet.')),
      );
      return;
    }
    _mapController.move(_myLocation!, 15.0);
  }

  void _centreOnBus() {
    if (_busLocation == null) {
      _centreOnMyLocation();
      return;
    }
    _mapController.move(_busLocation!, 14.5);
  }

  // ──────────────────── Socket.IO ────────────────────

  void _initSocket() {
    final serverUrl = ApiConstants.baseUrl.replaceAll('/api', '');

    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _statusMessage = 'Connected! Listening to active trips.';
        });
      }
      _socket.emit('joinBusRoom', _busId);
    });

    _socket.on('locationUpdate', (data) {
      if (mounted && data != null) {
        setState(() {
          if (data['latitude'] != null && data['longitude'] != null) {
            _hasLiveBusUpdate = true;
            _busLocation = LatLng(
              double.parse(data['latitude'].toString()),
              double.parse(data['longitude'].toString()),
            );
            _mapController.move(_busLocation!, 14.5);
          }
          if (data['speed'] != null) {
            _speed = double.parse(data['speed'].toString());
          }
          if (data['eta'] != null) {
            _eta = data['eta'].toString();
          }
          _statusMessage = _hasLiveBusUpdate
              ? 'Receiving live bus coordinates.'
              : 'Showing your current location until live bus data arrives.';
        });
      }
    });

    _socket.on('busApproaching', (data) {
      if (mounted && data != null) {
        final stopName = data['stopName'] ?? 'your stop';
        final dist = data['distanceMetres'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🚌 Bus approaching "$stopName" (${dist}m away)',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    _socket.onDisconnect((_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusMessage = 'Disconnected from tracking server.';
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionStream?.cancel();
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  // ──────────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        actions: [
          // Centre on bus button in app bar
          IconButton(
            icon: const Icon(Icons.directions_bus),
            tooltip: 'Centre on Bus',
            onPressed: _centreOnBus,
          ),
        ],
      ),
      body: _busLocation == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your current location...'),
                ],
              ),
            )
          : Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _busLocation!,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.transponet',
              ),

              // Markers layer — bus + my location
              MarkerLayer(
                markers: [
                  // Bus marker (uses your GPS until a live driver update arrives)
                  Marker(
                    point: _busLocation!,
                    width: 56,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // Separate "you" marker only when bus has a live remote location
                  if (_myLocation != null && _hasLiveBusUpdate)
                    Marker(
                      point: _myLocation!,
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.teal.withValues(alpha: 0.2),
                                border: Border.all(
                                    color: Colors.teal.withValues(alpha: 0.4),
                                    width: 2),
                              ),
                            ),
                            // Inner dot
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.teal.shade400,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const PolylineLayer(polylines: []),
            ],
          ),

          // ── Status bar ──
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _isConnected ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  // My location pill
                  if (_myLocation != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location,
                              size: 12, color: Colors.teal.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'GPS Active',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Legend ──
          if (_myLocation != null)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                        Colors.blue.shade600, Icons.directions_bus,
                        _hasLiveBusUpdate ? 'Bus' : 'Your Location'),
                    if (_hasLiveBusUpdate) ...[
                      const SizedBox(height: 6),
                      _buildLegendItem(
                          Colors.teal.shade400, Icons.circle, 'You'),
                    ],
                  ],
                ),
              ),
            ),

          // ── Bottom panel ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Bus $_busId',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Route A-10: College to Central Station',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ETA: $_eta',
                          style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Current Speed',
                          '${_speed.toStringAsFixed(1)} km/h', Icons.speed, Colors.orange),
                      _buildStatColumn(
                          'Next Stop', 'Main Gate', Icons.location_on, Colors.red),
                      _buildStatColumn(
                          'Occupancy', 'Medium', Icons.people, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── My Location FAB ──
      floatingActionButton: FloatingActionButton(
        onPressed: _centreOnMyLocation,
        backgroundColor:
            _myLocation != null ? Colors.teal : Colors.grey.shade400,
        tooltip: 'My Location',
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildLegendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
