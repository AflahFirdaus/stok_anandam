//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:my_api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:my_api_client/src/model/web_response_page_tkdn.dart';
import 'package:my_api_client/src/model/web_response_tkdn.dart';

class TkdnControllerApi {
  final Dio _dio;

  const TkdnControllerApi(this._dio);

  /// getAllTkdn
  ///
  ///
  /// Parameters:
  /// * [page]
  /// * [size]
  /// * [sortBy]
  /// * [direction]
  /// * [isTkdn]
  /// * [kategori]
  /// * [search]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [WebResponsePageTkdn] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<WebResponsePageTkdn>> getAllTkdn({
    Object? page = 0,
    Object? size = 10,
    Object? sortBy = 'nama',
    Object? direction = 'asc',
    Object? isTkdn,
    List<String>? categories,
    Object? search,
    Object? processor,
    Object? ram,
    Object? ssd,
    Object? hdd,
    Object? vga,
    Object? layar,
    Object? os,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/tkdn';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (page != null) r'page': page,
      if (size != null) r'size': size,
      if (sortBy != null) r'sortBy': sortBy,
      if (direction != null) r'direction': direction,
      if (isTkdn != null) r'isTkdn': isTkdn,
      if (categories != null) r'categories': categories,
      if (search != null) r'search': search,
      if (processor != null) r'processor': processor,
      if (ram != null) r'ram': ram,
      if (ssd != null) r'ssd': ssd,
      if (hdd != null) r'hdd': hdd,
      if (vga != null) r'vga': vga,
      if (layar != null) r'layar': layar,
      if (os != null) r'os': os,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    WebResponsePageTkdn? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<WebResponsePageTkdn, WebResponsePageTkdn>(
              rawData, 'WebResponsePageTkdn',
              growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<WebResponsePageTkdn>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// getTkdnDetail
  ///
  ///
  /// Parameters:
  /// * [id]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [WebResponseTkdn] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<WebResponseTkdn>> getTkdnDetail({
    required Object id,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/tkdn/{id}'.replaceAll('{' r'id' '}', id.toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    WebResponseTkdn? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<WebResponseTkdn, WebResponseTkdn>(
              rawData, 'WebResponseTkdn',
              growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<WebResponseTkdn>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }
}
