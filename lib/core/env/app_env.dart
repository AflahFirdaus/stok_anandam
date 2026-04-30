import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL backend API.
/// Sumber (prioritas): 1) --dart-define=BASE_URL=...  2) .env BASE_URL  3) default localhost.
String get apiBaseUrl {
  const fromDefine = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );
  final fromEnv = dotenv.env['BASE_URL']?.trim() ?? '';
  String raw = fromDefine.isNotEmpty
      ? fromDefine
      : (fromEnv.isNotEmpty ? fromEnv : 'http://localhost:8080');

  // Jika running di Android Emulator, 'localhost' merujuk ke device itu sendiri.
  // Gunakan '10.0.2.2' untuk mengakses localhost komputer host.
  if (!kIsWeb && Platform.isAndroid) {
    if (raw.contains('localhost')) {
      raw = raw.replaceFirst('localhost', '10.0.2.2');
    } else if (raw.contains('127.0.0.1')) {
      raw = raw.replaceFirst('127.0.0.1', '10.0.2.2');
    }
  }

  return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
}
