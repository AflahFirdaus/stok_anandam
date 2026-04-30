import 'package:equatable/equatable.dart';

enum RequestDeliveryStatus {
  DRAFT,
  MENUNGGU_GUDANG,
  MENUNGGU_PENGIRIMAN,
  DALAM_PENGIRIMAN,
  SELESAI,
  DIBATALKAN
}

class RequestDelivery extends Equatable {
  final int id;
  final String nomorRequest;
  final String receiverName;
  final String? receiverPhone;
  final String? alamatLengkap;
  final String? alamatMaps;
  final String? keterangan;
  final RequestDeliveryStatus status;
  final int? creatorId;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? penjadwalanId;
  final bool isUrgen;

  const RequestDelivery({
    required this.id,
    required this.nomorRequest,
    required this.receiverName,
    this.receiverPhone,
    this.alamatLengkap,
    this.alamatMaps,
    this.keterangan,
    required this.status,
    this.creatorId,
    this.creatorName,
    this.createdAt,
    this.updatedAt,
    this.penjadwalanId,
    this.isUrgen = false,
  });

  factory RequestDelivery.fromJson(Map<String, dynamic> json) {
    return RequestDelivery(
      id: json['id'] as int,
      nomorRequest: json['nomorRequest'] as String,
      receiverName: json['receiverName'] as String,
      receiverPhone: json['receiverPhone'] as String?,
      alamatLengkap: json['alamatLengkap'] as String?,
      alamatMaps: json['alamatMaps'] as String?,
      keterangan: json['keterangan'] as String?,
      status: _parseStatus(json['status'] as String),
      creatorId: json['creatorId'] as int?,
      creatorName: json['creatorName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      penjadwalanId: json['penjadwalanId'] as int?,
      isUrgen: json['isUrgen'] as bool? ?? false,
    );
  }

  static RequestDeliveryStatus _parseStatus(String status) {
    return RequestDeliveryStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => RequestDeliveryStatus.MENUNGGU_GUDANG,
    );
  }

  @override
  List<Object?> get props => [id, nomorRequest, receiverName, status];
}
