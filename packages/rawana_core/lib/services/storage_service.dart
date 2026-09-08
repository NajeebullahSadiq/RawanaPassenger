import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Uploads files to Supabase Storage buckets. Works on both native (using a
/// `dart:io` [File]) and on Flutter web (using raw bytes), because the web
/// browser cannot access the host filesystem.
class StorageService {
  /// Upload by raw bytes — works on every platform including web. Prefer this
  /// when you already have an `XFile` from `image_picker` (call `readAsBytes`).
  static Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    _requireSupabase();
    final client = Supabase.instance.client;
    await client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Native-only convenience wrapper around [uploadBytes]. Throws on web.
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'uploadFile(File) is not available on web. Use uploadBytes instead.',
      );
    }
    _requireSupabase();
    final client = Supabase.instance.client;
    await client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<String> uploadDriverDocument({
    required String docType,
    required String userId,
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final ext = _resolveExt(fileName ?? file?.path);
    final path = '$userId/$docType-${DateTime.now().millisecondsSinceEpoch}.$ext';
    return _uploadFlexible(
      bucket: 'driver-documents',
      path: path,
      file: file,
      bytes: bytes,
      contentType: _mimeForExt(ext),
    );
  }

  /// Prefer [PassengerService.uploadProfilePhoto] / driver onboarding API on web —
  /// direct client uploads require storage RLS policies on the Supabase project.
  @Deprecated('Use API upload via PassengerService or DriverService instead')
  static Future<String> uploadProfilePhoto({
    required String userId,
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final ext = _resolveExt(fileName ?? file?.path);
    final path = '$userId/photo-${DateTime.now().millisecondsSinceEpoch}.$ext';
    return _uploadFlexible(
      bucket: 'profile-photos',
      path: path,
      file: file,
      bytes: bytes,
      contentType: _mimeForExt(ext),
    );
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  static Future<String> _uploadFlexible({
    required String bucket,
    required String path,
    File? file,
    Uint8List? bytes,
    String? contentType,
  }) async {
    if (bytes != null) {
      return uploadBytes(
        bucket: bucket,
        path: path,
        bytes: bytes,
        contentType: contentType,
      );
    }
    if (file != null) {
      return uploadFile(bucket: bucket, path: path, file: file);
    }
    throw ArgumentError('Either `bytes` or `file` must be provided.');
  }

  static void _requireSupabase() {
    if (!AppConfig.hasSupabase) {
      throw StateError(
        'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }

  static String _resolveExt(String? sourceName) {
    if (sourceName == null) return 'jpg';
    final lastDot = sourceName.lastIndexOf('.');
    if (lastDot < 0 || lastDot == sourceName.length - 1) return 'jpg';
    return sourceName.substring(lastDot + 1).toLowerCase();
  }

  static String? _mimeForExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }
}
