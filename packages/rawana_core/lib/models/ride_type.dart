class RideType {
  final String id;
  final String name;
  final String iconName;
  final String description;
  final double fareMultiplier;
  final int displayOrder;

  const RideType({
    required this.id,
    required this.name,
    required this.iconName,
    required this.description,
    required this.fareMultiplier,
    required this.displayOrder,
  });

  factory RideType.fromJson(Map<String, dynamic> json) => RideType(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['icon_name'] as String? ?? 'car',
        description: json['description'] as String? ?? '',
        fareMultiplier: (json['fare_multiplier'] as num?)?.toDouble() ?? 1.0,
        displayOrder: json['display_order'] as int? ?? 0,
      );
}

class FareEstimate {
  final int estimatedFare;
  final int baseFare;
  final double farePerKm;
  final double farePerMin;
  final double distanceKm;
  final int durationMinutes;
  final int taxAmount;
  final String currency;
  final int discountAmount;
  final String? promoCode;
  final String? promoTitle;
  final String? promoError;
  final int? originalFare;
  /// Unpaid cancellation fee from an earlier booking, collected on this ride.
  final int outstandingFee;
  /// Account credit that will be applied at booking time.
  final int creditAvailable;

  const FareEstimate({
    required this.estimatedFare,
    required this.baseFare,
    this.farePerKm = 0,
    this.farePerMin = 0,
    required this.distanceKm,
    required this.durationMinutes,
    this.taxAmount = 0,
    this.currency = 'AFN',
    this.discountAmount = 0,
    this.promoCode,
    this.promoTitle,
    this.promoError,
    this.originalFare,
    this.outstandingFee = 0,
    this.creditAvailable = 0,
  });

  /// Ride price before account effects (credit / outstanding fee).
  int get rideTotal => estimatedFare + taxAmount;

  /// Credit that will actually be used on this ride.
  int get creditApplied => creditAvailable.clamp(0, rideTotal);

  /// Cash the passenger will hand the driver.
  int get cashToCollect => (rideTotal - creditApplied + outstandingFee).clamp(0, 1 << 31);

  factory FareEstimate.fromJson(Map<String, dynamic> json) => FareEstimate(
        estimatedFare: (json['estimated_fare'] as num).round(),
        baseFare: (json['base_fare'] as num?)?.round() ?? 0,
        farePerKm: (json['fare_per_km'] as num?)?.toDouble() ?? 0,
        farePerMin: (json['fare_per_min'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        durationMinutes: (json['duration_minutes'] as num?)?.round() ?? 0,
        taxAmount: (json['tax_amount'] as num?)?.round() ?? 0,
        currency: json['currency'] as String? ?? 'AFN',
        discountAmount: (json['discount_amount'] as num?)?.round() ?? 0,
        promoCode: json['promo_code'] as String?,
        promoTitle: json['promo_title'] as String?,
        promoError: json['promo_error'] as String?,
        originalFare: (json['original_fare'] as num?)?.round(),
        outstandingFee: (json['outstanding_fee'] as num?)?.round() ?? 0,
        creditAvailable: (json['credit_available'] as num?)?.round() ?? 0,
      );
}
