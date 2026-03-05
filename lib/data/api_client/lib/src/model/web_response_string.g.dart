// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_string.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponseString _$WebResponseStringFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponseString',
      json,
      ($checkedConvert) {
        final val = WebResponseString(
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

Map<String, dynamic> _$WebResponseStringToJson(WebResponseString instance) =>
    <String, dynamic>{
      if (instance.status != null) 'status': instance.status,
      if (instance.message != null) 'message': instance.message,
      if (instance.data != null) 'data': instance.data,
      if (instance.paging != null) 'paging': instance.paging!.toJson(),
    };
