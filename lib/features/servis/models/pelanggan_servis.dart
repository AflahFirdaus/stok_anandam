import 'package:equatable/equatable.dart';

class PelangganServis extends Equatable {
  final String? id;
  final String? namaPelanggan;
  final String? kategori;
  final String? noTelepon;
  final String? noWhatsapp;
  final String? alamat;
  final String? createdAt;
  final String? updatedAt;

  const PelangganServis({
    this.id,
    this.namaPelanggan,
    this.kategori,
    this.noTelepon,
    this.noWhatsapp,
    this.alamat,
    this.createdAt,
    this.updatedAt,
  });

  factory PelangganServis.fromJson(Map<String, dynamic> json) {
    return PelangganServis(
      id: json['id']?.toString(),
      namaPelanggan: json['namaPelanggan']?.toString(),
      kategori: json['kategori']?.toString(),
      noTelepon: json['noTelepon']?.toString(),
      noWhatsapp: json['noWhatsapp']?.toString(),
      alamat: json['alamat']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (namaPelanggan != null) 'namaPelanggan': namaPelanggan,
      if (kategori != null) 'kategori': kategori,
      if (noTelepon != null) 'noTelepon': noTelepon,
      if (noWhatsapp != null) 'noWhatsapp': noWhatsapp,
      if (alamat != null) 'alamat': alamat,
    };
  }

  @override
  List<Object?> get props => [
        id,
        namaPelanggan,
        kategori,
        noTelepon,
        noWhatsapp,
        alamat,
        createdAt,
        updatedAt,
      ];
}
