import 'package:equatable/equatable.dart';
import 'pelanggan_servis.dart';

class TransaksiServis extends Equatable {
  final String? id;
  final String? noServis;
  final String? trackingToken;
  final String? pelangganId;
  final PelangganServis? pelanggan;
  final String? namaPelanggan;
  final String? noTelepon;
  final String? jenisBarang;
  final String? merek;
  final String? modelSeri;
  final String? kelengkapan;
  final String? kerusakan;
  final double? dp;
  final double? estimasiBiaya;
  final String? statusTerkini;
  final String? kondisiServis;
  final String? ketTindakan;
  final String? namaPenerima;
  final String? namaTeknisi;
  final String? namaPenyerah;
  final String? tglTerima;
  final String? tglDitangani;
  final String? modelSeriBaru;
  final String? modelSeriLama;
  final String? tglAmbil;
  final String? pengambilNama;
  final String? durasiGaransi;
  final double? biayaFinal;
  final double? modalSparepart;
  final String? statusBayar;
  final String? tglJatuhTempo;
  final String? createdAt;
  final String? updatedAt;

  const TransaksiServis({
    this.id,
    this.noServis,
    this.trackingToken,
    this.pelangganId,
    this.pelanggan,
    this.namaPelanggan,
    this.noTelepon,
    this.jenisBarang,
    this.merek,
    this.modelSeri,
    this.kelengkapan,
    this.kerusakan,
    this.dp,
    this.estimasiBiaya,
    this.statusTerkini,
    this.kondisiServis,
    this.ketTindakan,
    this.namaPenerima,
    this.namaTeknisi,
    this.namaPenyerah,
    this.tglTerima,
    this.tglDitangani,
    this.tglAmbil,
    this.pengambilNama,
    this.modelSeriBaru,
    this.modelSeriLama,
    this.durasiGaransi,
    this.biayaFinal,
    this.modalSparepart,
    this.statusBayar,
    this.tglJatuhTempo,
    this.createdAt,
    this.updatedAt,
  });

  factory TransaksiServis.fromJson(Map<String, dynamic> json) {
    PelangganServis? parsedPelanggan;
    if (json['pelanggan'] != null && json['pelanggan'] is Map) {
      parsedPelanggan = PelangganServis.fromJson(json['pelanggan']);
    }

    // Extract nested names if available
    String? pPenerima = json['namaPenerima']?.toString();
    if (json['penerima'] != null && json['penerima'] is Map) {
      pPenerima = json['penerima']['nama']?.toString();
    }
    String? pTeknisi = json['namaTeknisi']?.toString();
    if (json['teknisi'] != null && json['teknisi'] is Map) {
      pTeknisi = json['teknisi']['nama']?.toString();
    }
    String? pPenyerah = json['namaPenyerah']?.toString();
    if (json['penyerah'] != null && json['penyerah'] is Map) {
      pPenyerah = json['penyerah']['nama']?.toString();
    }
    final status = json['statusTerkini']?.toString();
    final rawTglDitangani =
        json['tglDitangani']?.toString() ?? json['tanggalDitangani']?.toString();
    final fallbackTglDitangani =
        status == 'SEDANG_DIKERJAKAN' && pTeknisi?.isNotEmpty == true
            ? json['updatedAt']?.toString()
            : null;

    return TransaksiServis(
      id: json['id']?.toString(),
      noServis: json['noServis']?.toString(),
      trackingToken: json['trackingToken']?.toString(),
      pelangganId: json['pelangganId']?.toString(),
      pelanggan: parsedPelanggan,
      namaPelanggan: json['namaPelanggan']?.toString() ?? parsedPelanggan?.namaPelanggan,
      noTelepon: json['noTelepon']?.toString() ?? parsedPelanggan?.noTelepon,
      jenisBarang: json['jenisBarang']?.toString(),
      merek: json['merek']?.toString(),
      modelSeri: json['modelSeri']?.toString(),
      kelengkapan: json['kelengkapan']?.toString(),
      kerusakan: json['kerusakan']?.toString(),
      dp: json['dp'] != null ? (json['dp'] as num).toDouble() : null,
      estimasiBiaya: json['estimasiBiaya'] != null ? (json['estimasiBiaya'] as num).toDouble() : null,
      statusTerkini: status,
      kondisiServis: json['kondisiServis']?.toString(),
      ketTindakan: json['ketTindakan']?.toString(),
      modelSeriBaru: json['modelSeriBaru']?.toString(),
      modelSeriLama: json['modelSeriLama']?.toString(),
      namaPenerima: pPenerima,
      namaTeknisi: pTeknisi,
      namaPenyerah: pPenyerah,
      tglTerima: json['tglTerima']?.toString(),
      tglDitangani: rawTglDitangani ?? fallbackTglDitangani,
      tglAmbil: json['tglAmbil']?.toString(),
      pengambilNama: json['pengambilNama']?.toString(),
      durasiGaransi: json['durasiGaransi']?.toString(),
      biayaFinal: json['biayaFinal'] != null ? (json['biayaFinal'] as num).toDouble() : null,
      modalSparepart: json['modalSparepart'] != null ? (json['modalSparepart'] as num).toDouble() : null,
      statusBayar: json['statusBayar']?.toString(),
      tglJatuhTempo: json['tglJatuhTempo']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJsonCreate({String tipeNota = 'SERVIS'}) {
    return {
      if (pelangganId != null) 'pelangganId': pelangganId,
      if (jenisBarang != null) 'jenisBarang': jenisBarang,
      if (merek != null) 'merek': merek,
      if (modelSeri != null) 'modelSeri': modelSeri,
      if (kelengkapan != null) 'kelengkapan': kelengkapan,
      if (kerusakan != null) 'kerusakan': kerusakan,
      if (dp != null) 'dp': dp,
      if (estimasiBiaya != null) 'estimasiBiaya': estimasiBiaya,
      'tipeNota': tipeNota,
    };
  }

  Map<String, dynamic> toJsonUpdateStatus({
    required String statusBaru,
    String? kondisiServis,
    String? ketTindakan,
    int? teknisiId,
    int? penyerahId,
    String? pengambilNama,
    String? durasiGaransi,
    double? biayaFinal,
    double? modalSparepart,
    String? statusBayar,
    String? tglJatuhTempo,
    String? catatanPublikLog,
  }) {
    return {
      'statusBaru': statusBaru,
      if (kondisiServis != null) 'kondisiServis': kondisiServis,
      if (ketTindakan != null) 'ketTindakan': ketTindakan,
      if (teknisiId != null) 'teknisiId': teknisiId,
      if (penyerahId != null) 'penyerahId': penyerahId,
      if (pengambilNama != null) 'pengambilNama': pengambilNama,
      if (durasiGaransi != null) 'durasiGaransi': durasiGaransi,
      if (biayaFinal != null) 'biayaFinal': biayaFinal,
      if (modalSparepart != null) 'modalSparepart': modalSparepart,
      if (statusBayar != null) 'statusBayar': statusBayar,
      if (tglJatuhTempo != null) 'tglJatuhTempo': tglJatuhTempo,
      if (catatanPublikLog != null) 'catatanPublikLog': catatanPublikLog,
    };
  }

  @override
  List<Object?> get props => [
        id,
        noServis,
        trackingToken,
        statusTerkini,
      ];
}
