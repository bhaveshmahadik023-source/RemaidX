import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------
// PASTE YOUR ROUTES API KEY HERE (the one created in Google Cloud).
// ---------------------------------------------------------------
const String kRoutesApiKey = 'AIzaSyBZQ_lI0BHgAOrEVfTY7Q6W9w9-pFfe1Ds';

// One turn / instruction (from the Routes API).
class _Step {
  final String instruction;
  final String maneuver;
  final LatLng end;
  const _Step(this.instruction, this.maneuver, this.end);
}

/// Opens when a reminder is tapped.
/// Shows the route and ETA. Tapping "Start" begins navigation inside the app.
class ReminderMapScreen extends StatefulWidget {
  final String title;
  final String placeName;
  final double lat;
  final double lng;
  final int radiusM;

  const ReminderMapScreen({
    super.key,
    required this.title,
    required this.lat,
    required this.lng,
    this.placeName = '',
    this.radiusM = 700,
  });

  @override
  State<ReminderMapScreen> createState() => _ReminderMapScreenState();
}

class _ReminderMapScreenState extends State<ReminderMapScreen> {
  GoogleMapController? _controller;
  StreamSubscription<Position>? _sub;

  LatLng? _current;
  double? _straightDistance;
  bool _follow = true;
  String? _error;

  // Route data
  List<LatLng> _routePoints = [];
  List<double> _cum = []; // cumulative route length (meters)
  List<_Step> _steps = [];
  int? _routeMeters;
  int? _routeSeconds;
  LatLng? _routeOrigin;
  bool _fetching = false;
  String? _routeError;
  bool _fittedRoute = false;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  // Navigation mode data
  bool _navigating = false;
  bool _arrived = false;
  int _maneuverIndex = 0;
  double? _remainingMeters;
  double _bearing = 0;

  late final LatLng _destination = LatLng(widget.lat, widget.lng);

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  // ---------------- Live location ----------------

  Future<void> _startTracking() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Please turn on GPS.';
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Please allow location permission (in Settings).';
      }

      final first = await Geolocator.getCurrentPosition();
      _onPosition(first);

      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _onPosition,
        onError: (e) {
          if (mounted) setState(() => _error = e.toString());
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _onPosition(Position p) {
    final me = LatLng(p.latitude, p.longitude);
    final d = Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      _destination.latitude,
      _destination.longitude,
    );
    if (!mounted) return;
    setState(() {
      _current = me;
      _straightDistance = d;
      _error = null;
    });

    if (_navigating) {
      _updateNavigation(me, p);
    } else {
      _maybeFetchRoute(me);
      if (_follow && _routePoints.isEmpty) _fitBoth();
    }
  }

  // ---------------- Routes API ----------------

  void _maybeFetchRoute(LatLng me) {
    if (_fetching) return;
    if (_routeOrigin != null) {
      final moved = Geolocator.distanceBetween(
        _routeOrigin!.latitude,
        _routeOrigin!.longitude,
        me.latitude,
        me.longitude,
      );
      if (moved < 300) return;
    }
    _fetchRoute(me);
  }

  Future<void> _fetchRoute(LatLng from) async {
    if (kRoutesApiKey == 'PASTE_ROUTES_KEY_HERE') {
      setState(() => _routeError =
          'Routes API key is missing (add it at the top of reminder_map_screen.dart).');
      return;
    }

    _fetching = true;
    _lastFetch = DateTime.now();
    _routeOrigin = from;

    try {
      final res = await http.post(
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': kRoutesApiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,'
              'routes.polyline.encodedPolyline,'
              'routes.legs.steps.navigationInstruction,'
              'routes.legs.steps.endLocation',
        },
        body: jsonEncode({
          'origin': {
            'location': {
              'latLng': {
                'latitude': from.latitude,
                'longitude': from.longitude,
              }
            }
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': _destination.latitude,
                'longitude': _destination.longitude,
              }
            }
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'languageCode': 'en-US',
          'units': 'METRIC',
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode != 200) {
        throw (body['error']?['message'] ?? 'Error ${res.statusCode}')
            .toString();
      }

      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw 'No route found.';
      }

      final r = routes.first as Map<String, dynamic>;
      final points =
          _decodePolyline(r['polyline']['encodedPolyline'] as String);
      final seconds =
          int.tryParse((r['duration'] ?? '0s').toString().replaceAll('s', ''));

      // Steps (turn by turn)
      final legs = r['legs'] as List?;
      final stepsJson = (legs != null && legs.isNotEmpty)
          ? (legs.first['steps'] as List? ?? [])
          : [];
      final steps = <_Step>[];
      for (final s in stepsJson) {
        final ll = s['endLocation']?['latLng'];
        if (ll == null) continue;
        final ni = s['navigationInstruction'] as Map?;
        steps.add(_Step(
          (ni?['instructions'] ?? 'Continue').toString(),
          (ni?['maneuver'] ?? 'STRAIGHT').toString(),
          LatLng(
            (ll['latitude'] as num).toDouble(),
            (ll['longitude'] as num).toDouble(),
          ),
        ));
      }

      // Cumulative length
      final cum = <double>[0];
      for (var i = 1; i < points.length; i++) {
        cum.add(cum.last +
            Geolocator.distanceBetween(
              points[i - 1].latitude,
              points[i - 1].longitude,
              points[i].latitude,
              points[i].longitude,
            ));
      }

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _cum = cum;
        _steps = steps;
        _routeMeters = (r['distanceMeters'] as num?)?.toInt();
        _routeSeconds = seconds;
        _maneuverIndex = 0;
        _routeError = null;
      });

      if (!_navigating && _follow && !_fittedRoute) {
        _fittedRoute = true;
        _fitPoints(_routePoints);
      }
    } catch (e) {
      _routeOrigin = null;
      if (mounted) setState(() => _routeError = e.toString());
    } finally {
      _fetching = false;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ---------------- In-app navigation ----------------

  void _startNavigation() {
    if (_routePoints.isEmpty || _current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route is not ready yet, please wait...')),
      );
      return;
    }
    setState(() {
      _navigating = true;
      _arrived = false;
      _follow = true;
      _maneuverIndex = 0;
    });
    _updateNavigation(
      _current!,
      null,
    );
  }

  void _stopNavigation() {
    setState(() {
      _navigating = false;
      _arrived = false;
      _follow = true;
    });
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _current ?? _destination, zoom: 14),
      ),
    );
    _fitPoints(_routePoints);
  }

  // Maneuver location: 0 = start of the route, then the end of the previous step.
  LatLng _maneuverLocation(int m) =>
      m == 0 ? (_routeOrigin ?? _routePoints.first) : _steps[m - 1].end;

  void _updateNavigation(LatLng me, Position? p) {
    // Have we arrived?
    final toDest = Geolocator.distanceBetween(
      me.latitude,
      me.longitude,
      _destination.latitude,
      _destination.longitude,
    );
    if (toDest < 40) {
      setState(() {
        _arrived = true;
        _remainingMeters = 0;
      });
      return;
    }

    // Find the next turn.
    var m = _maneuverIndex;
    while (m < _steps.length) {
      final d = Geolocator.distanceBetween(
        me.latitude,
        me.longitude,
        _maneuverLocation(m).latitude,
        _maneuverLocation(m).longitude,
      );
      if (m == 0 && d > 50) {
        m++;
      } else if (m > 0 && d < 30) {
        m++;
      } else {
        break;
      }
    }

    // Distance from the route and distance remaining.
    final prog = _routeProgress(me);

    setState(() {
      _maneuverIndex = m;
      _remainingMeters = prog.$2;
    });

    // If off the route, fetch a new route.
    if (prog.$1 > 60 &&
        !_fetching &&
        DateTime.now().difference(_lastFetch).inSeconds > 8) {
      _fetchRoute(me);
    }

    // Camera: navigation style (tilt + heading).
    if (p != null && p.heading >= 0 && p.speed > 1) {
      _bearing = p.heading;
    }
    if (_follow) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: me,
            zoom: 18,
            bearing: _bearing,
            tilt: 55,
          ),
        ),
      );
    }
  }

  // (distance from the route, distance remaining to the destination)
  (double, double) _routeProgress(LatLng me) {
    if (_routePoints.length < 2) {
      return (0, _straightDistance ?? 0);
    }

    final cosLat = math.cos(me.latitude * math.pi / 180);
    double toX(LatLng p) => p.longitude * 111320 * cosLat;
    double toY(LatLng p) => p.latitude * 110540;

    final px = toX(me), py = toY(me);
    var best = double.infinity;
    var remaining = 0.0;

    for (var i = 0; i < _routePoints.length - 1; i++) {
      final ax = toX(_routePoints[i]), ay = toY(_routePoints[i]);
      final bx = toX(_routePoints[i + 1]), by = toY(_routePoints[i + 1]);
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
      t = t.clamp(0.0, 1.0);
      final cx = ax + t * dx, cy = ay + t * dy;
      final dist = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
      if (dist < best) {
        best = dist;
        final segLen = _cum[i + 1] - _cum[i];
        remaining = segLen * (1 - t) + (_cum.last - _cum[i + 1]);
      }
    }
    return (best, remaining);
  }

  IconData _maneuverIcon(String m) {
    switch (m) {
      case 'TURN_LEFT':
        return Icons.turn_left;
      case 'TURN_RIGHT':
        return Icons.turn_right;
      case 'TURN_SLIGHT_LEFT':
      case 'KEEP_LEFT':
      case 'RAMP_LEFT':
      case 'FORK_LEFT':
        return Icons.turn_slight_left;
      case 'TURN_SLIGHT_RIGHT':
      case 'KEEP_RIGHT':
      case 'RAMP_RIGHT':
      case 'FORK_RIGHT':
        return Icons.turn_slight_right;
      case 'TURN_SHARP_LEFT':
        return Icons.turn_sharp_left;
      case 'TURN_SHARP_RIGHT':
        return Icons.turn_sharp_right;
      case 'UTURN_LEFT':
        return Icons.u_turn_left;
      case 'UTURN_RIGHT':
        return Icons.u_turn_right;
      case 'ROUNDABOUT_LEFT':
        return Icons.roundabout_left;
      case 'ROUNDABOUT_RIGHT':
        return Icons.roundabout_right;
      case 'MERGE':
        return Icons.merge;
      default:
        return Icons.straight;
    }
  }

  // ---------------- Camera ----------------

  Future<void> _fitBoth() async {
    final me = _current;
    if (_controller == null || me == null) return;
    _fitPoints([me, _destination]);
  }

  Future<void> _fitPoints(List<LatLng> pts) async {
    final c = _controller;
    if (c == null || pts.isEmpty) return;

    var south = pts.first.latitude, north = pts.first.latitude;
    var west = pts.first.longitude, east = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    try {
      if (south == north && west == east) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 17));
      } else {
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(south, west),
              northeast: LatLng(north, east),
            ),
            100,
          ),
        );
      }
    } catch (_) {}
  }

  // ---------------- Text helpers ----------------

  String _formatDistance(double m) => m < 1000
      ? '${m.toStringAsFixed(0)} m'
      : '${(m / 1000).toStringAsFixed(m >= 10000 ? 0 : 1)} km';

  String _formatDuration(int sec) {
    final mins = (sec / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  String _arrivalTime(int sec) {
    final t = DateTime.now().add(Duration(seconds: sec));
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  String get _radiusLabel => widget.radiusM >= 1000
      ? '${(widget.radiusM / 1000).toStringAsFixed(widget.radiusM % 1000 == 0 ? 0 : 1)} km'
      : '${widget.radiusM} m';

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final radius = widget.radiusM.toDouble();
    final reached =
        _straightDistance != null && _straightDistance! <= radius;
    final hasRoute = _routePoints.isNotEmpty;

    return Scaffold(
      appBar: _navigating ? null : AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _destination, zoom: 15),
            onMapCreated: (c) {
              _controller = c;
              hasRoute ? _fitPoints(_routePoints) : _fitBoth();
            },
            myLocationEnabled: _current != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: !_navigating,
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: _destination,
                infoWindow: InfoWindow(
                  title: widget.title,
                  snippet: widget.placeName,
                ),
              ),
            },
            circles: {
              Circle(
                circleId: const CircleId('radius'),
                center: _destination,
                radius: radius,
                fillColor: Colors.blue.withAlpha(40),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            },
            polylines: {
              if (hasRoute)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _routePoints,
                  width: _navigating ? 10 : 7,
                  color: const Color(0xFF1A73E8),
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                )
              else if (_current != null)
                Polyline(
                  polylineId: const PolylineId('line'),
                  points: [_current!, _destination],
                  width: 4,
                  color: Colors.blue,
                  patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                ),
            },
          ),

          if (!_navigating && (_error != null || _routeError != null))
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error ?? 'Route: $_routeError'),
                ),
              ),
            ),

          if (_navigating) _navBanner(),
          if (_navigating) _navBottomBar() else _infoCard(reached, hasRoute),
        ],
      ),
    );
  }

  // Green banner at the top: the next turn.
  Widget _navBanner() {
    String text;
    IconData icon;
    String distText;

    if (_arrived) {
      text = 'You have arrived!';
      icon = Icons.flag;
      distText = widget.title;
    } else if (_maneuverIndex >= _steps.length) {
      text = 'Destination: ${widget.title}';
      icon = Icons.flag;
      distText = _formatDistance(_straightDistance ?? 0);
    } else {
      final step = _steps[_maneuverIndex];
      text = step.instruction;
      icon = _maneuverIcon(step.maneuver);
      final loc = _maneuverLocation(_maneuverIndex);
      final d = _current == null
          ? 0.0
          : Geolocator.distanceBetween(
              _current!.latitude,
              _current!.longitude,
              loc.latitude,
              loc.longitude,
            );
      distText = _maneuverIndex == 0 ? 'Now' : _formatDistance(d);
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Material(
            color: const Color(0xFF0B6B5E),
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          distText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Black bar at the bottom: exit, time, distance, re-centre.
  Widget _navBottomBar() {
    final remM = _remainingMeters ?? (_routeMeters?.toDouble() ?? 0);
    final totalM = (_routeMeters ?? 1).toDouble();
    final totalS = (_routeSeconds ?? 0).toDouble();
    final remS = totalM == 0 ? 0 : (totalS * remM / totalM).round();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              InkWell(
                onTap: _stopNavigation,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _arrived ? 'Arrived' : _formatDuration(remS),
                      style: const TextStyle(
                        color: Color(0xFF81C995),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatDistance(remM)}  •  ${_arrivalTime(remS)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _follow = !_follow);
                  if (!_follow) {
                    _fitPoints(_routePoints);
                  }
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _follow ? Colors.white12 : const Color(0xFF1A73E8),
                  ),
                  child: Icon(
                    _follow ? Icons.navigation : Icons.my_location,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card shown before navigation starts.
  Widget _infoCard(bool reached, bool hasRoute) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 20,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (widget.placeName.isNotEmpty)
                Text(
                  widget.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              if (_straightDistance == null)
                const Text('Finding your location...')
              else if (reached)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('You have arrived! ✅',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )
              else if (_routeSeconds != null && _routeMeters != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDuration(_routeSeconds!),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF188038),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_formatDistance(_routeMeters!.toDouble())}'
                        '  •  ${_arrivalTime(_routeSeconds!)}',
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black54),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Straight-line distance: ${_formatDistance(_straightDistance!)}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 4),
              Text(
                'Alert distance: $_radiusLabel',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: hasRoute ? _startNavigation : null,
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Start',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}