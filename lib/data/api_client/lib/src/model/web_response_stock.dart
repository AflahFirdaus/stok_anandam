//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:my_api_client/src/model/stock.dart';
import 'package:my_api_client/src/model/paging_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'web_response_stock.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WebResponseStock {
  /// Returns a new [WebResponseStock] instance.
  WebResponseStock({

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


  final Stock? data;



  @JsonKey(
    
    name: r'paging',
    required: false,
    includeIfNull: false
  )


  final PagingResponse? paging;



  @override
  bool operator ==(Object other) => identical(this, other) || other is WebResponseStock &&
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

  factory WebResponseStock.fromJson(Map<String, dynamic> json) => _$WebResponseStockFromJson(json);

  Map<String, dynamic> toJson() => _$WebResponseStockToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

