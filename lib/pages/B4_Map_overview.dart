import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/reminder.dart';
import '../services/location_service.dart';
import '../services/reminder_service.dart';
import '../widgets/map_pin.dart';

const _kPurple = Color(0xFF534AB7); // color for shopping reminders

// B4: Map overview.
// Shows all reminders that have a location as pins with radius circles.
// The user can filter (All / Place / Shopping), tap a pin to see its card,
// open Details, or open Directions in the phone's maps app.
class MapOverviewPage extends StatefulWidget {
  // Bottom menu tapped: 0 = Reminders, 1 = Map, 2 = Settings.
  final void Function(int index)? onTab;

  // "Details" button tapped (will open B5 later).
  final void Function(Reminder r)? onDetails;

  // false when the menu is provided by MainShell (so we do not show 2 menus).
  final bool showNav;

  const MapOverviewPage({
    super.key,
    this.onTab,
    this.onDetails,
    this.showNav = true,
  });

  @override
  State<MapOverviewPage> createState() => _MapOverviewPageState();
}
class _MapOverviewPageState extends State<MapOverviewPage> {
  static const _pune = LatLng(18.5204, 73.8567); // fallback map center
  final _map = MapController();
  final _service = ReminderService();
  String _filter = 'all'; // all / place / shopping
  String? _selectedId; // reminder shown in the bottom card
  LatLng? _me; // user's position (blue dot)
  bool _fitted = false; // we zoom to show all pins only once

  @override
  void initState() {
    super.initState();
    // Get the user's position for the blue dot. If it fails, just skip the dot.
    LocationService.current().then((ll) {
      if (mounted) setState(() => _me = ll);
    }).catchError((_) {});
  }

  // Teal for place, purple for shopping.
  Color _color(Reminder r) => r.type == 'shopping' ? _kPurple : kTeal;

  // Pin tapped: show its card and move the map there.
  void _select(Reminder r) {
    setState(() => _selectedId = r.id);
    _map.move(r.latLng, 15);
  }

  // After the first data load, zoom the map so all pins are visible.
  void _fitOnce(List<Reminder> items) {
    if (_fitted || items.isEmpty) return;
    _fitted = true;
    // Run after the current frame, because the map must be built first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (items.length == 1) {
          _map.move(items.first.latLng, 15);
        } else {
          _map.fitCamera(CameraFit.coordinates(
            coordinates: items.map((r) => r.latLng).toList(),
            // Extra space at top (chips) and bottom (card) so pins are not hidden
            padding: const EdgeInsets.fromLTRB(48, 100, 48, 240),
            maxZoom: 16,
          ));
        }
      } catch (_) {}
    });
  }

  // Directions button: open the phone's maps app with this place as destination.
  Future<void> _directions(Reminder r) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lng}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false, // no back arrow, this is a main tab
        title: const Text('Map',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),

      // Show our own menu only when this screen is used alone.
      // Inside MainShell the menu is already there, so we hide this one.
      bottomNavigationBar: widget.showNav
          ? NavigationBar(
              height: 72,
              backgroundColor: Colors.white,
              indicatorColor: kTealLight,
              selectedIndex: 1,
              onDestinationSelected: (i) => widget.onTab?.call(i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.notifications_none),
                    selectedIcon: Icon(Icons.notifications, color: kTeal),
                    label: 'Reminders'),
                NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map, color: kTeal),
                    label: 'Map'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings, color: kTeal),
                    label: 'Settings'),
              ],
            )
          : null,

      // Live data from Firestore. The screen redraws when reminders change.
      body: StreamBuilder<List<Reminder>>(
        stream: _service.stream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          // Keep only reminders that can be drawn on a map:
          // must have a location, not be "done", and match the chip filter.
          final all = snap.data ?? [];
          final items = all
              .where((r) =>
                  r.hasLocation &&
                  r.status != 'done' &&
                  (_filter == 'all' || r.type == _filter))
              .toList();
          _fitOnce(items);

          // Which reminder is shown in the card? The tapped one,
          // or the first one if nothing is tapped (or it was filtered out).
          Reminder? selected;
          for (final r in items) {
            if (r.id == _selectedId) selected = r;
          }
          selected ??= items.isNotEmpty ? items.first : null;

          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _me ?? _pune,
                  initialZoom: 13,
                ),
                children: [
                  // Map picture from OpenStreetMap
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.remindx',
                  ),

                  // Radius circle for each reminder (real meters)
                  CircleLayer(circles: [
                    for (final r in items)
                      CircleMarker(
                        point: r.latLng,
                        radius: r.radiusM.toDouble(),
                        useRadiusInMeter: true,
                        color: _color(r).withValues(alpha: 0.14),
                        borderColor: _color(r),
                        borderStrokeWidth: 1.5,
                      ),
                  ]),

                  // Pins (tap to select) and the blue "you are here" dot
                  MarkerLayer(markers: [
                    for (final r in items)
                      Marker(
                        point: r.latLng,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _select(r),
                          child: Center(child: MapPin(color: _color(r))),
                        ),
                      ),
                    if (_me != null)
                      Marker(
                        point: _me!,
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // soft outer glow
                            Container(
                                decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle)),
                            // solid blue dot
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                ],
              ),

              // Filter chips at the top of the map
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip('All', _filter == 'all',
                          () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _Chip('Place', _filter == 'place',
                          () => setState(() => _filter = 'place')),
                      const SizedBox(width: 8),
                      _Chip('Shopping', _filter == 'shopping',
                          () => setState(() => _filter = 'shopping')),
                    ],
                  ),
                ),
              ),

              // Bottom card: selected reminder, or a message if there is none
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: selected == null
                    ? _emptyCard(snap.connectionState == ConnectionState.waiting)
                    : _reminderCard(selected),
              ),
            ],
          );
        },
      ),
    );
  }

  // Card shown when there is nothing to display.
  Widget _emptyCard(bool loading) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Text(
            loading ? 'Loading reminders...' : 'No place reminders to show yet',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextGrey)),
      );

  // Card for the selected reminder: title, place, radius, and two buttons.
  Widget _reminderCard(Reminder r) {
    final c = _color(r);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Round icon: shop icon for shopping, pin icon for place
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    r.type == 'shopping' ? kPurpleLight : kTealLight,
                child: Icon(
                    r.type == 'shopping'
                        ? Icons.storefront_outlined
                        : Icons.location_on_outlined,
                    color: c),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kTextDark)),
                    const SizedBox(height: 2),
                    Text(r.placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: kTextGrey)),
                    const SizedBox(height: 6),
                    // Small pill: "Within 700 m"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: kTealLight,
                          borderRadius: BorderRadius.circular(7)),
                      child: Text('Within ${r.radiusLabel}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0B4F49))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Details: opens B5 (not built yet, so it shows a message for now)
              Expanded(
                child: SizedBox(
                  height: 39,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTealLight,
                      foregroundColor: const Color(0xFF0B4F49),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => widget.onDetails != null
                        ? widget.onDetails!(r)
                        : ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Reminder detail (B5) coming soon'))),
                    child: const Text('Details',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Directions: opens the phone's maps app
              Expanded(
                child: SizedBox(
                  height: 39,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kBorder),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _directions(r),
                    child: const Text('Directions',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kTextDark)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Filter chip (All / Place / Shopping). Teal when selected, white when not.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kTealLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? kTeal : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? const Color(0xFF0B4F49) : kTextDark)),
      ),
    );
  }
}