// @dart=3.5
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginUserRequest _$LoginUserRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LoginUserRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['username', 'password'],
        );
        final val = LoginUserRequest(
          username: $checkedConvert('username', (v) => v),
          password: $checkedConvert('password', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$LoginUserRequestToJson(LoginUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };
