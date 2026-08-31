import 'package:flutter/foundation.dart';
import '../models/marketing_report_models.dart';
import '../api/laporan_marketing_api.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';

/// Repository laporan omzet per marketing.
///
/// Otomatis menggabungkan data dari dua sumber:
/// - **sales aktif** (tabel `sales`) — via LaporanMarketingApi
/// - **data warehouse** (tabel `old_sales`) — via ApiNewEndpoints
///
/// Hasil merge per marketing sehingga user melihat rangkuman utuh dari 2016+

class LaporanMarketingRepository {
  LaporanMarketingRepository(this._api, this._newApi);

  final LaporanMarketingApi _api;
  final ApiNewEndpoints _newApi;

  /// Ringkasan omzet per marketing — gabungan data aktif + warehouse.
  /// Data < 2026 dari old_sales, data >= 2026 dari sales (tidak overlap).
  Future<MarketingSalesSummary> getOverview({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? empCodes,
  }) async {
    final cutDate = DateTime(2026, 1, 1);
    final reqStart = startDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);
    final reqEnd = endDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);

    // 1. Sales (data aktif >= 2026)
    MarketingSalesSummary? active;
    final bool needActive = reqEnd == null || !reqEnd.isBefore(cutDate);
    if (needActive) {
      final actStart = (reqStart != null && reqStart.isBefore(cutDate)) ? cutDate : reqStart;
      final actData = await _safeCall(
        () => _api.getOverview(
          period: period,
          date: date,
          startDate: actStart,
          endDate: reqEnd,
          empCodes: empCodes,
        ),
      );
      if (actData != null) active = MarketingSalesSummary.fromJson(actData);
    }

    // 2. Old_sales (warehouse < 2026)
    MarketingSalesSummary? warehouse;
    final bool needWarehouse = reqStart == null || reqStart.isBefore(cutDate);
    if (needWarehouse) {
      final whEnd = (reqEnd != null && !reqEnd.isBefore(cutDate))
          ? cutDate.subtract(const Duration(days: 1))
          : reqEnd;
      final whData = await _safeCall(
        () => _newApi.getOldMarketingOverview(
          period: period,
          date: date,
          startDate: reqStart,
          endDate: whEnd,
          empCode: empCodes?.join(','),
        ),
      );
      if (whData != null) warehouse = MarketingSalesSummary.fromJson(whData);
    }

    return _mergeOverview(
      active ?? const MarketingSalesSummary(),
      warehouse ?? const MarketingSalesSummary(),
    );
  }

  /// Detail per nota — gabungan data aktif + warehouse.
  Future<MarketingNotaDetail> getNotas({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? empCode,
  }) async {
    final cutDate = DateTime(2026, 1, 1);
    final reqStart = startDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);
    final reqEnd = endDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);

    // 1. Sales (data aktif >= 2026)
    MarketingNotaDetail? active;
    final bool needActive = reqEnd == null || !reqEnd.isBefore(cutDate);
    if (needActive) {
      final actStart = (reqStart != null && reqStart.isBefore(cutDate)) ? cutDate : reqStart;
      final actData = await _safeCall(
        () => _api.getNotas(
          period: period,
          date: date,
          startDate: actStart,
          endDate: reqEnd,
          empCode: empCode,
        ),
      );
      if (actData != null) active = MarketingNotaDetail.fromJson(actData);
    }

    // 2. Old_sales (warehouse < 2026)
    MarketingNotaDetail? warehouse;
    final bool needWarehouse = reqStart == null || reqStart.isBefore(cutDate);
    if (needWarehouse) {
      final whEnd = (reqEnd != null && !reqEnd.isBefore(cutDate))
          ? cutDate.subtract(const Duration(days: 1))
          : reqEnd;
      final whData = await _safeCall(
        () => _newApi.getOldMarketingNotas(
          period: period,
          date: date,
          startDate: reqStart,
          endDate: whEnd,
          empCode: empCode,
        ),
      );
      if (whData != null) warehouse = MarketingNotaDetail.fromJson(whData);
    }

    final empty = MarketingNotaDetail(period: period);
    return _mergeNotaDetail(
      active ?? empty,
      warehouse ?? empty,
    );
  }

  /// Detail per barang — gabungan data aktif + warehouse.
  Future<MarketingItemDetail> getItems({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? empCode,
  }) async {
    final cutDate = DateTime(2026, 1, 1);
    final reqStart = startDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);
    final reqEnd = endDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);

    // 1. Sales (data aktif >= 2026)
    MarketingItemDetail? active;
    final bool needActive = reqEnd == null || !reqEnd.isBefore(cutDate);
    if (needActive) {
      final actStart = (reqStart != null && reqStart.isBefore(cutDate)) ? cutDate : reqStart;
      final actData = await _safeCall(
        () => _api.getItems(
          period: period,
          date: date,
          startDate: actStart,
          endDate: reqEnd,
          empCode: empCode,
        ),
      );
      if (actData != null) active = MarketingItemDetail.fromJson(actData);
    }

    // 2. Old_sales (warehouse < 2026)
    MarketingItemDetail? warehouse;
    final bool needWarehouse = reqStart == null || reqStart.isBefore(cutDate);
    if (needWarehouse) {
      final whEnd = (reqEnd != null && !reqEnd.isBefore(cutDate))
          ? cutDate.subtract(const Duration(days: 1))
          : reqEnd;
      final whData = await _safeCall(
        () => _newApi.getOldMarketingItems(
          period: period,
          date: date,
          startDate: reqStart,
          endDate: whEnd,
          empCode: empCode,
        ),
      );
      if (whData != null) warehouse = MarketingItemDetail.fromJson(whData);
    }

    final empty = MarketingItemDetail(period: period);
    return _mergeItemDetail(
      active ?? empty,
      warehouse ?? empty,
    );
  }

  /// Timeline agregat grafik — sangat ringan (hanya N titik, bukan ratusan ribu nota).
  /// Menggabungkan data old_sales (< 2026) + sales (>= 2026).
  Future<MarketingTimeline> getTimeline({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? empCode,
  }) async {
    final cutDate = DateTime(2026, 1, 1);
    final reqStart = startDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);
    final reqEnd = endDate ?? (date != null ? DateTime(date.year, date.month, date.day) : null);

    // 1. Sales aktif (>= 2026)
    MarketingTimeline? active;
    final bool needActive = reqEnd == null || !reqEnd.isBefore(cutDate);
    if (needActive) {
      final actStart = (reqStart != null && reqStart.isBefore(cutDate)) ? cutDate : reqStart;
      final actData = await _safeCall(
        () => _api.getTimeline(
          period: period,
          date: date,
          startDate: actStart,
          endDate: reqEnd,
          empCode: empCode,
        ),
      );
      if (actData != null && actData.isNotEmpty) {
        active = MarketingTimeline.fromJson(actData);
      }
    }

    // 2. Old_sales warehouse (< 2026)
    MarketingTimeline? warehouse;
    final bool needWarehouse = reqStart == null || reqStart.isBefore(cutDate);
    if (needWarehouse) {
      final whEnd = (reqEnd != null && !reqEnd.isBefore(cutDate))
          ? cutDate.subtract(const Duration(days: 1))
          : reqEnd;
      final whData = await _safeCall(
        () => _newApi.getOldMarketingTimeline(
          period: period,
          date: date,
          startDate: reqStart,
          endDate: whEnd,
          empCode: empCode,
        ),
      );
      if (whData != null && whData.isNotEmpty) {
        warehouse = MarketingTimeline.fromJson(whData);
      }
    }

    const empty = MarketingTimeline();
    return MarketingTimeline.merge(
      warehouse ?? empty,
      active ?? empty,
    );
  }

  /// Panggil API, tangani error, return null jika gagal.
  Future<Map<String, dynamic>?> _safeCall(
      Future<Map<String, dynamic>> Function() call) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('[LaporanMarketingRepo] API call failed: $e');
      return null;
    }
  }
  // ==================== MERGE HELPERS ====================

  MarketingSalesSummary _mergeOverview(
      MarketingSalesSummary a, MarketingSalesSummary b) {
    final merged = <String, _Acc>{};
    for (var row in [...a.content, ...b.content]) {
      final key = row.empCode ?? '';
      merged.putIfAbsent(key, () => _Acc());
      merged[key]!.addRow(row);
    }
    final mergedContent = merged.entries
        .map((e) => e.value.toRow(e.key, a.content, b.content))
        .toList()
      ..sort((x, y) => y.omset.compareTo(x.omset));

    final totalQty = mergedContent.fold(0.0, (s, r) => s + r.qty);
    final totalOmset = mergedContent.fold(0.0, (s, r) => s + r.omset);
    final totalHpp = mergedContent.fold(0.0, (s, r) => s + r.totalHpp);
    final totalLaba = mergedContent.fold(0.0, (s, r) => s + r.labaKotor);

    return MarketingSalesSummary(
      period: a.period,
      rangeStart: a.rangeStart,
      rangeEnd: a.rangeEnd,
      content: mergedContent,
      totalQty: totalQty,
      totalOmset: totalOmset,
      totalHpp: totalHpp,
      totalLabaKotor: totalLaba,
      marginPct: totalHpp > 0 ? (totalLaba / totalHpp) * 100 : 0,
    );
  }

  MarketingNotaDetail _mergeNotaDetail(
      MarketingNotaDetail a, MarketingNotaDetail b) {
    final c = [...a.content, ...b.content];
    final tQty = c.fold(0.0, (s, r) => s + r.qty);
    final tOmset = c.fold(0.0, (s, r) => s + r.omset);
    final tHpp = c.fold(0.0, (s, r) => s + r.totalHpp);
    final tLaba = c.fold(0.0, (s, r) => s + r.labaKotor);

    return MarketingNotaDetail(
      empCode: a.empCode ?? b.empCode,
      empName: a.empName ?? b.empName,
      period: a.period,
      start: a.start ?? b.start,
      end: a.end ?? b.end,
      content: c,
      totalQty: tQty,
      totalOmset: tOmset,
      totalHpp: tHpp,
      totalLabaKotor: tLaba,
      marginPct: tHpp > 0 ? (tLaba / tHpp) * 100 : 0,
    );
  }

  MarketingItemDetail _mergeItemDetail(
      MarketingItemDetail a, MarketingItemDetail b) {
    final c = [...a.content, ...b.content];
    final tQty = c.fold(0.0, (s, r) => s + r.qty);
    final tOmset = c.fold(0.0, (s, r) => s + r.omset);
    final tHpp = c.fold(0.0, (s, r) => s + r.totalHpp);
    final tLaba = c.fold(0.0, (s, r) => s + r.labaKotor);

    return MarketingItemDetail(
      empCode: a.empCode ?? b.empCode,
      empName: a.empName ?? b.empName,
      period: a.period,
      start: a.start ?? b.start,
      end: a.end ?? b.end,
      content: c,
      totalQty: tQty,
      totalOmset: tOmset,
      totalHpp: tHpp,
      totalLabaKotor: tLaba,
      marginPct: tHpp > 0 ? (tLaba / tHpp) * 100 : 0,
    );
  }
}

/// Akumulator untuk merge per marketing.
class _Acc {
  double qty = 0, omset = 0, totalHpp = 0, labaKotor = 0;

  void addRow(MarketingSalesRow r) {
    qty += r.qty;
    omset += r.omset;
    totalHpp += r.totalHpp;
    labaKotor += r.labaKotor;
  }

  MarketingSalesRow toRow(
      String key, List<MarketingSalesRow> a, List<MarketingSalesRow> b) {
    final nameA =
        a.where((r) => r.empCode == key).map((r) => r.empName).firstOrNull;
    final nameB =
        b.where((r) => r.empCode == key).map((r) => r.empName).firstOrNull;
    final margin = totalHpp > 0 ? (labaKotor / totalHpp) * 100 : 0.0;
    return MarketingSalesRow(
      empCode: key.isEmpty ? null : key,
      empName: nameA ?? nameB,
      qty: qty,
      omset: omset,
      totalHpp: totalHpp,
      labaKotor: labaKotor,
      marginPct: margin,
    );
  }
}
