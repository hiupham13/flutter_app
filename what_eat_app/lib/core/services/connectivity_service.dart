import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Simple connectivity checker & listener.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult> get onStatusChange =>
      _connectivity.onConnectivityChanged.map((results) => results.first);

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

