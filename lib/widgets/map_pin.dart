import 'package:flutter/material.dart';
import '../constants.dart';

// The round pin drawn on the map (colored circle, white border, white dot).
// Used in B4 (reminders) and C2 (selected place).
class MapPin extends StatelessWidget {
  final Color color; // teal for place, purple for shopping
  const MapPin({super.key, this.color = kTeal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}