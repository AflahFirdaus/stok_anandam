import 'package:dio/dio.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/network/response_utils.dart';

import '../../../injection.dart';

/// Hasil list canvas (pagination).
class CanvasListResult {
  const CanvasListResult({
    required this.items,
    required this.totalElements,
    required this.totalPages,
  });
  final List<Canvasing> items;
  final int totalElements;
  final int totalPages;
}

/// Repository layer: satu entry point untuk data canvas (menggunakan API).
class CanvasRepository {
  CanvasRepository() : _api = getIt<CanvasingControllerApi>();

  final CanvasingControllerApi _api;

  static List<Canvasing> _parseContent(Object? content) {
    if (content == null) return [];
    if (content is! List) return [];
    final items = <Canvasing>[];
    for (final e in content) {
      if (e is Canvasing) {
        items.add(e);
      } else if (e is Map) {
        items.add(Canvasing.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return items;
  }

  Future<CanvasListResult> getList({
    int page = 0,
    int size = 20,
    String sortBy = 'namaInstansi',
    String direction = 'asc',
    String? search,
  }) async {
    try {
      final response = await _api.getAllCanvasing(
        page: page,
        size: size,
        sortBy: sortBy,
        direction: direction,
        search: search?.trim().isEmpty ?? true ? null : search?.trim(),
      );
      final data = response.data?.data;
      if (!isResponseSuccess(response.data?.status) || data == null) {
        throw Exception(response.data?.message ?? 'Gagal memuat data.');
      }
      final content = data.content;
      final items = _parseContent(content);
      final totalElements = data.totalElements is int
          ? data.totalElements as int
          : int.tryParse(data.totalElements?.toString() ?? '0') ?? 0;
      final totalPages = data.totalPages is int
          ? data.totalPages as int
          : int.tryParse(data.totalPages?.toString() ?? '0') ?? 0;
      return CanvasListResult(
        items: items,
        totalElements: totalElements,
        totalPages: totalPages,
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final body = e.response!.data as Map<Object?, Object?>;
        final status = body['status'];
        final dataPayload = body['data'];
        final paging = body['paging'];
        if (isResponseSuccess(status) && dataPayload is List) {
          final items = _parseContent(dataPayload);
          int totalElements = 0;
          int totalPages = 1;
          if (paging is Map) {
            final p = Map<String, dynamic>.from(paging.map((k, v) => MapEntry(k?.toString() ?? '', v)));
            totalElements = int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
            totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 1;
            if (totalPages < 1) totalPages = 1;
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
}
