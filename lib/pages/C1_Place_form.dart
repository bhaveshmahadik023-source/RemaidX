
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import 'C3_Search_results.dart';

class C1PlaceForm extends StatefulWidget {
  const C1PlaceForm({super.key});

  @override
  State<C1PlaceForm> createState() => _C1PlaceFormState();
}

class _C1PlaceFormState extends State<C1PlaceForm> {
  final TextEditingController taskController =
      TextEditingController(text: 'Meet friend');

  String placeName = '';
  String address = '';

  double? latitude;
  double? longitude;

  double radius = 700;
  String alertType = 'Message';

  bool isSaving = false;
  bool isGettingLocation = false;

  bool get hasLocation =>
      latitude != null && longitude != null;

  static const Color primaryColor = Color(0xFF107C73);
  static const Color lightColor = Color(0xFFE6F4F1);
  static const Color borderColor = Color(0xFFD7DEDE);
  static const Color textGrey = Color(0xFF637474);

  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }

  // Get the phone's current location.
  Future<void> _getCurrentLocation() async {
    setState(() {
      isGettingLocation = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location services on your phone.',
            ),
          ),
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required.',
            ),
          ),
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        placeName = 'Current Location';
        address =
            '${position.latitude}, ${position.longitude}';
        latitude = position.latitude;
        longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location selected!'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get location: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  // Search for a place or select a location on the map.
  Future<void> _changeLocation() async {
    final PickedPlace? place =
        await Navigator.push<PickedPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          mapStart: hasLocation
              ? LatLng(latitude!, longitude!)
              : null,
        ),
      ),
    );

    if (place == null || !mounted) return;

    setState(() {
      placeName = place.name;
      address = place.address;
      latitude = place.lat;
      longitude = place.lng;
    });
  }

  // Save reminder to Firestore.
  Future<void> _saveReminder() async {
    if (taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your task'),
        ),
      );
      return;
    }

    if (!hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final reminderData = <String, dynamic>{
        'title': taskController.text.trim(),
        'type': 'place',
        'placeName': placeName,
        'address': address,
        'lat': latitude!,
        'lng': longitude!,
        'radiusM': radius.round(),
        'alertType': alertType,
        'status': 'active',
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('reminders')
          .add(reminderData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder saved successfully!'),
          backgroundColor: primaryColor,
        ),
      );

      Navigator.pop(context, {
        ...reminderData,
        'id': docRef.id,
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminder: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: textGrey,
        ),
      ),
    );
  }

  Widget _locationCard() {
    return InkWell(
      onTap: _changeLocation,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: hasLocation ? lightColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasLocation ? primaryColor : borderColor,
            width: hasLocation ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor:
                  hasLocation ? primaryColor : lightColor,
              child: Icon(
                Icons.location_on_outlined,
                color: hasLocation ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? placeName : 'Select a location',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLocation
                        ? (address.isEmpty
                            ? '${latitude!.toStringAsFixed(5)}, '
                                '${longitude!.toStringAsFixed(5)}'
                            : address)
                        : 'Tap here to search or choose on map',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              hasLocation ? 'Change' : 'Choose',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPreview() {
    return InkWell(
      onTap: _changeLocation,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 145,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: hasLocation
            ? Stack(
                children: [
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 65,
                        color: Color(0xFFD1DCDA),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 28,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        placeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 38,
                    color: primaryColor,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to choose a location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textGrey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search for a place or pick it on the map',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatRadius(double value) {
    if (value >= 1000) {
      final km = value / 1000;
      return '${km.toStringAsFixed(
        km == km.roundToDouble() ? 0 : 1,
      )} km';
    }

    return '${value.round()} m';
  }

  Widget _distanceChip(double value, String label) {
    final selected = radius == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: lightColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? primaryColor : borderColor,
        width: selected ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight:
            selected ? FontWeight.w600 : FontWeight.normal,
        color: selected ? primaryColor : Colors.black87,
      ),
      onSelected: (_) {
        setState(() => radius = value);
      },
    );
  }

  Widget _alertOption({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = alertType == title;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => alertType = title);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 88,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? lightColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primaryColor : borderColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 25,
                color: selected ? primaryColor : textGrey,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'I know the place',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              children: [
                _sectionLabel('What is your task?'),
                TextField(
                  controller: taskController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Enter your task',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _sectionLabel('Location'),
                _locationCard(),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isGettingLocation
                        ? null
                        : _getCurrentLocation,
                    icon: isGettingLocation
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      isGettingLocation
                          ? 'Getting location...'
                          : 'Use Current Location',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(
                        color: primaryColor,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                _mapPreview(),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        "Remind me when I'm within",
                        style: TextStyle(
                          fontSize: 14,
                          color: textGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRadius(radius),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: borderColor,
                    thumbColor: Colors.white,
                    overlayColor:
                        primaryColor.withValues(alpha: 0.12),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    min: 100,
                    max: 1500,
                    divisions: 28,
                    value: radius,
                    onChanged: (value) {
                      setState(() => radius = value);
                    },
                  ),
                ),

                Wrap(
                  spacing: 7,
                  runSpacing: 2,
                  children: [
                    _distanceChip(300, '300 m'),
                    _distanceChip(500, '500 m'),
                    _distanceChip(700, '700 m'),
                    _distanceChip(1000, '1 km'),
                    _distanceChip(1500, '1.5 km'),
                  ],
                ),

                const SizedBox(height: 24),
                _sectionLabel('How should we alert you?'),

                Row(
                  children: [
                    _alertOption(
                      title: 'Message',
                      subtitle: 'Notification',
                      icon: Icons.chat_bubble_outline,
                    ),
                    const SizedBox(width: 12),
                    _alertOption(
                      title: 'Ring',
                      subtitle: 'Loud alarm sound',
                      icon: Icons.volume_up_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryColor.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 23,
                            width: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
