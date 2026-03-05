//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'paging_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PagingResponse {
  /// Returns a new [PagingResponse] instance.
  PagingResponse({

     this.currentPage,

     this.totalPage,

     this.size,

     this.totalItem,
  });

  @JsonKey(
    
    name: r'currentPage',
    required: false,
    includeIfNull: false
  )


  final Object? currentPage;



  @JsonKey(
    
    name: r'totalPage',
    required: false,
    includeIfNull: false
  )


  final Object? totalPage;



  @JsonKey(
    
    name: r'size',
    required: false,
    includeIfNull: false
  )


  final Object? size;



  @JsonKey(
    
    name: r'totalItem',
    required: false,
    includeIfNull: false
  )


  final Object? totalItem;



  @override
  bool operator ==(Object other) => identical(this, other) || other is PagingResponse &&
     other.currentPage == currentPage &&
     other.totalPage == totalPage &&
     other.size == size &&
     other.totalItem == totalItem;

  @override
  int get hashCode =>
    (currentPage == null ? 0 : currentPage.hashCode) +
    (totalPage == null ? 0 : totalPage.hashCode) +
    (size == null ? 0 : size.hashCode) +
    (totalItem == null ? 0 : totalItem.hashCode);

  factory PagingResponse.fromJson(Map<String, dynamic> json) => _$PagingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PagingResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

