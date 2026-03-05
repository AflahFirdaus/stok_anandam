// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Purchase',
      json,
      ($checkedConvert) {
        final val = Purchase(
          id: $checkedConvert('id', (v) => v),
          docDate: $checkedConvert('docDate', (v) => v),
          docNoP: $checkedConvert('docNoP', (v) => v),
          parName: $checkedConvert('parName', (v) => v),
          depCode: $checkedConvert('depCode', (v) => v),
          itemCode: $checkedConvert('itemCode', (v) => v),
          itemName: $checkedConvert('itemName', (v) => v),
          qty: $checkedConvert('qty', (v) => v),
          price: $checkedConvert('price', (v) => v),
          grandTotal: $checkedConvert('grandTotal', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
      if (instance.id != null) 'id': instance.id,
      if (instance.docDate != null) 'docDate': instance.docDate,
      if (instance.docNoP != null) 'docNoP': instance.docNoP,
      if (instance.parName != null) 'parName': instance.parName,
      if (instance.depCode != null) 'depCode': instance.depCode,
      if (instance.itemCode != null) 'itemCode': instance.itemCode,
      if (instance.itemName != null) 'itemName': instance.itemName,
      if (instance.qty != null) 'qty': instance.qty,
      if (instance.price != null) 'price': instance.price,
      if (instance.grandTotal != null) 'grandTotal': instance.grandTotal,
    };
