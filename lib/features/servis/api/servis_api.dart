import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ServisApi {
  final Dio _dio;

  ServisApi(this._dio);

  // --- Pelanggan Servis ---
  Future<Map<String, dynamic>> getPelangganServis({
    int page = 0,
    int size = 20,
    String? search,
  }) async {
    try {
      final response =
          await _dio.get('/api/v1/pelanggan-servis', queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final responseBody = response.data;
      if (responseBody is Map) {
        final mapBody = Map<String, dynamic>.from(responseBody);
        // Helper untuk akses paging yang typenya Map<dynamic, dynamic>
        Map<String, dynamic> pagingStr(Map p) {
          return p.map((k, v) => MapEntry(k.toString(), v));
        }

        // Pattern A: { status, data: {...pageable...}, paging: { totalPage, totalItem } }
        // Data berisi Page object dari Spring Boot (content, totalElements, etc.)
        final paging = mapBody['paging'];
        final dataField = mapBody['data'];

        // Cek pola dengan status + data (Map) + paging — seperti format stock yang sudah diubah
        if (mapBody.containsKey('status') && dataField is Map) {
          final innerData = Map<String, dynamic>.from(dataField);
          debugPrint(
              '[getPelangganServis] Pattern A (status/data(Page)/paging), inner keys: ${innerData.keys}');
          // Override totalElements/totalPages dari paging jika ada
          if (paging is Map) {
            final pMap = pagingStr(paging);
            final te = _intVal(pMap,
                ['totalItem', 'totalElements', 'total_item', 'total_elements']);
            if (te != null) innerData['totalElements'] = te;
            final tp = _intVal(
                pMap, ['totalPage', 'totalPages', 'total_page', 'total_pages']);
            if (tp != null) innerData['totalPages'] = tp;
          }
          return innerData;
        }

        // Pattern B: { status, data: [...items], paging: { totalPage, totalItem } }
        if (paging is Map &&
            mapBody.containsKey('status') &&
            dataField is List) {
          final items = dataField;
          final pMap = pagingStr(paging);
          final tp = _intVal(pMap,
                  ['totalPage', 'totalPages', 'total_page', 'total_pages']) ??
              1;
          final te = _intVal(pMap, [
                'totalItem',
                'totalElements',
                'total_item',
                'total_elements'
              ]) ??
              items.length;
          debugPrint(
              '[getPelangganServis] Pattern B (status/data(list)/paging): totalElements=$te totalPages=$tp items=${items.length}');
          return {
            'content': items,
            'totalElements': te,
            'totalPages': tp,
            'number': 0,
            'size': items.length,
            'last': items.isEmpty || tp <= 1,
            'first': true,
          };
        }

        // Pattern C: Response langsung berisi pageable ({ content, totalElements, totalPages, ... })
        if (mapBody.containsKey('content') ||
            mapBody.containsKey('totalElements')) {
          // Jika ada paging di root, tambahkan
          if (paging is Map) {
            final pMap = pagingStr(paging);
            mapBody['totalElements'] = _intVal(pMap, [
                  'totalItem',
                  'totalElements',
                  'total_item',
                  'total_elements'
                ]) ??
                mapBody['totalElements'];
            mapBody['totalPages'] = _intVal(pMap,
                    ['totalPage', 'totalPages', 'total_page', 'total_pages']) ??
                mapBody['totalPages'];
          }
          debugPrint(
              '[getPelangganServis] Pattern C (direct pageable), keys: ${mapBody.keys}');
          return mapBody;
        }

        debugPrint(
            '[getPelangganServis] Unknown pattern, keys: ${mapBody.keys}');
        return mapBody;
      }
      // Fallback: wrap raw list as paginated
      if (responseBody is List) {
        debugPrint(
            '[getPelangganServis] Response is List (${responseBody.length} items), wrapping as paginated');
        return {
          'content': responseBody,
          'totalElements': responseBody.length,
          'totalPages': 1,
          'number': 0,
          'size': responseBody.length,
          'first': true,
          'last': true,
        };
      }
      debugPrint(
          '[getPelangganServis] Unexpected response type: ${responseBody.runtimeType}');
      return _emptyPage();
    } catch (e) {
      debugPrint('ERROR getPelangganServis: $e');
      return _emptyPage();
    }
  }

  Future<Map<String, dynamic>> getPelangganServisById(String id) async {
    final response = await _dio.get('/api/v1/pelanggan-servis/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createPelangganServis(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/pelanggan-servis', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updatePelangganServis(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/pelanggan-servis/$id', data: data);
    return response.data;
  }

  Future<void> deletePelangganServis(String id) async {
    await _dio.delete('/api/v1/pelanggan-servis/$id');
  }

  // --- Transaksi Servis ---
  /// Fetch transaksi berdasarkan status dengan pagination & search.
  /// Mengembalikan Map paginasi dari backend: { content, totalElements, totalPages, ... }
  Future<Map<String, dynamic>> getTransaksiServisByStatus({
    required String status,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/transaksi-servis/filter-by-status',
        queryParameters: {
          'status': status,
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final responseBody = response.data;
      if (responseBody is Map) {
        return Map<String, dynamic>.from(responseBody);
      }
      // Fallback: wrap raw list as paginated
      if (responseBody is List) {
        return {
          'content': responseBody,
          'totalElements': responseBody.length,
          'totalPages': 1,
          'number': 0,
          'size': responseBody.length,
          'first': true,
          'last': true,
        };
      }
      return _emptyPage();
    } catch (e) {
      debugPrint('ERROR getTransaksiServisByStatus($status): $e');
      return _emptyPage();
    }
  }

  /// Helper to try multiple possible keys for integer values
  int? _intVal(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final val = json[key];
      if (val != null) {
        if (val is int) return val;
        if (val is double) return val.toInt();
        if (val is String) {
          final parsed = int.tryParse(val);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _emptyPage() {
    return {
      'content': <dynamic>[],
      'totalElements': 0,
      'totalPages': 0,
      'number': 0,
      'size': 20,
      'first': true,
      'last': true,
    };
  }

  Future<Map<String, dynamic>> createTransaksiServis(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/transaksi-servis', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateStatusTransaksi(
      String id, Map<String, dynamic> data) async {
    final response =
        await _dio.put('/api/v1/transaksi-servis/$id/status', data: data);
    return response.data;
  }

  // --- Klaim Distributor ---
  Future<Map<String, dynamic>> createKlaimDistributor(
      String transaksiId, Map<String, dynamic> data) async {
    final response = await _dio.post(
        '/api/v1/transaksi-servis/$transaksiId/klaim-distributor',
        data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateStatusKlaim(
      String klaimId, Map<String, dynamic> data) async {
    final response = await _dio.put(
        '/api/v1/transaksi-servis/klaim-distributor/$klaimId/status',
        data: data);
    return response.data;
  }

  Future<Map<String, dynamic>?> getKlaimByTransaksiId(
      String transaksiId) async {
    try {
      final response = await _dio.get(
        '/api/v1/klaim-distributor/by-transaksi/$transaksiId',
        options: Options(
          // Jangan throw untuk 404 - itu berarti tidak ada klaim
          validateStatus: (status) =>
              status == null ||
              (status >= 200 && status < 300) ||
              status == 404,
        ),
      );
      // Jika 404, return null (tidak ada klaim)
      if (response.statusCode == 404) return null;
      if (response.data == null) return null;
      // Handle both single object and list responses
      if (response.data is List) {
        final list = response.data as List;
        if (list.isEmpty) return null;
        return Map<String, dynamic>.from(list.first as Map);
      }
      if (response.data is! Map) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      debugPrint('[getKlaimByTransaksiId] Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getTransaksiById(String id) async {
    final response = await _dio.get('/api/v1/transaksi-servis/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Download PDF Nota Pengantar Klaim (bytes) untuk dicetak / disimpan.
  Future<Uint8List> downloadNotaPengantarKlaim(String transaksiId) async {
    try {
      final response = await _dio.get(
        '/api/v1/nota/klaim-pengantar/$transaksiId',
        options: Options(
          responseType: ResponseType.bytes,
          // Jangan throw untuk error - kita tangani sendiri
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200) {
        return response.data is List<int>
            ? Uint8List.fromList(response.data as List<int>)
            : Uint8List.fromList(List<int>.from(response.data as List));
      }
      // Coba parse error dari server
      String errorMsg = 'Gagal mengunduh PDF';
      try {
        if (response.data is List<int>) {
          final bodyStr = String.fromCharCodes(response.data as List<int>);
          final json = Map<String, dynamic>.from(jsonDecode(bodyStr) as Map);
          if (json['message'] != null) {
            errorMsg = json['message'].toString();
          }
        }
      } catch (_) {}
      throw Exception(errorMsg);
    } on DioException catch (e) {
      // Coba parse response body dari DioException jika ada
      String errorMsg = 'Gagal mencetak: Server error (500)';
      try {
        if (e.response?.data is List<int>) {
          final bodyStr = String.fromCharCodes(e.response?.data as List<int>);
          final json = Map<String, dynamic>.from(jsonDecode(bodyStr) as Map);
          if (json['message'] != null) {
            errorMsg = json['message'].toString();
          }
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  // --- Notifikasi ---
  Future<Map<String, dynamic>> getWaLink(
      String transaksiId, String tipePesan) async {
    final response = await _dio
        .get('/api/v1/notifikasi/wa-link/$transaksiId', queryParameters: {
      'tipePesan': tipePesan,
    });
    return response.data;
  }

  // --- Audit Log ---
  Future<List<dynamic>> getAuditLogTransaksi(String transaksiId) async {
    final response = await _dio.get('/api/v1/audit/transaksi/$transaksiId');
    final responseBody = response.data;
    if (responseBody is List) {
      return responseBody;
    }
    return [];
  }

  // --- Garansi ---
  Future<Map<String, dynamic>> getGaransiAktif({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/transaksi-servis/garansi/aktif',
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final responseBody = response.data;
      if (responseBody is Map) {
        return Map<String, dynamic>.from(responseBody);
      }
      if (responseBody is List) {
        return {
          'content': responseBody,
          'totalElements': responseBody.length,
          'totalPages': 1,
          'number': 0,
          'size': responseBody.length,
          'first': true,
          'last': true,
        };
      }
      return _emptyPage();
    } catch (e) {
      debugPrint('ERROR getGaransiAktif: $e');
      return _emptyPage();
    }
  }

  Future<Map<String, dynamic>> getGaransiExpired({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/transaksi-servis/garansi/expired',
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final responseBody = response.data;
      if (responseBody is Map) {
        return Map<String, dynamic>.from(responseBody);
      }
      if (responseBody is List) {
        return {
          'content': responseBody,
          'totalElements': responseBody.length,
          'totalPages': 1,
          'number': 0,
          'size': responseBody.length,
          'first': true,
          'last': true,
        };
      }
      return _emptyPage();
    } catch (e) {
      debugPrint('ERROR getGaransiExpired: $e');
      return _emptyPage();
    }
  }

  // --- Riwayat Pelanggan ---
  Future<Map<String, dynamic>> getRiwayatPelanggan(String pelangganId) async {
    final response = await _dio.get(
      '/api/v1/transaksi-servis/riwayat-pelanggan/$pelangganId',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // --- Laporan Keuangan ---
  Future<Map<String, dynamic>> getLaporanKeuangan(
      Map<String, dynamic> queryParams) async {
    final response = await _dio.get('/api/v1/laporan-servis/keuangan',
        queryParameters: queryParams);
    return response.data;
  }

  Future<Response> exportLaporanKeuangan(
      Map<String, dynamic> queryParams) async {
    final response = await _dio.get(
      '/api/v1/laporan-servis/keuangan/export',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return response;
  }
}
