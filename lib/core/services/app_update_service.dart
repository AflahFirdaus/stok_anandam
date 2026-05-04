import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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

      final platform = Platform.isAndroid ? 'ANDROID' : (Platform.isWindows ? 'WINDOWS' : 'ANDROID');
      final response = await _dio.get('/api/v1/public/app/latest', queryParameters: {'platform': platform});

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

  /// Download APK (Android) menggunakan ota_update atau buka URL (Windows)
  Stream<dynamic> downloadAndInstall(AppUpdateInfo info) {
    if (Platform.isWindows) {
      // Untuk Windows, kita buka URL MSIX yang akan memicu App Installer
      _launchWindowsUpdate(info.downloadUrl);
      return const Stream.empty();
    }

    return OtaUpdate().execute(
      info.downloadUrl,
      destinationFilename: 'app-release-${info.versionName}.apk',
      androidProviderAuthority: 'com.example.stok_anandam.ota_update_provider',
    );
  }

  Future<void> _launchWindowsUpdate(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppUpdate] Failed to launch Windows update: $e');
    }
  }
}
