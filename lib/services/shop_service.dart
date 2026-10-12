
class Shop {
  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final double distanceKm;

  const Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.distanceKm,
  });
}

class ShopService {
  static const List<Shop> _shops = [
    Shop(
      id: '1',
      name: 'Fashion Street',
      category: 'Clothes',
      address: 'Main Road',
      city: 'Pune',
      distanceKm: 0.8,
    ),
    Shop(
      id: '2',
      name: 'Central Mall',
      category: 'Clothes',
      address: 'City Centre',
      city: 'Pune',
      distanceKm: 1.4,
    ),
    Shop(
      id: '3',
      name: 'Local Cloth Store',
      category: 'Clothes',
      address: 'Market Lane',
      city: 'Pune',
      distanceKm: 1.6,
    ),
    Shop(
      id: '4',
      name: 'Style Hub',
      category: 'Clothes',
      address: 'Station Road',
      city: 'Pune',
      distanceKm: 2.1,
    ),
    Shop(
      id: '5',
      name: 'Shoe Point',
      category: 'Shoes',
      address: 'MG Road',
      city: 'Pune',
      distanceKm: 0.7,
    ),
    Shop(
      id: '6',
      name: 'StepUp Footwear',
      category: 'Shoes',
      address: 'Market Lane',
      city: 'Pune',
      distanceKm: 1.3,
    ),
    Shop(
      id: '7',
      name: 'City Medical',
      category: 'Medicine',
      address: 'Main Road',
      city: 'Pune',
      distanceKm: 0.6,
    ),
    Shop(
      id: '8',
      name: 'Health Plus Pharmacy',
      category: 'Medicine',
      address: 'Station Road',
      city: 'Pune',
      distanceKm: 1.2,
    ),
    Shop(
      id: '9',
      name: 'Fresh Basket',
      category: 'Groceries',
      address: 'Market Lane',
      city: 'Pune',
      distanceKm: 0.5,
    ),
    Shop(
      id: '10',
      name: 'Daily Needs Mart',
      category: 'Groceries',
      address: 'Main Road',
      city: 'Pune',
      distanceKm: 1.1,
    ),
    Shop(
      id: '11',
      name: 'Tech World',
      category: 'Electronics',
      address: 'City Centre',
      city: 'Pune',
      distanceKm: 1.8,
    ),
    Shop(
      id: '12',
      name: 'Book Corner',
      category: 'Books',
      address: 'College Road',
      city: 'Pune',
      distanceKm: 0.9,
    ),
    Shop(
      id: '13',
      name: 'Tasty Bites',
      category: 'Food',
      address: 'FC Road',
      city: 'Pune',
      distanceKm: 0.4,
    ),
    Shop(
      id: '14',
      name: 'Gift Gallery',
      category: 'Gifts',
      address: 'MG Road',
      city: 'Pune',
      distanceKm: 1.5,
    ),
  ];

  Future<List<Shop>> findShops({
    required String category,
    required String city,
    required String query,
    required bool nearestFirst,
  }) async {
    // Simulate an asynchronous data request.
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    final normalizedCity = city.trim().toLowerCase();
    final normalizedQuery = query.trim().toLowerCase();

    final results = _shops.where((shop) {
      final categoryMatches =
          shop.category.toLowerCase() ==
              category.toLowerCase();

      final cityMatches =
          normalizedCity.isEmpty ||
          shop.city.toLowerCase().contains(normalizedCity) ||
          normalizedCity.contains(shop.city.toLowerCase());

      final queryMatches =
          normalizedQuery.isEmpty ||
          shop.name.toLowerCase().contains(normalizedQuery) ||
          shop.address.toLowerCase().contains(normalizedQuery) ||
          shop.category.toLowerCase().contains(normalizedQuery);

      return categoryMatches && cityMatches && queryMatches;
    }).toList();

    if (nearestFirst) {
      results.sort(
        (a, b) => a.distanceKm.compareTo(b.distanceKm),
      );
    } else {
      results.sort(
        (a, b) => a.name.compareTo(b.name),
      );
    }

    return results;
  }
}
