// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponseUserResponse _$WebResponseUserResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponseUserResponse',
      json,
      ($checkedConvert) {
        final val = WebResponseUserResponse(
          status: $checkedConvert('status', (v) => v),
          message: $checkedConvert('message', (v) => v),
          data: $checkedConvert(
              'data',
              (v) => v == null
                  ? null
                  : UserResponse.fromJson(v as Map<String, dynamic>)),
          paging: $checkedConvert(
              'paging',
              (v) => v == null
                  ? null
                  : PagingResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebResponseUserResponseToJson(
        WebResponseUserResponse instance) =>
    <String, dynamic>{
      if (instance.status != null) 'status': instance.status,
      if (instance.message != null) 'message': instance.message,
      if (instance.data != null) 'data': instance.data!.toJson(),
      if (instance.paging != null) 'paging': instance.paging!.toJson(),
    };
