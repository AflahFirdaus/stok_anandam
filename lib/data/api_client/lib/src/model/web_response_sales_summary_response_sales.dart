//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:my_api_client/src/model/paging_response.dart';
import 'package:my_api_client/src/model/sales_summary_response_sales.dart';
import 'package:json_annotation/json_annotation.dart';

part 'web_response_sales_summary_response_sales.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WebResponseSalesSummaryResponseSales {
  /// Returns a new [WebResponseSalesSummaryResponseSales] instance.
  WebResponseSalesSummaryResponseSales({

     this.status,

     this.message,

     this.data,

     this.paging,
  });

  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false
  )


  final Object? status;



  @JsonKey(
    
    name: r'message',
    required: false,
    includeIfNull: false
  )


  final Object? message;



  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false
  )


  final SalesSummaryResponseSales? data;



  @JsonKey(
    
    name: r'paging',
    required: false,
    includeIfNull: false
  )


  final PagingResponse? paging;



  @override
  bool operator ==(Object other) => identical(this, other) || other is WebResponseSalesSummaryResponseSales &&
     other.status == status &&
     other.message == message &&
     other.data == data &&
     other.paging == paging;

  @override
  int get hashCode =>
    (status == null ? 0 : status.hashCode) +
    (message == null ? 0 : message.hashCode) +
    data.hashCode +
    paging.hashCode;

  factory WebResponseSalesSummaryResponseSales.fromJson(Map<String, dynamic> json) => _$WebResponseSalesSummaryResponseSalesFromJson(json);

  Map<String, dynamic> toJson() => _$WebResponseSalesSummaryResponseSalesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

