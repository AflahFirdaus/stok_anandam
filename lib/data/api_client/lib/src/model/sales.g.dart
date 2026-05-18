part of 'sales.dart';


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
          depCode: $checkedConvert('depCode', (v) => v),
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
      if (instance.id case final value?) 'id': value,
      if (instance.docDate case final value?) 'docDate': value,
      if (instance.docNo case final value?) 'docNo': value,
      if (instance.code case final value?) 'code': value,
      if (instance.parName case final value?) 'parName': value,
      if (instance.depCode case final value?) 'depCode': value,
      if (instance.itemName case final value?) 'itemName': value,
      if (instance.qty case final value?) 'qty': value,
      if (instance.price case final value?) 'price': value,
      if (instance.grandTotal case final value?) 'grandTotal': value,
      if (instance.empCode case final value?) 'empCode': value,
    };
