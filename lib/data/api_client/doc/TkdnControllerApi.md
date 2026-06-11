# my_api_client.api.TkdnControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:9099*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAllTkdn**](TkdnControllerApi.md#getalltkdn) | **GET** /api/v1/tkdn | 
[**getTkdnDetail**](TkdnControllerApi.md#gettkdndetail) | **GET** /api/v1/tkdn/{id} | 


# **getAllTkdn**
> WebResponsePageTkdn getAllTkdn(page, size, sortBy, direction, isTkdn, kategori, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getTkdnControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object direction = ; // Object | 
final Object isTkdn = ; // Object | 
final Object kategori = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getAllTkdn(page, size, sortBy, direction, isTkdn, kategori, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TkdnControllerApi->getAllTkdn: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to nama]
 **direction** | [**Object**](.md)|  | [optional] [default to asc]
 **isTkdn** | [**Object**](.md)|  | [optional] 
 **kategori** | [**Object**](.md)|  | [optional] 
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponsePageTkdn**](WebResponsePageTkdn.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTkdnDetail**
> WebResponseTkdn getTkdnDetail(id)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getTkdnControllerApi();
final Object id = ; // Object | 

try {
    final response = api.getTkdnDetail(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TkdnControllerApi->getTkdnDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | [**Object**](.md)|  | 

### Return type

[**WebResponseTkdn**](WebResponseTkdn.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

