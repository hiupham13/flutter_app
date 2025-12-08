import 'dart:async';
import 'package:dio/dio.dart';

/// A thin wrapper to add retry mechanism for API calls.
class NetworkClient {
  final Dio _dio;

  NetworkClient({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Execute a request with retry.
  Future<Response<T>> getWithRetry<T>(
    String path, {
    Map<String, dynamic>? query,
    int retries = 2,
    Duration delay = const Duration(milliseconds: 400),
  }) async {
    int attempt = 0;
    late Response<T> response;
    while (true) {
      try {
        response = await _dio.get<T>(path, queryParameters: query);
        return response;
      } catch (e) {
        attempt++;
        if (attempt > retries) rethrow;
        await Future.delayed(delay * attempt);
      }
    }
  }
}

