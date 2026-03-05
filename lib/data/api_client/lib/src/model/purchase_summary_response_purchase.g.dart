// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_summary_response_purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseSummaryResponsePurchase _$PurchaseSummaryResponsePurchaseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PurchaseSummaryResponsePurchase',
      json,
      ($checkedConvert) {
        final val = PurchaseSummaryResponsePurchase(
          totalGrandSum: $checkedConvert('totalGrandSum', (v) => v),
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
      if (instance.totalGrandSum != null) 'totalGrandSum': instance.totalGrandSum,
      if (instance.content != null) 'content': instance.content,
      if (instance.totalPages != null) 'totalPages': instance.totalPages,
      if (instance.totalElements != null) 'totalElements': instance.totalElements,
    };
