part of 'sort_object.dart';


SortObject _$SortObjectFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SortObject',
      json,
      ($checkedConvert) {
        final val = SortObject(
          empty: $checkedConvert('empty', (v) => v),
          sorted: $checkedConvert('sorted', (v) => v),
          unsorted: $checkedConvert('unsorted', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$SortObjectToJson(SortObject instance) =>
    <String, dynamic>{
      if (instance.empty case final value?) 'empty': value,
      if (instance.sorted case final value?) 'sorted': value,
      if (instance.unsorted case final value?) 'unsorted': value,
    };
