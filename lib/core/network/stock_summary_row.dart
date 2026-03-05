/// Satu baris ringkasan stok (flat atau hierarchy).
/// Untuk GET /api/v1/stock/summary-by-category/hierarchy.
class StockSummaryRow {
  const StockSummaryRow({
    required this.nama,
    required this.stok,
    required this.presentase,
    this.children = const [],
  });

  final String nama;
  final num stok;
  final num presentase;
  final List<StockSummaryRow> children;

  factory StockSummaryRow.fromJson(Map<String, dynamic> json) {
    num fromNum(dynamic v) {
      if (v is num) return v;
      return num.tryParse(v?.toString() ?? '0') ?? 0;
    }

    final childrenList = json['children'] as List<dynamic>?;
    return StockSummaryRow(
      nama: json['nama']?.toString() ?? '',
      stok: fromNum(json['stok']),
      presentase: fromNum(json['presentase']),
      children: childrenList
              ?.map((e) => StockSummaryRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
