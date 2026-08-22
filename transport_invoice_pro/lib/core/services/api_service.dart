import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../app/app_env.dart';

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

  /// Perform HTTP GET request.
  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('[ApiService GET Error] $endpoint: $e');
      rethrow;
    }
  }

  /// Perform HTTP POST request.
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('[ApiService POST Error] $endpoint: $e');
      rethrow;
    }
  }

  /// Perform HTTP PUT request.
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    try {
      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('[ApiService PUT Error] $endpoint: $e');
      rethrow;
    }
  }

  /// Perform HTTP PATCH request.
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    try {
      final response = await http.patch(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('[ApiService PATCH Error] $endpoint: $e');
      rethrow;
    }
  }

  /// Perform HTTP DELETE request.
  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${AppEnv.apiBaseUrl}$endpoint');
    try {
      final response = await http.delete(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('[ApiService DELETE Error] $endpoint: $e');
      rethrow;
    }
  }

  /// Helper to handle and parse HTTP response.
  static dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body is Map && body.containsKey('message')
          ? body['message']
          : 'Server request failed with status code ${response.statusCode}';
      throw ApiException(message.toString(), response.statusCode);
    }
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
