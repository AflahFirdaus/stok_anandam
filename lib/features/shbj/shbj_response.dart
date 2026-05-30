class ShbjResponse {
  final int? id;
  final String? uraianKelompokBarang;
  final String? uraianBarang;
  final String? spesifikasi;
  final String? satuan;
  final String? hargaSatuan;

  ShbjResponse({
    this.id,
    this.uraianKelompokBarang,
    this.uraianBarang,
    this.spesifikasi,
    this.satuan,
    this.hargaSatuan,
  });

  factory ShbjResponse.fromJson(Map<String, dynamic> json) {
    return ShbjResponse(
      id: json['id'] as int?,
      uraianKelompokBarang: json['uraianKelompokBarang']?.toString(),
      uraianBarang: json['uraianBarang']?.toString(),
      spesifikasi: json['spesifikasi']?.toString(),
      satuan: json['satuan']?.toString(),
      hargaSatuan: json['hargaSatuan']?.toString(),
    );
  }
}