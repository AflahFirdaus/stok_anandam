// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stock _$StockFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Stock',
      json,
      ($checkedConvert) {
        final val = Stock(
          id: $checkedConvert('id', (v) => v),
          itemCode: $checkedConvert('itemCode', (v) => v),
          itemName: $checkedConvert('itemName', (v) => v),
          kategoriNama: $checkedConvert('kategoriNama', (v) => v),
          kategoriItemcode: $checkedConvert('kategoriItemcode', (v) => v),
          finalStok: $checkedConvert('finalStok', (v) => v),
          hargaHpp: $checkedConvert('hargaHpp', (v) => v),
          grandTotal: $checkedConvert('grandTotal', (v) => v),
          modal: $checkedConvert('modal', (v) => v),
          warehouse: $checkedConvert('warehouse', (v) => v),
          finalPricelist: $checkedConvert('finalPricelist', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$StockToJson(Stock instance) => <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.itemCode case final value?) 'itemCode': value,
      if (instance.itemName case final value?) 'itemName': value,
      if (instance.kategoriNama case final value?) 'kategoriNama': value,
      if (instance.kategoriItemcode case final value?)
        'kategoriItemcode': value,
      if (instance.finalStok case final value?) 'finalStok': value,
      if (instance.hargaHpp case final value?) 'hargaHpp': value,
      if (instance.grandTotal case final value?) 'grandTotal': value,
      if (instance.finalPricelist case final value?) 'finalPricelist': value,
      if (instance.modal case final value?) 'modal': value,
      if (instance.warehouse case final value?) 'warehouse': value,
    };
