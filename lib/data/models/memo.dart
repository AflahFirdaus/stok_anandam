/// Model untuk fitur Memo (PENDING Barang)
/// Berhubungan dengan MemoController di backend.
library;
// ignore_for_file: constant_identifier_names

import 'package:stok_anandam/data/models/penjadwalan.dart';

enum MemoStatus {
  DRAFT,
  MENUNGGU_PERSETUJUAN,
  DISETUJUI,
  DITOLAK,
  MENUNGGU_GUDANG,
  MENUNGGU_TEKNISI,
  PROSES_TEKNISI,
  BUFFER_ZONE,
  MENUNGGU_PENGIRIMAN,
  DALAM_PENGIRIMAN,
  DITERIMA_USER,
  TERKIRIM_SEBAGIAN,
  KENDALA_BARANG,
  MENUNGGU_NOTA,

  SELESAI,
  DIBATALKAN,
  DIJADWALKAN,
  PENDING,
  DELETED,
  MENUNGGU_EXPEDISI,
  MENUNGGU_KONFIRMASI_PICKUP;

  String get label {
    switch (this) {
      case MemoStatus.DRAFT:
        return 'DRAFT (Marketing)';
      case MemoStatus.MENUNGGU_PERSETUJUAN:
        return 'MENUNGGU ACC';
      case MemoStatus.DISETUJUI:
        return 'DISETUJUI';
      case MemoStatus.DITOLAK:
        return 'DITOLAK';
      case MemoStatus.MENUNGGU_GUDANG:
        return 'MENUNGGU GUDANG';
      case MemoStatus.MENUNGGU_NOTA:
        return 'MENUNGGU NOTA';

      case MemoStatus.MENUNGGU_TEKNISI:
        return 'MENUNGGU TEKNISI';
      case MemoStatus.PROSES_TEKNISI:
        return 'PROSES TEKNISI';
      case MemoStatus.BUFFER_ZONE:
        return 'BUFFER ZONE';
      case MemoStatus.MENUNGGU_PENGIRIMAN:
        return 'MENUNGGU PENGIRIMAN';
      case MemoStatus.DALAM_PENGIRIMAN:
        return 'DALAM PENGIRIMAN';
      case MemoStatus.DITERIMA_USER:
        return 'DITERIMA USER';
      case MemoStatus.TERKIRIM_SEBAGIAN:
        return 'TERKIRIM SEBAGIAN';
      case MemoStatus.KENDALA_BARANG:
        return 'KENDALA BARANG';
      case MemoStatus.SELESAI:
        return 'SELESAI';
      case MemoStatus.DIBATALKAN:
        return 'DIBATALKAN';
      case MemoStatus.DIJADWALKAN:
        return 'DIJADWALKAN';
      case MemoStatus.PENDING:
        return 'PENDING';
      case MemoStatus.DELETED:
        return 'DELETED';
      case MemoStatus.MENUNGGU_EXPEDISI:
        return 'MENUNGGU EXPEDISI';
      case MemoStatus.MENUNGGU_KONFIRMASI_PICKUP:
        return 'MENUNGGU KONFIRMASI (Admin/Mkt)';
    }
  }

  List<MemoStatus> get nextPossibleStatuses {
    switch (this) {
      case MemoStatus.DRAFT:
        return [MemoStatus.MENUNGGU_PERSETUJUAN];
      case MemoStatus.MENUNGGU_PERSETUJUAN:
        return [MemoStatus.DISETUJUI, MemoStatus.DITOLAK];
      case MemoStatus.DISETUJUI:
        return [MemoStatus.MENUNGGU_GUDANG, MemoStatus.MENUNGGU_NOTA];
      case MemoStatus.MENUNGGU_GUDANG:
        return [
          MemoStatus.MENUNGGU_TEKNISI,
          MemoStatus.MENUNGGU_PENGIRIMAN,
          MemoStatus.MENUNGGU_NOTA
        ];
      case MemoStatus.MENUNGGU_NOTA:
        return [MemoStatus.BUFFER_ZONE];
      case MemoStatus.MENUNGGU_TEKNISI:
        return [MemoStatus.PROSES_TEKNISI];
      case MemoStatus.PROSES_TEKNISI:
        return [MemoStatus.BUFFER_ZONE, MemoStatus.MENUNGGU_PENGIRIMAN];
      case MemoStatus.BUFFER_ZONE:
        return [MemoStatus.MENUNGGU_PENGIRIMAN];
      case MemoStatus.MENUNGGU_PENGIRIMAN:
        return [MemoStatus.DALAM_PENGIRIMAN];
      case MemoStatus.DALAM_PENGIRIMAN:
        return [
          MemoStatus.DITERIMA_USER,
          MemoStatus.TERKIRIM_SEBAGIAN,
          MemoStatus.KENDALA_BARANG
        ];
      case MemoStatus.DITERIMA_USER:
        return [MemoStatus.SELESAI];
      case MemoStatus.TERKIRIM_SEBAGIAN:
        return [MemoStatus.MENUNGGU_PENGIRIMAN, MemoStatus.SELESAI];
      case MemoStatus.KENDALA_BARANG:
        return [MemoStatus.MENUNGGU_GUDANG, MemoStatus.DIBATALKAN];
      case MemoStatus.PENDING:
        return [MemoStatus.MENUNGGU_PERSETUJUAN, MemoStatus.DIBATALKAN];
      default:
        // Fallback for others: allow to SELESAI or DIBATALKAN if not terminal
        if (this == MemoStatus.SELESAI ||
            this == MemoStatus.DIBATALKAN ||
            this == MemoStatus.DITOLAK) {
          return [];
        }
        return [MemoStatus.SELESAI, MemoStatus.DIBATALKAN];
    }
  }
}

class MemoItem {
  final int? id;
  final String? namaBarang;
  final num qty;
  final num hargaSatuan;
  final num subtotal;
  final String? status;
  final String? catatanGudang;
  final num qtyShipped;

  MemoItem({
    this.id,
    this.namaBarang,
    this.qty = 0,
    this.hargaSatuan = 0,
    this.subtotal = 0,
    this.status,
    this.catatanGudang,
    this.qtyShipped = 0,
  });

  num get qtyRemaining => qty - qtyShipped;

  factory MemoItem.fromJson(Map<String, dynamic> json) {
    num fromNum(dynamic v) {
      if (v is num) return v;
      return num.tryParse(v?.toString() ?? '0') ?? 0;
    }

    return MemoItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      namaBarang: json['namaBarang']?.toString(),
      qty: fromNum(json['qty']),
      hargaSatuan: fromNum(json['hargaSatuan']),
      subtotal: fromNum(json['subtotal']),
      status: json['status']?.toString(),
      catatanGudang: json['catatanGudang']?.toString(),
      qtyShipped: fromNum(json['qtyShipped']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'namaBarang': namaBarang,
        'qty': qty,
        'hargaSatuan': hargaSatuan,
        'subtotal': subtotal,
        'catatan': catatanGudang,
      };
}

class MemoLog {
  final int? id;
  final String? status;
  final DateTime? createdAt;
  final String? actorName;
  final String? keterangan;

  MemoLog({
    this.id,
    this.status,
    this.createdAt,
    this.actorName,
    this.keterangan,
  });

  factory MemoLog.fromJson(Map<String, dynamic> json) {
    return MemoLog(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      status: json['status']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      actorName: json['actorName']?.toString(),
      keterangan: json['keterangan']?.toString(),
    );
  }
}

class MemoDetail {
  final String? id;
  final List<MemoLog> logs;
  final String? nomorMemo;
  final int? customerId;
  final int? pelangganMybizId;
  final String? customerPhone;
  final String? customerName;
  final DateTime? tanggalMemo;
  final num totalHarga;
  final String? deskripsi;
  final String? nomorJl;

  final MemoStatus? statusAkhir;
  final bool isTeknisRequired;
  final bool isDeliveryRequired;
  final String? marketingName;
  final String? marketingUsername;
  final String? metodePembayaran;
  final String? memoType;
  final String? orderIdMarketplace;
  final String? resi;
  final String? ekspedisi;
  final String? subEkspedisi;
  final String? platform;
  final String? kodePos;
  final String? tempo;
  final String? creatorName;
  final String? creatorPhone;
  final String? marketingEmpCode;
  final String? buktiFoto;
  final String? buktiFotoUrl;
  final String? desaKelurahan;
  final String? kecamatan;
  final String? kabupatenKota;
  final String? opsiPengiriman;
  final String? tipeOngkir;
  final String? estimasiOngkir;
  final String? badanUsaha;
  final List<MemoItem> items;
  final List<PenjadwalanResponse> penjadwalanHistory;

  final String? revisedFromId;
  final String? revisedFromNomorMemo;

  MemoDetail({
    this.id,
    this.nomorMemo,
    this.customerId,
    this.pelangganMybizId,
    this.customerPhone,
    this.customerName,
    this.tanggalMemo,
    this.totalHarga = 0,
    this.deskripsi,
    this.nomorJl,
    this.statusAkhir,
    this.isTeknisRequired = false,
    this.isDeliveryRequired = false,
    this.marketingName,
    this.marketingUsername,
    this.marketingEmpCode,
    this.metodePembayaran,
    this.memoType,
    this.orderIdMarketplace,
    this.resi,
    this.ekspedisi,
    this.subEkspedisi,
    this.platform,
    this.kodePos,
    this.tempo,
    this.creatorName,
    this.creatorPhone,
    this.buktiFoto,
    this.buktiFotoUrl,
    this.desaKelurahan,
    this.kecamatan,
    this.kabupatenKota,
    this.opsiPengiriman,
    this.tipeOngkir,
    this.estimasiOngkir,
    this.badanUsaha,
    this.items = const [],
    this.logs = const [],
    this.penjadwalanHistory = const [],
    this.revisedFromId,
    this.revisedFromNomorMemo,
  });

  num get totalQty => items.fold(0, (sum, item) => sum + item.qty);

  bool get isMarketingDelivery {
    final bool hasMarketingInHistory = penjadwalanHistory.any((p) =>
        p.tipeTugas == 'PENGIRIMAN' &&
        (p.personelRole?.toUpperCase().contains('MARKETING') ?? false));
    if (hasMarketingInHistory) return true;

    return (opsiPengiriman ?? '').toUpperCase().contains('MARKETING');
  }

  String get deliveryMethodLabel {
    final String opsi = (opsiPengiriman ?? '').toUpperCase();

    // 1. Check Priority: Scheduling History
    final bool hasMarketingInHistory = penjadwalanHistory.any((p) =>
        p.tipeTugas == 'PENGIRIMAN' &&
        (p.personelRole?.toUpperCase().contains('MARKETING') ?? false));

    if (hasMarketingInHistory) return 'DIKIRIM MARKETING';

    final bool hasDeliveryInHistory = penjadwalanHistory.any((p) =>
        p.tipeTugas == 'PENGIRIMAN' &&
        !(p.personelRole?.toUpperCase().contains('MARKETING') ?? false));

    if (hasDeliveryInHistory) return 'DIKIRIM DELIVERY';

    // 2. Check Fallback: Initial Option (opsiPengiriman)
    if (opsi.contains('MARKETING')) return 'DIKIRIM MARKETING';
    if (opsi.contains('DRIVER')) return 'DIKIRIM DELIVERY';
    if (opsi.contains('DELIVERY')) return 'DIKIRIM DELIVERY';
    if (opsi.isNotEmpty && opsi != 'AMBIL DI TOKO') return 'DIKIRIM $opsi';

    return 'DIKIRIM DELIVERY';
  }

  factory MemoDetail.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    final logsList = json['logs'] as List<dynamic>?;
    final penjadwalanList = json['penjadwalanHistory'] as List<dynamic>?;

    return MemoDetail(
      id: json['id']?.toString(),
      nomorMemo: json['nomorMemo']?.toString(),
      customerId: json['customerId'] is int
          ? json['customerId'] as int
          : int.tryParse(json['customerId']?.toString() ?? ''),
      pelangganMybizId: json['pelangganMybizId'] is int
          ? json['pelangganMybizId'] as int
          : int.tryParse(json['pelangganMybizId']?.toString() ?? ''),
      customerPhone: json['customerPhone']?.toString(),
      customerName: json['customerName']?.toString(),
      tanggalMemo: json['tanggalMemo'] != null
          ? DateTime.tryParse(json['tanggalMemo'].toString())
          : null,
      totalHarga: (json['totalHarga'] as num?) ?? 0,
      deskripsi: json['deskripsi']?.toString(),
      nomorJl: json['nomorJl']?.toString(),
      statusAkhir: MemoStatus.values.firstWhere(
        (e) => e.name == json['statusAkhir'],
        orElse: () => MemoStatus.MENUNGGU_GUDANG,
      ),
      isTeknisRequired: json['isTeknisRequired'] == true,
      isDeliveryRequired: json['isDeliveryRequired'] == true,
      marketingName: json['marketingName']?.toString(),
      marketingUsername: json['marketingUsername']?.toString(),
      marketingEmpCode: json['marketingEmpCode']?.toString(),
      metodePembayaran: json['metodePembayaran']?.toString(),
      memoType: json['memoType']?.toString(),
      orderIdMarketplace: json['orderIdMarketplace']?.toString(),
      resi: json['resi']?.toString(),
      ekspedisi: json['ekspedisi']?.toString(),
      subEkspedisi: json['subEkspedisi']?.toString(),
      platform: json['platform']?.toString(),
      kodePos: json['kodePos']?.toString(),
      tempo: json['tempo']?.toString(),
      creatorName: json['creatorName']?.toString() ?? 'System',
      creatorPhone: json['creatorPhone']?.toString(),
      buktiFoto: json['buktiFoto']?.toString(),
      buktiFotoUrl: json['buktiFotoUrl']?.toString(),
      desaKelurahan: json['desaKelurahan']?.toString() ?? '',
      kecamatan: json['kecamatan']?.toString() ?? '',
      kabupatenKota: json['kabupatenKota']?.toString() ?? '',
      opsiPengiriman: json['opsiPengiriman']?.toString(),
      tipeOngkir: json['tipeOngkir']?.toString(),
      estimasiOngkir: json['estimasiOngkir']?.toString(),
      badanUsaha: json['badanUsaha']?.toString(),
      items: itemsList
              ?.map((e) => MemoItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      logs: logsList
              ?.map((e) => MemoLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      penjadwalanHistory: penjadwalanList
              ?.map((e) =>
                  PenjadwalanResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      revisedFromId: json['revisedFromId']?.toString(),
      revisedFromNomorMemo: json['revisedFromNomorMemo']?.toString(),
    );
  }
}

class EmployeeOption {
  final String empCode;
  final String empName;

  EmployeeOption({required this.empCode, required this.empName});

  factory EmployeeOption.fromJson(Map<String, dynamic> json) {
    return EmployeeOption(
      empCode: json['empCode']?.toString() ?? '',
      empName: json['empName']?.toString() ?? '',
    );
  }
}
