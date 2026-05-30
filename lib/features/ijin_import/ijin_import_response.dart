/// Model Ijin Import Response
class IjinImportResponse {
  final int? no;
  final String? namaBarang;
  final String? spesifikasi;
  final String? keterangan;

  IjinImportResponse({
    this.no,
    this.namaBarang,
    this.spesifikasi,
    this.keterangan,
  });

  factory IjinImportResponse.fromJson(Map<String, dynamic> json) {
    return IjinImportResponse(
      no: int.tryParse(json['no']?.toString() ?? ''),
      namaBarang: json['namaBarang']?.toString(),
      spesifikasi: json['spesifikasi']?.toString(),
      keterangan: json['keterangan']?.toString(),
    );
  }
}