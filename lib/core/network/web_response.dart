/// Wrapper response seragam dari backend (status, message, data, paging).
/// Gunakan untuk parse response yang mengikuti struktur dokumen API_INTEGRATION.md.
class WebResponse<T> {
  const WebResponse({
    required this.status,
    required this.message,
    this.data,
    this.paging,
  });

  final int status;
  final String message;
  final T? data;
  final PagingResponse? paging;

  bool get isSuccess => status >= 200 && status < 300;

  factory WebResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return WebResponse(
      status: (json['status'] is int)
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      paging: json['paging'] != null && json['paging'] is Map<String, dynamic>
          ? PagingResponse.fromJson(json['paging'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Metadata pagination dari backend (currentPage, totalPage, size, totalItem).
class PagingResponse {
  const PagingResponse({
    required this.currentPage,
    required this.totalPage,
    required this.size,
    required this.totalItem,
  });

  final int currentPage;
  final int totalPage;
  final int size;
  final int totalItem;

  factory PagingResponse.fromJson(Map<String, dynamic> json) {
    int from(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    return PagingResponse(
      currentPage: from(json['currentPage']),
      totalPage: from(json['totalPage']),
      size: from(json['size']),
      totalItem: from(json['totalItem']),
    );
  }
}
