# my_api_client.api.DashboardControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:9099*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getSummary**](DashboardControllerApi.md#getsummary) | **GET** /api/v1/dashboard/summary | 


# **getSummary**
> WebResponseDashboardResponse getSummary()



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getDashboardControllerApi();

try {
    final response = api.getSummary();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DashboardControllerApi->getSummary: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebResponseDashboardResponse**](WebResponseDashboardResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

