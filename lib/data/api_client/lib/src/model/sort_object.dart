//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'sort_object.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SortObject {
  /// Returns a new [SortObject] instance.
  SortObject({

     this.empty,

     this.sorted,

     this.unsorted,
  });

  @JsonKey(
    
    name: r'empty',
    required: false,
    includeIfNull: false
  )


  final Object? empty;



  @JsonKey(
    
    name: r'sorted',
    required: false,
    includeIfNull: false
  )


  final Object? sorted;



  @JsonKey(
    
    name: r'unsorted',
    required: false,
    includeIfNull: false
  )


  final Object? unsorted;



  @override
  bool operator ==(Object other) => identical(this, other) || other is SortObject &&
     other.empty == empty &&
     other.sorted == sorted &&
     other.unsorted == unsorted;

  @override
  int get hashCode =>
    (empty == null ? 0 : empty.hashCode) +
    (sorted == null ? 0 : sorted.hashCode) +
    (unsorted == null ? 0 : unsorted.hashCode);

  factory SortObject.fromJson(Map<String, dynamic> json) => _$SortObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SortObjectToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

