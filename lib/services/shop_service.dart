import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'places_service.dart'; // uses kGoogleApiKey from this file

class Shop {
  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final double distanceKm;
  final double lat;
  final double lng;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.distanceKm,
    required this.lat,
    required this.lng,
  });
}

// Finds real shops using Google Places (New) Text Search.
// Example: category "Clothes" + city "Pune" -> "clothes shop in Pune".
// findShops() keeps the same name and parameters as before,
// so D1, D2 and D3 do not need any changes.
class ShopService {
  static const String _searchUrl =
      'https://places.googleapis.com/v1/places:searchText';

  Future<List<Shop>> findShops({
    required String category,
    required String city,
    required String query,
    required bool nearestFirst,
  }) async {
    final area = city.trim();

    if (area.isEmpty) {
      throw Exception('Please enter a city or area.');
    }

    if (kGoogleApiKey.trim().isEmpty ||
        kGoogleApiKey.startsWith('PASTE_')) {
      throw Exception(
        'Google API key is missing (add it at the top of places_service.dart).',
      );
    }

    final position = await _getCurrentPosition();
    final term = _searchTerm(category, query);
    final textQuery = '$term in $area';

    debugPrint('Google shop search: "$textQuery"');

    final response = await http
        .post(
          Uri.parse(_searchUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': kGoogleApiKey,
            'X-Goog-FieldMask': 'places.id,places.displayName,'
                'places.formattedAddress,places.location,'
                'places.businessStatus',
          },
          body: jsonEncode({
            'textQuery': textQuery,
            'maxResultCount': 20,
            'languageCode': 'en',
            'regionCode': 'IN',
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        (body['error']?['message'] ?? 'Error ${response.statusCode}')
            .toString(),
      );
    }

    final places = (body['places'] as List?) ?? [];
    debugPrint('Google places received: ${places.length}');

    // Read the shops first, without distances.
    final raw = <_RawShop>[];
    final seen = <String>{};

    for (final item in places) {
      final p = item as Map<String, dynamic>;

      // Skip shops that are closed for good.
      if (p['businessStatus'] == 'CLOSED_PERMANENTLY') continue;

      final name = (p['displayName']?['text'] ?? '').toString().trim();
      final loc = p['location'] as Map<String, dynamic>?;
      if (name.isEmpty || loc == null) continue;

      final id = (p['id'] ?? '').toString();
      if (id.isEmpty || !seen.add(id)) continue;

      raw.add(_RawShop(
        id: id,
        name: name,
        address: (p['formattedAddress'] ?? area).toString(),
        lat: (loc['latitude'] as num).toDouble(),
        lng: (loc['longitude'] as num).toDouble(),
      ));
    }

    if (raw.isEmpty) return [];

    // Distance is measured from the user's GPS position.
    // If GPS is not available, use the middle of the results instead.
    final fromLat = position?.latitude ??
        raw.map((s) => s.lat).reduce((a, b) => a + b) / raw.length;
    final fromLng = position?.longitude ??
        raw.map((s) => s.lng).reduce((a, b) => a + b) / raw.length;

    final results = [
      for (final s in raw)
        Shop(
          id: s.id,
          name: s.name,
          category: category,
          address: s.address,
          city: area,
          distanceKm: Geolocator.distanceBetween(
                fromLat,
                fromLng,
                s.lat,
                s.lng,
              ) /
              1000,
          lat: s.lat,
          lng: s.lng,
        ),
    ];

    if (nearestFirst) {
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
      results.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return results;
  }

  // If the user typed something different from the category chip,
  // search for that. Otherwise use a good Google search word for the category.
  String _searchTerm(String category, String query) {
    final q = query.trim();
    final cat = category.trim().toLowerCase();

    if (q.isNotEmpty && q.toLowerCase() != cat) return q;

    switch (cat) {
      case 'clothes':
      case 'clothing':
        return 'clothes shop';
      case 'shoes':
        return 'shoe shop';
      case 'medicine':
      case 'pharmacy':
        return 'pharmacy';
      case 'groceries':
      case 'grocery':
        return 'grocery store';
      case 'electronics':
        return 'electronics store';
      case 'books':
        return 'book store';
      case 'food':
      case 'restaurants':
        return 'restaurant';
      case 'gifts':
        return 'gift shop';
      default:
        return '$cat shop';
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }
  }
}

class _RawShop {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  const _RawShop({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}