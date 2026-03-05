import 'package:my_api_client/src/model/canvasing.dart';
import 'package:my_api_client/src/model/dashboard_response.dart';
import 'package:my_api_client/src/model/data_canvasing.dart';
import 'package:my_api_client/src/model/data_canvasing_request.dart';
import 'package:my_api_client/src/model/login_user_request.dart';
import 'package:my_api_client/src/model/page_canvasing.dart';
import 'package:my_api_client/src/model/page_data_canvasing.dart';
import 'package:my_api_client/src/model/page_stock.dart';
import 'package:my_api_client/src/model/page_tkdn.dart';
import 'package:my_api_client/src/model/pageable_object.dart';
import 'package:my_api_client/src/model/paging_response.dart';
import 'package:my_api_client/src/model/purchase.dart';
import 'package:my_api_client/src/model/purchase_summary_response_purchase.dart';
import 'package:my_api_client/src/model/refresh_token_request.dart';
import 'package:my_api_client/src/model/sales.dart';
import 'package:my_api_client/src/model/sales_summary_response_sales.dart';
import 'package:my_api_client/src/model/sort_object.dart';
import 'package:my_api_client/src/model/stock.dart';
import 'package:my_api_client/src/model/tkdn.dart';
import 'package:my_api_client/src/model/token_response.dart';
import 'package:my_api_client/src/model/user_request.dart';
import 'package:my_api_client/src/model/user_response.dart';
import 'package:my_api_client/src/model/web_response_dashboard_response.dart';
import 'package:my_api_client/src/model/web_response_data_canvasing.dart';
import 'package:my_api_client/src/model/web_response_list_user_response.dart';
import 'package:my_api_client/src/model/web_response_page_canvasing.dart';
import 'package:my_api_client/src/model/web_response_page_data_canvasing.dart';
import 'package:my_api_client/src/model/web_response_page_stock.dart';
import 'package:my_api_client/src/model/web_response_page_tkdn.dart';
import 'package:my_api_client/src/model/web_response_purchase_summary_response_purchase.dart';
import 'package:my_api_client/src/model/web_response_sales_summary_response_sales.dart';
import 'package:my_api_client/src/model/web_response_stock.dart';
import 'package:my_api_client/src/model/web_response_string.dart';
import 'package:my_api_client/src/model/web_response_tkdn.dart';
import 'package:my_api_client/src/model/web_response_token_response.dart';
import 'package:my_api_client/src/model/web_response_user_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'Canvasing':
          return Canvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DashboardResponse':
          return DashboardResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DataCanvasing':
          return DataCanvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DataCanvasingRequest':
          return DataCanvasingRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LoginUserRequest':
          return LoginUserRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageCanvasing':
          return PageCanvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageDataCanvasing':
          return PageDataCanvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageStock':
          return PageStock.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageTkdn':
          return PageTkdn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageableObject':
          return PageableObject.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PagingResponse':
          return PagingResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Purchase':
          return Purchase.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PurchaseSummaryResponsePurchase':
          return PurchaseSummaryResponsePurchase.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshTokenRequest':
          return RefreshTokenRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Sales':
          return Sales.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SalesSummaryResponseSales':
          return SalesSummaryResponseSales.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SortObject':
          return SortObject.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Stock':
          return Stock.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Tkdn':
          return Tkdn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TokenResponse':
          return TokenResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UserRequest':
          return UserRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UserResponse':
          return UserResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseDashboardResponse':
          return WebResponseDashboardResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseDataCanvasing':
          return WebResponseDataCanvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseListUserResponse':
          return WebResponseListUserResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponsePageCanvasing':
          return WebResponsePageCanvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponsePageDataCanvasing':
          return WebResponsePageDataCanvasing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponsePageStock':
          return WebResponsePageStock.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponsePageTkdn':
          return WebResponsePageTkdn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponsePurchaseSummaryResponsePurchase':
          return WebResponsePurchaseSummaryResponsePurchase.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseSalesSummaryResponseSales':
          return WebResponseSalesSummaryResponseSales.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseStock':
          return WebResponseStock.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseString':
          return WebResponseString.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseTkdn':
          return WebResponseTkdn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseTokenResponse':
          return WebResponseTokenResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WebResponseUserResponse':
          return WebResponseUserResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return Map<dynamic, BaseType>.fromIterables(
              value.keys,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    } 
    throw Exception('Cannot deserialize');
  }