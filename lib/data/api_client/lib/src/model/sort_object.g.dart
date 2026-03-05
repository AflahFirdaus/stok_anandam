// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sort_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      if (instance.empty != null) 'empty': instance.empty,
      if (instance.sorted != null) 'sorted': instance.sorted,
      if (instance.unsorted != null) 'unsorted': instance.unsorted,
    };
