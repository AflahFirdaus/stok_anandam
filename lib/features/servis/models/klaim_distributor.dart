import 'package:equatable/equatable.dart';
import 'transaksi_servis.dart';

class KlaimDistributor extends Equatable {
  final String? id;
  final TransaksiServis? transaksi;
  final String? namaDistributor;
  final String? alamatDistributor;
  final String? tanggalKirim;
  final String? tanggalKembali;
  final String? resiPengiriman;
  final double? biayaKlaim;
  final String? createdAt;
  final String? updatedAt;

  const KlaimDistributor({
    this.id,
    this.transaksi,
    this.namaDistributor,
    this.alamatDistributor,
    this.tanggalKirim,
    this.tanggalKembali,
    this.resiPengiriman,
    this.biayaKlaim,
    this.createdAt,
    this.updatedAt,
  });

  factory KlaimDistributor.fromJson(Map<String, dynamic> json) {
    TransaksiServis? parsedTransaksi;
    if (json['transaksi'] != null && json['transaksi'] is Map) {
      parsedTransaksi = TransaksiServis.fromJson(json['transaksi']);
    }

    return KlaimDistributor(
      id: json['id']?.toString(),
      transaksi: parsedTransaksi,
      namaDistributor: json['namaDistributor']?.toString(),
      alamatDistributor: json['alamatDistributor']?.toString(),
      tanggalKirim: json['tanggalKirim']?.toString(),
      tanggalKembali: json['tanggalKembali']?.toString(),
      resiPengiriman: json['resiPengiriman']?.toString(),
      biayaKlaim: json['biayaKlaim'] != null
          ? (json['biayaKlaim'] as num).toDouble()
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      if (namaDistributor != null) 'namaDistributor': namaDistributor,
      if (alamatDistributor != null) 'alamatDistributor': alamatDistributor,
      if (resiPengiriman != null) 'resiPengiriman': resiPengiriman,
      if (biayaKlaim != null) 'biayaKlaim': biayaKlaim,
    };
  }

  Map<String, dynamic> toJsonUpdateStatus({
    required String statusBaru,
    String? catatanInternal,
    String? catatanPublik,
    String? resiPengiriman,
  }) {
    return {
      'statusBaru': statusBaru,
      if (catatanInternal != null) 'catatanInternal': catatanInternal,
      if (catatanPublik != null) 'catatanPublik': catatanPublik,
      if (resiPengiriman != null) 'resiPengiriman': resiPengiriman,
    };
  }

  @override
  List<Object?> get props => [
        id,
        namaDistributor,
        resiPengiriman,
      ];
}
