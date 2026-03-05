/// Helper untuk response API yang seragam (status, message, data, paging).
/// Backend kadang mengirim [status] sebagai int 200 atau string "200".
library;

/// Mengembalikan true jika [status] dianggap sukses (2xx).
bool isResponseSuccess(Object? status) {
  if (status == null) return false;
  if (status == 200) return true;
  if (status is int && status >= 200 && status < 300) return true;
  final s = status.toString().trim();
  if (s == '200') return true;
  final code = int.tryParse(s);
  return code != null && code >= 200 && code < 300;
}
