//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:my_api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:my_api_client/src/model/web_response_sales_summary_response_sales.dart';

class SalesControllerApi {

  final Dio _dio;

  const SalesControllerApi(this._dio);

  /// getAllSales
  /// 
  ///
  /// Parameters:
  /// * [page] 
  /// * [size] 
  /// * [sortBy] 
  /// * [direction] 
  /// * [startDate] 
  /// * [endDate] 
  /// * [empCode] 
  /// * [search] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [WebResponseSalesSummaryResponseSales] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<WebResponseSalesSummaryResponseSales>> getAllSales({ 
    Object? page = 0,
    Object? size = 10,
    Object? sortBy = 'docDate',
    Object? direction = 'desc',
    Object? startDate,
    Object? endDate,
    Object? empCode,
    Object? search,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/sales';
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
      if (startDate != null) r'startDate': startDate,
      if (endDate != null) r'endDate': endDate,
      if (empCode != null) r'empCode': empCode,
      if (search != null) r'search': search,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    WebResponseSalesSummaryResponseSales? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<WebResponseSalesSummaryResponseSales, WebResponseSalesSummaryResponseSales>(rawData, 'WebResponseSalesSummaryResponseSales', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<WebResponseSalesSummaryResponseSales>(
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
