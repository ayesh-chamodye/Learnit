import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Singleton API client with connection pooling and caching
class ApiClient {
  static const int _defaultTimeoutSeconds = 30;
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: _defaultTimeoutSeconds),
        receiveTimeout: const Duration(seconds: _defaultTimeoutSeconds),
        sendTimeout: const Duration(seconds: _defaultTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate',
          'User-Agent': 'LearnItApp/1.0 (Flutter)',
        },
      ),
    );





    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: true,
          responseBody: false,
          error: true,
        ),
      );
    }
  }

  Dio get dio => _dio;


}
