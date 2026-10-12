
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
  static const String _userAgent = 'RemindX/1.0 (student project)';

  static const String _nominatim =
      'https://nominatim.openstreetmap.org';

  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

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

    final center = await _findAreaCenter(area);
    final position = await _getCurrentPosition();

    final tags = _tagsForCategory(category);
    final queryText = query.trim().toLowerCase();

    final overpassQuery = '''
[out:json][timeout:50];
(
${tags.map((tag) => '''
  node["${tag.key}"="${tag.value}"](around:10000,${center.lat},${center.lng});
  way["${tag.key}"="${tag.value}"](around:10000,${center.lat},${center.lng});
  relation["${tag.key}"="${tag.value}"](around:10000,${center.lat},${center.lng});
''').join()}
);
out center tags;
''';

    final elements = await _fetchShopElements(overpassQuery);

    debugPrint('Overpass elements received: ${elements.length}');

    final results = <Shop>[];
    final seen = <String>{};

    for (final item in elements) {
      final element = item as Map<String, dynamic>;
      final tagsMap =
          (element['tags'] as Map<String, dynamic>?) ?? {};

      final name = (tagsMap['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;

      final centerMap = element['center'] as Map<String, dynamic>?;

      final elementLat =
          (element['lat'] as num?)?.toDouble() ??
          (centerMap?['lat'] as num?)?.toDouble();

      final elementLng =
          (element['lon'] as num?)?.toDouble() ??
          (centerMap?['lon'] as num?)?.toDouble();

      if (elementLat == null || elementLng == null) continue;

      final addressParts = [
        tagsMap['addr:street'],
        tagsMap['addr:suburb'],
        tagsMap['addr:city'],
        tagsMap['addr:postcode'],
      ].whereType<String>().where((part) => part.trim().isNotEmpty);

      final address =
          addressParts.isEmpty ? area : addressParts.join(', ');

      final searchable =
          '$name $address ${tagsMap['brand'] ?? ''}'.toLowerCase();

      if (queryText.isNotEmpty &&
          !searchable.contains(queryText)) {
        continue;
      }

      final id = '${element['type']}/${element['id']}';
      if (!seen.add(id)) continue;

      final distance = position == null
          ? _distanceKm(
              center.lat,
              center.lng,
              elementLat,
              elementLng,
            )
          : Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                elementLat,
                elementLng,
              ) /
              1000;

      results.add(
        Shop(
          id: id,
          name: name,
          category: category,
          address: address,
          city: (tagsMap['addr:city'] as String?) ?? area,
          distanceKm: distance,
          lat: elementLat,
          lng: elementLng,
        ),
      );
    }

    debugPrint('Named shops after filtering: ${results.length}');

    if (nearestFirst) {
      results.sort(
        (a, b) => a.distanceKm.compareTo(b.distanceKm),
      );
    } else {
      results.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return results;
  }

  Future<List<dynamic>> _fetchShopElements(
    String overpassQuery,
  ) async {
    Object? lastError;

    for (final endpoint in _overpassEndpoints) {
      // Retry a failed endpoint once before moving to the next one.
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          debugPrint('Trying shop search endpoint: $endpoint');

          final response = await http
              .post(
                Uri.parse(endpoint),
                headers: {
                  'User-Agent': _userAgent,
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: {'data': overpassQuery},
              )
              .timeout(const Duration(seconds: 60));

          if (response.statusCode == 200) {
            final decoded =
                jsonDecode(response.body) as Map<String, dynamic>;

            final elements = decoded['elements'];
            if (elements is List<dynamic>) {
              return elements;
            }

            throw Exception('Invalid response from shop search service.');
          }

          lastError = Exception(
            'HTTP ${response.statusCode} from $endpoint',
          );

          // Do not keep retrying client errors, except rate limits.
          if (response.statusCode < 500 &&
              response.statusCode != 429) {
            break;
          }
        } on TimeoutException catch (error) {
          lastError = error;
          debugPrint('Shop search timed out: $endpoint');
        } catch (error) {
          lastError = error;
          debugPrint('Shop search failed: $error');
        }
      }
    }

    throw Exception(
      'Could not load shops because the map data services failed. '
      'Please try again later. Details: $lastError',
    );
  }

  Future<_AreaCenter> _findAreaCenter(String area) async {
    final uri = Uri.parse('$_nominatim/search').replace(
      queryParameters: {
        'q': area,
        'format': 'jsonv2',
        'limit': '1',
      },
    );

    final response = await http
        .get(
          uri,
          headers: {'User-Agent': _userAgent},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Could not find this city or area.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;

    if (list.isEmpty) {
      throw Exception(
        'City or area not found. Try a more specific name.',
      );
    }

    final result = list.first as Map<String, dynamic>;

    return _AreaCenter(
      double.parse(result['lat'].toString()),
      double.parse(result['lon'].toString()),
    );
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

  List<_ShopTag> _tagsForCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'clothes':
      case 'clothing':
        return [
          _ShopTag('shop', 'clothes'),
          _ShopTag('shop', 'boutique'),
        ];

      case 'shoes':
        return [
          _ShopTag('shop', 'shoes'),
          _ShopTag('shop', 'shoe_repair'),
        ];

      case 'medicine':
      case 'pharmacy':
        return [
          _ShopTag('shop', 'chemist'),
          _ShopTag('amenity', 'pharmacy'),
        ];

      case 'groceries':
      case 'grocery':
        return [
          _ShopTag('shop', 'supermarket'),
          _ShopTag('shop', 'convenience'),
          _ShopTag('shop', 'grocery'),
        ];

      case 'electronics':
        return [_ShopTag('shop', 'electronics')];

      case 'books':
        return [_ShopTag('shop', 'books')];

      case 'food':
      case 'restaurants':
        return [
          _ShopTag('amenity', 'restaurant'),
          _ShopTag('amenity', 'cafe'),
          _ShopTag('amenity', 'fast_food'),
        ];

      case 'gifts':
        return [_ShopTag('shop', 'gift')];

      default:
        return [_ShopTag('shop', category.trim().toLowerCase())];
    }
  }

  double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}

class _ShopTag {
  final String key;
  final String value;

  const _ShopTag(this.key, this.value);
}

class _AreaCenter {
  final double lat;
  final double lng;

  const _AreaCenter(this.lat, this.lng);
}
