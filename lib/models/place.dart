
class PickedPlace {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const PickedPlace({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }

  factory PickedPlace.fromMap(Map<String, dynamic> map) {
    return PickedPlace(
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }
}
