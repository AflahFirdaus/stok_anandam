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
      if (instance.accessToken != null) 'accessToken': instance.accessToken,
      if (instance.refreshToken != null) 'refreshToken': instance.refreshToken,
      if (instance.type != null) 'type': instance.type,
    };
