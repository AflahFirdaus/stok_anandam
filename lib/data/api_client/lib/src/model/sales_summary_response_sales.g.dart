part of 'sales_summary_response_sales.dart';


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
      if (instance.totalGrandSum case final value?) 'totalGrandSum': value,
      if (instance.content case final value?) 'content': value,
      if (instance.totalPages case final value?) 'totalPages': value,
      if (instance.totalElements case final value?) 'totalElements': value,
    };
