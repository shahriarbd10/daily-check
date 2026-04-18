import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_discovery.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio dio;
  static const String _defaultBaseUrl =
      "https://daily-check-xx0v.onrender.com/api";
  static const String _baseUrlPrefsKey = 'api_base_url';
  static const String _lastWorkingBaseUrlPrefsKey = 'api_last_working_base_url';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  Future<String?>? _discoveryFuture;
  bool _discoveryStarted = false;
  bool _recoveryInProgress = false;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _resolveInitialBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: "application/json",
      ),
    );

    // Logging Interceptor
    if (!kReleaseMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    // Auth Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }

  static String _resolveInitialBaseUrl() {
    final envUrl = _configuredBaseUrl.trim();
    if (envUrl.isNotEmpty) return envUrl;
    return _defaultBaseUrl;
  }

  Future<void> _refreshBaseUrlFromPreferences() async {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      // Environment value always wins when provided.
      if (dio.options.baseUrl != _configuredBaseUrl.trim()) {
        dio.options.baseUrl = _configuredBaseUrl.trim();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_baseUrlPrefsKey) ?? '').trim();
    if (saved.isNotEmpty) {
      if (dio.options.baseUrl != saved) {
        dio.options.baseUrl = saved;
      }
      return;
    }

    final lastWorking =
        (prefs.getString(_lastWorkingBaseUrlPrefsKey) ?? '').trim();
    if (lastWorking.isNotEmpty) {
      if (dio.options.baseUrl != lastWorking) {
        dio.options.baseUrl = lastWorking;
      }
      return;
    }

    if (!_discoveryStarted) {
      _discoveryStarted = true;
      _discoveryFuture = discoverApiBaseUrl();
    }

    final discovered = await _discoveryFuture;
    final target = (discovered ?? _defaultBaseUrl).trim();
    if (dio.options.baseUrl != target) {
      dio.options.baseUrl = target;
    }
  }

  Future<void> _saveLastWorkingBaseUrl() async {
    final current = dio.options.baseUrl.trim();
    if (current.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastWorkingBaseUrlPrefsKey, current);
  }

  Future<void> _clearLastWorkingBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastWorkingBaseUrlPrefsKey);
  }

  bool _isRecoverableNetworkError(Object error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    final msg = (error.message ?? '').toLowerCase();
    return msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('timed out');
  }

  Future<bool> _recoverBaseUrl() async {
    if (_recoveryInProgress) return false;
    _recoveryInProgress = true;
    try {
      final previous = dio.options.baseUrl.trim();
      final prefs = await SharedPreferences.getInstance();
      final savedOverride = (prefs.getString(_baseUrlPrefsKey) ?? '').trim();
      if (savedOverride == previous) {
        await prefs.remove(_baseUrlPrefsKey);
      }
      await _clearLastWorkingBaseUrl();
      _discoveryStarted = false;
      _discoveryFuture = null;
      final discovered = (await discoverApiBaseUrl())?.trim();
      if (discovered != null && discovered.isNotEmpty && discovered != previous) {
        dio.options.baseUrl = discovered;
        await _saveLastWorkingBaseUrl();
        return true;
      }
      return false;
    } finally {
      _recoveryInProgress = false;
    }
  }

  Future<Response> _executeWithAutoRecovery(
    Future<Response> Function() request,
  ) async {
    try {
      await _refreshBaseUrlFromPreferences();
      final response = await request();
      await _saveLastWorkingBaseUrl();
      return response;
    } catch (e) {
      if (_isRecoverableNetworkError(e)) {
        final recovered = await _recoverBaseUrl();
        if (recovered) {
          final response = await request();
          await _saveLastWorkingBaseUrl();
          return response;
        }
      }
      rethrow;
    }
  }

  static Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlPrefsKey, url.trim());
  }

  static Future<void> clearApiBaseUrlOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlPrefsKey);
  }

  // Helper methods for common requests
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _executeWithAutoRecovery(
        () => dio.get(path, queryParameters: queryParameters),
      );
    } catch (e) {
      if (!kReleaseMode) {
        print('Dio GET Error: $e');
      }
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      if (!kReleaseMode) {
        print('Attempting POST to: ${dio.options.baseUrl}$path');
      }
      return await _executeWithAutoRecovery(() => dio.post(path, data: data));
    } catch (e) {
      if (!kReleaseMode) {
        if (e is DioException) {
          print('Dio POST Error: ${e.type} - ${e.message}');
          if (e.error != null) print('Detail: ${e.error}');
        } else {
          print('POST Error: $e');
        }
      }
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      if (!kReleaseMode) {
        print('Attempting PUT to: ${dio.options.baseUrl}$path');
      }
      return await _executeWithAutoRecovery(() => dio.put(path, data: data));
    } catch (e) {
      if (!kReleaseMode) {
        if (e is DioException) {
          print('Dio PUT Error: ${e.type} - ${e.message}');
          if (e.error != null) print('Detail: ${e.error}');
        } else {
          print('PUT Error: $e');
        }
      }
      rethrow;
    }
  }
}
