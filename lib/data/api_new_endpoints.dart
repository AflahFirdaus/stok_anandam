import 'package:dio/dio.dart';
import 'package:stok_anandam/core/network/stock_summary_row.dart';

/// Endpoint baru dari API (lihat docs/API_INTEGRATION.md) yang belum ada di client generated.
/// Memakai Dio yang sama (baseUrl + auth) dari injection.
class ApiNewEndpoints {
  ApiNewEndpoints(this._dio);

  final Dio _dio;

  /// GET /api/v1/auth/me
  /// Returns data user yang login (nama, username, role) untuk header.
  Future<AuthMeResult?> getMe() async {
    final response = await _dio.get<Object>('/api/v1/auth/me');
    final data = response.data;
    if (data == null || data is! Map) return null;
    final inner = data['data'];
    if (inner is! Map) return null;
    return AuthMeResult.fromJson(Map<String, dynamic>.from(inner));
  }

  /// GET /api/v1/sales/employee-codes
  /// Returns daftar kode karyawan untuk dropdown filter.
  Future<List<String>> getEmployeeCodes() async {
    final response = await _dio.get<Object>('/api/v1/sales/employee-codes');
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    return [];
  }

  /// GET /api/v1/canvasing/options?search=&limit=50
  /// Returns options ringan (id, namaInstansi) untuk dropdown.
  Future<List<CanvasingOption>> getCanvasingOptions({
    String? search,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'limit': limit,
    };
    final response = await _dio.get<Object>(
      '/api/v1/canvasing/options',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((e) {
            if (e is Map) return CanvasingOption.fromJson(Map<String, dynamic>.from(e));
            return null;
          })
          .whereType<CanvasingOption>()
          .where((o) => o.id != null || (o.namaInstansi != null && o.namaInstansi!.isNotEmpty))
          .toList();
    }
    return [];
  }

  /// GET /api/v1/tkdn/categories
  /// Returns daftar kategori unik untuk dropdown filter.
  Future<List<String>> getTkdnCategories() async {
    final response = await _dio.get<Object>('/api/v1/tkdn/categories');
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    return [];
  }

  /// GET /api/v1/stock/summary-by-category?groupBy=
  /// Returns ringkasan stok per kategori (flat list).
  Future<List<StockSummaryRow>> getStockSummaryByCategory({
    String groupBy = 'kategori_itemcode',
  }) async {
    final response = await _dio.get<Object>(
      '/api/v1/stock/summary-by-category',
      queryParameters: {'groupBy': groupBy},
    );
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((e) => e is Map ? StockSummaryRow.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<StockSummaryRow>()
          .toList();
    }
    return [];
  }

  /// GET /api/v1/stock/summary-by-category/hierarchy?groupBy=
  /// Returns ringkasan stok 2 level (parent + children).
  Future<List<StockSummaryRow>> getStockSummaryHierarchy({
    String groupBy = 'kategori_itemcode',
  }) async {
    final response = await _dio.get<Object>(
      '/api/v1/stock/summary-by-category/hierarchy',
      queryParameters: {'groupBy': groupBy},
    );
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((e) => e is Map ? StockSummaryRow.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<StockSummaryRow>()
          .toList();
    }
    return [];
  }

  /// GET /api/v1/activity-logs/last-sync
  /// Returns data log terakhir migrasi.
  Future<DateTime?> getLastSync() async {
    try {
      final response = await _dio.get<Object>('/api/v1/activity-logs/last-sync');
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final timestampStr = data['data']['timestamp']?.toString();
        if (timestampStr != null) {
          return DateTime.parse(timestampStr);
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/v1/old-data/meta
  /// Returns max year per category and min year for Data Warehouse labels.
  Future<OldDataMeta> getOldDataMeta() async {
    try {
      final response = await _dio.get<Object>('/api/v1/old-data/meta');
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final d = data['data'] as Map;
        return OldDataMeta(
          minYear: (d['minYear'] as num?)?.toInt() ?? 2016,
          salesMaxYear: (d['salesMaxYear'] as num?)?.toInt(),
          purchaseMaxYear: (d['purchaseMaxYear'] as num?)?.toInt(),
          itemSnMaxYear: (d['itemSnMaxYear'] as num?)?.toInt(),
        );
      }
    } catch (_) {}
    return const OldDataMeta(minYear: 2016);
  }

  /// GET /api/v1/activity-logs
  Future<Map<String, dynamic>> getActivityLogs({
    int page = 0,
    int size = 20,
    String? username,
    String? action,
    String sortBy = 'timestamp',
    String direction = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (username != null && username.isNotEmpty) 'username': username,
      if (action != null && action.isNotEmpty) 'action': action,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/activity-logs',
      queryParameters: queryParams,
    );
    return response.data ?? {};
  }

  /// GET /api/sn/masuk
  Future<Map<String, dynamic>> getSnMasuk({
    int page = 0,
    int size = 20,
    String sortBy = 'tanggal',
    String direction = 'desc',
    String? search,
    String? docId,
    String? user,
    String? itemName,
    String? sn,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (search != null && search.isNotEmpty) 'search': search,
      if (docId != null && docId.isNotEmpty) 'docId': docId,
      if (user != null && user.isNotEmpty) 'user': user,
      if (itemName != null && itemName.isNotEmpty) 'itemName': itemName,
      if (sn != null && sn.isNotEmpty) 'sn': sn,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/sn/masuk',
      queryParameters: queryParams,
    );
    return response.data ?? {};
  }

  /// GET /api/sn/keluar
  Future<Map<String, dynamic>> getSnKeluar({
    int page = 0,
    int size = 20,
    String sortBy = 'tanggal',
    String direction = 'desc',
    String? search,
    String? docId,
    String? user,
    String? itemName,
    String? sn,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (search != null && search.isNotEmpty) 'search': search,
      if (docId != null && docId.isNotEmpty) 'docId': docId,
      if (user != null && user.isNotEmpty) 'user': user,
      if (itemName != null && itemName.isNotEmpty) 'itemName': itemName,
      if (sn != null && sn.isNotEmpty) 'sn': sn,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/sn/keluar',
      queryParameters: queryParams,
    );
    return response.data ?? {};
  }

  /// GET /api/v1/old-data/sales
  Future<Map<String, dynamic>> getOldSales({
    int page = 0,
    int size = 20,
    String sortBy = 'docDate',
    String direction = 'desc',
    String? search,
    String? startDate,
    String? endDate,
    String? empCode,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (search != null && search.isNotEmpty) 'search': search,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      if (empCode != null && empCode.isNotEmpty) 'empCode': empCode,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/old-data/sales',
      queryParameters: queryParams,
    );
    return response.data ?? {};
  }

  /// GET /api/v1/old-data/purchase
  Future<Map<String, dynamic>> getOldPurchase({
    int page = 0,
    int size = 20,
    String sortBy = 'docDate',
    String direction = 'desc',
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (search != null && search.isNotEmpty) 'search': search,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/old-data/purchase',
      queryParameters: queryParams,
    );
    return response.data ?? {};
  }

  /// GET /api/v1/old-data/item-sn
  Future<Map<String, dynamic>> getOldItemSn({
    int page = 0,
    int size = 20,
    String sortBy = 'tanggal',
    String direction = 'desc',
    String? search,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null && type.isNotEmpty) 'type': type,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/old-data/item-sn',
      queryParameters: queryParams,
    );
    return response.data ?? {};
  }

  /// GET /api/v1/old-data/employee-codes
  Future<List<String>> getOldEmployeeCodes() async {
    final response = await _dio.get<Object>('/api/v1/old-data/employee-codes');
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    return [];
  }

  // --- MIGRATION TRIGGERS ---
  Future<void> startStockMigration() async {
    await _dio.post('/api/v1/migration/stock');
  }

  Future<void> startSalesMigration() async {
    await _dio.post('/api/v1/migration/sales');
  }

  Future<void> startPurchaseMigration() async {
    await _dio.post('/api/v1/migration/purchase');
  }

  Future<void> startSnMigration() async {
    await _dio.post('/api/v1/migration/sn');
  }

  Future<void> startCanvasingMigration() async {
    await _dio.post('/api/v1/migration/canvasing');
  }

  Future<void> startTkdnMigration() async {
    await _dio.post('/api/v1/migration/tkdn');
  }

  Future<void> startPricelistMigration() async {
    await _dio.post('/api/v1/migration/pricelist');
  }

  /// GET /api/v1/sales/export
  /// Returns raw bytes of the Excel file.
  Future<List<int>> exportSales({
    String? startDate,
    String? endDate,
    String? empCode,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (empCode != null) 'empCode': empCode,
      if (search != null) 'search': search,
    };
    final response = await _dio.get<List<int>>(
      '/api/v1/sales/export',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }

  /// GET /api/v1/purchases/export
  /// Returns raw bytes of the Excel file.
  Future<List<int>> exportPurchases({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (search != null) 'search': search,
    };
    final response = await _dio.get<List<int>>(
      '/api/v1/purchases/export',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}

/// Model Activity Log
class ActivityLog {
  final int id;
  final String? username;
  final String? action;
  final String? details;
  final String? ipAddress;
  final DateTime? timestamp;

  ActivityLog({
    required this.id,
    this.username,
    this.action,
    this.details,
    this.ipAddress,
    this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString(),
      action: json['action']?.toString(),
      details: json['details']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'].toString()) : null,
    );
  }
}

/// Hasil GET /api/v1/auth/me (nama, username, role).
class AuthMeResult {
  AuthMeResult({this.nama, this.username, this.role});

  final String? nama;
  final String? username;
  final String? role;

  factory AuthMeResult.fromJson(Map<String, dynamic> json) {
    return AuthMeResult(
      nama: json['nama']?.toString().trim(),
      username: json['username']?.toString().trim(),
      role: json['role']?.toString().trim(),
    );
  }

  String get displayName => (nama != null && nama!.isNotEmpty) ? nama! : (username ?? 'User');
}

/// Satu option dari GET /api/v1/canvasing/options (id + namaInstansi).
class CanvasingOption {
  CanvasingOption({this.id, this.namaInstansi});

  final Object? id;
  final String? namaInstansi;

  factory CanvasingOption.fromJson(Map<String, dynamic> json) {
    return CanvasingOption(
      id: json['id'],
      namaInstansi: json['namaInstansi']?.toString(),
    );
  }
}

/// Model Item SN Response
class ItemSerialNumberResponse {
  final DateTime? tanggal;
  final String? docId;
  final String? user;
  final String? itemName;
  final String? sn;

  ItemSerialNumberResponse({
    this.tanggal,
    this.docId,
    this.user,
    this.itemName,
    this.sn,
  });

  factory ItemSerialNumberResponse.fromJson(Map<String, dynamic> json) {
    return ItemSerialNumberResponse(
      tanggal: json['tanggal'] != null ? DateTime.tryParse(json['tanggal'].toString()) : null,
      docId: json['docId']?.toString(),
      user: json['user']?.toString(),
      itemName: json['itemName']?.toString(),
      sn: json['sn']?.toString(),
    );
  }
}

/// Model for date range meta returned by /api/v1/old-data/meta.
class OldDataMeta {
  final int minYear;
  final int? salesMaxYear;
  final int? purchaseMaxYear;
  final int? itemSnMaxYear;

  const OldDataMeta({
    this.minYear = 2016,
    this.salesMaxYear,
    this.purchaseMaxYear,
    this.itemSnMaxYear,
  });

  String get salesRange => '$minYear - ${salesMaxYear ?? '...'}';
  String get purchaseRange => '$minYear - ${purchaseMaxYear ?? '...'}';
  String get itemSnRange => '$minYear - ${itemSnMaxYear ?? '...'}';
}
