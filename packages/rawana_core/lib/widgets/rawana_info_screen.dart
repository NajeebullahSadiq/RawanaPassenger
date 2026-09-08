import 'package:flutter/material.dart';
import '../content/rawana_driver_content.dart';
import '../theme/rawana_theme.dart';
import 'rawana_section_label.dart';
import 'rawana_surface_card.dart';

/// Scrollable policy / guidelines screen built from [RawanaInfoSection] blocks.
class RawanaInfoScreen extends StatelessWidget {
  const RawanaInfoScreen({
    super.key,
    required this.title,
    required this.sections,
    this.leading,
  });

  final String title;
  final List<RawanaInfoSection> sections;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          if (leading != null) ...[leading!, const SizedBox(height: 20)],
          for (final section in sections) ...[
            RawanaSectionLabel(
              section.title,
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            ),
            RawanaSurfaceCard(
              padding: const EdgeInsets.all(18),
              shadows: const [],
              border: Border.all(color: RawanaColors.divider),
              child: Text(
                section.body,
                style: const TextStyle(
                  color: RawanaColors.onSurface,
                  height: 1.55,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
