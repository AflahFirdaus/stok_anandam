import 'package:json_annotation/json_annotation.dart';

part 'stock.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Stock {
  Stock({
    this.id,
    this.itemCode,
    this.itemName,
    this.kategoriNama,
    this.kategoriItemcode,
    this.finalStok,
    this.hargaHpp,
    this.grandTotal,
    this.modal,
    this.warehouse,
    this.finalPricelist,
    this.isPpn,
  });

  @JsonKey(name: r'id', required: false, includeIfNull: false)
  final Object? id;

  @JsonKey(name: r'itemCode', required: false, includeIfNull: false)
  final Object? itemCode;

  @JsonKey(name: r'itemName', required: false, includeIfNull: false)
  final Object? itemName;

  @JsonKey(name: r'kategoriNama', required: false, includeIfNull: false)
  final Object? kategoriNama;

  @JsonKey(name: r'kategoriItemcode', required: false, includeIfNull: false)
  final Object? kategoriItemcode;

  @JsonKey(name: r'finalStok', required: false, includeIfNull: false)
  final Object? finalStok;

  @JsonKey(name: r'hargaHpp', required: false, includeIfNull: false)
  final Object? hargaHpp;

  @JsonKey(name: r'grandTotal', required: false, includeIfNull: false)
  final Object? grandTotal;

  @JsonKey(name: r'finalPricelist', required: false, includeIfNull: false)
  final Object? finalPricelist;

  @JsonKey(name: r'modal', required: false, includeIfNull: false)
  final Object? modal;

  @JsonKey(name: r'warehouse', required: false, includeIfNull: false)
  final Object? warehouse;

  @JsonKey(name: r'isPpn', required: false, includeIfNull: false)
  final Object? isPpn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          other.id == id &&
          other.itemCode == itemCode &&
          other.itemName == itemName &&
          other.kategoriNama == kategoriNama &&
          other.kategoriItemcode == kategoriItemcode &&
          other.finalStok == finalStok &&
          other.hargaHpp == hargaHpp &&
          other.grandTotal == grandTotal &&
          other.finalPricelist == finalPricelist &&
          other.modal == modal &&
          other.warehouse == warehouse &&
          other.isPpn == isPpn;

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) +
      (itemCode?.hashCode ?? 0) +
      (itemName?.hashCode ?? 0) +
      (kategoriNama?.hashCode ?? 0) +
      (kategoriItemcode?.hashCode ?? 0) +
      (finalStok?.hashCode ?? 0) +
      (hargaHpp?.hashCode ?? 0) +
      (grandTotal?.hashCode ?? 0) +
      (finalPricelist?.hashCode ?? 0) +
      (modal?.hashCode ?? 0) +
      (warehouse?.hashCode ?? 0) +
      (isPpn?.hashCode ?? 0);

  factory Stock.fromJson(Map<String, dynamic> json) => _$StockFromJson(json);

  Map<String, dynamic> toJson() => _$StockToJson(this);

  @override
  String toString() => toJson().toString();
}
