import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for DashboardControllerApi
void main() {
  final instance = MyApiClient().getDashboardControllerApi();

  group(DashboardControllerApi, () {
    //Future<WebResponseDashboardResponse> getSummary() async
    test('test getSummary', () async {
      // TODO
    });

  });
}
