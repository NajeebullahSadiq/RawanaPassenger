import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Round profile photo with an initials fallback.
class RawanaAvatar extends StatelessWidget {
  const RawanaAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 52,
    this.ring = false,
  });

  final String name;
  final String? photoUrl;
  final double size;

  /// White ring, for avatars that overlap a map or another surface.
  final bool ring;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: RawanaColors.inkGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: context.text.title.copyWith(color: Colors.white, fontSize: size * 0.36),
      ),
    );
    final url = photoUrl?.trim();
    final image = (url == null || url.isEmpty)
        ? fallback
        : ClipOval(
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
            ),
          );
    return Container(
      width: size,
      height: size,
      padding: ring ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      decoration: ring
          ? BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: RawanaShadows.low)
          : null,
      child: image,
    );
  }
}
