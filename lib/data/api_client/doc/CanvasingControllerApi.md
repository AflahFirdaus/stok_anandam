# my_api_client.api.CanvasingControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:9099*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAllCanvasing**](CanvasingControllerApi.md#getallcanvasing) | **GET** /api/v1/canvasing | 


# **getAllCanvasing**
> WebResponsePageCanvasing getAllCanvasing(page, size, sortBy, direction, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getCanvasingControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object direction = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getAllCanvasing(page, size, sortBy, direction, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling CanvasingControllerApi->getAllCanvasing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to namaInstansi]
 **direction** | [**Object**](.md)|  | [optional] [default to asc]
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponsePageCanvasing**](WebResponsePageCanvasing.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

