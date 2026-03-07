part of 'pageable_object.dart';


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
      if (instance.offset case final value?) 'offset': value,
      if (instance.sort?.toJson() case final value?) 'sort': value,
      if (instance.pageSize case final value?) 'pageSize': value,
      if (instance.pageNumber case final value?) 'pageNumber': value,
      if (instance.paged case final value?) 'paged': value,
      if (instance.unpaged case final value?) 'unpaged': value,
    };
