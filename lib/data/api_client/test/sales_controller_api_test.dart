import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for SalesControllerApi
void main() {
  final instance = MyApiClient().getSalesControllerApi();

  group(SalesControllerApi, () {
    //Future<WebResponseSalesSummaryResponseSales> getAllSales({ Object page, Object size, Object sortBy, Object direction, Object startDate, Object endDate, Object empCode, Object search }) async
    test('test getAllSales', () async {
      // TODO
    });

  });
}
