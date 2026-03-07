// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponseTokenResponse _$WebResponseTokenResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponseTokenResponse',
      json,
      ($checkedConvert) {
        final val = WebResponseTokenResponse(
          status: $checkedConvert('status', (v) => v),
          message: $checkedConvert('message', (v) => v),
          data: $checkedConvert(
              'data',
              (v) => v == null
                  ? null
                  : TokenResponse.fromJson(v as Map<String, dynamic>)),
          paging: $checkedConvert(
              'paging',
              (v) => v == null
                  ? null
                  : PagingResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebResponseTokenResponseToJson(
        WebResponseTokenResponse instance) =>
    <String, dynamic>{
      if (instance.status case final value?) 'status': value,
      if (instance.message case final value?) 'message': value,
      if (instance.data?.toJson() case final value?) 'data': value,
      if (instance.paging?.toJson() case final value?) 'paging': value,
    };
