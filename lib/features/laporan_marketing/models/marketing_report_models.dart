/// Kode pembantu parsing nilai JSON backend dengan aman.
double _d(Object? v) => v is num ? v.toDouble() : 0;
String? _s(Object? v) => v?.toString();

/// Presentase margin (%) dihitung dari **Margin Kotor ÷ Total HPP**
/// (bukan lagi dibagi Omset).
double _margin(double labaKotor, double hpp) =>
    hpp <= 0 ? 0 : (labaKotor / hpp) * 100;

/// Satu baris ringkasan omzet & margin kotor per marketing.
class MarketingSalesRow {
  final String? empCode;
  final String? empName;
  final double qty;
  final double omset;
  final double totalHpp;
  final double labaKotor;
  final double marginPct;

  const MarketingSalesRow({
    this.empCode,
    this.empName,
    this.qty = 0,
    this.omset = 0,
    this.totalHpp = 0,
    this.labaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingSalesRow.fromJson(Map<String, dynamic> j) =>
      MarketingSalesRow(
        empCode: _s(j['empCode']),
        empName: _s(j['empName']),
        qty: _d(j['qty']),
        omset: _d(j['omset']),
        totalHpp: _d(j['totalHpp']),
        labaKotor: _d(j['labaKotor']),
        marginPct: _margin(_d(j['labaKotor']), _d(j['totalHpp'])),
      );
}

/// Response ringkasan omzet per marketing (dari endpoint overview).
class MarketingSalesSummary {
  final String period;
  final String? rangeStart;
  final String? rangeEnd;
  final List<MarketingSalesRow> content;
  final double totalQty;
  final double totalOmset;
  final double totalHpp;
  final double totalLabaKotor;
  final double marginPct;

  const MarketingSalesSummary({
    this.period = 'DAY',
    this.rangeStart,
    this.rangeEnd,
    this.content = const [],
    this.totalQty = 0,
    this.totalOmset = 0,
    this.totalHpp = 0,
    this.totalLabaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingSalesSummary.fromJson(Map<String, dynamic> j) {
    final range = j['range'] is Map
        ? Map<String, dynamic>.from(j['range'] as Map)
        : <String, dynamic>{};
    final content = (j['content'] as List? ?? const [])
        .map((e) => MarketingSalesRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return MarketingSalesSummary(
      period: j['period']?.toString() ?? 'DAY',
      rangeStart: range['start']?.toString(),
      rangeEnd: range['end']?.toString(),
      content: content,
      totalQty: _d(j['totalQty']),
      totalOmset: _d(j['totalOmset']),
      totalHpp: _d(j['totalHpp']),
      totalLabaKotor: _d(j['totalLabaKotor']),
      marginPct: _margin(_d(j['totalLabaKotor']), _d(j['totalHpp'])),
    );
  }
}
/// Satu baris detail per nota (doc).
class MarketingNotaRow {
  final String? docNo;
  final String? docDate;
  final String? code;
  final String? parName;
  final String? empCode;
  final String? empName;
  final double qty;
  final double omset;
  final double totalHpp;
  final double labaKotor;
  final double marginPct;

  const MarketingNotaRow({
    this.docNo,
    this.docDate,
    this.code,
    this.parName,
    this.empCode,
    this.empName,
    this.qty = 0,
    this.omset = 0,
    this.totalHpp = 0,
    this.labaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingNotaRow.fromJson(Map<String, dynamic> j) => MarketingNotaRow(
        docNo: _s(j['docNo']),
        docDate: _s(j['docDate']),
        code: _s(j['code']),
        parName: _s(j['parName']),
        empCode: _s(j['empCode']),
        empName: _s(j['empName']),
        qty: _d(j['qty']),
        omset: _d(j['omset']),
        totalHpp: _d(j['totalHpp']),
        labaKotor: _d(j['labaKotor']),
        marginPct: _margin(_d(j['labaKotor']), _d(j['totalHpp'])),
      );
}

/// Response detail per nota (endpoint notas).
class MarketingNotaDetail {
  final String? empCode;
  final String? empName;
  final String period;
  final String? start;
  final String? end;
  final List<MarketingNotaRow> content;
  final double totalQty;
  final double totalOmset;
  final double totalHpp;
  final double totalLabaKotor;
  final double marginPct;

  const MarketingNotaDetail({
    this.empCode,
    this.empName,
    this.period = 'DAY',
    this.start,
    this.end,
    this.content = const [],
    this.totalQty = 0,
    this.totalOmset = 0,
    this.totalHpp = 0,
    this.totalLabaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingNotaDetail.fromJson(Map<String, dynamic> j) {
    final content = (j['content'] as List? ?? const [])
        .map((e) => MarketingNotaRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return MarketingNotaDetail(
      empCode: _s(j['empCode']),
      empName: _s(j['empName']),
      period: j['period']?.toString() ?? 'DAY',
      start: _s(j['start']),
      end: _s(j['end']),
      content: content,
      totalQty: _d(j['totalQty']),
      totalOmset: _d(j['totalOmset']),
      totalHpp: _d(j['totalHpp']),
      totalLabaKotor: _d(j['totalLabaKotor']),
      marginPct: _margin(_d(j['totalLabaKotor']), _d(j['totalHpp'])),
    );
  }
}
/// Satu baris detail per barang (item).
class MarketingItemRow {
  final String? iteCode;
  final String? itemName;
  final String? depCode;
  final String? depName;
  final String? empCode;
  final String? empName;
  final double qty;
  final double omset;
  final double totalHpp;
  final double labaKotor;
  final double marginPct;

  const MarketingItemRow({
    this.iteCode,
    this.itemName,
    this.depCode,
    this.depName,
    this.empCode,
    this.empName,
    this.qty = 0,
    this.omset = 0,
    this.totalHpp = 0,
    this.labaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingItemRow.fromJson(Map<String, dynamic> j) => MarketingItemRow(
        iteCode: _s(j['iteCode']),
        itemName: _s(j['itemName']),
        depCode: _s(j['depCode']),
        depName: _s(j['depName']),
        empCode: _s(j['empCode']),
        empName: _s(j['empName']),
        qty: _d(j['qty']),
        omset: _d(j['omset']),
        totalHpp: _d(j['totalHpp']),
        labaKotor: _d(j['labaKotor']),
        marginPct: _margin(_d(j['labaKotor']), _d(j['totalHpp'])),
      );
}

/// Response detail per barang (endpoint items).
class MarketingItemDetail {
  final String? empCode;
  final String? empName;
  final String period;
  final String? start;
  final String? end;
  final List<MarketingItemRow> content;
  final double totalQty;
  final double totalOmset;
  final double totalHpp;
  final double totalLabaKotor;
  final double marginPct;

  const MarketingItemDetail({
    this.empCode,
    this.empName,
    this.period = 'DAY',
    this.start,
    this.end,
    this.content = const [],
    this.totalQty = 0,
    this.totalOmset = 0,
    this.totalHpp = 0,
    this.totalLabaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingItemDetail.fromJson(Map<String, dynamic> j) {
    final content = (j['content'] as List? ?? const [])
        .map((e) => MarketingItemRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return MarketingItemDetail(
      empCode: _s(j['empCode']),
      empName: _s(j['empName']),
      period: j['period']?.toString() ?? 'DAY',
      start: _s(j['start']),
      end: _s(j['end']),
      content: content,
      totalQty: _d(j['totalQty']),
      totalOmset: _d(j['totalOmset']),
      totalHpp: _d(j['totalHpp']),
      totalLabaKotor: _d(j['totalLabaKotor']),
      marginPct: _margin(_d(j['totalLabaKotor']), _d(j['totalHpp'])),
    );
  }
}/// Satu titik waktu pada grafik timeline marketing.
class MarketingTimelinePoint {
  final String key;    // '2017', '2026-01', '2026-01-15'
  final String label;  // 'Jan', '15/01', '2017'
  final double omset;
  final double totalHpp;
  final double labaKotor;
  final double marginPct;

  const MarketingTimelinePoint({
    required this.key,
    required this.label,
    this.omset = 0,
    this.totalHpp = 0,
    this.labaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingTimelinePoint.fromJson(Map<String, dynamic> j) =>
      MarketingTimelinePoint(
        key: j['key']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        omset: _d(j['omset']),
        totalHpp: _d(j['totalHpp']),
        labaKotor: _d(j['labaKotor']),
        marginPct: _margin(_d(j['labaKotor']), _d(j['totalHpp'])),
      );
}

/// Response timeline agregat dari endpoint /reports/marketing/timeline.
class MarketingTimeline {
  final String period;
  final String? start;
  final String? end;
  final String? empCode;
  final List<MarketingTimelinePoint> points;
  final double totalOmset;
  final double totalHpp;
  final double totalLabaKotor;
  final double marginPct;

  const MarketingTimeline({
    this.period = 'DAY',
    this.start,
    this.end,
    this.empCode,
    this.points = const [],
    this.totalOmset = 0,
    this.totalHpp = 0,
    this.totalLabaKotor = 0,
    this.marginPct = 0,
  });

  factory MarketingTimeline.fromJson(Map<String, dynamic> j) {
    final pts = (j['points'] as List? ?? const [])
        .map((e) =>
            MarketingTimelinePoint.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return MarketingTimeline(
      period: j['period']?.toString() ?? 'DAY',
      start: _s(j['start']),
      end: _s(j['end']),
      empCode: _s(j['empCode']),
      points: pts,
      totalOmset: _d(j['totalOmset']),
      totalHpp: _d(j['totalHpp']),
      totalLabaKotor: _d(j['totalLabaKotor']),
      marginPct: _margin(_d(j['totalLabaKotor']), _d(j['totalHpp'])),
    );
  }

  /// Gabung dua timeline (active + warehouse) menjadi satu timeline.
  /// Key yang sama di-aggregate (omset dijumlahkan).
  static MarketingTimeline merge(MarketingTimeline a, MarketingTimeline b) {
    final map = <String, MarketingTimelinePoint>{};
    for (final pt in [...a.points, ...b.points]) {
      if (map.containsKey(pt.key)) {
        final prev = map[pt.key]!;
        final newOmset = prev.omset + pt.omset;
        final newHpp = prev.totalHpp + pt.totalHpp;
        final newLaba = prev.labaKotor + pt.labaKotor;
        map[pt.key] = MarketingTimelinePoint(
          key: pt.key,
          label: pt.label.isEmpty ? prev.label : pt.label,
          omset: newOmset,
          totalHpp: newHpp,
          labaKotor: newLaba,
          marginPct: _margin(newLaba, newHpp),
        );
      } else {
        map[pt.key] = pt;
      }
    }
    // Urutkan berdasarkan key (string sort works because format is sortable)
    final sorted = map.values.toList()..sort((x, y) => x.key.compareTo(y.key));
    final totalOmset = a.totalOmset + b.totalOmset;
    final totalHpp = a.totalHpp + b.totalHpp;
    final totalLaba = a.totalLabaKotor + b.totalLabaKotor;
    return MarketingTimeline(
      period: a.period,
      start: a.start ?? b.start,
      end: b.end ?? a.end,
      empCode: a.empCode,
      points: sorted,
      totalOmset: totalOmset,
      totalHpp: totalHpp,
      totalLabaKotor: totalLaba,
      marginPct: _margin(totalLaba, totalHpp),
    );
  }
}
