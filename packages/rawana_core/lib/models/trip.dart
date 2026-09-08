import '../utils/geo_parse.dart';

enum TripStatus {
  searching,
  accepted,
  driverArriving,
  tripStarted,
  completed,
  cancelled;

  static TripStatus fromString(String value) => switch (value) {
    'searching' => TripStatus.searching,
    'accepted' => TripStatus.accepted,
    'driver_arriving' => TripStatus.driverArriving,
    'trip_started' => TripStatus.tripStarted,
    'completed' => TripStatus.completed,
    'cancelled' => TripStatus.cancelled,
    _ => TripStatus.searching,
  };

  String get apiValue => switch (this) {
    TripStatus.searching => 'searching',
    TripStatus.accepted => 'accepted',
    TripStatus.driverArriving => 'driver_arriving',
    TripStatus.tripStarted => 'trip_started',
    TripStatus.completed => 'completed',
    TripStatus.cancelled => 'cancelled',
  };

  bool get isActive => [
    TripStatus.searching,
    TripStatus.accepted,
    TripStatus.driverArriving,
    TripStatus.tripStarted,
  ].contains(this);
}

class TripLocation {
  final double lat;
  final double lng;
  final String address;

  const TripLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class TripParty {
  final String? name;
  final String? phone;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColour;
  final String? plateNumber;
  final String? profilePhotoUrl;
  final double? ratingAverage;

  const TripParty({
    this.name,
    this.phone,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColour,
    this.plateNumber,
    this.profilePhotoUrl,
    this.ratingAverage,
  });

  factory TripParty.fromUserJson(Map<String, dynamic>? json) => TripParty(
    name: json?['name'] as String?,
    phone: json?['phone'] as String?,
    ratingAverage: (json?['rating_average'] as num?)?.toDouble(),
  );

  factory TripParty.fromDriverJson(Map<String, dynamic>? json) => TripParty(
    name: json?['name'] as String?,
    phone: json?['phone'] as String?,
    vehicleMake: json?['vehicle_make'] as String?,
    vehicleModel: json?['vehicle_model'] as String?,
    vehicleColour: json?['vehicle_colour'] as String?,
    plateNumber: json?['plate_number'] as String?,
    profilePhotoUrl: json?['profile_photo_url'] as String?,
    ratingAverage: (json?['rating_average'] as num?)?.toDouble(),
  );
}

class Trip {
  final String id;
  final TripStatus status;
  final String? rideTypeId;
  final String? rideTypeName;
  final String? rideTypeIconName;
  final String pickupAddress;
  final String dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final int? estimatedFare;
  final int? finalFare;
  final double? distanceKm;
  final int? durationMinutes;
  final String? driverId;
  final TripParty? passenger;
  final TripParty? driver;
  final String currency;
  final DateTime? driverArrivedAt;
  final DateTime? searchExpiresAt;
  final DateTime? offerExpiresAt;
  final DateTime? acceptedAt;
  final DateTime? cashCollectedAt;
  final DateTime? serverTime;
  final int? taxAmount;
  final int? upfrontFare;
  final DateTime? createdAt;
  final int? discountAmount;
  final int? creditApplied;
  /// Unpaid cancellation fee from an earlier booking collected on this ride.
  final int outstandingFeeApplied;
  final String? promoCode;
  final int rematchCount;
  final String? routeSnapshotUrl;
  /// `passenger` | `driver` | `admin` once the trip is cancelled.
  final String? cancelledBy;
  final String? cancellationReason;

  const Trip({
    required this.id,
    required this.status,
    this.rideTypeId,
    this.rideTypeName,
    this.rideTypeIconName,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.estimatedFare,
    this.finalFare,
    this.distanceKm,
    this.durationMinutes,
    this.driverId,
    this.passenger,
    this.driver,
    this.currency = 'AFN',
    this.driverArrivedAt,
    this.searchExpiresAt,
    this.offerExpiresAt,
    this.acceptedAt,
    this.cashCollectedAt,
    this.serverTime,
    this.taxAmount,
    this.upfrontFare,
    this.createdAt,
    this.discountAmount,
    this.creditApplied,
    this.outstandingFeeApplied = 0,
    this.promoCode,
    this.rematchCount = 0,
    this.routeSnapshotUrl,
    this.cancelledBy,
    this.cancellationReason,
  });

  /// True when the system closed the search because nobody accepted.
  bool get cancelledForNoDrivers =>
      status == TripStatus.cancelled &&
      cancelledBy == 'admin' &&
      cancellationReason == 'no_drivers_available';

  /// Cash the passenger hands the driver.
  ///
  /// Once the server has settled the trip, `final_fare` is authoritative; before
  /// that the server-provided `upfront_fare` (estimate + tax − credit) is used.
  int get cashToCollect {
    final settled = finalFare;
    if (status == TripStatus.completed && settled != null && settled >= 0) {
      return settled;
    }
    if (upfrontFare != null) return upfrontFare!;
    if ((settled ?? 0) > 0) return settled!;
    return ((estimatedFare ?? 0) + (taxAmount ?? 0) - (creditApplied ?? 0) + outstandingFeeApplied)
        .clamp(0, 1 << 31);
  }

  /// The ride price itself — excludes any outstanding fee collected for Rawana.
  int get rideFare => (cashToCollect - outstandingFeeApplied).clamp(0, 1 << 31);

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  static double? _numAsDouble(Object? value) => value is num
      ? value.toDouble()
      : value is String
      ? double.tryParse(value)
      : null;

  static double? _parsePointLat(Object? point) => parseWktLat(point);

  static double? _parsePointLng(Object? point) => parseWktLng(point);

  factory Trip.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;
    final drivers = json['drivers'] as Map<String, dynamic>?;
    final pickupLocation = json['pickup_location'];
    final dropoffLocation = json['dropoff_location'];
    return Trip(
      id: json['id'] as String,
      status: TripStatus.fromString(json['status'] as String? ?? 'searching'),
      rideTypeId: json['ride_type_id'] as String?,
      rideTypeName: json['ride_type_name'] as String? ??
          _asMap(json['ride_types'])?['name'] as String?,
      rideTypeIconName: json['ride_type_icon'] as String? ??
          _asMap(json['ride_types'])?['icon_name'] as String?,
      pickupAddress: json['pickup_address'] as String? ?? '',
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      pickupLat:
          _numAsDouble(json['pickup_lat']) ?? _parsePointLat(pickupLocation),
      pickupLng:
          _numAsDouble(json['pickup_lng']) ?? _parsePointLng(pickupLocation),
      dropoffLat:
          _numAsDouble(json['dropoff_lat']) ?? _parsePointLat(dropoffLocation),
      dropoffLng:
          _numAsDouble(json['dropoff_lng']) ?? _parsePointLng(dropoffLocation),
      estimatedFare: (json['estimated_fare'] as num?)?.round(),
      finalFare: (json['final_fare'] as num?)?.round(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.round(),
      driverId: json['driver_id'] as String?,
      passenger: users != null ? TripParty.fromUserJson(users) : null,
      driver: drivers != null ? TripParty.fromDriverJson(drivers) : null,
      currency: json['currency'] as String? ?? 'AFN',
      driverArrivedAt: json['driver_arrived_at'] != null
          ? DateTime.tryParse(json['driver_arrived_at'] as String)
          : null,
      searchExpiresAt: json['search_expires_at'] != null
          ? DateTime.tryParse(json['search_expires_at'] as String)
          : null,
      offerExpiresAt: json['offer_expires_at'] != null
          ? DateTime.tryParse(json['offer_expires_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      cashCollectedAt: json['cash_collected_at'] != null
          ? DateTime.tryParse(json['cash_collected_at'] as String)
          : null,
      serverTime: json['server_time'] != null
          ? DateTime.tryParse(json['server_time'] as String)
          : null,
      taxAmount: (json['tax_amount'] as num?)?.round(),
      upfrontFare: (json['upfront_fare'] as num?)?.round(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      discountAmount: (json['discount_amount'] as num?)?.round(),
      creditApplied: (json['credit_applied'] as num?)?.round(),
      outstandingFeeApplied: (json['outstanding_fee_applied'] as num?)?.round() ?? 0,
      promoCode: json['promo_code'] as String?,
      rematchCount: (json['rematch_count'] as num?)?.round() ?? 0,
      routeSnapshotUrl: json['route_snapshot_url'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }
}

class DriverLocation {
  final double? lat;
  final double? lng;
  final double? heading;

  const DriverLocation({this.lat, this.lng, this.heading});

  factory DriverLocation.fromJson(Map<String, dynamic> json) => DriverLocation(
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    heading: _usableHeading((json['heading'] as num?)?.toDouble()),
  );
}

/// Online driver near the passenger pickup point (pre-match map display).
class NearbyDriver {
  final String driverId;
  final double lat;
  final double lng;
  final double? heading;
  final double? distanceMeters;
  final double? ratingAverage;

  const NearbyDriver({
    required this.driverId,
    required this.lat,
    required this.lng,
    this.heading,
    this.distanceMeters,
    this.ratingAverage,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) => NearbyDriver(
    driverId: json['driver_id'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    heading: _usableHeading((json['heading'] as num?)?.toDouble()),
    distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    ratingAverage: (json['rating_average'] as num?)?.toDouble(),
  );
}

class TripBookingDraft {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final String? rideTypeId;
  final String? promoCode;

  const TripBookingDraft({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    this.rideTypeId,
    this.promoCode,
  });

  TripBookingDraft copyWith({
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
    String? rideTypeId,
    String? promoCode,
  }) => TripBookingDraft(
    pickupLat: pickupLat ?? this.pickupLat,
    pickupLng: pickupLng ?? this.pickupLng,
    pickupAddress: pickupAddress ?? this.pickupAddress,
    dropoffLat: dropoffLat ?? this.dropoffLat,
    dropoffLng: dropoffLng ?? this.dropoffLng,
    dropoffAddress: dropoffAddress ?? this.dropoffAddress,
    rideTypeId: rideTypeId ?? this.rideTypeId,
    promoCode: promoCode ?? this.promoCode,
  );
}

double? _usableHeading(double? heading) {
  if (heading == null || heading <= 0 || heading > 360) return null;
  return heading;
}
