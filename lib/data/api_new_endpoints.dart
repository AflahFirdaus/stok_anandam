import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:stok_anandam/core/network/stock_summary_row.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/data/models/penjadwalan.dart';
import 'package:stok_anandam/data/models/request_delivery.dart';
import 'package:my_api_client/my_api_client.dart';


/// Endpoint baru dari API (lihat docs/API_INTEGRATION.md) yang belum ada di client generated.
/// Memakai Dio yang sama (baseUrl + auth) dari injection.
class ApiNewEndpoints {
  ApiNewEndpoints(this._dio);

  final Dio _dio;
  String get baseUrl => _dio.options.baseUrl;

  /// GET /api/v1/auth/me
  /// Returns data user yang login (nama, username, role) untuk header.
  Future<AuthMeResult?> getMe() async {
    final response = await _dio.get<Object>('/api/v1/auth/me');
    final data = response.data;
    debugPrint('[ApiNewEndpoints] getMe raw response: $data');
    if (data == null || data is! Map) return null;
    final inner = (data as Map)['data'];
    if (inner is! Map) return null;
    return AuthMeResult.fromJson(Map<String, dynamic>.from(inner));
  }

  /// POST /api/v1/auth/change-password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post('/api/v1/auth/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  /// GET /api/v1/sales/employee-codes
  /// Returns daftar kode karyawan untuk dropdown filter.
  Future<List<EmployeeOption>> getEmployeeCodes() async {
    final response = await _dio.get<Object>('/api/v1/sales/employee-codes');
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => EmployeeOption.fromJson(e as Map<String, dynamic>))
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

  // --- MEMO ENDPOINTS ---

  /// POST /api/v1/memos
  Future<String?> createMemo(Map<String, dynamic> request) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/v1/memos', data: request);
    return response.data?['data']?.toString();
  }

  /// PUT /api/v1/memos/{id}
  Future<void> updateMemo(String id, Map<String, dynamic> request) async {
    await _dio.put('/api/v1/memos/$id', data: request);
  }

  /// POST /api/v1/memos/pending
  Future<String?> createPendingMemo(Map<String, dynamic> request) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/v1/memos/pending', data: request);
    return response.data?['data']?.toString();
  }

  /// GET /api/v1/memos
  Future<List<MemoDetail>> getListMemo({String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/memos',
      queryParameters: {if (status != null) 'status': status},
    );
    final list = response.data?['data'] as List?;
    return list?.map((e) => MemoDetail.fromJson(Map<String, dynamic>.from(e))).toList() ?? [];
  }

  /// GET /api/v1/memos/counts
  Future<Map<String, int>> getMemoCounts() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/memos/counts');
    final data = response.data?['data'];
    if (data is Map) {
      return Map<String, int>.from(data.map((key, value) => MapEntry(key.toString(), (value as num).toInt())));
    }
    return {};
  }

  /// GET /api/v1/memos/{id}
  Future<MemoDetail?> getMemoDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/memos/$id');
    final data = response.data?['data'];
    if (data == null) return null;
    return MemoDetail.fromJson(Map<String, dynamic>.from(data));
  }

  /// PUT /api/v1/memos/pending/{id}/approve
  Future<void> approvePending(String id) async {
    await _dio.put('/api/v1/memos/pending/$id/approve');
  }

  /// PUT /api/v1/memos/pending/{id}/reject
  Future<void> rejectPending(String id) async {
    await _dio.put('/api/v1/memos/pending/$id/reject');
  }

  /// PUT /api/v1/memos/pending/{id}/release
  Future<void> releasePending(String id) async {
    await _dio.put('/api/v1/memos/pending/$id/release');
  }

  /// PUT /api/v1/memos/pending/{id}/continue
  Future<void> continuePendingMemo(String id, Map<String, dynamic> request) async {
    await _dio.put(
      '/api/v1/memos/pending/$id/continue',
      data: {'details': request},
    );
  }

  /// PUT /api/v1/memos/pending/{id}/finish-pending
  Future<void> finishPendingMemo(String id) async {
    await _dio.put('/api/v1/memos/pending/$id/finish-pending');
  }

  /// POST /api/v1/memos/{id}/penjadwalan
  Future<String?> createPenjadwalan(String memoId, Map<String, dynamic> request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/memos/$memoId/penjadwalan',
      data: request,
    );
    return response.data?['data']?.toString();
  }

  /// PUT /api/v1/memos/{id}/finalize
  Future<void> finalizeMemo(String id) async {
    await _dio.put('/api/v1/memos/$id/finalize');
  }

  /// GET /api/v1/kodepos?search=
  Future<List<Map<String, dynamic>>> searchKodepos(String search) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kodepos',
      queryParameters: {'search': search},
    );
    final list = response.data?['data'] as List?;
    return list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
  }

  /// PUT /api/v1/memos/items/{itemId}/catatan
  Future<void> updateItemCatatan(int itemId, String catatan) async {
    await _dio.put(
      '/api/v1/memos/items/$itemId/catatan',
      data: {'catatanGudang': catatan},
    );
  }

  /// GET /api/v1/users?role=&size=500
  Future<List<UserAccount>> getUsersByRole(String role) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users',
      queryParameters: {'role': role, 'size': 500},
    );
    final list = response.data?['data'] as List?;
    return list?.map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [];
  }

  Future<List<UserAccount>> getAllUsers() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users',
      queryParameters: {'size': 500},
    );
    final list = response.data?['data'] as List?;
    return list?.map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [];
  }

  /// PUT /api/v1/memos/{id}/gudang-finish (Sekarang tanpa request body)
  Future<void> finishWarehouseProcess(String id) async {
    await _dio.put('/api/v1/memos/$id/gudang-finish');
  }

  /// PUT /api/v1/memos/{id}/invoice-finish (Input JL)
  Future<void> finishInvoicingProcess(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/v1/memos/$id/invoice-finish', data: data);
  }

  /// PUT /api/v1/memos/{id}/delivery-route
  Future<void> confirmDeliveryRoute(String id, Map<String, dynamic> request) async {
    await _dio.put(
      '/api/v1/memos/$id/delivery-route',
      data: request,
    );
  }

  /// PUT /api/v1/memos/{id}/pickup-route
  Future<void> confirmPickupRoute(String id, {required String filePath, required String fileName}) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _dio.put('/api/v1/memos/$id/pickup-route', data: formData);
  }

  /// PUT /api/v1/memos/{id}/pickup-final
  Future<void> confirmPickupFinal(String id) async {
    await _dio.put('/api/v1/memos/$id/pickup-final');
  }

  /// PUT /api/v1/memos/{id}/report-issue
  Future<void> reportPhysicalIssue(String id, String catatan) async {
    await _dio.put(
      '/api/v1/memos/$id/report-issue',
      data: {
        'targetStatus': 'KENDALA_BARANG',
        'keteranganLog': catatan,
      },
    );
  }

  /// PUT /api/v1/memos/{id}/force-complete
  Future<void> forceComplete(String id, String alasan) async {
    await _dio.put(
      '/api/v1/memos/$id/force-complete',
      data: {
        'targetStatus': 'SELESAI',
        'keteranganLog': alasan,
      },
    );
  }

  /// PUT /api/v1/memos/{id}/technician-finish
  Future<void> finishTechnicianProcess(String id) async {
    await _dio.put('/api/v1/memos/$id/technician-finish');
  }

  /// PUT /api/v1/memos/{id}/delivery-finish
  Future<void> finishDeliveryProcess(String id, {required String filePath, required String fileName, String? catatan}) async {
    debugPrint('[ApiNewEndpoints] finishDeliveryProcess - id: $id, path: $filePath, name: $fileName');
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('[ApiNewEndpoints] ERROR: File does not exist at $filePath');
      throw Exception('File tidak ditemukan di sistem: $filePath');
    }
    final size = await file.length();
    debugPrint('[ApiNewEndpoints] File size: ${size / 1024} KB');

    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      if (catatan != null) 'catatan': catatan,
    });
    try {
      await _dio.put('/api/v1/memos/$id/delivery-finish', data: formData);
      debugPrint('[ApiNewEndpoints] finishDeliveryProcess success');
    } catch (e) {
      debugPrint('[ApiNewEndpoints] finishDeliveryProcess ERROR: $e');
      if (e is DioException) {
        debugPrint('[ApiNewEndpoints] Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// PUT /api/v1/memos/{id}/status

  Future<void> updateStatus(String id, String targetStatus, String keterangan) async {
    await _dio.put(
      '/api/v1/memos/$id/status',
      data: {
        'targetStatus': targetStatus,
        'keteranganLog': keterangan,
      },
    );
  }

  /// PUT /api/v1/memos/{id}/resi
  Future<void> updateResi(String id, String resi) async {
    await _dio.put(
      '/api/v1/memos/$id/resi',
      data: {'resi': resi},
    );
  }

  /// PUT /api/v1/memos/{id}/complete
  Future<void> completeMemo(String id) async {
    await _dio.put('/api/v1/memos/$id/complete');
  }

  /// GET /api/v1/customers/options?search=
  Future<List<CustomerOption>> searchCustomers(String search) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/customers/options',
      queryParameters: {'search': search},
    );
    final list = response.data?['data'] as List?;
    return list?.map((e) => CustomerOption.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [];
  }

  /// POST /api/v1/memos/{id}/konfirmasi-kirim
  Future<void> konfirmasiKirim(String memoId, List<Map<String, dynamic>> items, {required XFile photo}) async {
    final formData = FormData.fromMap({
      'itemsJson': jsonEncode({'items': items}),
      'photo': await MultipartFile.fromFile(photo.path, filename: photo.name),
    });
    
    await _dio.post(
      '/api/v1/memos/$memoId/konfirmasi-kirim',
      data: formData,
    );
  }

  /// GET /api/v1/penjadwalan
  /// Returns list tugas (Memo-based or Manual) based on tipe & status.
  Future<List<PenjadwalanResponse>> getListTugas({
    String tipe = 'SEMUA',
    String status = 'SEMUA',
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (tipe != 'SEMUA') queryParams['tipe'] = tipe;
    if (status != 'SEMUA') queryParams['status'] = status;

    final response = await _dio.get<Object>(
      '/api/v1/penjadwalan',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null) return [];
    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((e) => e is Map ? PenjadwalanResponse.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<PenjadwalanResponse>()
          .toList();
    }
    return [];
  }

  /// GET /api/v1/penjadwalan/{id}
  Future<PenjadwalanResponse?> getTugasDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/penjadwalan/$id');
    final data = response.data?['data'];
    if (data == null) return null;
    return PenjadwalanResponse.fromJson(Map<String, dynamic>.from(data));
  }

  /// PUT /api/v1/penjadwalan/{id}
  Future<void> updateManualTask(String id, Map<String, dynamic> request) async {
    await _dio.put(
      '/api/v1/penjadwalan/$id',
      data: request,
    );
  }

  /// PUT /api/v1/penjadwalan/{id}/selesai
  Future<void> startManualTask(String id) async {
    await _dio.put('/api/v1/penjadwalan/$id/mulai');
  }

  Future<void> finishManualTask(String id, {
    required String filePath, 
    required String fileName, 
    required String namaPenerima, 
    String? catatanOperasional
  }) async {
    debugPrint('[ApiNewEndpoints] finishManualTask - id: $id, path: $filePath');
    final file = File(filePath);
    if (!await file.exists()) {
       debugPrint('[ApiNewEndpoints] ERROR: File does not exist at $filePath');
       throw Exception('File tidak ditemukan di sistem: $filePath');
    }

    final formData = FormData.fromMap({
      'nama_penerima': namaPenerima,
      'catatan_operasional': catatanOperasional ?? '',
      'photo': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    try {
      await _dio.put('/api/v1/penjadwalan/$id/selesai', data: formData);
      debugPrint('[ApiNewEndpoints] finishManualTask success');
    } catch (e) {
      debugPrint('[ApiNewEndpoints] finishManualTask ERROR: $e');
      rethrow;
    }
  }

  // --- REQUEST DELIVERY ENDPOINTS ---
  
  Future<List<RequestDelivery>> getListRequestDelivery({String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/request-delivery',
      queryParameters: {if (status != null) 'status': status},
    );
    final list = response.data?['data'] as List?;
    return list?.map((e) => RequestDelivery.fromJson(Map<String, dynamic>.from(e))).toList() ?? [];
  }

  Future<void> createBulkPenjadwalan({
    List<String>? memoIds,
    List<int>? requestDeliveryIds,
    required int personelId,
    required DateTime tanggalRencana,
  }) async {
    await _dio.post(
      '/api/v1/penjadwalan/bulk',
      data: {
        if (memoIds != null) 'memoIds': memoIds,
        if (requestDeliveryIds != null) 'requestDeliveryIds': requestDeliveryIds,
        'personelId': personelId,
        'tanggalRencana': tanggalRencana.toIso8601String(),
      },
    );
  }

  Future<void> createRequestDelivery(Map<String, dynamic> request) async {
    await _dio.post('/api/v1/request-delivery', data: request);
  }

  Future<RequestDelivery?> getRequestDeliveryDetail(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/request-delivery/$id');
    final data = response.data?['data'];
    if (data == null) return null;
    return RequestDelivery.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> createBatchDropOff({
    List<String>? memoIds,
    List<int>? requestDeliveryIds,
    required int personelId,
    required DateTime tanggalRencana,
    required String expeditionName,
  }) async {
    await _dio.post(
      '/api/v1/penjadwalan/batch-drop-off',
      data: {
        if (memoIds != null) 'memoIds': memoIds,
        if (requestDeliveryIds != null) 'requestDeliveryIds': requestDeliveryIds,
        'personelId': personelId,
        'tanggalRencana': tanggalRencana.toIso8601String(),
        'expeditionName': expeditionName,
      },
    );
  }

  /// PUT /api/v1/penjadwalan/bulk/mulai
  Future<void> bulkMulaiTugas(List<int> ids) async {
    await _dio.put('/api/v1/penjadwalan/bulk/mulai', data: ids);
  }

  /// PUT /api/v1/penjadwalan/bulk/selesai
  Future<void> bulkSelesaikanTugas(
    List<int> ids, {
    required String filePath,
    required String fileName,
    required String namaPenerima,
    String? catatanOperasional,
  }) async {
    debugPrint('[ApiNewEndpoints] bulkSelesaikanTugas - ids: $ids, path: $filePath');
    final formData = FormData.fromMap({
      'ids': ids,
      'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      'nama_penerima': namaPenerima,
      if (catatanOperasional != null) 'catatan_operasional': catatanOperasional,
    });
    try {
      await _dio.put('/api/v1/penjadwalan/bulk/selesai', data: formData);
      debugPrint('[ApiNewEndpoints] bulkSelesaikanTugas success');
    } catch (e) {
       debugPrint('[ApiNewEndpoints] bulkSelesaikanTugas ERROR: $e');
       rethrow;
    }
  }

  /// GET /api/v1/stock & /api/v1/tkdn (Combined Search for Suggestions)
  Future<List<ItemSuggestion>> searchItemSuggestions(String search) async {
    final List<ItemSuggestion> results = [];
    final searchLower = search.toLowerCase().trim();

    // 1. Search in Stock
    try {
      final stockRes = await _dio.get<Map<String, dynamic>>(
        '/api/v1/stock',
        queryParameters: {'search': searchLower, 'size': 15},
      );
      final stockData = stockRes.data?['data'];
      if (stockData is List) {
        for (var item in stockData) {
          final itemName = item['itemName']?.toString() ?? '';
          if (itemName.isNotEmpty) {
            results.add(ItemSuggestion(
              itemName: itemName,
              itemCode: item['itemCode']?.toString(),
              // Mengambil harga dari final_pricelist (tabel pricelist)
              price: num.tryParse(item['final_pricelist']?.toString() ??
                  item['finalPricelist']?.toString() ??
                  ''),
              source: 'STOK',
            ));
          }
        }
      } else if (stockData is Map && stockData['content'] is List) {
        for (var item in stockData['content']) {
          final itemName = item['itemName']?.toString() ?? '';
          if (itemName.isNotEmpty) {
            results.add(ItemSuggestion(
              itemName: itemName,
              itemCode: item['itemCode']?.toString(),
              price: num.tryParse(item['final_pricelist']?.toString() ??
                  item['finalPricelist']?.toString() ??
                  ''),
              source: 'STOK',
            ));
          }
        }
      }
    } catch (_) {}

    // 2. Search in TKDN
    try {
      final tkdnRes = await _dio.get<Map<String, dynamic>>(
        '/api/v1/tkdn',
        queryParameters: {'search': searchLower, 'size': 15, 'isTkdn': true},
      );
      final tkdnData = tkdnRes.data?['data'];
      if (tkdnData is List) {
        for (var item in tkdnData) {
          final itemName = item['nama']?.toString() ?? item['namaBarang']?.toString() ?? '';
          if (itemName.isNotEmpty) {
            results.add(ItemSuggestion(
              itemName: itemName,
              itemCode: item['itemCode']?.toString(),
              price: null, // TKDN tidak perlu harga
              source: 'TKDN',
            ));
          }
        }
      } else if (tkdnData is Map && tkdnData['content'] is List) {
        for (var item in tkdnData['content']) {
          final itemName = item['nama']?.toString() ?? item['namaBarang']?.toString() ?? '';
          if (itemName.isNotEmpty) {
            results.add(ItemSuggestion(
              itemName: itemName,
              itemCode: item['itemCode']?.toString(),
              price: null, // TKDN tidak perlu harga
              source: 'TKDN',
            ));
          }
        }
      }
    } catch (_) {}

    // Remove duplicates by name (case-insensitive) and prioritize STOK
    final seen = <String>{};
    final uniqueResults = <ItemSuggestion>[];
    
    // Process STOK first
    for (var res in results.where((r) => r.source == 'STOK')) {
      if (seen.add(res.itemName.toLowerCase())) {
        uniqueResults.add(res);
      }
    }
    // Then TKDN
    for (var res in results.where((r) => r.source == 'TKDN')) {
      if (seen.add(res.itemName.toLowerCase())) {
        uniqueResults.add(res);
      }
    }

    return uniqueResults;
  }
}

class ItemSuggestion {
  final String itemName;
  final String? itemCode;
  final num? price;
  final String source;

  ItemSuggestion({
    required this.itemName,
    this.itemCode,
    this.price,
    required this.source,
  });
}

/// Model Customer Option (id + namaPelanggan + noHp)
class CustomerOption {
  final int? id;
  final String? namaPelanggan;
  final String? noHp;

  CustomerOption({this.id, this.namaPelanggan, this.noHp});

  factory CustomerOption.fromJson(Map<String, dynamic> json) {
    return CustomerOption(
      id: int.tryParse(json['id']?.toString() ?? ''),
      namaPelanggan: json['namaPelanggan']?.toString(),
      noHp: json['noHp']?.toString(),
    );
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
  AuthMeResult({this.nama, this.username, this.role, this.employeeCode});

  final String? nama;
  final String? username;
  final String? role;
  final String? employeeCode;

  factory AuthMeResult.fromJson(Map<String, dynamic> json) {
    debugPrint('[ApiNewEndpoints] AuthMeResult.fromJson: $json');
    return AuthMeResult(
      nama: json['nama']?.toString().trim(),
      username: json['username']?.toString().trim(),
      role: json['role']?.toString().trim(),
      employeeCode: json['employeeCode']?.toString().trim(),
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

/// Model User (from GET /api/v1/users)
class UserAccount {
  final int id;
  final String nama;
  final String username;
  final String role;
  final String? employeeCode;

  UserAccount({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    this.employeeCode,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nama: json['nama']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString().trim(),
    );
  }
}
