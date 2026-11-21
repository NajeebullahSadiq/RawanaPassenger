import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// HTTP client for the Rawana backend.
///
/// The bearer token is **resolved on every request** from the live Supabase
/// session, so there is no window after sign-in where the API client still
/// holds a stale (or missing) token. The legacy [setToken] / constructor
/// `token` parameter remains supported for non-Supabase flows (admin portal,
/// tests).
class ApiClient {
  /// Called when the backend still rejects the session after a refresh
  /// attempt; apps sign out and return to the auth screen.
  static void Function()? onSessionExpired;

  static const _retryDelays = [Duration(milliseconds: 600), Duration(milliseconds: 1500)];

  ApiClient({required String baseUrl, String? token}) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 30),
        )) {
    if (token != null) _explicitToken = token;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _resolveToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final retried = error.requestOptions.extra['_authRetried'] == true;
          if (status == 401 && !retried && AppConfig.hasSupabase) {
            try {
              final refreshed = await Supabase.instance.client.auth.refreshSession();
              final token = refreshed.session?.accessToken;
              if (token != null && token.isNotEmpty) {
                error.requestOptions.extra['_authRetried'] = true;
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                _explicitToken = token;
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (_) {
              // Fall through — caller handles missing/invalid session.
            }
            if (error.requestOptions.headers.containsKey('Authorization')) {
              onSessionExpired?.call();
            }
          }
          if (_isRetryable(error)) {
            final req = error.requestOptions;
            final attempt = (req.extra['_retryAttempt'] as int?) ?? 0;
            await Future<void>.delayed(_retryDelays[attempt]);
            req.extra['_retryAttempt'] = attempt + 1;
            try {
              return handler.resolve(await _dio.fetch(req));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  String? _explicitToken;

  /// Only idempotent GETs are retried, and only for transient failures.
  static bool _isRetryable(DioException error) {
    final req = error.requestOptions;
    if (req.method.toUpperCase() != 'GET') return false;
    if (((req.extra['_retryAttempt'] as int?) ?? 0) >= _retryDelays.length) return false;
    final status = error.response?.statusCode;
    return switch (error.type) {
      DioExceptionType.connectionError || DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse => status == 502 || status == 503 || status == 504,
      _ => false,
    };
  }

  Future<String?> _resolveToken() async {
    if (AppConfig.hasSupabase) {
      final client = Supabase.instance.client;
      var session = client.auth.currentSession;
      if (session != null && session.isExpired) {
        try {
          final refreshed = await client.auth.refreshSession();
          session = refreshed.session;
        } catch (_) {
          session = null;
        }
      }
      if (session != null) return session.accessToken;
    }
    return _explicitToken;
  }

  /// Override the token (e.g. when Supabase is not in use). Pass an empty
  /// string or null to clear.
  void setToken(String? token) {
    _explicitToken = (token == null || token.isEmpty) ? null : token;
  }

  /// Base URL this client talks to (no trailing slash).
  String get baseUrl {
    final url = _dio.options.baseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Turns an API-relative path (e.g. `/rides/<id>/route-snapshot`) into an
  /// absolute URL. Absolute URLs are returned unchanged.
  String absoluteUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '$baseUrl$path';
  }

  /// Synchronous bearer header for widgets such as `Image.network` that cannot
  /// await the interceptor. Falls back to the explicit token.
  Map<String, String> authHeaders() {
    String? token = _explicitToken;
    if (AppConfig.hasSupabase) {
      token = Supabase.instance.client.auth.currentSession?.accessToken ?? token;
    }
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _mapResponse(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: query);
    return _mapResponse(response.data);
  }

  Future<dynamic> getList(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: query);
    return response.data;
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return _mapResponse(response.data);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.patch(path, data: data);
    return _mapResponse(response.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
