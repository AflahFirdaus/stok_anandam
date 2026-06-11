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

    // Memetakan "oldValue" -> "newValue" menjadi keterangan yang mudah dibaca
    final String oldV = json['oldValue']?.toString() ?? '-';
    final String newV = json['newValue']?.toString() ?? '-';
    final String ket = '$oldV → $newV';

    return ServisAuditLog(
      // id: json['id'], // Jika tidak ada id di API, biarkan null
      entitas: json['tableName']?.toString(), // Peta ke entitas
      aksi: json['fieldName']?.toString() ?? 'UPDATE', // Peta ke aksi/field
      keterangan: ket,
      createdAt: json['changedAt']?.toString(),
      karyawanNama: kNama,
      karyawanRole: '-', // Tidak ada di API, beri nilai default
      catatanInternal: null,
      catatanPublik: null,
    );
  }

  @override
  List<Object?> get props => [id, entitasId, aksi, createdAt];
}
