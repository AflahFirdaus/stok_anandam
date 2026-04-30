// MANUAL MODEL - DO NOT USE BUILD_RUNNER FOR THIS FILE
import 'employee_sales_response.dart';

class DashboardResponse {
  final Object? totalSalesToday;
  final Object? totalPurchasesToday;
  final Object? totalVisitsToday;
  final Object? totalLowStockItems;
  final Object? lowStockPreview;
  final Object? totalTkdnItems;
  final Object? totalHpp;
  final Object? pendingValue;
  final Object? pendingStock;
  final List<EmployeeSalesResponse>? employeeSalesToday;
  final List<EmployeeSalesResponse>? employeeSalesMonth;

  int get debugHeader => 999;

  DashboardResponse({
    this.totalSalesToday,
    this.totalPurchasesToday,
    this.totalVisitsToday,
    this.totalLowStockItems,
    this.lowStockPreview,
    this.totalTkdnItems,
    this.totalHpp,
    this.pendingValue,
    this.pendingStock,
    this.employeeSalesToday,
    this.employeeSalesMonth,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    print('DEBUG DASHBOARD FROMJSON EXECUTION (ID: 999): $json');

    List<EmployeeSalesResponse>? parseEmpList(dynamic raw) {
      if (raw == null) return null;
      if (raw is! List) return null;
      return List<EmployeeSalesResponse>.from(
        raw.map((e) => EmployeeSalesResponse.fromJson(e as Map<String, dynamic>)),
      );
    }

    return DashboardResponse(
      totalSalesToday: json['totalSalesToday'] ?? json['total_sales_today'],
      totalPurchasesToday: json['totalPurchasesToday'] ?? json['total_purchases_today'],
      totalVisitsToday: json['totalVisitsToday'] ?? json['total_visits_today'],
      totalLowStockItems: json['totalLowStockItems'] ?? json['total_low_stock_items'],
      lowStockPreview: json['lowStockPreview'] ?? json['low_stock_preview'],
      totalTkdnItems: json['totalTkdnItems'] ?? json['total_tkdn_items'],
      totalHpp: json['totalHpp'] ?? json['total_hpp'],
      pendingValue: json['pendingValue'] ?? json['pending_value'],
      pendingStock: json['pendingStock'] ?? json['pending_stock'],
      employeeSalesToday: parseEmpList(json['employeeSalesToday'] ?? json['employee_sales_today']),
      employeeSalesMonth: parseEmpList(json['employeeSalesMonth'] ?? json['employee_sales_month']),
    );
  }

  Map<String, dynamic> toJson() {
    final val = <String, dynamic>{};
    void writeNotNull(String key, dynamic value) {
      if (value != null) val[key] = value;
    }
    writeNotNull('totalSalesToday', totalSalesToday);
    writeNotNull('totalPurchasesToday', totalPurchasesToday);
    writeNotNull('totalVisitsToday', totalVisitsToday);
    writeNotNull('totalLowStockItems', totalLowStockItems);
    writeNotNull('lowStockPreview', lowStockPreview);
    writeNotNull('totalTkdnItems', totalTkdnItems);
    writeNotNull('totalHpp', totalHpp);
    writeNotNull('pendingValue', pendingValue);
    writeNotNull('pendingStock', pendingStock);
    writeNotNull('employeeSalesToday',
        employeeSalesToday?.map((e) => e.toJson()).toList());
    writeNotNull('employeeSalesMonth',
        employeeSalesMonth?.map((e) => e.toJson()).toList());
    print('DEBUG DASHBOARD Response TOJSON: $val');
    return val;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardResponse &&
          other.totalSalesToday == totalSalesToday &&
          other.totalPurchasesToday == totalPurchasesToday &&
          other.totalVisitsToday == totalVisitsToday &&
          other.totalLowStockItems == totalLowStockItems &&
          other.lowStockPreview == lowStockPreview &&
          other.totalTkdnItems == totalTkdnItems &&
          other.totalHpp == totalHpp &&
          other.pendingValue == pendingValue &&
          other.pendingStock == pendingStock &&
          other.employeeSalesToday == employeeSalesToday &&
          other.employeeSalesMonth == employeeSalesMonth;

  @override
  int get hashCode =>
      (totalSalesToday?.hashCode ?? 0) +
      (totalPurchasesToday?.hashCode ?? 0) +
      (totalVisitsToday?.hashCode ?? 0) +
      (totalLowStockItems?.hashCode ?? 0) +
      (lowStockPreview?.hashCode ?? 0) +
      (totalTkdnItems?.hashCode ?? 0) +
      (totalHpp?.hashCode ?? 0) +
      (pendingValue?.hashCode ?? 0) +
      (pendingStock?.hashCode ?? 0) +
      (employeeSalesToday?.hashCode ?? 0) +
      (employeeSalesMonth?.hashCode ?? 0);

  @override
  String toString() => toJson().toString();
}
