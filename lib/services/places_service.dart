import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place.dart';

// Talks to Nominatim (free OpenStreetMap service) for two things:
//   1. search("Phoenix")  -> list of places with lat/lng
//   2. reverse(lat, lng)  -> name of the place at that point
class PlacesService {
  static const _base = 'https://nominatim.openstreetmap.org';

  // Nominatim asks every app to send its name in User-Agent.
  // (Browsers like Chrome ignore this and send their own Referer, that is OK.)
  static const _headers = {'User-Agent': 'RemindX/1.0 (student project)'};

  // Search by text. Returns max 8 results.
  static Future<List<PickedPlace>> search(String query) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'limit': '8',
      'accept-language': 'en',
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode})');
    }

    final list = jsonDecode(res.body) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      // "display_name" looks like: "Phoenix Marketcity, Viman Nagar, Pune, ..."
      // We take the first part as the name and the next 3 parts as the address.
      final parts = (m['display_name'] as String? ?? '').split(', ');
      final name = (m['name'] as String?)?.isNotEmpty == true
          ? m['name'] as String
          : parts.first;
      return PickedPlace(
        name: name,
        address: parts.skip(1).take(3).join(', '),
        lat: double.parse(m['lat'].toString()),
        lng: double.parse(m['lon'].toString()),
      );
    }).toList();
  }

  // Find the name of a place from its coordinates.
  // The result keeps the exact point the user tapped, not the address point.
  static Future<PickedPlace> reverse(LatLng p) async {
    final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
      'lat': p.latitude.toString(),
      'lon': p.longitude.toString(),
      'format': 'jsonv2',
      'zoom': '17',
      'accept-language': 'en',
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('Reverse failed');

    final m = jsonDecode(res.body) as Map<String, dynamic>;
    final parts = (m['display_name'] as String? ?? '').split(', ');
    final name = (m['name'] as String?)?.isNotEmpty == true
        ? m['name'] as String
        : (parts.first.isEmpty ? 'Dropped pin' : parts.first);
    return PickedPlace(
      name: name,
      address: parts.skip(1).take(3).join(', '),
      lat: p.latitude,
      lng: p.longitude,
    );
  }
}