import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for AuthControllerApi
void main() {
  final instance = MyApiClient().getAuthControllerApi();

  group(AuthControllerApi, () {
    //Future<WebResponseTokenResponse> login(LoginUserRequest loginUserRequest) async
    test('test login', () async {
      // TODO
    });

    //Future<WebResponseTokenResponse> refreshToken(RefreshTokenRequest refreshTokenRequest) async
    test('test refreshToken', () async {
      // TODO
    });

  });
}
