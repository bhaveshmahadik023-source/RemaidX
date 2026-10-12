
import 'package:flutter/material.dart';

import 'D2_shop_suggestions.dart';

const Color _teal = Color(0xFF117C75);
const Color _purple = Color(0xFF6155CC);

class ShopSearchPage extends StatefulWidget {
  const ShopSearchPage({super.key});

  @override
  State<ShopSearchPage> createState() =>
      _ShopSearchPageState();
}

class _ShopSearchPageState extends State<ShopSearchPage> {
  final TextEditingController _itemController =
      TextEditingController(text: 'clothes');

  final TextEditingController _cityController =
      TextEditingController(text: 'Pune');

  String _category = 'Clothes';

  static const List<String> _categories = [
    'Clothes',
    'Shoes',
    'Medicine',
    'Groceries',
    'Electronics',
    'Books',
    'Food',
    'Gifts',
  ];

  @override
  void dispose() {
    _itemController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _findShops() {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a city or area.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopSuggestionsPage(
          category: _category,
          query: _itemController.text.trim(),
          city: _cityController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Find shops for me'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'What do you want to buy?',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.store_outlined),
                border: OutlineInputBorder(),
                hintText: 'Enter item or shop name',
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final selected = category == _category;

                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  selectedColor: const Color(0xFFEFEDFF),
                  side: BorderSide(
                    color: selected
                        ? _purple
                        : Colors.black12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _category = category;
                      _itemController.text =
                          category.toLowerCase();
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            const Text(
              'City or area',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _cityController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon:
                    Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
                hintText: 'Enter city (e.g. Pune)',
              ),
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEDFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _purple,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Choose a category and city. '
                      'Shop suggestions currently use demo data.',
                      style: TextStyle(color: _purple),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _findShops,
                icon: const Icon(Icons.search),
                label: const Text('Find nearby shops'),
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
