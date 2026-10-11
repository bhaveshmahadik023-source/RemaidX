import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import 'C2_Map_picker.dart';

// C3: Choose location by searching.
// The user can: type a name, use GPS, or open the map.
// When the user picks a place, this screen closes and returns a PickedPlace.
class SearchResultsPage extends StatefulWidget {
  // false when opened from C2, so we do not open the map again (no loop).
  final bool allowMapChoice;

  // Where the map should start if "Choose on map" is tapped.
  final LatLng? mapStart;

  const SearchResultsPage(
      {super.key, this.allowMapChoice = true, this.mapStart});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final _ctrl = TextEditingController(); // text in the search box
  Timer? _timer; // used to wait before searching (debounce)
  int _req = 0; // request number, used to ignore old (late) answers
  List<PickedPlace> _results = [];
  bool _loading = false; // true while searching
  bool _locating = false; // true while reading GPS
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // Called on every letter the user types.
  void _onChanged(String q) {
    _timer?.cancel();

    // Less than 3 letters: clear the list, do not search.
    if (q.trim().length < 3) {
      _req++; // makes any running search "old", so its answer is ignored
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    // Wait 700 ms after the user stops typing, then search.
    // Nominatim allows only 1 request per second, so we must not search on every letter.
    _timer = Timer(const Duration(milliseconds: 700), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    final id = ++_req;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await PlacesService.search(q);
      // If the user typed something newer meanwhile, ignore this answer.
      if (!mounted || id != _req) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _req) return;
      setState(() {
        _error = 'Could not search. Check your internet.';
        _loading = false;
      });
    }
  }

  // "Use my current location": read GPS, find its name, return it.
  Future<void> _useCurrent() async {
    setState(() => _locating = true);
    try {
      final ll = await LocationService.current();
      PickedPlace place;
      try {
        place = await PlacesService.reverse(ll);
      } catch (_) {
        // If the name lookup fails, still return the GPS point.
        place = PickedPlace(
            name: 'Current location',
            address: '',
            lat: ll.latitude,
            lng: ll.longitude);
      }
      if (mounted) Navigator.pop(context, place);
    } on LocationException catch (e) {
      _msg(e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // "Choose on map": open C2, and pass its result back to the caller.
  Future<void> _chooseOnMap() async {
    final p = await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(
          builder: (_) => MapPickerPage(initialCenter: widget.mapStart)),
    );
    if (p != null && mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final typed = _ctrl.text.trim().length >= 3;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        title: const Text('Choose location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps the layout phone-sized when opened in Chrome.
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Search',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kTextGrey)),
                const SizedBox(height: 8),

                // Search box
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: _onChanged,
                  style: const TextStyle(fontSize: 15, color: kTextDark),
                  decoration: InputDecoration(
                    hintText: 'Search a place',
                    hintStyle: const TextStyle(color: Color(0xFF9AA5A3)),
                    prefixIcon: const Icon(Icons.search, color: kTextGrey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kTeal, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 1: use GPS
                _ActionCard(
                  icon: Icons.my_location,
                  bg: kTealLight,
                  iconColor: kTeal,
                  label: 'Use my current location',
                  loading: _locating,
                  onTap: _useCurrent,
                ),

                // Card 2: open map (hidden when this screen was opened from C2)
                if (widget.allowMapChoice) ...[
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.map_outlined,
                    bg: const Color(0xFFF6F8F7),
                    iconColor: kTextGrey,
                    label: 'Choose on map',
                    onTap: _chooseOnMap,
                  ),
                ],
                const SizedBox(height: 24),

                // Results area: loading / error / list / "no results"
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red))
                else if (_results.isNotEmpty) ...[
                  const Text('RESULTS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kTextGrey)),
                  const SizedBox(height: 6),
                  for (final p in _results) _ResultRow(place: p),
                ] else if (typed)
                  const Text('No results found',
                      style: TextStyle(color: kTextGrey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A white rounded card with an icon and text (the two option buttons).
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color bg, iconColor;
  final String label;
  final bool loading; // shows a small spinner and disables the tap
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: loading ? null : onTap,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
                radius: 16,
                backgroundColor: bg,
                child: Icon(icon, size: 18, color: iconColor)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextDark)),
            ),
            if (loading)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}

// One search result: pin icon + name + address.
// Tapping it closes the screen and returns this place.
class _ResultRow extends StatelessWidget {
  final PickedPlace place;
  const _ResultRow({required this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context, place),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: kTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextDark)),
                      const SizedBox(height: 2),
                      Text(place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: kTextGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEDF0EF)),
      ],
    );
  }
}