import '../api/api_client.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      PlaceSuggestion(
        placeId: json['place_id'] as String,
        description: json['description'] as String? ?? '',
        mainText:
            json['main_text'] as String? ??
            json['description'] as String? ??
            '',
        secondaryText: json['secondary_text'] as String? ?? '',
      );
}

class PlaceDetails {
  final String address;
  final double lat;
  final double lng;

  const PlaceDetails({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) => PlaceDetails(
    address:
        json['address'] as String? ??
        json['formatted_address'] as String? ??
        '',
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );
}

class RouteStep {
  final String instruction;
  final String maneuver;
  final double distanceM;
  final int durationSeconds;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String polyline;

  const RouteStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceM,
    required this.durationSeconds,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    this.polyline = '',
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
    instruction: json['instruction'] as String? ?? 'Continue',
    maneuver: json['maneuver'] as String? ?? 'straight',
    distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
    durationSeconds: (json['duration_seconds'] as num?)?.round() ?? 0,
    startLat: (json['start_lat'] as num?)?.toDouble() ?? 0,
    startLng: (json['start_lng'] as num?)?.toDouble() ?? 0,
    endLat: (json['end_lat'] as num?)?.toDouble() ?? 0,
    endLng: (json['end_lng'] as num?)?.toDouble() ?? 0,
    polyline: json['polyline'] as String? ?? '',
  );
}

class RouteOption {
  final String label;
  final String polyline;
  final double distanceKm;
  final int durationMinutes;
  final String provider;
  final bool isFallback;
  final List<RouteStep> steps;

  const RouteOption({
    required this.label,
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
    this.provider = 'unknown',
    this.isFallback = false,
    this.steps = const [],
  });

  factory RouteOption.fromJson(
    Map<String, dynamic> json, {
    String fallbackLabel = 'Route',
  }) => RouteOption(
    label: json['label'] as String? ?? fallbackLabel,
    polyline: json['polyline'] as String? ?? '',
    distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    durationMinutes: (json['duration_minutes'] as num?)?.round() ?? 0,
    provider: json['provider'] as String? ?? 'unknown',
    isFallback: json['is_fallback'] == true,
    steps: (json['steps'] as List<dynamic>? ?? [])
        .map((e) => RouteStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class RouteDirections extends RouteOption {
  final List<RouteOption> routes;

  const RouteDirections({
    required super.label,
    required super.polyline,
    required super.distanceKm,
    required super.durationMinutes,
    super.provider,
    super.isFallback,
    super.steps,
    this.routes = const [],
  });

  factory RouteDirections.fromJson(Map<String, dynamic> json) {
    final routes = (json['routes'] as List<dynamic>? ?? [])
        .map((e) => RouteOption.fromJson(e as Map<String, dynamic>))
        .where((route) => route.polyline.isNotEmpty)
        .toList();
    final selected = routes.isNotEmpty ? routes.first : null;
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    final steps = rawSteps.isNotEmpty
        ? rawSteps
            .map((e) => RouteStep.fromJson(e as Map<String, dynamic>))
            .toList()
        : selected?.steps ?? const <RouteStep>[];
    return RouteDirections(
      label: json['label'] as String? ?? selected?.label ?? 'Recommended',
      polyline: json['polyline'] as String? ?? selected?.polyline ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ??
          selected?.distanceKm ??
          0,
      durationMinutes: (json['duration_minutes'] as num?)?.round() ??
          selected?.durationMinutes ??
          0,
      provider: json['provider'] as String? ?? selected?.provider ?? 'unknown',
      isFallback: json['is_fallback'] == true || selected?.isFallback == true,
      steps: steps,
      routes: routes,
    );
  }
}

class MapsService {
  final ApiClient _api;

  MapsService(this._api);

  Future<List<PlaceSuggestion>> autocomplete(
    String query, {
    double? lat,
    double? lng,
  }) async {
    final data = await _api.get(
      '/maps/autocomplete',
      query: {
        'input': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    final list =
        data['predictions'] as List<dynamic>? ??
        data['results'] as List<dynamic>? ??
        [];
    return list
        .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlaceDetails> getPlace(String placeId) async {
    final data = await _api.get('/maps/place', query: {'place_id': placeId});
    return PlaceDetails.fromJson(data);
  }

  Future<PlaceDetails> reverseGeocode(double lat, double lng) async {
    final data = await _api.get(
      '/maps/reverse',
      query: {'lat': lat, 'lng': lng},
    );
    return PlaceDetails(
      address: data['address'] as String? ?? '',
      lat: lat,
      lng: lng,
    );
  }

  Future<RouteDirections> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final data = await _api.get(
      '/maps/directions',
      query: {
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
      },
    );
    return RouteDirections.fromJson(data);
  }
}
