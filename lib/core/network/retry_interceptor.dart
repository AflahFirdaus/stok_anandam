import 'dart:async';
import 'package:dio/dio.dart';

/// Interceptor untuk melakukan percobaan ulang (retry) otomatis jika request gagal 
/// karena masalah jaringan, serta mencegah request ganda yang identik.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  // Cache untuk menyimpan request yang sedang berjalan (deduplication)
  final Map<String, Completer<Response>> _inflightRequests = {};

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
  });

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Deduplication Logic (Hanya untuk GET request)
    if (options.method == 'GET') {
      final authHeader = options.headers['Authorization'] ?? '';
      final cacheKey = '${options.method}_${options.uri}_${options.queryParameters}_$authHeader';
      
      if (_inflightRequests.containsKey(cacheKey)) {
        try {
          final response = await _inflightRequests[cacheKey]!.future;
          return handler.resolve(response);
        } catch (e) {
          // Jika request asli gagal, biarkan request baru ini lewat
        }
      } else {
        _inflightRequests[cacheKey] = Completer<Response>();
      }
    }
    
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Selesaikan completer jika ada (untuk deduplication)
    final authHeader = response.requestOptions.headers['Authorization'] ?? '';
    final cacheKey = '${response.requestOptions.method}_${response.requestOptions.uri}_${response.requestOptions.queryParameters}_$authHeader';
    if (_inflightRequests.containsKey(cacheKey)) {
      _inflightRequests.remove(cacheKey)!.complete(response);
    }
    return super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    
    // Hapus dari inflight cache jika error
    final authHeader = options.headers['Authorization'] ?? '';
    final cacheKey = '${options.method}_${options.uri}_${options.queryParameters}_$authHeader';
    if (_inflightRequests.containsKey(cacheKey)) {
      _inflightRequests.remove(cacheKey)!.completeError(err);
    }

    // 2. Retry Logic
    // Hanya lakukan retry jika error jaringan atau timeout, dan belum melebihi maxRetries
    int retryCount = options.extra['retry_count'] ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      retryCount++;
      options.extra['retry_count'] = retryCount;

      print('🔄 Network Error: Mencoba kembali (${retryCount}/$maxRetries) untuk: ${options.path}');

      // Jeda sebelum mencoba lagi
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
