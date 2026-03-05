// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paging_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PagingResponse _$PagingResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PagingResponse',
      json,
      ($checkedConvert) {
        final val = PagingResponse(
          currentPage: $checkedConvert('currentPage', (v) => v),
          totalPage: $checkedConvert('totalPage', (v) => v),
          size: $checkedConvert('size', (v) => v),
          totalItem: $checkedConvert('totalItem', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$PagingResponseToJson(PagingResponse instance) =>
    <String, dynamic>{
      if (instance.currentPage != null) 'currentPage': instance.currentPage,
      if (instance.totalPage != null) 'totalPage': instance.totalPage,
      if (instance.size != null) 'size': instance.size,
      if (instance.totalItem != null) 'totalItem': instance.totalItem,
    };
