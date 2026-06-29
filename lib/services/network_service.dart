import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Verifies host network connectivity for the wrapped Android app.
class NetworkService {
  NetworkService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> hasInternetAccess() async {
    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on Exception {
      return false;
    }
  }
}
