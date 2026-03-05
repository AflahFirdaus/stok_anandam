import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for DataCanvasingControllerApi
void main() {
  final instance = MyApiClient().getDataCanvasingControllerApi();

  group(DataCanvasingControllerApi, () {
    //Future<WebResponseDataCanvasing> create(DataCanvasingRequest dataCanvasingRequest) async
    test('test create', () async {
      // TODO
    });

    //Future<WebResponsePageDataCanvasing> getAll({ Object page, Object size, Object sortBy, Object direction, Object startDate, Object endDate, Object search }) async
    test('test getAll', () async {
      // TODO
    });

  });
}
