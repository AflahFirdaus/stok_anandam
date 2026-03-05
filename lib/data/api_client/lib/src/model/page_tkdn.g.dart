// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_tkdn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageTkdn _$PageTkdnFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PageTkdn',
      json,
      ($checkedConvert) {
        final val = PageTkdn(
          totalPages: $checkedConvert('totalPages', (v) => v),
          totalElements: $checkedConvert('totalElements', (v) => v),
          size: $checkedConvert('size', (v) => v),
          content: $checkedConvert('content', (v) => v),
          number: $checkedConvert('number', (v) => v),
          sort: $checkedConvert(
              'sort',
              (v) => v == null
                  ? null
                  : SortObject.fromJson(v as Map<String, dynamic>)),
          first: $checkedConvert('first', (v) => v),
          last: $checkedConvert('last', (v) => v),
          numberOfElements: $checkedConvert('numberOfElements', (v) => v),
          pageable: $checkedConvert(
              'pageable',
              (v) => v == null
                  ? null
                  : PageableObject.fromJson(v as Map<String, dynamic>)),
          empty: $checkedConvert('empty', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$PageTkdnToJson(PageTkdn instance) => <String, dynamic>{
      if (instance.totalPages != null) 'totalPages': instance.totalPages,
      if (instance.totalElements != null) 'totalElements': instance.totalElements,
      if (instance.size != null) 'size': instance.size,
      if (instance.content != null) 'content': instance.content,
      if (instance.number != null) 'number': instance.number,
      if (instance.sort != null) 'sort': instance.sort!.toJson(),
      if (instance.first != null) 'first': instance.first,
      if (instance.last != null) 'last': instance.last,
      if (instance.numberOfElements != null)
        'numberOfElements': instance.numberOfElements,
      if (instance.pageable != null) 'pageable': instance.pageable!.toJson(),
      if (instance.empty != null) 'empty': instance.empty,
    };
