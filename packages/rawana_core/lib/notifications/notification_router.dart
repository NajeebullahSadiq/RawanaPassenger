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
        return '/active-trip';
      case 'trip_completed':
        return '/trip-complete';
      case 'trip_cancelled':
        return '/home';
      case 'driver_rematch':
        return '/searching';
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
      case 'admin_broadcast':
        return '/dashboard';
      default:
        return null;
    }
  }
}
