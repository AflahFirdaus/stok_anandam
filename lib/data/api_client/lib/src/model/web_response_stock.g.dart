// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_response_stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebResponseStock _$WebResponseStockFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WebResponseStock',
      json,
      ($checkedConvert) {
        final val = WebResponseStock(
          status: $checkedConvert('status', (v) => v),
          message: $checkedConvert('message', (v) => v),
          data: $checkedConvert(
              'data',
              (v) =>
                  v == null ? null : Stock.fromJson(v as Map<String, dynamic>)),
          paging: $checkedConvert(
              'paging',
              (v) => v == null
                  ? null
                  : PagingResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$WebResponseStockToJson(WebResponseStock instance) =>
    <String, dynamic>{
      if (instance.status != null) 'status': instance.status,
      if (instance.message != null) 'message': instance.message,
      if (instance.data != null) 'data': instance.data!.toJson(),
      if (instance.paging != null) 'paging': instance.paging!.toJson(),
    };
