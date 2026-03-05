//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'purchase_summary_response_purchase.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PurchaseSummaryResponsePurchase {
  /// Returns a new [PurchaseSummaryResponsePurchase] instance.
  PurchaseSummaryResponsePurchase({

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
  bool operator ==(Object other) => identical(this, other) || other is PurchaseSummaryResponsePurchase &&
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

  factory PurchaseSummaryResponsePurchase.fromJson(Map<String, dynamic> json) => _$PurchaseSummaryResponsePurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseSummaryResponsePurchaseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

