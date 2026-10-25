/// FCM deep-link routing for ride lifecycle events.
enum NotificationType {
  rideRequest,
  rideAccepted,
  driverArriving,
  tripStarted,
  tripCompleted,
  payoutApproved,
  ticketReply,
  adminBroadcast,
}

class NotificationRouter {
  static const _tapOnlyTypes = {
    'scheduled_ride_booked',
    'scheduled_ride_confirmed',
    'scheduled_ride_reminder',
    'scheduled_ride_driver_released',
    'scheduled_ride_released',
  };

  static bool isTapOnly(String type) => _tapOnlyTypes.contains(type);

  static String? routeForType(String type, {String role = 'passenger'}) {
    if (role == 'driver') {
      return _driverRouteForType(type);
    }
    return _passengerRouteForType(type);
  }

  static String? _passengerRouteForType(String type) {
    switch (type) {
      case 'ride_accepted':
      case 'driver_arriving':
      case 'trip_started':
      case 'trip_message':
        return '/active-trip';
      case 'trip_completed':
        return '/trip-complete';
      case 'trip_cancelled':
        return '/home';
      case 'driver_rematch':
      case 'scheduled_ride_dispatching':
        return '/searching';
      case 'scheduled_ride_booked':
      case 'scheduled_ride_confirmed':
      case 'scheduled_ride_reminder':
      case 'scheduled_ride_driver_released':
        return '/scheduled-rides';
      case 'ride_request':
        return null;
      case 'admin_broadcast':
        return '/notifications';
      default:
        return null;
    }
  }

  static String? _driverRouteForType(String type) {
    switch (type) {
      case 'ride_request':
        return '/incoming-request';
      case 'driver_arriving':
      case 'trip_started':
        return '/trip-in-progress';
      case 'ride_accepted':
        return '/navigate-pickup';
      case 'trip_completed':
        return '/fare-summary';
      case 'trip_cancelled':
        return '/dashboard';
      case 'payout_approved':
        return '/wallet';
      case 'scheduled_ride_reminder':
      case 'scheduled_ride_released':
        return '/scheduled-rides';
      case 'admin_broadcast':
        return '/dashboard';
      default:
        return null;
    }
  }
}
