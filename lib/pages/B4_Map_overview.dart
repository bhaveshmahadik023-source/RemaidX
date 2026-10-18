import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/reminder.dart';
import '../services/location_service.dart';
import '../services/reminder_service.dart';

const _kPurple = Color(0xFF534AB7); // Shopping reminders

// B4: Map overview.
// Shows all reminders with locations as pins and radius circles.
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
  static const latlong.LatLng _pune =
      latlong.LatLng(18.5204, 73.8567); // Fallback map center

  final _service = ReminderService();

  gmaps.GoogleMapController? _mapController;

  String _filter = 'all'; // all / place / shopping
  String? _selectedId; // Reminder shown in the bottom card
  latlong.LatLng? _me; // User's position
  bool _fitted = false; // Zoom to show all pins only once

  @override
  void initState() {
    super.initState();

    // Get the user's position. If it fails, skip the location marker.
    LocationService.current().then((location) {
      if (mounted) {
        setState(() => _me = location);
      }
    }).catchError((_) {});
  }

  // Teal for place, purple for shopping.
  Color _color(Reminder r) =>
      r.type == 'shopping' ? _kPurple : kTeal;

  gmaps.LatLng _toGoogleLatLng(latlong.LatLng point) {
    return gmaps.LatLng(point.latitude, point.longitude);
  }

  // Pin tapped: show its card and move the map there.
  void _select(Reminder r) {
    setState(() => _selectedId = r.id);

    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        _toGoogleLatLng(r.latLng),
        15,
      ),
    );
  }

  // Zoom the map so all reminder pins are visible.
  void _fitOnce(List<Reminder> items) {
    if (_fitted || items.isEmpty || _mapController == null) return;

    _fitted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _mapController == null) return;

      if (items.length == 1) {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(
            _toGoogleLatLng(items.first.latLng),
            15,
          ),
        );
        return;
      }

      final points = items.map((r) => r.latLng).toList();

      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;

      for (final point in points.skip(1)) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      // Google Maps bounds require a non-zero area.
      if (minLat == maxLat) {
        minLat -= 0.001;
        maxLat += 0.001;
      }
      if (minLng == maxLng) {
        minLng -= 0.001;
        maxLng += 0.001;
      }

      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(
          gmaps.LatLngBounds(
            southwest: gmaps.LatLng(minLat, minLng),
            northeast: gmaps.LatLng(maxLat, maxLng),
          ),
          80,
        ),
      );
    });
  }

  // Directions button: open the phone's maps app with this place as destination.
  Future<void> _directions(Reminder r) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${r.lat},${r.lng}',
    );

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Map',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      // Show our own menu only when this screen is used alone.
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
                  label: 'Reminders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map, color: kTeal),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: kTeal),
                  label: 'Settings',
                ),
              ],
            )
          : null,

      // Live data from Firestore.
      body: StreamBuilder<List<Reminder>>(
        stream: _service.stream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          // Show reminders that have a location, are not done,
          // and match the selected filter.
          final all = snap.data ?? [];
          final items = all
              .where(
                (r) =>
                    r.hasLocation &&
                    r.status != 'done' &&
                    (_filter == 'all' || r.type == _filter),
              )
              .toList();

          _fitOnce(items);

          // Show the tapped reminder, or the first reminder by default.
          Reminder? selected;
          for (final r in items) {
            if (r.id == _selectedId) {
              selected = r;
              break;
            }
          }
          selected ??= items.isNotEmpty ? items.first : null;

          final markers = <gmaps.Marker>{
            for (final r in items)
              gmaps.Marker(
                markerId: gmaps.MarkerId('reminder_${r.id}'),
                position: _toGoogleLatLng(r.latLng),
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  r.type == 'shopping'
                      ? gmaps.BitmapDescriptor.hueViolet
                      : gmaps.BitmapDescriptor.hueCyan,
                ),
                onTap: () => _select(r),
              ),
            if (_me != null)
              gmaps.Marker(
                markerId: const gmaps.MarkerId('my_location'),
                position: _toGoogleLatLng(_me!),
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                  gmaps.BitmapDescriptor.hueAzure,
                ),
                infoWindow: const gmaps.InfoWindow(title: 'You are here'),
              ),
          };

          final circles = <gmaps.Circle>{
            for (final r in items)
              gmaps.Circle(
                circleId: gmaps.CircleId('radius_${r.id}'),
                center: _toGoogleLatLng(r.latLng),
                radius: r.radiusM.toDouble(),
                fillColor: _color(r).withValues(alpha: 0.14),
                strokeColor: _color(r),
                strokeWidth: 2,
              ),
          };

          return Stack(
            children: [
              gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: _toGoogleLatLng(_me ?? _pune),
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _fitOnce(items);
                },
                markers: markers,
                circles: circles,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Filter chips at the top of the map.
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        'All',
                        _filter == 'all',
                        () => setState(() {
                          _filter = 'all';
                          _fitted = false;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        'Place',
                        _filter == 'place',
                        () => setState(() {
                          _filter = 'place';
                          _fitted = false;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        'Shopping',
                        _filter == 'shopping',
                        () => setState(() {
                          _filter = 'shopping';
                          _fitted = false;
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom card: selected reminder, or a message if there is none.
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: selected == null
                    ? _emptyCard(
                        snap.connectionState == ConnectionState.waiting,
                      )
                    : _reminderCard(selected),
              ),
            ],
          );
        },
      ),
    );
  }

  // Card shown when there is nothing to display.
  Widget _emptyCard(bool loading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Text(
        loading ? 'Loading reminders...' : 'No place reminders to show yet',
        textAlign: TextAlign.center,
        style: const TextStyle(color: kTextGrey),
      ),
    );
  }

  // Card for the selected reminder.
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
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    r.type == 'shopping' ? kPurpleLight : kTealLight,
                child: Icon(
                  r.type == 'shopping'
                      ? Icons.storefront_outlined
                      : Icons.location_on_outlined,
                  color: c,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.placeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kTealLight,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Within ${r.radiusLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B4F49),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                              content: Text(
                                'Reminder detail (B5) coming soon',
                              ),
                            ),
                          ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 39,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kBorder),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _directions(r),
                    child: const Text(
                      'Directions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
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

// Filter chip (All / Place / Shopping).
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? const Color(0xFF0B4F49) : kTextDark,
          ),
        ),
      ),
    );
  }
}
