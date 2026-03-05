# my_api_client.api.SalesControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAllSales**](SalesControllerApi.md#getallsales) | **GET** /api/v1/sales | 


# **getAllSales**
> WebResponseSalesSummaryResponseSales getAllSales(page, size, sortBy, direction, startDate, endDate, empCode, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getSalesControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object direction = ; // Object | 
final Object startDate = ; // Object | 
final Object endDate = ; // Object | 
final Object empCode = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getAllSales(page, size, sortBy, direction, startDate, endDate, empCode, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SalesControllerApi->getAllSales: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to docDate]
 **direction** | [**Object**](.md)|  | [optional] [default to desc]
 **startDate** | [**Object**](.md)|  | [optional] 
 **endDate** | [**Object**](.md)|  | [optional] 
 **empCode** | [**Object**](.md)|  | [optional] 
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponseSalesSummaryResponseSales**](WebResponseSalesSummaryResponseSales.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

