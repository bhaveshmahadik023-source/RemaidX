
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.category} shops in ${widget.city}',
        ),
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
            return const Center(
              child: Text(
                'Could not load shops. Please try again.',
              ),
            );
          }

          final shops = snapshot.data ?? [];

          return Column(
            children: [
              // Illustrative map panel.
              Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFFE9EEEC),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 110,
                      color: Color(0xFFB5C4BF),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: _purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 20,
                      child: Text(
                        widget.city,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${shops.length} shops found',
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
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'No demo shops found. '
                            'Try Pune or another category.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    ...shops.map(
                      (shop) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            color: Color(0xFFD8DEDE),
                          ),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            child: Text(shop.id),
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
                                  builder: (_) =>
                                      ConfirmShopPage(
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
                      'Demo shop data. Connect a Places API '
                      'for real listings.',
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
