import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for CanvasingControllerApi
void main() {
  final instance = MyApiClient().getCanvasingControllerApi();

  group(CanvasingControllerApi, () {
    //Future<WebResponsePageCanvasing> getAllCanvasing({ Object page, Object size, Object sortBy, Object direction, Object search }) async
    test('test getAllCanvasing', () async {
      // TODO
    });

  });
}
