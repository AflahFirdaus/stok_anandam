# my_api_client.api.UserControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createUser**](UserControllerApi.md#createuser) | **POST** /api/v1/users | 
[**deleteUser**](UserControllerApi.md#deleteuser) | **DELETE** /api/v1/users/{id} | 
[**getAllUsers**](UserControllerApi.md#getallusers) | **GET** /api/v1/users | 
[**updateUser**](UserControllerApi.md#updateuser) | **PUT** /api/v1/users/{id} | 


# **createUser**
> WebResponseUserResponse createUser(userRequest)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getUserControllerApi();
final UserRequest userRequest = ; // UserRequest | 

try {
    final response = api.createUser(userRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UserControllerApi->createUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userRequest** | [**UserRequest**](UserRequest.md)|  | 

### Return type

[**WebResponseUserResponse**](WebResponseUserResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteUser**
> WebResponseString deleteUser(id)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getUserControllerApi();
final Object id = ; // Object | 

try {
    final response = api.deleteUser(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UserControllerApi->deleteUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | [**Object**](.md)|  | 

### Return type

[**WebResponseString**](WebResponseString.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllUsers**
> WebResponseListUserResponse getAllUsers(page, size)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getUserControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 

try {
    final response = api.getAllUsers(page, size);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UserControllerApi->getAllUsers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]

### Return type

[**WebResponseListUserResponse**](WebResponseListUserResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUser**
> WebResponseUserResponse updateUser(id, userRequest)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getUserControllerApi();
final Object id = ; // Object | 
final UserRequest userRequest = ; // UserRequest | 

try {
    final response = api.updateUser(id, userRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UserControllerApi->updateUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | [**Object**](.md)|  | 
 **userRequest** | [**UserRequest**](UserRequest.md)|  | 

### Return type

[**WebResponseUserResponse**](WebResponseUserResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

