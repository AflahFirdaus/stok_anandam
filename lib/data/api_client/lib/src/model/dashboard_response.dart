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
  final List<EmployeeSalesResponse>? employeeSalesToday;

  int get debugHeader => 999;

  DashboardResponse({
    this.totalSalesToday,
    this.totalPurchasesToday,
    this.totalVisitsToday,
    this.totalLowStockItems,
    this.lowStockPreview,
    this.totalTkdnItems,
    this.totalHpp,
    this.employeeSalesToday,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      totalSalesToday: json['totalSalesToday'],
      totalPurchasesToday: json['totalPurchasesToday'],
      totalVisitsToday: json['totalVisitsToday'],
      totalLowStockItems: json['totalLowStockItems'],
      lowStockPreview: json['lowStockPreview'],
      totalTkdnItems: json['totalTkdnItems'],
      totalHpp: json['totalHpp'],
      employeeSalesToday: (json['employeeSalesToday'] as List<dynamic>?)
          ?.map((e) => EmployeeSalesResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
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
    writeNotNull('employeeSalesToday',
        employeeSalesToday?.map((e) => e.toJson()).toList());
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
          other.employeeSalesToday == employeeSalesToday;

  @override
  int get hashCode =>
      (totalSalesToday?.hashCode ?? 0) +
      (totalPurchasesToday?.hashCode ?? 0) +
      (totalVisitsToday?.hashCode ?? 0) +
      (totalLowStockItems?.hashCode ?? 0) +
      (lowStockPreview?.hashCode ?? 0) +
      (totalTkdnItems?.hashCode ?? 0) +
      (totalHpp?.hashCode ?? 0) +
      (employeeSalesToday?.hashCode ?? 0);

  @override
  String toString() => toJson().toString();
}
