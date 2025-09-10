import 'package:dio/dio.dart';
import '../core/app_config.dart';

class ApiClient {
  final Dio _dio;
  ApiClient(this._dio) {
    _dio.options
      ..baseUrl = AppConfig.baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers = {'Accept': 'application/json'};
  }

  Dio get raw => _dio;

  // >>> ADD: set token sekali, update header Authorization
  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
  // <<< ADD END

  Never _error(DioException e) {
    final r = e.response;
    final m = (r?.data is Map && r?.data['message'] != null)
        ? r!.data['message'].toString()
        : e.message ?? 'Network error';
    throw ApiClientException(m, r?.statusCode);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      return await _dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      _error(e);
    }
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      _error(e);
    }
  }
}

class ApiClientException implements Exception {
  final String message;
  final int? status;
  ApiClientException(this.message, this.status);
  @override
  String toString() => 'ApiClientException($status): $message';
}
