import 'package:connectivity_plus/connectivity_plus.dart';

typedef ConnectivityCallback = void Function(bool isConnected);

/// Monitors network and reports connectivity changes.
class ConnectivityService {
  static void init(ConnectivityCallback onChanged) {
    Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      onChanged(connected);
    });
    Connectivity().checkConnectivity().then((results) {
      onChanged(results.any((r) => r != ConnectivityResult.none));
    });
  }
}
