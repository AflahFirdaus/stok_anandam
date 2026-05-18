// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_list_string.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponseListString _$WebResponseListStringFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponseListString',
      json,
      ($checkedConvert) {
        final val = WebResponseListString(
          status: $checkedConvert('status', (v) => v),
          message: $checkedConvert('message', (v) => v),
          data: $checkedConvert('data',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          paging: $checkedConvert(
              'paging',
              (v) => v == null
                  ? null
                  : PagingResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebResponseListStringToJson(
        WebResponseListString instance) =>
    <String, dynamic>{
      if (instance.status case final value?) 'status': value,
      if (instance.message case final value?) 'message': value,
      if (instance.data case final value?) 'data': value,
      if (instance.paging?.toJson() case final value?) 'paging': value,
    };
