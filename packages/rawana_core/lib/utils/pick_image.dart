import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/ui/rawana_action_sheet.dart';

/// Asks camera or gallery (gallery only on web), then picks one image.
/// Resolves to null when the user cancels either step.
Future<XFile?> pickRawanaImage(
  BuildContext context, {
  String? title,
  bool frontCamera = false,
  int imageQuality = 80,
  double maxDimension = 2048,
}) async {
  ImageSource? source = ImageSource.gallery;
  if (!kIsWeb) {
    final l10n = context.l10n;
    source = await RawanaActionSheet.menu<ImageSource>(
      context,
      title: title ?? l10n.addPhoto,
      options: [
        RawanaSheetOption(value: ImageSource.camera, label: l10n.takePhoto, icon: LucideIcons.camera),
        RawanaSheetOption(value: ImageSource.gallery, label: l10n.chooseFromGallery, icon: LucideIcons.image),
      ],
    );
  }
  if (source == null) return null;
  return ImagePicker().pickImage(
    source: source,
    preferredCameraDevice: frontCamera ? CameraDevice.front : CameraDevice.rear,
    imageQuality: imageQuality,
    maxWidth: maxDimension,
    maxHeight: maxDimension,
  );
}
