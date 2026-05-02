import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppUpdateInfo {
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String? releaseNotes;
  final bool isForceUpdate;

  AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    this.releaseNotes,
    this.isForceUpdate = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      versionName: json['versionName'] ?? '',
      versionCode: json['versionCode'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'],
      isForceUpdate: json['isForceUpdate'] ?? false,
    );
  }
}

class AppUpdateService {
  final Dio _dio;

  AppUpdateService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: dotenv.env['BASE_URL'] ?? '',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  /// Cek apakah ada update tersedia berdasarkan versionCode
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint(
          '[AppUpdate] Current version: ${packageInfo.version}+$currentCode');

      final response = await _dio.get('/api/v1/public/app/latest');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final info = AppUpdateInfo.fromJson(response.data['data']);
        debugPrint(
            '[AppUpdate] Server version: ${info.versionName}+${info.versionCode}');

        // Ada update jika versionCode server > lokal
        if (info.versionCode > currentCode) {
          return info;
        }
      }
    } catch (e) {
      debugPrint('[AppUpdate] Check update failed: $e');
    }
    return null;
  }

  /// Download APK menggunakan ota_update
  Stream<OtaEvent> downloadAndInstall(AppUpdateInfo info) {
    return OtaUpdate().execute(
      info.downloadUrl,
      destinationFilename: 'app-release-${info.versionName}.apk',
    );
  }
}
