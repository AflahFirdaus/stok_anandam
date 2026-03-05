//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'sales.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Sales {
  /// Returns a new [Sales] instance.
  Sales({

     this.id,

     this.docDate,

     this.docNo,

     this.code,

     this.parName,

     this.itemName,

     this.qty,

     this.price,

     this.grandTotal,

     this.empCode,
  });

  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false
  )


  final Object? id;



  @JsonKey(
    
    name: r'docDate',
    required: false,
    includeIfNull: false
  )


  final Object? docDate;



  @JsonKey(
    
    name: r'docNo',
    required: false,
    includeIfNull: false
  )


  final Object? docNo;



  @JsonKey(
    
    name: r'code',
    required: false,
    includeIfNull: false
  )


  final Object? code;



  @JsonKey(
    
    name: r'parName',
    required: false,
    includeIfNull: false
  )


  final Object? parName;



  @JsonKey(
    
    name: r'itemName',
    required: false,
    includeIfNull: false
  )


  final Object? itemName;



  @JsonKey(
    
    name: r'qty',
    required: false,
    includeIfNull: false
  )


  final Object? qty;



  @JsonKey(
    
    name: r'price',
    required: false,
    includeIfNull: false
  )


  final Object? price;



  @JsonKey(
    
    name: r'grandTotal',
    required: false,
    includeIfNull: false
  )


  final Object? grandTotal;



  @JsonKey(
    
    name: r'empCode',
    required: false,
    includeIfNull: false
  )


  final Object? empCode;



  @override
  bool operator ==(Object other) => identical(this, other) || other is Sales &&
     other.id == id &&
     other.docDate == docDate &&
     other.docNo == docNo &&
     other.code == code &&
     other.parName == parName &&
     other.itemName == itemName &&
     other.qty == qty &&
     other.price == price &&
     other.grandTotal == grandTotal &&
     other.empCode == empCode;

  @override
  int get hashCode =>
    (id == null ? 0 : id.hashCode) +
    (docDate == null ? 0 : docDate.hashCode) +
    (docNo == null ? 0 : docNo.hashCode) +
    (code == null ? 0 : code.hashCode) +
    (parName == null ? 0 : parName.hashCode) +
    (itemName == null ? 0 : itemName.hashCode) +
    (qty == null ? 0 : qty.hashCode) +
    (price == null ? 0 : price.hashCode) +
    (grandTotal == null ? 0 : grandTotal.hashCode) +
    (empCode == null ? 0 : empCode.hashCode);

  factory Sales.fromJson(Map<String, dynamic> json) => _$SalesFromJson(json);

  Map<String, dynamic> toJson() => _$SalesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

