import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import '../utils/storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = StorageService();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        validateStatus: (_) => true,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response != null) {
            _logResponse(error.response!);
          } else if (kDebugMode) {
            debugPrint('┌──────────────── API ERROR ─────────────────');
            debugPrint(
                '│ ${error.requestOptions.method} ${error.requestOptions.uri}');
            debugPrint('│ ${error.message}');
            debugPrint('└────────────────────────────────────────────');
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final response = await _dio.get(path, queryParameters: params);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post(path, data: body);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      fileField: await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPostFiles(
    String path, {
    required Map<String, String> fields,
    required Map<String, List<String>> files,
  }) async {
    final formData = FormData();
    fields.forEach((key, value) {
      formData.fields.add(MapEntry(key, value));
    });
    for (final entry in files.entries) {
      for (final filePath in entry.value) {
        formData.files.add(
          MapEntry(entry.key, await MultipartFile.fromFile(filePath)),
        );
      }
    }
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPatchFiles(
    String path, {
    required Map<String, String> fields,
    required Map<String, List<String>> files,
  }) async {
    final formData = FormData();
    fields.forEach((key, value) {
      formData.fields.add(MapEntry(key, value));
    });
    for (final entry in files.entries) {
      for (final filePath in entry.value) {
        formData.files.add(
          MapEntry(entry.key, await MultipartFile.fromFile(filePath)),
        );
      }
    }
    final response = await _dio.patch(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.patch(path, data: body);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _dio.delete(path);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 0;
    final body = _asMap(response.data);

    if ((statusCode >= 200 && statusCode < 300) || body['success'] == true) {
      return body;
    }

    throw ApiException(
      statusCode: statusCode,
      message: body['message']?.toString() ??
          body['error']?.toString() ??
          'Something went wrong',
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const ApiException(
      statusCode: 0,
      message: 'Server returned an unexpected response',
    );
  }

  void _logRequest(RequestOptions options) {
    if (!kDebugMode) return;
    debugPrint('┌──────────────── API REQUEST ────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    debugPrint('│ Headers: ${_redactHeaders(options.headers)}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('│ Query: ${_prettyJson(options.queryParameters)}');
    }
    if (options.data != null) {
      debugPrint('│ Body: ${_prettyBody(options.data)}');
    }
    debugPrint('└────────────────────────────────────────────');
  }

  void _logResponse(Response<dynamic> response) {
    if (!kDebugMode) return;
    debugPrint('┌──────────────── API RESPONSE ───────────────');
    debugPrint(
        '│ ${response.requestOptions.method} ${response.requestOptions.uri}');
    debugPrint('│ Status: ${response.statusCode}');
    debugPrint('│ Body: ${_prettyBody(response.data)}');
    debugPrint('└────────────────────────────────────────────');
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (key.toLowerCase() == 'authorization') {
        return MapEntry(key, 'Bearer <redacted>');
      }
      return MapEntry(key, value);
    });
  }

  String _prettyBody(dynamic value) {
    if (value is FormData) {
      return _prettyJson({
        'fields': {
          for (final field in value.fields) field.key: field.value,
        },
        'files': value.files.map((file) => file.key).toList(),
      });
    }
    return _prettyJson(value);
  }

  String _prettyJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
