import 'package:flutter/material.dart';

/// Google Maps-style “Re-center” pill for live maps.
class MapRecenterButton extends StatelessWidget {
  const MapRecenterButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const _teal = Color(0xFF1B7A7A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD0D5DD)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded, size: 18, color: _teal),
              SizedBox(width: 8),
              Text(
                'Re-center',
                style: TextStyle(
                  color: _teal,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
