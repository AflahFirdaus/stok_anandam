import 'package:test/test.dart';
import 'package:my_api_client/my_api_client.dart';


/// tests for UserControllerApi
void main() {
  final instance = MyApiClient().getUserControllerApi();

  group(UserControllerApi, () {
    //Future<WebResponseUserResponse> createUser(UserRequest userRequest) async
    test('test createUser', () async {
      // TODO
    });

    //Future<WebResponseString> deleteUser(Object id) async
    test('test deleteUser', () async {
      // TODO
    });

    //Future<WebResponseListUserResponse> getAllUsers({ Object page, Object size }) async
    test('test getAllUsers', () async {
      // TODO
    });

    //Future<WebResponseUserResponse> updateUser(Object id, UserRequest userRequest) async
    test('test updateUser', () async {
      // TODO
    });

  });
}
