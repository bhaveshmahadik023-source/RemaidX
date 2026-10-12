
import 'package:flutter/material.dart';

import '../services/shop_service.dart';

const Color _teal = Color(0xFF117C75);
const Color _purple = Color(0xFF6155CC);

class ConfirmShopPage extends StatefulWidget {
  final Shop shop;
  final String task;

  const ConfirmShopPage({
    super.key,
    required this.shop,
    required this.task,
  });

  @override
  State<ConfirmShopPage> createState() =>
      _ConfirmShopPageState();
}

class _ConfirmShopPageState extends State<ConfirmShopPage> {
  double _radiusMeters = 700;
  String _alertType = 'Ring';

  String get _radiusLabel {
    if (_radiusMeters >= 1000) {
      return '${(_radiusMeters / 1000).toStringAsFixed(1)} km';
    }

    return '${_radiusMeters.round()} m';
  }

  Future<void> _saveReminder() async {
    // Reminder data prepared for future Firestore integration.
    final reminder = <String, dynamic>{
      'shopId': widget.shop.id,
      'shopName': widget.shop.name,
      'address': widget.shop.address,
      'city': widget.shop.city,
      'task': widget.task,
      'radiusMeters': _radiusMeters.round(),
      'alertType': _alertType,
      'createdAt': DateTime.now().toIso8601String(),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder configured for ${reminder['shopName']} '
          '(${reminder['radiusMeters']} m, $_alertType).',
        ),
        backgroundColor: _teal,
      ),
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (mounted) {
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Confirm shop'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selected shop information.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEDFF),
                border: Border.all(color: _purple),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.storefront_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.shop.address}, '
                          '${widget.shop.city} · '
                          '${widget.shop.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Illustrative map panel.
            Container(
              height: 105,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEEC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 78,
                    color: Color(0xFFB5C4BF),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0x335F55CC),
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: _purple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Your task',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 7),

            TextFormField(
              initialValue: widget.task,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    "Remind me when I'm within",
                  ),
                ),
                Text(
                  _radiusLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _teal,
                  ),
                ),
              ],
            ),

            Slider(
              value: _radiusMeters,
              min: 300,
              max: 1500,
              divisions: 24,
              activeColor: _teal,
              onChanged: (value) {
                setState(() => _radiusMeters = value);
              },
            ),

            Wrap(
              spacing: 8,
              children: [
                300.0,
                500.0,
                700.0,
                1000.0,
                1500.0,
              ].map((value) {
                final label = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(value == 1000 ? 0 : 1)} km'
                    : '${value.round()} m';

                return ChoiceChip(
                  label: Text(label),
                  selected: _radiusMeters == value,
                  onSelected: (_) {
                    setState(() => _radiusMeters = value);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            const Text('How should we alert you?'),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _alertOption(
                    'Message',
                    Icons.chat_bubble_outline,
                    'Notification',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _alertOption(
                    'Ring',
                    Icons.volume_up_outlined,
                    'Loud alarm sound',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _saveReminder,
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Save reminder',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertOption(
    String type,
    IconData icon,
    String subtitle,
  ) {
    final selected = _alertType == type;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => _alertType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE5F4F1)
              : Colors.white,
          border: Border.all(
            color: selected
                ? _teal
                : const Color(0xFFD8DEDE),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? _teal : Colors.black54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: _teal,
              ),
          ],
        ),
      ),
    );
  }
}
