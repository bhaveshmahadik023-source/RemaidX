import 'package:flutter/material.dart';
import '../constants.dart';

// The big teal rounded button used on many screens
// (Use this location, Get started, Continue, Log in...).
class PrimaryButton extends StatelessWidget {
  final String text; // text shown on the button
  final VoidCallback onTap; // what happens when tapped
  final bool loading; // true = show a spinner and disable the button

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kTeal,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        // null disables the button, so it cannot be tapped while loading
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(text,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}