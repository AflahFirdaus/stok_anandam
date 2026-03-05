import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for StockControllerApi
void main() {
  final instance = MyApiClient().getStockControllerApi();

  group(StockControllerApi, () {
    //Future<WebResponsePageStock> getAllStocks({ Object page, Object size, Object sortBy, Object direction, Object search }) async
    test('test getAllStocks', () async {
      // TODO
    });

    //Future<WebResponsePageStock> getAllStocks1({ Object page, Object size, Object sortBy, Object direction, Object search }) async
    test('test getAllStocks1', () async {
      // TODO
    });

    //Future<WebResponseStock> getStockDetail(Object id) async
    test('test getStockDetail', () async {
      // TODO
    });

    //Future<WebResponseStock> getStockDetail1(Object id) async
    test('test getStockDetail1', () async {
      // TODO
    });

  });
}
