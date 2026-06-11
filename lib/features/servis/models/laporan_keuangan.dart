class LaporanKeuangan {
  final String periode;
  final int totalTransaksiServis;
  final double totalOmzetServis;
  final double totalModalSparepart;
  final double labaBersihServis;

  LaporanKeuangan({
    required this.periode,
    required this.totalTransaksiServis,
    required this.totalOmzetServis,
    required this.totalModalSparepart,
    required this.labaBersihServis,
  });

  factory LaporanKeuangan.fromJson(Map<String, dynamic> json) {
    return LaporanKeuangan(
      periode: json['periode']?.toString() ?? '-',
      totalTransaksiServis: json['totalTransaksiServis'] ?? 0,
      totalOmzetServis: (json['totalOmzetServis'] ?? 0).toDouble(),
      totalModalSparepart: (json['totalModalSparepart'] ?? 0).toDouble(),
      labaBersihServis: (json['labaBersihServis'] ?? 0).toDouble(),
    );
  }
}