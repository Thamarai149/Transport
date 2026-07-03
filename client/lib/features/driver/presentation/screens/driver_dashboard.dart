import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/constants/api_constants.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late io.Socket _socket;
  bool _isConnected = false;
  bool _isTripActive = false;
  final String _busId = 'BUS-402';
  String _selectedRoute = 'Route A-10';

  Timer? _tripTimer;
  int _updatesSent = 0;

  // Real GPS
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Position>? _tripPositionStream;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _initLocation();
  }

  // ──────────────────── Location ────────────────────

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() => _locationPermissionGranted = true);

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (mounted) setState(() => _currentPosition = pos);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((p) {
      if (mounted) setState(() => _currentPosition = p);
    });
  }

  // ──────────────────── Socket ────────────────────

  void _initSocket() {
    final serverUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      if (mounted) setState(() => _isConnected = true);
    });

    _socket.onDisconnect((_) {
      if (mounted) setState(() => _isConnected = false);
    });
  }

  // ──────────────────── Trip ────────────────────

  void _toggleTrip() {
    if (_isTripActive) {
      _stopTrip();
    } else {
      _startTrip();
    }
  }

  void _emitLocation(Position position) {
    final speedKmh = position.speed >= 0 ? position.speed * 3.6 : 0.0;

    _socket.emit('driverLocationUpdate', {
      'busId': _busId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': speedKmh,
      'eta': 'Live',
    });
  }

  void _startTrip() {
    if (!_locationPermissionGranted || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Enable GPS and wait for a location fix before starting the trip.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTripActive = true;
      _updatesSent = 0;
    });

    _emitLocation(_currentPosition!);
    setState(() => _updatesSent++);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip started! Streaming your current GPS location...')),
    );

    _tripPositionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (!mounted || !_isTripActive) return;
      setState(() => _currentPosition = position);
      _emitLocation(position);
      setState(() => _updatesSent++);
    });

    _tripTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || !_isTripActive || _currentPosition == null) return;
      _emitLocation(_currentPosition!);
      setState(() => _updatesSent++);
    });
  }

  void _stopTrip() {
    _tripTimer?.cancel();
    _tripPositionStream?.cancel();
    _tripTimer = null;
    _tripPositionStream = null;
    setState(() => _isTripActive = false);
  }

  void _handleLogout() async {
    _stopTrip();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _stopTrip();
    _positionStream?.cancel();
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  // ──────────────────── My Location Map Bottom Sheet ────────────────────

  void _showMyLocationMap() {
    if (!_locationPermissionGranted || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
              'Location not available. Please enable GPS and grant permission.'),
        ),
      );
      return;
    }

    final myPos =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollController) => Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.my_location,
                          color: Colors.teal.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Current Location',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${myPos.latitude.toStringAsFixed(5)}, ${myPos.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: myPos,
                      initialZoom: 15.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.transponet',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: myPos,
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.teal.withValues(alpha: 0.15),
                                    border: Border.all(
                                        color:
                                            Colors.teal.withValues(alpha: 0.3),
                                        width: 2),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.teal.shade500,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // GPS info row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGpsInfoTile('Accuracy',
                        '${_currentPosition!.accuracy.toStringAsFixed(0)} m',
                        Icons.gps_fixed),
                    _buildGpsInfoTile(
                        'Speed',
                        _currentPosition!.speed >= 0
                            ? '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h'
                            : '—',
                        Icons.speed),
                    _buildGpsInfoTile(
                        'Altitude',
                        '${_currentPosition!.altitude.toStringAsFixed(0)} m',
                        Icons.terrain),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGpsInfoTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal.shade600, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // ──────────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TranspoNet Driver Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Connection status ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isConnected ? Colors.green : Colors.red),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isConnected
                        ? 'Connected to GPS Server'
                        : 'Disconnected from Server',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── My Current Location card ──
            InkWell(
              onTap: _showMyLocationMap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'View My Location on Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentPosition != null
                                ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}  •  Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(0)}m'
                                : _locationPermissionGranted
                                    ? 'Acquiring GPS fix...'
                                    : 'Location permission required',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Route / Bus selector ──
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRoute,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Route',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Route A-10',
                            child: Text('Route A-10 (College to Station)')),
                        DropdownMenuItem(
                            value: 'Route B-02',
                            child: Text('Route B-02 (College to Airport)')),
                      ],
                      onChanged: _isTripActive
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedRoute = val);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _busId,
                      decoration: const InputDecoration(
                        labelText: 'Bus Plate Number',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── GPS source indicator ──
            if (_locationPermissionGranted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gps_fixed,
                        size: 14,
                        color: _currentPosition != null
                            ? Colors.teal
                            : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _currentPosition != null
                          ? 'Trip will stream your current GPS location'
                          : 'Waiting for GPS fix...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentPosition != null
                            ? Colors.teal.shade700
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Start / End Trip button ──
            ElevatedButton(
              onPressed: (_isConnected && _currentPosition != null) ? _toggleTrip : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isTripActive ? Colors.red : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _isTripActive
                    ? 'End Active Trip'
                    : 'Start Scheduled Trip',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // ── Live streaming progress ──
            if (_isTripActive) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                'Streaming live GPS updates: $_updatesSent',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Current location: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: Colors.teal.shade600),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
