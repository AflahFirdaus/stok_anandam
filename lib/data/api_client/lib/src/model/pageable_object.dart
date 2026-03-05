//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:my_api_client/src/model/sort_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pageable_object.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageableObject {
  /// Returns a new [PageableObject] instance.
  PageableObject({

     this.offset,

     this.sort,

     this.pageSize,

     this.pageNumber,

     this.paged,

     this.unpaged,
  });

  @JsonKey(
    
    name: r'offset',
    required: false,
    includeIfNull: false
  )


  final Object? offset;



  @JsonKey(
    
    name: r'sort',
    required: false,
    includeIfNull: false
  )


  final SortObject? sort;



  @JsonKey(
    
    name: r'pageSize',
    required: false,
    includeIfNull: false
  )


  final Object? pageSize;



  @JsonKey(
    
    name: r'pageNumber',
    required: false,
    includeIfNull: false
  )


  final Object? pageNumber;



  @JsonKey(
    
    name: r'paged',
    required: false,
    includeIfNull: false
  )


  final Object? paged;



  @JsonKey(
    
    name: r'unpaged',
    required: false,
    includeIfNull: false
  )


  final Object? unpaged;



  @override
  bool operator ==(Object other) => identical(this, other) || other is PageableObject &&
     other.offset == offset &&
     other.sort == sort &&
     other.pageSize == pageSize &&
     other.pageNumber == pageNumber &&
     other.paged == paged &&
     other.unpaged == unpaged;

  @override
  int get hashCode =>
    (offset == null ? 0 : offset.hashCode) +
    sort.hashCode +
    (pageSize == null ? 0 : pageSize.hashCode) +
    (pageNumber == null ? 0 : pageNumber.hashCode) +
    (paged == null ? 0 : paged.hashCode) +
    (unpaged == null ? 0 : unpaged.hashCode);

  factory PageableObject.fromJson(Map<String, dynamic> json) => _$PageableObjectFromJson(json);

  Map<String, dynamic> toJson() => _$PageableObjectToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

