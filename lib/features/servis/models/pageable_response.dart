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
    final rawContent = json['content'] as List<dynamic>? ?? [];
    final content = rawContent
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    return PageableResponse(
      content: content,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      hasNext: json['last'] != null ? !(json['last'] as bool) : (json['number'] as int? ?? 0) + 1 < (json['totalPages'] as int? ?? 1),
      hasPrevious: !(json['first'] as bool? ?? true),
    );
  }
}