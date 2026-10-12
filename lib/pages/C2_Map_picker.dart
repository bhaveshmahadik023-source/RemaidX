import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../widgets/map_pin.dart';
import '../widgets/common.dart'; // PrimaryButton
import 'C3_Search_results.dart';

// C2: Choose location on a map.
// The user taps the map to move the pin. A circle shows the alert radius.
// "Use this location" closes the screen and returns a PickedPlace.
class MapPickerPage extends StatefulWidget {
  final LatLng? initialCenter; // where the pin starts (optional)
  final double radiusM; // circle size in meters
  const MapPickerPage({super.key, this.initialCenter, this.radiusM = 700});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  // Used only if we have no start point and GPS is not available.
  static const _pune = LatLng(18.5204, 73.8567);

  final _map = MapController(); // lets us move the map from code
  late LatLng _pin; // current pin position
  PickedPlace? _place; // name of the pin position (null while loading)
  int _req = 0; // request number, to ignore old name lookups

  @override
  void initState() {
    super.initState();
    _pin = widget.initialCenter ?? _pune;
    _resolve(_pin);

    // No start point given: quietly try to move to the user's GPS position.
    // We wait for the first frame, because the map must be ready before we move it.
    if (widget.initialCenter == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMe(silent: true));
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // Target button: move the pin and the map to the user's GPS position.
  // silent = true means do not show errors (used on screen start).
  Future<void> _goToMe({bool silent = false}) async {
    try {
      final ll = await LocationService.current();
      if (!mounted) return;
      _setPin(ll, move: true);
    } on LocationException catch (e) {
      if (!silent) _msg(e.message);
    }
  }

  // Put the pin at a new point and find its name.
  void _setPin(LatLng p, {bool move = false}) {
    setState(() {
      _pin = p;
      _place = null; // shows "Finding address..." and disables the button
    });
    if (move) _map.move(p, 16);
    _resolve(p);
  }

  // Ask Nominatim for the name of the pin position.
  Future<void> _resolve(LatLng p) async {
    final id = ++_req;
    PickedPlace place;
    try {
      place = await PlacesService.reverse(p);
    } catch (_) {
      // No internet or lookup failed: use the coordinates as the name.
      place = PickedPlace(
          name: 'Dropped pin',
          address:
              '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
          lat: p.latitude,
          lng: p.longitude);
    }
    // The user may have tapped again meanwhile, so ignore old answers.
    if (!mounted || id != _req) return;
    setState(() => _place = place);
  }

  // Search box tapped: open C3 and move the pin to the chosen result.
  Future<void> _openSearch() async {
    final r = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(
          builder: (_) => const SearchResultsPage(allowMapChoice: false)),
    );
    if (r == null || !mounted) return;
    _req++; // cancels any running name lookup
    setState(() {
  _pin = LatLng(r.lat, r.lng);
  _place = r;
});
_map.move(LatLng(r.lat, r.lng), 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text('Choose location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Top part: the map with search box and target button on top of it
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: 15,
                    onTap: (_, p) => _setPin(p), // tap = move the pin
                  ),
                  children: [
                    // Map picture from OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.remindx',
                    ),
                    // Alert radius circle (real meters, not screen pixels)
                    CircleLayer(circles: [
                      CircleMarker(
                        point: _pin,
                        radius: widget.radiusM,
                        useRadiusInMeter: true,
                        color: kTeal.withValues(alpha: 0.14),
                        borderColor: kTeal,
                        borderStrokeWidth: 1.5,
                      ),
                    ]),
                    // The pin
                    MarkerLayer(markers: [
                      Marker(
                          point: _pin,
                          width: 28,
                          height: 28,
                          child: const MapPin()),
                    ]),
                  ],
                ),

                // Search box (only looks like a text box, tap opens C3)
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
                          Text('Search a place',
                              style: TextStyle(
                                  color: Color(0xFF9AA5A3), fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Target button: go to my location
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(side: BorderSide(color: kBorder)),
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

          // Bottom sheet: place name and the confirm button
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small grey handle bar
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                          color: kBorder,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                 Text(_place?.name ?? 'Finding address...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kTextDark)),
                  const SizedBox(height: 4),
                  const Text('Tap the map to move the pin',
                      style: TextStyle(fontSize: 12, color: kTextGrey)),
                  const SizedBox(height: 16),
                  // While the name is loading the button shows a spinner,
                  // so the user cannot confirm a half-ready place.
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