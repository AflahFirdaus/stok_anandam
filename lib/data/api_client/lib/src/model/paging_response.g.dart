part of 'paging_response.dart';


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
      if (instance.currentPage case final value?) 'currentPage': value,
      if (instance.totalPage case final value?) 'totalPage': value,
      if (instance.size case final value?) 'size': value,
      if (instance.totalItem case final value?) 'totalItem': value,
    };
