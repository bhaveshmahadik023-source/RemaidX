import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place.dart';

// ---------------------------------------------------------------
// PASTE YOUR GOOGLE API KEY HERE.
// The key's API restrictions must include:
//   Places API (New)  and  Geocoding API
// ---------------------------------------------------------------
const String kGoogleApiKey = 'AIzaSyBZQ_lI0BHgAOrEVfTY7Q6W9w9-pFfe1Ds';

/// A suggestion shown while typing (no lat/lng yet; we get it after the user picks one).
class PlaceSuggestion {
  final String placeId;
  final String mainText; // "Phoenix Marketcity"
  final String secondaryText; // "Viman Nagar, Pune, Maharashtra"

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

// Uses Google Places (New) + Geocoding:
//   1. search("Phoenix")      -> list of places (with lat/lng)
//   2. reverse(lat, lng)      -> name of the place at that point
//   3. suggest("phoe")        -> smart suggestions while typing
//   4. fromSuggestion(id)     -> lat/lng of the chosen suggestion
//
// search() and reverse() keep the same names and return types as before,
// so other screens do not need any changes.
class PlacesService {
  static const _places = 'https://places.googleapis.com/v1';

  static void _checkKey() {
    if (kGoogleApiKey.trim().isEmpty ||
        kGoogleApiKey.startsWith('PASTE_')) {
      throw Exception(
        'Google API key is missing (add it at the top of places_service.dart).',
      );
    }
  }

  static Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(
        (body['error']?['message'] ?? 'Error ${res.statusCode}').toString(),
      );
    }
    return body;
  }

  // One search session (typing -> picking a place). Used for billing.
  static String newSessionToken() {
    final r = math.Random.secure();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  static PickedPlace _toPicked(Map<String, dynamic> p) {
    final loc = p['location'] as Map<String, dynamic>;
    return PickedPlace(
      name: (p['displayName']?['text'] ?? '').toString(),
      address: (p['formattedAddress'] ?? '').toString(),
      lat: (loc['latitude'] as num).toDouble(),
      lng: (loc['longitude'] as num).toDouble(),
    );
  }

  // -------------------------------------------------------------
  // 1. Text search. Max 8 results. If `near` is given, nearby places come first.
  // -------------------------------------------------------------
  static Future<List<PickedPlace>> search(String query, {LatLng? near}) async {
    _checkKey();

    final res = await http.post(
      Uri.parse('$_places/places:searchText'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': kGoogleApiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.location',
      },
      body: jsonEncode({
        'textQuery': query,
        'maxResultCount': 8,
        'languageCode': 'en',
        'regionCode': 'IN',
        if (near != null)
          'locationBias': {
            'circle': {
              'center': {
                'latitude': near.latitude,
                'longitude': near.longitude,
              },
              'radius': 30000.0,
            }
          },
      }),
    );

    final body = _parse(res);
    return [
      for (final p in (body['places'] as List?) ?? [])
        _toPicked(p as Map<String, dynamic>),
    ];
  }

  // -------------------------------------------------------------
  // 2. Name from coordinates. Keeps the exact point the user tapped.
  // -------------------------------------------------------------
  static Future<PickedPlace> reverse(LatLng p) async {
    _checkKey();

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${p.latitude},${p.longitude}',
      'language': 'en',
      'key': kGoogleApiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Reverse failed');

    final m = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (m['results'] as List?) ?? [];

    // Skip plus-code results (e.g. "FJ2V+X8"); they are not useful as a name.
    Map<String, dynamic>? best;
    for (final r in results) {
      final types = (r['types'] as List?)?.cast<String>() ?? const [];
      if (!types.contains('plus_code')) {
        best = r as Map<String, dynamic>;
        break;
      }
    }

    if (best == null) {
      return PickedPlace(
        name: 'Dropped pin',
        address: '',
        lat: p.latitude,
        lng: p.longitude,
      );
    }

    final parts = (best['formatted_address'] as String? ?? '').split(', ');
    return PickedPlace(
      name: parts.first.isEmpty ? 'Dropped pin' : parts.first,
      address: parts.skip(1).take(3).join(', '),
      lat: p.latitude,
      lng: p.longitude,
    );
  }

  // -------------------------------------------------------------
  // 3. Smart suggestions (while typing)
  // -------------------------------------------------------------
  static Future<List<PlaceSuggestion>> suggest(
    String input, {
    LatLng? near,
    String? sessionToken,
  }) async {
    _checkKey();
    if (input.trim().length < 2) return [];

    final res = await http.post(
      Uri.parse('$_places/places:autocomplete'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': kGoogleApiKey,
      },
      body: jsonEncode({
        'input': input,
        'languageCode': 'en',
        'includedRegionCodes': ['in'],
        if (sessionToken != null) 'sessionToken': sessionToken,
        if (near != null)
          'locationBias': {
            'circle': {
              'center': {
                'latitude': near.latitude,
                'longitude': near.longitude,
              },
              'radius': 30000.0,
            }
          },
      }),
    );

    final body = _parse(res);
    return [
      for (final s in (body['suggestions'] as List?) ?? [])
        if (s['placePrediction'] != null)
          PlaceSuggestion(
            placeId: s['placePrediction']['placeId'] as String,
            mainText: (s['placePrediction']['structuredFormat']?['mainText']
                        ?['text'] ??
                    s['placePrediction']['text']?['text'] ??
                    '')
                .toString(),
            secondaryText: (s['placePrediction']['structuredFormat']
                        ?['secondaryText']?['text'] ??
                    '')
                .toString(),
          ),
    ];
  }

  // -------------------------------------------------------------
  // 4. Get lat/lng after the user picks a suggestion
  // -------------------------------------------------------------
  static Future<PickedPlace> fromSuggestion(
    String placeId, {
    String? sessionToken,
  }) async {
    _checkKey();

    final uri = Uri.parse('$_places/places/$placeId').replace(
      queryParameters: {
        'languageCode': 'en',
        if (sessionToken != null) 'sessionToken': sessionToken,
      },
    );
    final res = await http.get(
      uri,
      headers: {
        'X-Goog-Api-Key': kGoogleApiKey,
        'X-Goog-FieldMask': 'displayName,formattedAddress,location',
      },
    );

    return _toPicked(_parse(res));
  }
}