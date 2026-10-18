import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as osm;

import '../constants.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../widgets/map_pin.dart';
import '../widgets/common.dart'; // PrimaryButton
import 'C3_Search_results.dart';

// C2: Choose a location on Google Maps.
// The user taps the map to move the pin. A circle shows the alert radius.
// "Use this location" closes the screen and returns a PickedPlace.
class MapPickerPage extends StatefulWidget {
  final osm.LatLng? initialCenter;
  final double radiusM;

  const MapPickerPage({
    super.key,
    this.initialCenter,
    this.radiusM = 700,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  // Fallback when no initial point or GPS position is available.
  static const osm.LatLng _pune = osm.LatLng(18.5204, 73.8567);

  gmaps.GoogleMapController? _mapController;
  late osm.LatLng _pin;
  PickedPlace? _place;
  int _req = 0;

  @override
  void initState() {
    super.initState();
    _pin = widget.initialCenter ?? _pune;
    _resolve(_pin);

    if (widget.initialCenter == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToMe(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _goToMe({bool silent = false}) async {
    try {
      // LocationService returns latlong2 LatLng in the existing project.
      final osm.LatLng position = await LocationService.current();
      if (!mounted) return;
      _setPin(position, move: true);
    } on LocationException catch (e) {
      if (!silent) _msg(e.message);
    }
  }

  void _setPin(osm.LatLng point, {bool move = false}) {
    setState(() {
      _pin = point;
      _place = null;
    });

    if (move) {
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(point.latitude, point.longitude),
          16,
        ),
      );
    }

    _resolve(point);
  }

  Future<void> _resolve(osm.LatLng point) async {
    final requestId = ++_req;
    PickedPlace place;

    try {
      // PlacesService.reverse accepts latlong2 LatLng in the existing project.
      place = await PlacesService.reverse(point);
    } catch (_) {
      place = PickedPlace(
        name: 'Dropped pin',
        address:
            '${point.latitude.toStringAsFixed(4)}, '
            '${point.longitude.toStringAsFixed(4)}',
        lat: point.latitude,
        lng: point.longitude,
      );
    }

    if (!mounted || requestId != _req) return;
    setState(() => _place = place);
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchResultsPage(allowMapChoice: false),
      ),
    );

    if (result == null || !mounted) return;

    final point = osm.LatLng(result.lat, result.lng);
    _req++;

    setState(() {
      _pin = point;
      _place = result;
    });

    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(point.latitude, point.longitude),
        16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapPoint = gmaps.LatLng(_pin.latitude, _pin.longitude);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text(
          'Choose location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: mapPoint,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (point) {
                    _setPin(
                      osm.LatLng(point.latitude, point.longitude),
                    );
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    gmaps.Marker(
                      markerId: const gmaps.MarkerId('selected_location'),
                      position: mapPoint,
                    ),
                  },
                  circles: {
                    gmaps.Circle(
                      circleId: const gmaps.CircleId('alert_radius'),
                      center: mapPoint,
                      radius: widget.radiusM,
                      fillColor: kTeal.withValues(alpha: 0.14),
                      strokeColor: kTeal,
                      strokeWidth: 2,
                    ),
                  },
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      height: 51,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: kTextGrey),
                          SizedBox(width: 12),
                          Text(
                            'Search a place',
                            style: TextStyle(
                              color: Color(0xFF9AA5A3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: kBorder),
                    ),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _goToMe,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.my_location, color: kTextDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: kBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _place?.name ?? 'Finding address...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap the map to move the pin',
                    style: TextStyle(fontSize: 12, color: kTextGrey),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Use this location',
                    loading: _place == null,
                    onTap: () => Navigator.pop(context, _place),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
