import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../app/app_env.dart';
import 'user_session.dart';

/// Central API Service for performing HTTP requests to the Node.js Express backend.
class ApiService {
  static String? _authToken;

  /// Set active JWT authorization token.
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get active authorization token.
  static String? get authToken => _authToken;

  /// Get default HTTP headers including Authorization if available.
  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static bool _isRefreshing = false;
  static final List<Completer<void>> _refreshQueue = [];

  /// Renew expired user session transparently using Refresh Token Rotation.
  static Future<bool> _recreateSession() async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _refreshQueue.add(completer);
      await completer.future;
      return UserSession.token != null;
    }

    _isRefreshing = true;
    try {
      final refreshTok = UserSession.refreshToken;
      if (refreshTok == null || refreshTok.isEmpty) {
        return false;
      }

      final uri = Uri.parse('${AppEnv.apiBaseUrl}/auth/recreate-session');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshTok}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final newToken = body['token'] as String;
        final newRefreshToken = body['refreshToken'] as String;
        await UserSession.updateTokens(newToken, newRefreshToken);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService _recreateSession Error]: $e');
    } finally {
      _isRefreshing = false;
      for (final completer in _refreshQueue) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      _refreshQueue.clear();
    }
    return false;
  }

  /// Request execution wrapper with auto-retry on 401 Unauthorized and network error sanitization.
  static Future<dynamic> _request(
    Future<http.Response> Function() requestFn, {
    int retryCount = 0,
  }) async {
    try {
      final response = await requestFn();
      return _handleResponse(response);
    } catch (e) {
      // 1. Transparent token refresh on 401 Unauthorized
      if (e is ApiException && e.statusCode == 401 && retryCount < 1) {
        final refreshSuccess = await _recreateSession();
        if (refreshSuccess) {
          return _request(requestFn, retryCount: 1);
        } else {
          await UserSession.clearSession();
        }
      }

      // 2. Map raw connection/network errors to clean, user-friendly messages
      if (e is http.ClientException || 
          e.toString().contains('SocketException') || 
          e.toString().contains('HandshakeException')) {
        throw ApiException(
          'Cannot connect to the server. Please check your internet connection or verify if the backend is running.',
          503,
        );
      }

      rethrow;
    }
  }

  /// Perform HTTP GET request.
  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint').replace(queryParameters: queryParams);
    return _request(() => http.get(uri, headers: _headers));
  }

  /// Perform HTTP POST request.
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    return _request(() => http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    ));
  }

  /// Perform HTTP PUT request.
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    return _request(() => http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    ));
  }

  /// Perform HTTP PATCH request.
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    return _request(() => http.patch(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    ));
  }

  /// Perform HTTP DELETE request.
  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    return _request(() => http.delete(uri, headers: _headers));
  }

  /// Helper to handle and parse HTTP response, mapping raw errors to user-friendly messages.
  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      // Non-JSON response (e.g. HTML gateway crash)
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body ?? {};
    }

    final int status = response.statusCode;
    String friendlyMessage = 'An unexpected error occurred. Please try again.';

    // 1. Handle Server-side Errors (5xx) - NEVER show raw backend exception details
    if (status >= 500) {
      friendlyMessage = 'Something went wrong on our server. Please try again later.';
    } 
    // 2. Handle Client-side Errors (4xx)
    else {
      final rawMessage = (body is Map && body.containsKey('message'))
          ? body['message']?.toString()
          : null;

      if (rawMessage != null && rawMessage.isNotEmpty) {
        // Sanitize the message: if it contains database or ORM keywords, redact it
        final lowerMsg = rawMessage.toLowerCase();
        final hasDbKeywords = lowerMsg.contains('prisma') ||
            lowerMsg.contains('database') ||
            lowerMsg.contains('sql') ||
            lowerMsg.contains('postgres') ||
            lowerMsg.contains('sqlite') ||
            lowerMsg.contains('query') ||
            lowerMsg.contains('constraint') ||
            lowerMsg.contains('foreign key') ||
            lowerMsg.contains('table') ||
            lowerMsg.contains('column');

        if (hasDbKeywords) {
          friendlyMessage = 'A database error occurred. Please contact support.';
        } else {
          friendlyMessage = rawMessage;
        }
      } else {
        // Fallback messages based on HTTP status codes
        switch (status) {
          case 400:
            friendlyMessage = 'Invalid request. Please check your input.';
            break;
          case 401:
            friendlyMessage = 'Your session has expired. Please log in again.';
            break;
          case 403:
            friendlyMessage = 'You do not have permission to access this resource.';
            break;
          case 404:
            friendlyMessage = 'The requested information was not found.';
            break;
          case 429:
            friendlyMessage = 'Too many requests. Please slow down and try again.';
            break;
        }
      }
    }

    throw ApiException(friendlyMessage, status);
  }

  /// Upload signature image to backend / Supabase S3 storage bucket.
  static Future<String?> uploadSignature(String base64Image) async {
    try {
      final response = await post('/upload/signature', {
        'image': base64Image,
      });
      if (response['success'] == true && response['data'] != null) {
        return response['data']['url'] as String?;
      }
    } catch (e) {
      if (kDebugMode) print('[ApiService Signature Upload Error]: $e');
    }
    return null;
  }
}

/// Custom Exception thrown by ApiService.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
