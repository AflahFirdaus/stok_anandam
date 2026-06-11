# my_api_client.api.AuthControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:9099*

Method | HTTP request | Description
------------- | ------------- | -------------
[**login**](AuthControllerApi.md#login) | **POST** /api/v1/auth/login | 
[**refreshToken**](AuthControllerApi.md#refreshtoken) | **POST** /api/v1/auth/refresh | 


# **login**
> WebResponseTokenResponse login(loginUserRequest)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getAuthControllerApi();
final LoginUserRequest loginUserRequest = ; // LoginUserRequest | 

try {
    final response = api.login(loginUserRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthControllerApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginUserRequest** | [**LoginUserRequest**](LoginUserRequest.md)|  | 

### Return type

[**WebResponseTokenResponse**](WebResponseTokenResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshToken**
> WebResponseTokenResponse refreshToken(refreshTokenRequest)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getAuthControllerApi();
final RefreshTokenRequest refreshTokenRequest = ; // RefreshTokenRequest | 

try {
    final response = api.refreshToken(refreshTokenRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthControllerApi->refreshToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshTokenRequest** | [**RefreshTokenRequest**](RefreshTokenRequest.md)|  | 

### Return type

[**WebResponseTokenResponse**](WebResponseTokenResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

