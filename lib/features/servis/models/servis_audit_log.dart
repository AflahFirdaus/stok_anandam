import 'package:equatable/equatable.dart';

class ServisAuditLog extends Equatable {
  final int? id;
  final String? entitas;
  final String? entitasId;
  final String? aksi;
  final String? keterangan;
  final String? dataSebelum;
  final String? dataSesudah;
  final String? catatanInternal;
  final String? catatanPublik;
  final String? karyawanNama;
  final String? karyawanRole;
  final String? createdAt;

  const ServisAuditLog({
    this.id,
    this.entitas,
    this.entitasId,
    this.aksi,
    this.keterangan,
    this.dataSebelum,
    this.dataSesudah,
    this.catatanInternal,
    this.catatanPublik,
    this.karyawanNama,
    this.karyawanRole,
    this.createdAt,
  });

  factory ServisAuditLog.fromJson(Map<String, dynamic> json) {
    // Memetakan struktur API "changedBy" ke karyawanNama
    final String kNama = json['changedBy']?.toString() ?? 'Sistem';

    // Ambil fieldName sebagai aksi (bisa berupa "status_terkini" atau "CREATE_NOTA_SERVIS")
    final String fieldName = json['fieldName']?.toString() ?? 'UPDATE';
    final String tableName = json['tableName']?.toString() ?? '';

    // Tentukan tipe aksi yang lebih deskriptif
    String aksiLabel;
    if (fieldName == 'CREATE_NOTA_SERVIS') {
      aksiLabel = 'PEMBUATAN NOTA';
    } else if (fieldName == 'CREATE_KLAIM_DISTRIBUTOR') {
      aksiLabel = 'PENGAJUAN KLAIM';
    } else if (fieldName == 'UPDATE_KLAIM_STATUS') {
      aksiLabel = 'STATUS KLAIM';
    } else if (fieldName == 'EDIT_NOTA_SERVIS') {
      aksiLabel = 'EDIT NOTA';
    } else if (fieldName == 'status_terkini') {
      aksiLabel = 'PERUBAHAN STATUS';
    } else if (fieldName == 'model_seri') {
      aksiLabel = 'PERUBAHAN SN';
    } else {
      aksiLabel = fieldName.replaceAll('_', ' ').toUpperCase();
    }

    // Untuk CREATE_NOTA_SERVIS, oldValue berisi "NOTA_SERVIS_DIBUAT" dan newValue berisi deskripsi lengkap
    // Untuk field-level change, oldValue -> newValue
    final String oldV = json['oldValue']?.toString() ?? '-';
    final String newV = json['newValue']?.toString() ?? '-';

    String keterangan;
    if (fieldName == 'CREATE_NOTA_SERVIS') {
      // newValue berisi deskripsi lengkap pembuatan nota
      keterangan = newV;
    } else if (fieldName == 'status_terkini') {
      keterangan = 'Status berubah: $oldV → $newV';
    } else if (fieldName == 'model_seri') {
      keterangan = 'Serial Number: $oldV → $newV';
    } else {
      keterangan = '$oldV → $newV';
    }

    return ServisAuditLog(
      entitas: tableName,
      aksi: aksiLabel,
      keterangan: keterangan,
      createdAt: json['changedAt']?.toString(),
      karyawanNama: kNama,
      karyawanRole: '-',
      dataSebelum: oldV,
      dataSesudah: newV,
      catatanInternal: null,
      catatanPublik: null,
    );
  }

  /// Helper untuk mendapatkan ikon berdasarkan tipe aksi
  String get actionIcon {
    switch (aksi) {
      case 'PEMBUATAN NOTA':
        return 'add_circle';
      case 'PERUBAHAN STATUS':
        return 'swap_horiz';
      case 'PERUBAHAN SN':
        return 'qr_code';
      default:
        return 'edit_note';
    }
  }

  @override
  List<Object?> get props => [id, entitasId, aksi, createdAt];
}
