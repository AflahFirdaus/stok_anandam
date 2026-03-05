class DashboardLocalData {
  final double totalSalesToday;
  final double totalPurchasesToday;
  final int totalVisitsToday;
  final int totalLowStockItems;
  final dynamic lowStockPreview;
  final int totalTkdnItems;
  final double totalHpp;
  final int debugHeader;
  final List<EmployeeSalesLocalData> employeeSalesToday;

  DashboardLocalData({
    required this.totalSalesToday,
    required this.totalPurchasesToday,
    required this.totalVisitsToday,
    required this.totalLowStockItems,
    this.lowStockPreview,
    required this.totalTkdnItems,
    required this.totalHpp,
    required this.debugHeader,
    required this.employeeSalesToday,
  });

  factory DashboardLocalData.fromDynamic(dynamic d) {
    if (d == null) return DashboardLocalData(
      totalSalesToday: 0, totalPurchasesToday: 0, totalVisitsToday: 0,
      totalLowStockItems: 0, totalTkdnItems: 0, totalHpp: 0,
      debugHeader: 0,
      employeeSalesToday: [],
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

    final empSales = <EmployeeSalesLocalData>[];
    try {
      final rawList = d['employeeSalesToday'];
      if (rawList is List) {
        for (final item in rawList) {
          empSales.add(EmployeeSalesLocalData.fromDynamic(item));
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
      debugHeader: toInt(d['debugHeader']),
      employeeSalesToday: empSales,
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
