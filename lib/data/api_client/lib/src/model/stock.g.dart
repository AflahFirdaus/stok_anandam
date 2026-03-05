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
          finalPricelist: $checkedConvert('finalPricelist', (v) => v),
          warehouse: $checkedConvert('warehouse', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$StockToJson(Stock instance) => <String, dynamic>{
      if (instance.id != null) 'id': instance.id,
      if (instance.itemCode != null) 'itemCode': instance.itemCode,
      if (instance.itemName != null) 'itemName': instance.itemName,
      if (instance.kategoriNama != null) 'kategoriNama': instance.kategoriNama,
      if (instance.kategoriItemcode != null)
        'kategoriItemcode': instance.kategoriItemcode,
      if (instance.finalStok != null) 'finalStok': instance.finalStok,
      if (instance.hargaHpp != null) 'hargaHpp': instance.hargaHpp,
      if (instance.grandTotal != null) 'grandTotal': instance.grandTotal,
      if (instance.finalPricelist != null)
        'finalPricelist': instance.finalPricelist,
      if (instance.warehouse != null) 'warehouse': instance.warehouse,
    };
