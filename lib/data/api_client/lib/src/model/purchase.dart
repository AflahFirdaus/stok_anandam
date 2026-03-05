//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'purchase.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Purchase {
  /// Returns a new [Purchase] instance.
  Purchase({

     this.id,

     this.docDate,

     this.docNoP,

     this.parName,

     this.depCode,

     this.itemCode,

     this.itemName,

     this.qty,

     this.price,

     this.grandTotal,
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
    
    name: r'docNoP',
    required: false,
    includeIfNull: false
  )


  final Object? docNoP;



  @JsonKey(
    
    name: r'parName',
    required: false,
    includeIfNull: false
  )


  final Object? parName;



  @JsonKey(
    
    name: r'depCode',
    required: false,
    includeIfNull: false
  )


  final Object? depCode;



  @JsonKey(
    
    name: r'itemCode',
    required: false,
    includeIfNull: false
  )


  final Object? itemCode;



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



  @override
  bool operator ==(Object other) => identical(this, other) || other is Purchase &&
     other.id == id &&
     other.docDate == docDate &&
     other.docNoP == docNoP &&
     other.parName == parName &&
     other.depCode == depCode &&
     other.itemCode == itemCode &&
     other.itemName == itemName &&
     other.qty == qty &&
     other.price == price &&
     other.grandTotal == grandTotal;

  @override
  int get hashCode =>
    (id == null ? 0 : id.hashCode) +
    (docDate == null ? 0 : docDate.hashCode) +
    (docNoP == null ? 0 : docNoP.hashCode) +
    (parName == null ? 0 : parName.hashCode) +
    (depCode == null ? 0 : depCode.hashCode) +
    (itemCode == null ? 0 : itemCode.hashCode) +
    (itemName == null ? 0 : itemName.hashCode) +
    (qty == null ? 0 : qty.hashCode) +
    (price == null ? 0 : price.hashCode) +
    (grandTotal == null ? 0 : grandTotal.hashCode);

  factory Purchase.fromJson(Map<String, dynamic> json) => _$PurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

