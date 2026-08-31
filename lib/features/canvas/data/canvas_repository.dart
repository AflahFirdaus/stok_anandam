import 'package:dio/dio.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/features/canvas/models/data_canvasing_model.dart';
import '../../../injection.dart';

/// Hasil list data canvas (pagination).
class CanvasListResult {
  const CanvasListResult({
    required this.items,
    required this.totalElements,
    required this.totalPages,
  });
  final List<DataCanvasingItem> items;
  final int totalElements;
  final int totalPages;
}

/// Repository layer: satu entry point untuk data canvas (menggunakan API).
class CanvasRepository {
  CanvasRepository({Dio? dio}) : _dio = dio ?? getIt<Dio>();

  final Dio _dio;

  static List<DataCanvasingItem> _parseContent(Object? content) {
    if (content == null) return [];
    if (content is! List) return [];
    final items = <DataCanvasingItem>[];
    for (final e in content) {
      if (e is DataCanvasingItem) {
        items.add(e);
      } else if (e is Map) {
        items.add(DataCanvasingItem.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return items;
  }

  Future<CanvasListResult> getList({
    int page = 0,
    int size = 50,
    String sortBy = 'tanggal',
    String direction = 'desc',
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'direction': direction,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/data-canvasing',
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body == null) {
        return const CanvasListResult(items: [], totalElements: 0, totalPages: 1);
      }

      final dataPayload = body['data'];
      final paging = body['paging'];

      List<DataCanvasingItem> items = [];
      int totalElements = 0;
      int totalPages = 1;

      if (dataPayload is List) {
        items = _parseContent(dataPayload);
      } else if (dataPayload is Map && dataPayload['content'] is List) {
        items = _parseContent(dataPayload['content']);
        totalElements = int.tryParse(dataPayload['totalElements']?.toString() ?? '0') ?? items.length;
        totalPages = int.tryParse(dataPayload['totalPages']?.toString() ?? '1') ?? 1;
      }

      if (paging is Map) {
        final p = Map<String, dynamic>.from(paging.map((k, v) => MapEntry(k?.toString() ?? '', v)));
        totalElements = int.tryParse(p['totalItem']?.toString() ?? '$totalElements') ?? totalElements;
        totalPages = int.tryParse(p['totalPage']?.toString() ?? '$totalPages') ?? totalPages;
        if (totalPages < 1) totalPages = 1;
      } else if (totalElements == 0 && items.isNotEmpty) {
        totalElements = items.length;
      }

      return CanvasListResult(
        items: items,
        totalElements: totalElements,
        totalPages: totalPages,
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final body = e.response!.data as Map;
        final status = body['status'];
        final dataPayload = body['data'];
        final paging = body['paging'];
        if (isResponseSuccess(status) && dataPayload is List) {
          final items = _parseContent(dataPayload);
          int totalElements = items.length;
          int totalPages = 1;
          if (paging is Map) {
            final p = Map<String, dynamic>.from(paging.map((k, v) => MapEntry(k?.toString() ?? '', v)));
            totalElements = int.tryParse(p['totalItem']?.toString() ?? '$totalElements') ?? totalElements;
            totalPages = int.tryParse(p['totalPage']?.toString() ?? '1') ?? 1;
          }
          return CanvasListResult(
            items: items,
            totalElements: totalElements,
            totalPages: totalPages,
          );
        }
      }
      rethrow;
    }
  }

  /// Menambah data kunjungan canvas
  Future<void> createDataCanvasing({
    required String canvasingId,
    required String tanggal,
    required String canvasVisit,
    String? keterangan,
    String? catatan,
  }) async {
    final payload = <String, dynamic>{
      'pelangganId': canvasingId,
      'canvasingId': canvasingId,
      'tanggal': tanggal,
      'kunjungan': canvasVisit,
      'canvasVisit': canvasVisit,
      if (keterangan != null && keterangan.trim().isNotEmpty)
        'keterangan': keterangan.trim()
      else
        'keterangan': '',
      if (catatan != null && catatan.trim().isNotEmpty)
        'catatan': catatan.trim()
      else
        'catatan': '',
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/data-canvasing',
      data: payload,
    );

    final status = response.data?['status'];
    if (!isResponseSuccess(status) && (response.statusCode ?? 0) >= 400) {
      throw Exception(response.data?['message'] ?? 'Gagal menyimpan data canvas.');
    }
  }
}
