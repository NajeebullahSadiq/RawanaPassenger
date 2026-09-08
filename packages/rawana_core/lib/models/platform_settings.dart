class PlatformSettings {
  final bool maintenanceMode;
  final bool forceUpdate;
  final String maintenanceMessage;
  final String minAndroid;
  final String minIos;
  final String storeUrlAndroid;
  final String storeUrlIos;
  final String driverStoreUrlAndroid;
  final String driverStoreUrlIos;

  const PlatformSettings({
    required this.maintenanceMode,
    required this.forceUpdate,
    required this.maintenanceMessage,
    required this.minAndroid,
    required this.minIos,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
    required this.driverStoreUrlAndroid,
    required this.driverStoreUrlIos,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) => PlatformSettings(
        maintenanceMode: json['maintenance_mode'] == true,
        forceUpdate: json['force_update'] == true,
        maintenanceMessage: json['maintenance_message'] as String? ??
            'Rawana is temporarily unavailable. Please try again shortly.',
        minAndroid: json['min_app_version_android'] as String? ?? '0.0.0',
        minIos: json['min_app_version_ios'] as String? ?? '0.0.0',
        storeUrlAndroid: json['store_url_android'] as String? ?? '',
        storeUrlIos: json['store_url_ios'] as String? ?? '',
        driverStoreUrlAndroid: json['driver_store_url_android'] as String? ?? '',
        driverStoreUrlIos: json['driver_store_url_ios'] as String? ?? '',
      );

  String storeUrl({required bool ios, required bool driverApp}) {
    if (driverApp) {
      return ios ? driverStoreUrlIos : driverStoreUrlAndroid;
    }
    return ios ? storeUrlIos : storeUrlAndroid;
  }
}

int _compareSemver(String a, String b) {
  List<int> parts(String v) {
    final core = v.split(RegExp(r'[+-]')).first;
    return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  final left = parts(a);
  final right = parts(b);
  for (var i = 0; i < 3; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l - r;
  }
  return 0;
}

enum PlatformBlockKind { maintenance, forceUpdate }

class PlatformBlock {
  final PlatformBlockKind kind;
  final String message;
  final String? storeUrl;

  const PlatformBlock({
    required this.kind,
    required this.message,
    this.storeUrl,
  });
}

PlatformBlock? evaluatePlatformGate({
  required PlatformSettings settings,
  required String appVersion,
  required bool ios,
  required bool driverApp,
}) {
  if (settings.maintenanceMode) {
    return PlatformBlock(
      kind: PlatformBlockKind.maintenance,
      message: settings.maintenanceMessage,
    );
  }
  if (!settings.forceUpdate) return null;
  final min = ios ? settings.minIos : settings.minAndroid;
  if (_compareSemver(appVersion, min) < 0) {
    return PlatformBlock(
      kind: PlatformBlockKind.forceUpdate,
      message: min,
      storeUrl: settings.storeUrl(ios: ios, driverApp: driverApp),
    );
  }
  return null;
}
