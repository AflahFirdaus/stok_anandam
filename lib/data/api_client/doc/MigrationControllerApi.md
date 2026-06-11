# my_api_client.api.MigrationControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:9099*

Method | HTTP request | Description
------------- | ------------- | -------------
[**startCanvasingMigration**](MigrationControllerApi.md#startcanvasingmigration) | **POST** /api/v1/migration/canvasing | 
[**startPurchaseMigration**](MigrationControllerApi.md#startpurchasemigration) | **POST** /api/v1/migration/purchase | 
[**startSalesMigration**](MigrationControllerApi.md#startsalesmigration) | **POST** /api/v1/migration/sales | 
[**startStockMigration**](MigrationControllerApi.md#startstockmigration) | **POST** /api/v1/migration/stock | 
[**startTkdnMigration**](MigrationControllerApi.md#starttkdnmigration) | **POST** /api/v1/migration/tkdn | 


# **startCanvasingMigration**
> WebResponseString startCanvasingMigration()



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getMigrationControllerApi();

try {
    final response = api.startCanvasingMigration();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MigrationControllerApi->startCanvasingMigration: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebResponseString**](WebResponseString.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startPurchaseMigration**
> WebResponseString startPurchaseMigration()



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getMigrationControllerApi();

try {
    final response = api.startPurchaseMigration();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MigrationControllerApi->startPurchaseMigration: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebResponseString**](WebResponseString.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startSalesMigration**
> WebResponseString startSalesMigration()



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getMigrationControllerApi();

try {
    final response = api.startSalesMigration();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MigrationControllerApi->startSalesMigration: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebResponseString**](WebResponseString.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startStockMigration**
> WebResponseString startStockMigration()



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getMigrationControllerApi();

try {
    final response = api.startStockMigration();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MigrationControllerApi->startStockMigration: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebResponseString**](WebResponseString.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startTkdnMigration**
> WebResponseString startTkdnMigration()



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getMigrationControllerApi();

try {
    final response = api.startTkdnMigration();
    print(response);
} catch on DioException (e) {
    print('Exception when calling MigrationControllerApi->startTkdnMigration: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebResponseString**](WebResponseString.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

