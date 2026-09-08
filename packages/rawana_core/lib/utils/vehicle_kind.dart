import 'package:flutter/material.dart';

/// Visual vehicle used on live maps (matches ride-type `icon_name`).
enum VehicleKind {
  car,
  bike,
  premium,
  xl;

  static VehicleKind fromIconName(String? name) {
    switch (name?.trim().toLowerCase()) {
      case 'bike':
      case 'motorcycle':
      case 'moto':
      case 'scooter':
        return VehicleKind.bike;
      case 'premium':
      case 'comfort':
        return VehicleKind.premium;
      case 'xl':
      case 'van':
      case 'suv':
        return VehicleKind.xl;
      default:
        return VehicleKind.car;
    }
  }

  String get apiName => switch (this) {
        VehicleKind.bike => 'bike',
        VehicleKind.premium => 'premium',
        VehicleKind.xl => 'xl',
        VehicleKind.car => 'car',
      };

  IconData get mapIcon => switch (this) {
        VehicleKind.bike => Icons.two_wheeler,
        VehicleKind.premium => Icons.directions_car,
        VehicleKind.xl => Icons.airport_shuttle,
        VehicleKind.car => Icons.local_taxi,
      };
}
