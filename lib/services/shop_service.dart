import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'places_service.dart';

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

class ShopService {
  static const String _searchUrl =
      'https://places.googleapis.com/v1/places:searchText';

  final http.Client _client;

  ShopService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Shop>> findShops({
    required String category,
    required String city,
    required String query,
    required bool nearestFirst,
    double? centerLat,
    double? centerLng,
  }) async {
    final area = city.trim();

    if ((centerLat == null) != (centerLng == null)) {
      throw ArgumentError(
        'Both centerLat and centerLng must be provided together.',
      );
    }

    if (kGoogleApiKey.trim().isEmpty || kGoogleApiKey.startsWith('PASTE_')) {
      throw Exception('Google API key is missing in places_service.dart.');
    }

    if (centerLat != null &&
        centerLng != null &&
        (!centerLat.isFinite ||
            !centerLng.isFinite ||
            centerLat < -90 ||
            centerLat > 90 ||
            centerLng < -180 ||
            centerLng > 180)) {
      throw ArgumentError('The selected location is invalid.');
    }

    if (area.isEmpty && centerLat == null) {
      throw Exception('Enter a city or area, or select a location on the map.');
    }

    final term = _searchTerm(category, query);
    final textQuery = area.isEmpty ? term : '$term in $area';

    debugPrint('Google shop search: "$textQuery"');

    final response = await _client
        .post(
          Uri.parse(_searchUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': kGoogleApiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,'
                'places.formattedAddress,places.location,'
                'places.businessStatus',
          },
          body: jsonEncode({
            'textQuery': textQuery,
            'maxResultCount': 20,
            'languageCode': 'en',
            'regionCode': 'IN',
            if (centerLat != null && centerLng != null)
              'locationBias': {
                'circle': {
                  'center': {'latitude': centerLat, 'longitude': centerLng},
                  'radius': 10000.0,
                },
              },
          }),
        )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from Google Places API.');
    }

    if (response.statusCode != 200) {
      final error = decoded['error'];
      final message = error is Map ? error['message']?.toString() : null;

      throw Exception(message ?? 'Google Places error ${response.statusCode}.');
    }

    final places = decoded['places'] as List? ?? [];

    debugPrint('Google places received: ${places.length}');

    final raw = <_RawShop>[];
    final seen = <String>{};

    for (final item in places) {
      if (item is! Map<String, dynamic>) continue;

      if (item['businessStatus'] == 'CLOSED_PERMANENTLY') {
        continue;
      }

      final name = (item['displayName']?['text'] ?? '').toString().trim();

      final location = item['location'] as Map<String, dynamic>?;

      if (name.isEmpty || location == null) continue;

      final id = (item['id'] ?? '').toString();

      if (id.isEmpty || !seen.add(id)) continue;

      final latitude = location['latitude'];
      final longitude = location['longitude'];

      if (latitude is! num || longitude is! num) continue;

      raw.add(
        _RawShop(
          id: id,
          name: name,
          address: (item['formattedAddress'] ?? area).toString(),
          lat: latitude.toDouble(),
          lng: longitude.toDouble(),
        ),
      );
    }

    if (raw.isEmpty) return [];

    // Prefer the selected map location, otherwise use device GPS.
    Position? position;

    if (centerLat == null || centerLng == null) {
      position = await _getCurrentPosition();
    }

    final fromLat =
        centerLat ??
        position?.latitude ??
        _average(raw.map((shop) => shop.lat));

    final fromLng =
        centerLng ??
        position?.longitude ??
        _average(raw.map((shop) => shop.lng));

    final results = <Shop>[
      for (final shop in raw)
        Shop(
          id: shop.id,
          name: shop.name,
          category: category,
          address: shop.address,
          city: area,
          distanceKm:
              Geolocator.distanceBetween(fromLat, fromLng, shop.lat, shop.lng) /
              1000,
          lat: shop.lat,
          lng: shop.lng,
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

  String _searchTerm(String category, String query) {
    final q = query.trim();
    final cat = category.trim().toLowerCase();

    if (q.isNotEmpty && q.toLowerCase() != cat) {
      return q;
    }

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
    } catch (error) {
      debugPrint('Could not get current position: $error');
      return null;
    }
  }

  double _average(Iterable<double> values) {
    final list = values.toList();

    if (list.isEmpty) return 0;

    return list.reduce((a, b) => a + b) / list.length;
  }

  void dispose() {
    _client.close();
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
