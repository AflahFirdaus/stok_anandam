part of 'purchase.dart';

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
          empCode: $checkedConvert('empCode', (v) => v),
          empName: $checkedConvert('empName', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.docDate case final value?) 'docDate': value,
      if (instance.docNoP case final value?) 'docNoP': value,
      if (instance.parName case final value?) 'parName': value,
      if (instance.depCode case final value?) 'depCode': value,
      if (instance.itemCode case final value?) 'itemCode': value,
      if (instance.itemName case final value?) 'itemName': value,
      if (instance.qty case final value?) 'qty': value,
      if (instance.price case final value?) 'price': value,
      if (instance.grandTotal case final value?) 'grandTotal': value,
      if (instance.empCode case final value?) 'empCode': value,
      if (instance.empName case final value?) 'empName': value,
    };