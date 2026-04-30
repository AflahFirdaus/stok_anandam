import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class FileDownloadService {
  static Future<void> downloadFile(List<int> bytes, String fileName, String mimeType) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }
}
