class StokBadanItem {
  final String badan;
  final String depCode;
  final String? depName;
  final String itemCode;
  final String? itemName;
  final int stokQty;
  final int lineCount;

  StokBadanItem({
    required this.badan,
    required this.depCode,
    this.depName,
    required this.itemCode,
    this.itemName,
    required this.stokQty,
    required this.lineCount,
  });

  factory StokBadanItem.fromJson(Map<String, dynamic> json) {
    return StokBadanItem(
      badan: json['badan']?.toString() ?? '',
      depCode: (json['dep_code'] ?? json['depCode'])?.toString() ?? '',
      depName: (json['dep_name'] ?? json['depName'])?.toString(),
      itemCode: (json['item_code'] ?? json['itemCode'] ?? json['ite_code'])?.toString() ?? '',
      itemName: (json['item_name'] ?? json['itemName'])?.toString(),
      stokQty: int.tryParse((json['stok_qty'] ?? json['stokQty'])?.toString() ?? '0') ?? 0,
      lineCount: int.tryParse((json['line_count'] ?? json['lineCount'])?.toString() ?? '0') ?? 0,
    );
  }
}

class StokBadanGroup {
  final String badan;
  final int totalItems;
  final int totalQty;
  final List<StokBadanItem> items;

  StokBadanGroup({
    required this.badan,
    required this.totalItems,
    required this.totalQty,
    required this.items,
  });

  factory StokBadanGroup.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return StokBadanGroup(
      badan: json['badan']?.toString() ?? '',
      totalItems: int.tryParse((json['totalItems'] ?? json['total_items'])?.toString() ?? '0') ?? 0,
      totalQty: int.tryParse((json['totalQty'] ?? json['total_qty'])?.toString() ?? '0') ?? 0,
      items: list
          .map((e) => StokBadanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}