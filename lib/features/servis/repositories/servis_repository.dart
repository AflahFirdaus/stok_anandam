import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stok_anandam/features/servis/models/laporan_keuangan.dart';
import 'package:stok_anandam/features/servis/models/riwayat_servis.dart';

import '../models/pageable_response.dart';
import '../models/pelanggan_servis.dart';
import '../models/transaksi_servis.dart';
import '../models/klaim_distributor.dart';
import '../models/servis_audit_log.dart';
import '../api/servis_api.dart';

class ServisRepository {
  final ServisApi _api;

  ServisRepository(this._api);

  // --- Pelanggan Servis ---
  Future<PageableResponse<PelangganServis>> getPelangganServis({
    int page = 0,
    int size = 100,
    String? search,
  }) async {
    final response =
        await _api.getPelangganServis(page: page, size: size, search: search);
    return PageableResponse.fromJson(response, PelangganServis.fromJson);
  }

  Future<PelangganServis> createPelangganServis(
      PelangganServis pelanggan) async {
    final response = await _api.createPelangganServis(pelanggan.toJson());
    return PelangganServis.fromJson(Map<String, dynamic>.from(response));
  }

  Future<PelangganServis> updatePelangganServis(
      String id, PelangganServis pelanggan) async {
    final response = await _api.updatePelangganServis(id, pelanggan.toJson());
    return PelangganServis.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deletePelangganServis(String id) async {
    await _api.deletePelangganServis(id);
  }

  // --- Transaksi Servis ---
  Future<PageableResponse<TransaksiServis>> getTransaksiServisByStatus({
    required String status,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.getTransaksiServisByStatus(
      status: status,
      search: search,
      page: page,
      size: size,
    );
    return PageableResponse.fromJson(response, TransaksiServis.fromJson);
  }

  Future<TransaksiServis> createTransaksiServis(
      Map<String, dynamic> payload) async {
    final response = await _api.createTransaksiServis(payload);
    return TransaksiServis.fromJson(Map<String, dynamic>.from(response));
  }

  Future<TransaksiServis> updateStatusTransaksi(
      String id, Map<String, dynamic> data) async {
    final response = await _api.updateStatusTransaksi(id, data);
    return TransaksiServis.fromJson(Map<String, dynamic>.from(response));
  }

  // --- Klaim Distributor ---
  Future<KlaimDistributor> createKlaimDistributor(
      String transaksiId, Map<String, dynamic> data) async {
    final response = await _api.createKlaimDistributor(transaksiId, data);
    return KlaimDistributor.fromJson(Map<String, dynamic>.from(response));
  }

  Future<KlaimDistributor> updateStatusKlaim(
      String klaimId, Map<String, dynamic> data) async {
    final response = await _api.updateStatusKlaim(klaimId, data);
    return KlaimDistributor.fromJson(Map<String, dynamic>.from(response));
  }

  Future<KlaimDistributor?> getKlaimByTransaksiId(String transaksiId) async {
    try {
      final response = await _api.getKlaimByTransaksiId(transaksiId);
      if (response == null) return null;
      return KlaimDistributor.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<TransaksiServis> getTransaksiById(String id) async {
    final response = await _api.getTransaksiById(id);
    return TransaksiServis.fromJson(Map<String, dynamic>.from(response));
  }

  /// Download PDF Nota Pengantar Klaim dalam bentuk bytes.
  Future<Uint8List> downloadNotaPengantarKlaim(String transaksiId) async {
    return await _api.downloadNotaPengantarKlaim(transaksiId);
  }

  // --- Audit Log ---
  Future<List<ServisAuditLog>> getAuditLogs(String transaksiId) async {
    final list = await _api.getAuditLogTransaksi(transaksiId);
    return list.map((e) {
      return ServisAuditLog.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  // --- Notifikasi ---
  Future<String?> getWaLink(String transaksiId, String tipePesan) async {
    try {
      final response = await _api.getWaLink(transaksiId, tipePesan);
      final waLink = response['waLink']?.toString();
      if (waLink != null) {
        String updated = waLink.replaceAll('api.anandamcomputer.com', 'anandam.id');
        if (updated.contains('track/') && !updated.contains('track/servis/')) {
          updated = updated.replaceAll('track/', 'track/servis/');
        } else if (updated.contains('track%2F') && !updated.contains('track%2Fservis%2F')) {
          updated = updated.replaceAll('track%2F', 'track%2Fservis%2F');
        }
        return updated;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Garansi ---
  Future<PageableResponse<TransaksiServis>> getGaransiAktif({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.getGaransiAktif(
      search: search,
      page: page,
      size: size,
    );
    return PageableResponse.fromJson(response, TransaksiServis.fromJson);
  }

  Future<PageableResponse<TransaksiServis>> getGaransiExpired({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.getGaransiExpired(
      search: search,
      page: page,
      size: size,
    );
    return PageableResponse.fromJson(response, TransaksiServis.fromJson);
  }

  // --- Riwayat Pelanggan ---
  Future<RiwayatServisPelanggan> getRiwayatPelanggan(String pelangganId) async {
    final response = await _api.getRiwayatPelanggan(pelangganId);
    return RiwayatServisPelanggan.fromJson(response);
  }

  // --- Laporan Keuangan ---
  Future<LaporanKeuangan> getLaporanKeuangan(
      DateTime? start, DateTime? end) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final queryParams = <String, dynamic>{};

    if (start != null && end != null) {
      queryParams['start'] = dateFormat.format(start);
      queryParams['end'] = dateFormat.format(end);
    }

    final response = await _api.getLaporanKeuangan(queryParams);
    return LaporanKeuangan.fromJson(response);
  }

  Future<String> exportLaporanKeuangan(DateTime start, DateTime end) async {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final queryParams = <String, dynamic>{
      'start': dateFormat.format(start),
      'end': dateFormat.format(end),
    };

    final response = await _api.exportLaporanKeuangan(queryParams);

    // Ambil nama file dari header content-disposition
    final disposition = response.headers.value('content-disposition') ?? '';
    String filename = 'laporan-keuangan-servis.csv';
    final filenameMatch = RegExp(r'filename="?(.+?)"?$').firstMatch(disposition);
    if (filenameMatch != null) {
      filename = filenameMatch.group(1)!;
    }

    // Simpan file ke direktori download/temp
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    // Response data berupa bytes (kita pakai responseType: bytes)
    final bytes = response.data is List<int>
        ? response.data as List<int>
        : Uint8List.fromList(List<int>.from(response.data as List));
    await file.writeAsBytes(bytes);

    // Buka file dengan aplikasi default
    await OpenFilex.open(file.path);

    return file.path;
  }
}