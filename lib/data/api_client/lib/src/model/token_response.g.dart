// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TokenResponse',
      json,
      ($checkedConvert) {
        final val = TokenResponse(
          accessToken: $checkedConvert('accessToken', (v) => v),
          refreshToken: $checkedConvert('refreshToken', (v) => v),
          type: $checkedConvert('type', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      if (instance.accessToken case final value?) 'accessToken': value,
      if (instance.refreshToken case final value?) 'refreshToken': value,
      if (instance.type case final value?) 'type': value,
    };
