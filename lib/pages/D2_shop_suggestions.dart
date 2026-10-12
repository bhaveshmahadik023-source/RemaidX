
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/shop_service.dart';
import 'D3_confirm_shop.dart';

const Color _teal = Color(0xFF117C75);
const Color _purple = Color(0xFF6155CC);

class ShopSuggestionsPage extends StatefulWidget {
  final String category;
  final String query;
  final String city;

  const ShopSuggestionsPage({
    super.key,
    required this.category,
    required this.query,
    required this.city,
  });

  @override
  State<ShopSuggestionsPage> createState() =>
      _ShopSuggestionsPageState();
}

class _ShopSuggestionsPageState
    extends State<ShopSuggestionsPage> {
  final ShopService _service = ShopService();
  final MapController _mapController = MapController();

  bool _nearestFirst = true;
  late Future<List<Shop>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  void _loadShops() {
    _shopsFuture = _service.findShops(
      category: widget.category,
      city: widget.city,
      query: widget.query,
      nearestFirst: _nearestFirst,
    );
  }

  void _sort(bool nearest) {
    setState(() {
      _nearestFirst = nearest;
      _loadShops();
    });
  }

  void _showShopOnMap(Shop shop) {
    _mapController.move(
      LatLng(shop.lat, shop.lng),
      16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: Text('${widget.category} shops'),
      ),
      body: FutureBuilder<List<Shop>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load real shops.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check your internet connection or try again later.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(_loadShops);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final shops = snapshot.data ?? [];

          final initialCenter = shops.isNotEmpty
              ? LatLng(shops.first.lat, shops.first.lng)
              : const LatLng(18.5204, 73.8567);

          return Column(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.remindx',
                    ),
                    MarkerLayer(
                      markers: shops.map((shop) {
                        return Marker(
                          point: LatLng(shop.lat, shop.lng),
                          width: 44,
                          height: 52,
                          child: Tooltip(
                            message: shop.name,
                            child: const Icon(
                              Icons.location_on,
                              color: _purple,
                              size: 42,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${shops.length} real shops found',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Nearest'),
                          selected: _nearestFirst,
                          onSelected: (_) => _sort(true),
                        ),
                        ChoiceChip(
                          label: const Text('A to Z'),
                          selected: !_nearestFirst,
                          onSelected: (_) => _sort(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (shops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Text(
                          'No shops found in this area. '
                          'Try another city, area, or category.',
                          textAlign: TextAlign.center,
                        ),
                      ),

                    ...shops.map(
                      (shop) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: Color(0xFFD8DEDE),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _showShopOnMap(shop),
                          leading: const CircleAvatar(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.store),
                          ),
                          title: Text(
                            shop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${shop.address} · '
                            '${shop.distanceKm.toStringAsFixed(1)} km',
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ConfirmShopPage(
                                    shop: shop,
                                    task:
                                        'Buy ${widget.category.toLowerCase()}',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Select'),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Map and shop data provided by OpenStreetMap. '
                      'Some shops may not be listed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
