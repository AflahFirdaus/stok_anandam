import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for TkdnControllerApi
void main() {
  final instance = MyApiClient().getTkdnControllerApi();

  group(TkdnControllerApi, () {
    //Future<WebResponsePageTkdn> getAllTkdn({ Object page, Object size, Object sortBy, Object direction, Object isTkdn, Object kategori, Object search }) async
    test('test getAllTkdn', () async {
      // TODO
    });

    //Future<WebResponseTkdn> getTkdnDetail(Object id) async
    test('test getTkdnDetail', () async {
      // TODO
    });

  });
}
