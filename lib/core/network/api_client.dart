import 'package:dio/dio.dart';

import '../error/failure.dart';

class ApiResponse {
  const ApiResponse(this.data, this.meta);

  final dynamic data;
  final Map<String, dynamic> meta;
}

/// Thin Dio wrapper: unwraps the `{success, data, error, meta}` envelope and
/// converts every failure into a [Failure].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<ApiResponse> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<ApiResponse> delete(String path) => _send(() => _dio.delete<dynamic>(path));

  Future<ApiResponse> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body is! Map || body['success'] != true) {
        throw const Failure('Unexpected response from server.');
      }
      final meta = body['meta'];
      return ApiResponse(
        body['data'],
        meta is Map ? Map<String, dynamic>.from(meta) : const {},
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Failure _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure('The server took too long to respond.', isNetwork: true);
      case DioExceptionType.connectionError:
        return const Failure(
          'Cannot reach the server. Check your connection and that the backend is running.',
          isNetwork: true,
        );
      default:
        final body = e.response?.data;
        if (body is Map && body['error'] is String) return Failure(body['error'] as String);
        return Failure('Request failed (${e.response?.statusCode ?? 'unknown'}).');
    }
  }
}
