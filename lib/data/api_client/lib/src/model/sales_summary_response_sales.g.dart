// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_summary_response_sales.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesSummaryResponseSales _$SalesSummaryResponseSalesFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'SalesSummaryResponseSales',
      json,
      ($checkedConvert) {
        final val = SalesSummaryResponseSales(
          totalGrandSum: $checkedConvert('totalGrandSum', (v) => v),
          content: $checkedConvert('content', (v) => v),
          totalPages: $checkedConvert('totalPages', (v) => v),
          totalElements: $checkedConvert('totalElements', (v) => v),
        );
        return val;
      },
    );

Map<String, dynamic> _$SalesSummaryResponseSalesToJson(
        SalesSummaryResponseSales instance) =>
    <String, dynamic>{
      if (instance.totalGrandSum != null) 'totalGrandSum': instance.totalGrandSum,
      if (instance.content != null) 'content': instance.content,
      if (instance.totalPages != null) 'totalPages': instance.totalPages,
      if (instance.totalElements != null) 'totalElements': instance.totalElements,
    };
