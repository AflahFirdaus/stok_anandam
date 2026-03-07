part of 'page_canvasing.dart';


PageCanvasing _$PageCanvasingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PageCanvasing',
      json,
      ($checkedConvert) {
        final val = PageCanvasing(
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

Map<String, dynamic> _$PageCanvasingToJson(PageCanvasing instance) =>
    <String, dynamic>{
      if (instance.totalPages case final value?) 'totalPages': value,
      if (instance.totalElements case final value?) 'totalElements': value,
      if (instance.size case final value?) 'size': value,
      if (instance.content case final value?) 'content': value,
      if (instance.number case final value?) 'number': value,
      if (instance.sort?.toJson() case final value?) 'sort': value,
      if (instance.first case final value?) 'first': value,
      if (instance.last case final value?) 'last': value,
      if (instance.numberOfElements case final value?)
        'numberOfElements': value,
      if (instance.pageable?.toJson() case final value?) 'pageable': value,
      if (instance.empty case final value?) 'empty': value,
    };
