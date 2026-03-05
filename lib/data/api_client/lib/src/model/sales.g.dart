// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sales _$SalesFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Sales',
      json,
      ($checkedConvert) {
        final val = Sales(
          id: $checkedConvert('id', (v) => v),
          docDate: $checkedConvert('docDate', (v) => v),
          docNo: $checkedConvert('docNo', (v) => v),
          code: $checkedConvert('code', (v) => v),
          parName: $checkedConvert('parName', (v) => v),
          itemName: $checkedConvert('itemName', (v) => v),
          qty: $checkedConvert('qty', (v) => v),
          price: $checkedConvert('price', (v) => v),
          grandTotal: $checkedConvert('grandTotal', (v) => v),
          empCode: $checkedConvert('empCode', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$SalesToJson(Sales instance) => <String, dynamic>{
      if (instance.id != null) 'id': instance.id,
      if (instance.docDate != null) 'docDate': instance.docDate,
      if (instance.docNo != null) 'docNo': instance.docNo,
      if (instance.code != null) 'code': instance.code,
      if (instance.parName != null) 'parName': instance.parName,
      if (instance.itemName != null) 'itemName': instance.itemName,
      if (instance.qty != null) 'qty': instance.qty,
      if (instance.price != null) 'price': instance.price,
      if (instance.grandTotal != null) 'grandTotal': instance.grandTotal,
      if (instance.empCode != null) 'empCode': instance.empCode,
    };
