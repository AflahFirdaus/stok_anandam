
part of 'purchase_summary_response_purchase.dart';


PurchaseSummaryResponsePurchase _$PurchaseSummaryResponsePurchaseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PurchaseSummaryResponsePurchase',
      json,
      ($checkedConvert) {
        final val = PurchaseSummaryResponsePurchase(
          totalGrandSum: $checkedConvert('totalGrandSum', (v) => v),
          totalQty: $checkedConvert('totalQty', (v) => v),
          content: $checkedConvert('content', (v) => v),
          totalPages: $checkedConvert('totalPages', (v) => v),
          totalElements: $checkedConvert('totalElements', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$PurchaseSummaryResponsePurchaseToJson(
        PurchaseSummaryResponsePurchase instance) =>
    <String, dynamic>{
      if (instance.totalGrandSum case final value?) 'totalGrandSum': value,
      if (instance.totalQty case final value?) 'totalQty': value,
      if (instance.content case final value?) 'content': value,
      if (instance.totalPages case final value?) 'totalPages': value,
      if (instance.totalElements case final value?) 'totalElements': value,
    };
