import 'package:equatable/equatable.dart';

/// Model untuk data kunjungan canvas dari GET /api/v1/data-canvasing
class DataCanvasingItem extends Equatable {
  final String? id;
  final String? pelangganId;
  final String? namaInstansi;
  final String? tanggalLabel;
  final String? kunjungan;
  final String? keterangan;
  final String? catatan;

  const DataCanvasingItem({
    this.id,
    this.pelangganId,
    this.namaInstansi,
    this.tanggalLabel,
    this.kunjungan,
    this.keterangan,
    this.catatan,
  });

  factory DataCanvasingItem.fromJson(Map<String, dynamic> json) {
    return DataCanvasingItem(
      id: json['id']?.toString(),
      pelangganId: json['pelangganId']?.toString() ??
          json['canvasingId']?.toString(),
      namaInstansi: json['namaInstansi']?.toString() ??
          (json['canvasing'] is Map
              ? (json['canvasing'] as Map)['namaInstansi']?.toString()
              : null),
      tanggalLabel:
          json['tanggalLabel']?.toString() ?? json['tanggal']?.toString(),
      kunjungan:
          json['kunjungan']?.toString() ?? json['canvasVisit']?.toString(),
      keterangan: json['keterangan']?.toString(),
      catatan: json['catatan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pelangganId': pelangganId,
        'namaInstansi': namaInstansi,
        'tanggalLabel': tanggalLabel,
        'kunjungan': kunjungan,
        'keterangan': keterangan,
        'catatan': catatan,
      };

  @override
  List<Object?> get props => [
        id,
        pelangganId,
        namaInstansi,
        tanggalLabel,
        kunjungan,
        keterangan,
        catatan,
      ];
}
