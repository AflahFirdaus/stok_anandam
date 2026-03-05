/// Detail error dari backend (untuk validasi form / debug).
/// Dipakai ketika response.status >= 400 dan data berisi object error.
class ApiErrorData {
  ApiErrorData({
    this.timestamp,
    this.status,
    this.error,
    this.message,
    this.path,
    this.fieldErrors,
  });

  factory ApiErrorData.fromJson(Map<String, dynamic> json) {
    Map<String, String>? fieldErrors;
    if (json['fieldErrors'] != null && json['fieldErrors'] is Map) {
      fieldErrors = (json['fieldErrors'] as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }

    return ApiErrorData(
      timestamp: json['timestamp']?.toString(),
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? ''),
      error: json['error']?.toString(),
      message: json['message']?.toString(),
      path: json['path']?.toString(),
      fieldErrors: fieldErrors,
    );
  }

  final String? timestamp;
  final int? status;
  final String? error;
  final String? message;
  final String? path;
  final Map<String, String>? fieldErrors;
}
