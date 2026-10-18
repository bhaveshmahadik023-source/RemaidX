import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

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

class _ShopSuggestionsPageState extends State<ShopSuggestionsPage> {
  final ShopService _service = ShopService();

  gmaps.GoogleMapController? _mapController;
  bool _nearestFirst = true;
  late Future<List<Shop>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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

  Future<void> _showShopOnMap(Shop shop) async {
    await _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(shop.lat, shop.lng),
          zoom: 16,
        ),
      ),
    );
  }

  Set<gmaps.Marker> _markersFor(List<Shop> shops) {
    return shops.map((shop) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(shop.id.toString()),
        position: gmaps.LatLng(shop.lat, shop.lng),
        infoWindow: gmaps.InfoWindow(title: shop.name),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueViolet,
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: Text('${widget.category} shops TEST'),
      ),
      body: FutureBuilder<List<Shop>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Shows the real reason (key missing, API blocked, etc.).
                    Text(
                      snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
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
              ? gmaps.LatLng(shops.first.lat, shops.first.lng)
              : const gmaps.LatLng(18.5204, 73.8567);

          return Column(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: initialCenter,
                    zoom: 13,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markersFor(shops),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
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
                      'Shop data provided by Google Maps. '
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