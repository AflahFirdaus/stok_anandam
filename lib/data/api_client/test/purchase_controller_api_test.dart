import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for PurchaseControllerApi
void main() {
  final instance = MyApiClient().getPurchaseControllerApi();

  group(PurchaseControllerApi, () {
    //Future<WebResponsePurchaseSummaryResponsePurchase> getPurchases({ Object page, Object size, Object sortBy, Object dir, Object startDate, Object endDate, Object search }) async
    test('test getPurchases', () async {
      // TODO
    });

  });
}
