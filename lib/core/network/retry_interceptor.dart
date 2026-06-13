import 'dart:async';
import 'package:dio/dio.dart';

/// Interceptor untuk melakukan percobaan ulang (retry) otomatis jika request gagal 
/// karena masalah jaringan atau server (502/503/504).
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Pass-through tanpa blocking / deduplication (menghindari deadlock)
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Pass-through tanpa blocking / deduplication (menghindari deadlock)
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    int retryCount = options.extra['retry_count'] ?? 0;

    // Hanya lakukan retry jika terjadi error jaringan, timeout, atau server overloading (502/503/504)
    if (_shouldRetry(err) && retryCount < maxRetries) {
      retryCount++;
      options.extra['retry_count'] = retryCount;

      print('🔄 Gangguan Jaringan: Mencoba kembali ($retryCount/$maxRetries) untuk: ${options.path}');

      // Jeda progresif sebelum mencoba lagi
      await Future.delayed(retryInterval * retryCount);

      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        // Jika retry gagal, biarkan masuk ke onError lagi untuk retry berikutnya atau menyerah
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.type == DioExceptionType.badResponse && 
            (err.response?.statusCode == 502 || err.response?.statusCode == 503 || err.response?.statusCode == 504));
  }
}
