// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pageable_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageableObject _$PageableObjectFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PageableObject',
      json,
      ($checkedConvert) {
        final val = PageableObject(
          offset: $checkedConvert('offset', (v) => v),
          sort: $checkedConvert(
              'sort',
              (v) => v == null
                  ? null
                  : SortObject.fromJson(v as Map<String, dynamic>)),
          pageSize: $checkedConvert('pageSize', (v) => v),
          pageNumber: $checkedConvert('pageNumber', (v) => v),
          paged: $checkedConvert('paged', (v) => v),
          unpaged: $checkedConvert('unpaged', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$PageableObjectToJson(PageableObject instance) =>
    <String, dynamic>{
      if (instance.offset != null) 'offset': instance.offset,
      if (instance.sort != null) 'sort': instance.sort!.toJson(),
      if (instance.pageSize != null) 'pageSize': instance.pageSize,
      if (instance.pageNumber != null) 'pageNumber': instance.pageNumber,
      if (instance.paged != null) 'paged': instance.paged,
      if (instance.unpaged != null) 'unpaged': instance.unpaged,
    };
