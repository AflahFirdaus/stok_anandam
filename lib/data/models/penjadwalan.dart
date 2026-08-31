import 'package:equatable/equatable.dart';

enum TipeTugas { PENGIRIMAN, TEKNISI, PENGAMBILAN, DROP_OFF_EKSPEDISI }

enum StatusJadwal { MENUNGGU_KONFIRMASI, DIJADWALKAN, DALAM_PENGIRIMAN, SELESAI, BATAL }

class PenjadwalanResponse extends Equatable {
  final int? id;
  final String? memoId;
  final String? nomorMemo;
  final int? requestDeliveryId;
  final String? nomorRequest;
  final String tipeTugas;
  final String statusJadwal;
  final String? alamatLengkap;
  final String? alamatMaps;
  final int? idKodepos;
  final String? estimasiWaktu;
  final String? catatan;
  final String? namaPenerima;
  final String? fotoBukti;
  final String? catatanOperasional;
  final String? tanggalJadwal;
  final int? personelId;
  final String? personelName;
  final String? personelRole;
  final String? kodePos;
  final bool? isUrgen;
  final String? marketingName;
  final String? kecamatan;
  final String? desaKelurahan;
  final String? kabupatenKota;
  final String? manualCustomerName;
  final String? manualNoHp;
  final bool? isExpedition;
  final String? manifestId;
  final List<String>? manifestResiList;
  final double? latitude;
  final double? longitude;
  final String? updatedAt;

  const PenjadwalanResponse({
    this.id,
    this.memoId,
    this.nomorMemo,
    this.requestDeliveryId,
    this.nomorRequest,
    required this.tipeTugas,
    required this.statusJadwal,
    this.alamatLengkap,
    this.alamatMaps,
    this.idKodepos,
    this.estimasiWaktu,
    this.catatan,
    this.namaPenerima,
    this.fotoBukti,
    this.catatanOperasional,
    this.tanggalJadwal,
    this.personelId,
    this.personelName,
    this.personelRole,
    this.kodePos,
    this.isUrgen,
    this.marketingName,
    this.kecamatan,
    this.desaKelurahan,
    this.kabupatenKota,
    this.manualCustomerName,
    this.manualNoHp,
    this.isExpedition,
    this.manifestId,
    this.manifestResiList,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  factory PenjadwalanResponse.fromJson(Map<String, dynamic> json) {
    return PenjadwalanResponse(
      id: json['id'] as int?,
      memoId: json['memoId']?.toString(),
      nomorMemo: json['nomorMemo']?.toString(),
      requestDeliveryId: json['requestDeliveryId'] as int?,
      nomorRequest: json['nomorRequest']?.toString(),
      tipeTugas: json['tipeTugas']?.toString() ?? 'PENGIRIMAN',
      statusJadwal: json['statusJadwal']?.toString() ?? 'MENUNGGU_KONFIRMASI',
      alamatLengkap: json['alamatLengkap']?.toString(),
      alamatMaps: json['alamatMaps']?.toString(),
      idKodepos: json['idKodepos'] as int?,
      estimasiWaktu: json['estimasiWaktu']?.toString(),
      catatan: json['catatan']?.toString(),
      namaPenerima: json['namaPenerima']?.toString(),
      fotoBukti: json['fotoBukti']?.toString(),
      catatanOperasional: json['catatanOperasional']?.toString(),
      tanggalJadwal: json['tanggalJadwal']?.toString(),
      personelId: json['personelId'] as int?,
      personelName: json['personelName']?.toString(),
      personelRole: json['personelRole']?.toString(),
      kodePos: json['kodePos']?.toString(),
      isUrgen: json['isUrgen'] as bool?,
      marketingName: json['marketingName']?.toString(),
      kecamatan: json['kecamatan']?.toString(),
      desaKelurahan: json['desaKelurahan']?.toString(),
      kabupatenKota: json['kabupatenKota']?.toString(),
      manualCustomerName: json['manualCustomerName']?.toString(),
      manualNoHp: json['manualNoHp']?.toString(),
      isExpedition: json['isExpedition'] as bool?,
      manifestId: json['manifestId']?.toString(),
      manifestResiList: (json['manifestResiList'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        memoId,
        nomorMemo,
        requestDeliveryId,
        nomorRequest,
        tipeTugas,
        statusJadwal,
        alamatLengkap,
        alamatMaps,
        idKodepos,
        estimasiWaktu,
        catatan,
        namaPenerima,
        fotoBukti,
        catatanOperasional,
        tanggalJadwal,
        personelId,
        personelName,
        personelRole,
        kodePos,
        isUrgen,
        marketingName,
        manualCustomerName,
        manualNoHp,
        isExpedition,
        manifestId,
        manifestResiList,
        latitude,
        longitude,
        updatedAt,
      ];
}
