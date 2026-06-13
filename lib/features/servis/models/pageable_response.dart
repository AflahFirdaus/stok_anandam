class PageableResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int size;
  final bool hasNext;
  final bool hasPrevious;

  const PageableResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.size,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PageableResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawContent = (json['content'] ??
            json['records'] ??
            json['data'] ??
            []) as List<dynamic>? ??
        [];
    final content =
        rawContent.map((e) => fromJsonT(e as Map<String, dynamic>)).toList();

    // Support multiple common field names from different backends
    final totalElements = _intVal(json, [
          'totalElements',
          'totalElements',
          'total_count',
          'totalCount',
          'totalRecords',
          'total'
        ]) ??
        content.length;

    final totalPages = _intVal(
            json, ['totalPages', 'totalPages', 'total_pages', 'totalPage']) ??
        (totalElements > 0
            ? (totalElements / (json['size'] as int? ?? 20)).ceil()
            : 0);

    final currentPage =
        _intVal(json, ['number', 'page', 'numberOfElements']) ?? 0;

    final size = _intVal(json, ['size', 'pageSize', 'per_page']) ?? 20;

    final hasNext = json['last'] != null
        ? !(json['last'] as bool)
        : json['hasNext'] as bool? ??
            json['has_next'] as bool? ??
            (currentPage + 1 < totalPages);

    final hasPrevious = json['first'] != null
        ? !(json['first'] as bool)
        : json['hasPrevious'] as bool? ??
            json['has_previous'] as bool? ??
            currentPage > 0;

    return PageableResponse(
      content: content,
      totalElements: totalElements,
      totalPages: totalPages,
      currentPage: currentPage,
      size: size,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  /// Helper to try multiple possible keys for integer values
  static int? _intVal(Map<String, dynamic> json, List<String> keys) {
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
}
