# my_api_client.api.StockControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAllStocks**](StockControllerApi.md#getallstocks) | **GET** /api/v1/stock | 
[**getAllStocks1**](StockControllerApi.md#getallstocks1) | **GET** /api/v1/stocks | 
[**getStockDetail**](StockControllerApi.md#getstockdetail) | **GET** /api/v1/stock/{id} | 
[**getStockDetail1**](StockControllerApi.md#getstockdetail1) | **GET** /api/v1/stocks/{id} | 


# **getAllStocks**
> WebResponsePageStock getAllStocks(page, size, sortBy, direction, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getStockControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object direction = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getAllStocks(page, size, sortBy, direction, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling StockControllerApi->getAllStocks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to itemName]
 **direction** | [**Object**](.md)|  | [optional] [default to asc]
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponsePageStock**](WebResponsePageStock.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllStocks1**
> WebResponsePageStock getAllStocks1(page, size, sortBy, direction, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getStockControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object direction = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getAllStocks1(page, size, sortBy, direction, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling StockControllerApi->getAllStocks1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to itemName]
 **direction** | [**Object**](.md)|  | [optional] [default to asc]
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponsePageStock**](WebResponsePageStock.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getStockDetail**
> WebResponseStock getStockDetail(id)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getStockControllerApi();
final Object id = ; // Object | 

try {
    final response = api.getStockDetail(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling StockControllerApi->getStockDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | [**Object**](.md)|  | 

### Return type

[**WebResponseStock**](WebResponseStock.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getStockDetail1**
> WebResponseStock getStockDetail1(id)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getStockControllerApi();
final Object id = ; // Object | 

try {
    final response = api.getStockDetail1(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling StockControllerApi->getStockDetail1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | [**Object**](.md)|  | 

### Return type

[**WebResponseStock**](WebResponseStock.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

