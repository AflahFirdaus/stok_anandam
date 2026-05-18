//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:my_api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:my_api_client/src/model/web_response_purchase_summary_response_purchase.dart';
import 'package:my_api_client/src/model/web_response_list_string.dart';

class PurchaseControllerApi {

  final Dio _dio;

  const PurchaseControllerApi(this._dio);

  /// getPurchases
  /// 
  ///
  /// Parameters:
  /// * [page] 
  /// * [size] 
  /// * [sortBy] 
  /// * [dir] 
  /// * [startDate] 
  /// * [endDate] 
  /// * [categories]
  /// * [search] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [WebResponsePurchaseSummaryResponsePurchase] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<WebResponsePurchaseSummaryResponsePurchase>> getPurchases({ 
    Object? page = 0,
    Object? size = 10,
    Object? sortBy = 'docDate',
    Object? dir = 'desc',
    Object? startDate,
    Object? endDate,
    List<String>? categories,
    Object? search,
    Object? searchColumn,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/purchases';
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
      if (dir != null) r'dir': dir,
      if (startDate != null) r'startDate': startDate,
      if (endDate != null) r'endDate': endDate,
      if (categories != null) r'categories': categories,
      if (search != null) r'search': search,
      if (searchColumn != null) r'searchColumn': searchColumn,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    WebResponsePurchaseSummaryResponsePurchase? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<WebResponsePurchaseSummaryResponsePurchase, WebResponsePurchaseSummaryResponsePurchase>(rawData, 'WebResponsePurchaseSummaryResponsePurchase', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<WebResponsePurchaseSummaryResponsePurchase>(
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

  Future<Response<WebResponseListString>> getCategories({ 
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/purchases/categories';
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

    WebResponseListString? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<WebResponseListString, WebResponseListString>(rawData, 'WebResponseListString', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<WebResponseListString>(
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
