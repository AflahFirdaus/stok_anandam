# my_api_client.api.DataCanvasingControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create**](DataCanvasingControllerApi.md#create) | **POST** /api/v1/data-canvasing | 
[**getAll**](DataCanvasingControllerApi.md#getall) | **GET** /api/v1/data-canvasing | 


# **create**
> WebResponseDataCanvasing create(dataCanvasingRequest)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getDataCanvasingControllerApi();
final DataCanvasingRequest dataCanvasingRequest = ; // DataCanvasingRequest | 

try {
    final response = api.create(dataCanvasingRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DataCanvasingControllerApi->create: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dataCanvasingRequest** | [**DataCanvasingRequest**](DataCanvasingRequest.md)|  | 

### Return type

[**WebResponseDataCanvasing**](WebResponseDataCanvasing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAll**
> WebResponsePageDataCanvasing getAll(page, size, sortBy, direction, startDate, endDate, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getDataCanvasingControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object direction = ; // Object | 
final Object startDate = ; // Object | 
final Object endDate = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getAll(page, size, sortBy, direction, startDate, endDate, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DataCanvasingControllerApi->getAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to tanggal]
 **direction** | [**Object**](.md)|  | [optional] [default to desc]
 **startDate** | [**Object**](.md)|  | [optional] 
 **endDate** | [**Object**](.md)|  | [optional] 
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponsePageDataCanvasing**](WebResponsePageDataCanvasing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

