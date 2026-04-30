import 'package:my_api_client/src/model/dashboard_response.dart';
import 'package:my_api_client/src/model/employee_sales_response.dart';

class DashboardLocalData {
  final double totalSalesToday;
  final double totalPurchasesToday;
  final int totalVisitsToday;
  final int totalLowStockItems;
  final dynamic lowStockPreview;
  final int totalTkdnItems;
  final double totalHpp;
  final double pendingValue;
  final int pendingStock;
  final int debugHeader;
  final List<EmployeeSalesLocalData> employeeSalesToday;
  final List<EmployeeSalesLocalData> employeeSalesMonth;

  DashboardLocalData({
    required this.totalSalesToday,
    required this.totalPurchasesToday,
    required this.totalVisitsToday,
    required this.totalLowStockItems,
    this.lowStockPreview,
    required this.totalTkdnItems,
    required this.totalHpp,
    required this.pendingValue,
    required this.pendingStock,
    required this.debugHeader,
    required this.employeeSalesToday,
    required this.employeeSalesMonth,
  });

  factory DashboardLocalData.fromDynamic(dynamic d) {
    print('DEBUG DASHBOARD UI RAW: $d');
    if (d == null) return DashboardLocalData(
      totalSalesToday: 0, totalPurchasesToday: 0, totalVisitsToday: 0,
      totalLowStockItems: 0, totalTkdnItems: 0, totalHpp: 0,
      pendingValue: 0, pendingStock: 0,
      debugHeader: 0,
      employeeSalesToday: [],
      employeeSalesMonth: [],
    );

    // Utility to safely convert dynamic to double
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }

    // Utility to safely convert dynamic to int
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    }

    final empSalesToday = <EmployeeSalesLocalData>[];
    try {
      final rawList = d['employeeSalesToday'];
      if (rawList is List) {
        for (final item in rawList) {
          empSalesToday.add(EmployeeSalesLocalData.fromDynamic(item));
        }
      }
    } catch (_) {}

    final empSalesMonth = <EmployeeSalesLocalData>[];
    try {
      final rawList = d['employeeSalesMonth'];
      if (rawList is List) {
        for (final item in rawList) {
          empSalesMonth.add(EmployeeSalesLocalData.fromDynamic(item));
        }
      }
    } catch (_) {}

    return DashboardLocalData(
      totalSalesToday: toDouble(d['totalSalesToday']),
      totalPurchasesToday: toDouble(d['totalPurchasesToday']),
      totalVisitsToday: toInt(d['totalVisitsToday']),
      totalLowStockItems: toInt(d['totalLowStockItems']),
      lowStockPreview: d['lowStockPreview'],
      totalTkdnItems: toInt(d['totalTkdnItems']),
      totalHpp: toDouble(d['totalHpp']),
      pendingValue: toDouble(d['pendingValue']),
      pendingStock: toInt(d['pendingStock']),
      debugHeader: toInt(d['debugHeader']),
      employeeSalesToday: empSalesToday,
      employeeSalesMonth: empSalesMonth,
    );
  }

  /// Direct factory from typed DashboardResponse — no toJson() round-trip.
  factory DashboardLocalData.fromResponse(DashboardResponse r) {
    double toDouble(Object? v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }

    int toInt(Object? v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    }

    EmployeeSalesLocalData mapEmp(EmployeeSalesResponse e) {
      return EmployeeSalesLocalData(
        empName: e.empName ?? 'Unknown',
        empCode: e.empCode ?? '-',
        totalSales: toDouble(e.totalSales),
      );
    }

    return DashboardLocalData(
      totalSalesToday: toDouble(r.totalSalesToday),
      totalPurchasesToday: toDouble(r.totalPurchasesToday),
      totalVisitsToday: toInt(r.totalVisitsToday),
      totalLowStockItems: toInt(r.totalLowStockItems),
      lowStockPreview: r.lowStockPreview,
      totalTkdnItems: toInt(r.totalTkdnItems),
      totalHpp: toDouble(r.totalHpp),
      pendingValue: toDouble(r.pendingValue),
      pendingStock: toInt(r.pendingStock),
      debugHeader: r.debugHeader,
      employeeSalesToday: r.employeeSalesToday?.map(mapEmp).toList() ?? [],
      employeeSalesMonth: r.employeeSalesMonth?.map(mapEmp).toList() ?? [],
    );
  }
}

class EmployeeSalesLocalData {
  final String empName;
  final String empCode;
  final double totalSales;

  EmployeeSalesLocalData({
    required this.empName,
    required this.empCode,
    required this.totalSales,
  });

  factory EmployeeSalesLocalData.fromDynamic(dynamic d) {
    if (d == null) return EmployeeSalesLocalData(empName: '', empCode: '', totalSales: 0);

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
    }

    return EmployeeSalesLocalData(
      empName: d['empName']?.toString() ?? 'Unknown',
      empCode: d['empCode']?.toString() ?? '-',
      totalSales: toDouble(d['totalSales']),
    );
  }
}
