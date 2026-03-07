// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_page_data_canvasing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponsePageDataCanvasing _$WebResponsePageDataCanvasingFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponsePageDataCanvasing',
      json,
      ($checkedConvert) {
        final val = WebResponsePageDataCanvasing(
          status: $checkedConvert('status', (v) => v),
          message: $checkedConvert('message', (v) => v),
          data: $checkedConvert(
              'data',
              (v) => v == null
                  ? null
                  : PageDataCanvasing.fromJson(v as Map<String, dynamic>)),
          paging: $checkedConvert(
              'paging',
              (v) => v == null
                  ? null
                  : PagingResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebResponsePageDataCanvasingToJson(
        WebResponsePageDataCanvasing instance) =>
    <String, dynamic>{
      if (instance.status case final value?) 'status': value,
      if (instance.message case final value?) 'message': value,
      if (instance.data?.toJson() case final value?) 'data': value,
      if (instance.paging?.toJson() case final value?) 'paging': value,
    };
