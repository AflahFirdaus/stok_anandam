//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:my_api_client/src/model/sort_object.dart';
import 'package:my_api_client/src/model/pageable_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_stock.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageStock {
  /// Returns a new [PageStock] instance.
  PageStock({

     this.totalPages,

     this.totalElements,

     this.size,

     this.content,

     this.number,

     this.sort,

     this.first,

     this.last,

     this.numberOfElements,

     this.pageable,

     this.empty,
  });

  @JsonKey(
    
    name: r'totalPages',
    required: false,
    includeIfNull: false
  )


  final Object? totalPages;



  @JsonKey(
    
    name: r'totalElements',
    required: false,
    includeIfNull: false
  )


  final Object? totalElements;



  @JsonKey(
    
    name: r'size',
    required: false,
    includeIfNull: false
  )


  final Object? size;



  @JsonKey(
    
    name: r'content',
    required: false,
    includeIfNull: false
  )


  final Object? content;



  @JsonKey(
    
    name: r'number',
    required: false,
    includeIfNull: false
  )


  final Object? number;



  @JsonKey(
    
    name: r'sort',
    required: false,
    includeIfNull: false
  )


  final SortObject? sort;



  @JsonKey(
    
    name: r'first',
    required: false,
    includeIfNull: false
  )


  final Object? first;



  @JsonKey(
    
    name: r'last',
    required: false,
    includeIfNull: false
  )


  final Object? last;



  @JsonKey(
    
    name: r'numberOfElements',
    required: false,
    includeIfNull: false
  )


  final Object? numberOfElements;



  @JsonKey(
    
    name: r'pageable',
    required: false,
    includeIfNull: false
  )


  final PageableObject? pageable;



  @JsonKey(
    
    name: r'empty',
    required: false,
    includeIfNull: false
  )


  final Object? empty;



  @override
  bool operator ==(Object other) => identical(this, other) || other is PageStock &&
     other.totalPages == totalPages &&
     other.totalElements == totalElements &&
     other.size == size &&
     other.content == content &&
     other.number == number &&
     other.sort == sort &&
     other.first == first &&
     other.last == last &&
     other.numberOfElements == numberOfElements &&
     other.pageable == pageable &&
     other.empty == empty;

  @override
  int get hashCode =>
    (totalPages == null ? 0 : totalPages.hashCode) +
    (totalElements == null ? 0 : totalElements.hashCode) +
    (size == null ? 0 : size.hashCode) +
    (content == null ? 0 : content.hashCode) +
    (number == null ? 0 : number.hashCode) +
    sort.hashCode +
    (first == null ? 0 : first.hashCode) +
    (last == null ? 0 : last.hashCode) +
    (numberOfElements == null ? 0 : numberOfElements.hashCode) +
    pageable.hashCode +
    (empty == null ? 0 : empty.hashCode);

  factory PageStock.fromJson(Map<String, dynamic> json) => _$PageStockFromJson(json);

  Map<String, dynamic> toJson() => _$PageStockToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

