import 'package:equatable/equatable.dart';

/// Detail singkat setiap transaksi servis dalam riwayat.
class ItemRiwayatServis extends Equatable {
  final String id;
  final String noServis;
  final String? jenisBarang;
  final String? merek;
  final String? modelSeri;
  final String? kerusakan;
  final double? biayaFinal;
  final String? statusTerkini;
  final String? tglTerima;
  final String? tglAmbil;
  final String? createdAt;

  const ItemRiwayatServis({
    required this.id,
    required this.noServis,
    this.jenisBarang,
    this.merek,
    this.modelSeri,
    this.kerusakan,
    this.biayaFinal,
    this.statusTerkini,
    this.tglTerima,
    this.tglAmbil,
    this.createdAt,
  });

  factory ItemRiwayatServis.fromJson(Map<String, dynamic> json) {
    return ItemRiwayatServis(
      id: json['id']?.toString() ?? '',
      noServis: json['noServis']?.toString() ?? '',
      jenisBarang: json['jenisBarang']?.toString(),
      merek: json['merek']?.toString(),
      modelSeri: json['modelSeri']?.toString(),
      kerusakan: json['kerusakan']?.toString(),
      biayaFinal:
          json['biayaFinal'] != null ? (json['biayaFinal'] as num).toDouble() : null,
      statusTerkini: json['statusTerkini']?.toString(),
      tglTerima: json['tglTerima']?.toString(),
      tglAmbil: json['tglAmbil']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        noServis,
        jenisBarang,
        merek,
        modelSeri,
        kerusakan,
        biayaFinal,
        statusTerkini,
        tglTerima,
        tglAmbil,
        createdAt,
      ];
}

/// Response lengkap riwayat servis seorang pelanggan.
class RiwayatServisPelanggan extends Equatable {
  final String pelangganId;
  final String? namaPelanggan;
  final String? noTelepon;
  final String? noWhatsapp;
  final String? alamat;
  final int totalServis;
  final double totalBiayaFinal;
  final double totalPendapatanBersih;
  final List<ItemRiwayatServis> daftarServis;

  const RiwayatServisPelanggan({
    required this.pelangganId,
    this.namaPelanggan,
    this.noTelepon,
    this.noWhatsapp,
    this.alamat,
    this.totalServis = 0,
    this.totalBiayaFinal = 0,
    this.totalPendapatanBersih = 0,
    this.daftarServis = const [],
  });

  factory RiwayatServisPelanggan.fromJson(Map<String, dynamic> json) {
    final rawList = json['daftarServis'] as List<dynamic>? ?? [];
    return RiwayatServisPelanggan(
      pelangganId: json['pelangganId']?.toString() ?? '',
      namaPelanggan: json['namaPelanggan']?.toString(),
      noTelepon: json['noTelepon']?.toString(),
      noWhatsapp: json['noWhatsapp']?.toString(),
      alamat: json['alamat']?.toString(),
      totalServis: json['totalServis'] as int? ?? 0,
      totalBiayaFinal:
          json['totalBiayaFinal'] != null
              ? (json['totalBiayaFinal'] as num).toDouble()
              : 0,
      totalPendapatanBersih:
          json['totalPendapatanBersih'] != null
              ? (json['totalPendapatanBersih'] as num).toDouble()
              : 0,
      daftarServis: rawList
          .map((e) => ItemRiwayatServis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        pelangganId,
        namaPelanggan,
        noTelepon,
        noWhatsapp,
        alamat,
        totalServis,
        totalBiayaFinal,
        totalPendapatanBersih,
        daftarServis,
      ];
}