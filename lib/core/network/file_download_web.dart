import 'dart:html' as html;

class FileDownloadService {
  static Future<void> downloadFile(
      List<int> bytes, String fileName, String mimeType) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.Url.revokeObjectUrl(url);
  }
}
