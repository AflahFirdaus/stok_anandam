import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL backend API.
/// Sumber (prioritas): 1) --dart-define=BASE_URL=...  2) .env BASE_URL  3) default localhost.
String get apiBaseUrl {
  const fromDefine = String.fromEnvironment(
    'BASE_URL',
    defaultValue: '',
  );
  final fromEnv = dotenv.env['BASE_URL']?.trim() ?? '';
  final raw = fromDefine.isNotEmpty
      ? fromDefine
      : (fromEnv.isNotEmpty ? fromEnv : 'http://localhost:8080');
  return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
}
