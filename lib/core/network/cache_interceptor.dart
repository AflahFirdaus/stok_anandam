import 'package:dio/dio.dart';

class InMemoryCacheInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Pass-through without modifying options or resolving early
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Pass-through without caching responses
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Pass-through without catching errors
    super.onError(err, handler);
  }

  void clearCache() {
    // No-op while disabled
  }
}
