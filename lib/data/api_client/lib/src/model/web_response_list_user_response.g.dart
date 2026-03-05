// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_list_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponseListUserResponse _$WebResponseListUserResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponseListUserResponse',
      json,
      ($checkedConvert) {
        final val = WebResponseListUserResponse(
          status: $checkedConvert('status', (v) => v),
          message: $checkedConvert('message', (v) => v),
          data: $checkedConvert('data', (v) => v),
          paging: $checkedConvert(
              'paging',
              (v) => v == null
                  ? null
                  : PagingResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebResponseListUserResponseToJson(
        WebResponseListUserResponse instance) =>
    <String, dynamic>{
      if (instance.status != null) 'status': instance.status,
      if (instance.message != null) 'message': instance.message,
      if (instance.data != null) 'data': instance.data,
      if (instance.paging != null) 'paging': instance.paging!.toJson(),
    };
