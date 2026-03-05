//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'sales_summary_response_sales.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SalesSummaryResponseSales {
  /// Returns a new [SalesSummaryResponseSales] instance.
  SalesSummaryResponseSales({

     this.totalGrandSum,

     this.content,

     this.totalPages,

     this.totalElements,
  });

  @JsonKey(
    
    name: r'totalGrandSum',
    required: false,
    includeIfNull: false
  )


  final Object? totalGrandSum;



  @JsonKey(
    
    name: r'content',
    required: false,
    includeIfNull: false
  )


  final Object? content;



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



  @override
  bool operator ==(Object other) => identical(this, other) || other is SalesSummaryResponseSales &&
     other.totalGrandSum == totalGrandSum &&
     other.content == content &&
     other.totalPages == totalPages &&
     other.totalElements == totalElements;

  @override
  int get hashCode =>
    (totalGrandSum == null ? 0 : totalGrandSum.hashCode) +
    (content == null ? 0 : content.hashCode) +
    (totalPages == null ? 0 : totalPages.hashCode) +
    (totalElements == null ? 0 : totalElements.hashCode);

  factory SalesSummaryResponseSales.fromJson(Map<String, dynamic> json) => _$SalesSummaryResponseSalesFromJson(json);

  Map<String, dynamic> toJson() => _$SalesSummaryResponseSalesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

