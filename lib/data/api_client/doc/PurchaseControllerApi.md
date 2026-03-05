# my_api_client.api.PurchaseControllerApi

## Load the API package
```dart
import 'package:my_api_client/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getPurchases**](PurchaseControllerApi.md#getpurchases) | **GET** /api/v1/purchases | 


# **getPurchases**
> WebResponsePurchaseSummaryResponsePurchase getPurchases(page, size, sortBy, dir, startDate, endDate, search)



### Example
```dart
import 'package:my_api_client/api.dart';

final api = MyApiClient().getPurchaseControllerApi();
final Object page = ; // Object | 
final Object size = ; // Object | 
final Object sortBy = ; // Object | 
final Object dir = ; // Object | 
final Object startDate = ; // Object | 
final Object endDate = ; // Object | 
final Object search = ; // Object | 

try {
    final response = api.getPurchases(page, size, sortBy, dir, startDate, endDate, search);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PurchaseControllerApi->getPurchases: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | [**Object**](.md)|  | [optional] [default to 0]
 **size** | [**Object**](.md)|  | [optional] [default to 10]
 **sortBy** | [**Object**](.md)|  | [optional] [default to docDate]
 **dir** | [**Object**](.md)|  | [optional] [default to desc]
 **startDate** | [**Object**](.md)|  | [optional] 
 **endDate** | [**Object**](.md)|  | [optional] 
 **search** | [**Object**](.md)|  | [optional] 

### Return type

[**WebResponsePurchaseSummaryResponsePurchase**](WebResponsePurchaseSummaryResponsePurchase.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

