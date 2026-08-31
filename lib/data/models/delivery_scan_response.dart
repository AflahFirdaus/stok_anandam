class DeliveryScanResponse {
  final String memoId;
  final String nomorMemo;
  final int penjadwalanId;
  final String? alamatLengkap;
  final String? alamatMaps;
  final String? namaPenerima;
  final String? noHpPenerima;
  final String pesan;

  const DeliveryScanResponse({
    required this.memoId,
    required this.nomorMemo,
    required this.penjadwalanId,
    this.alamatLengkap,
    this.alamatMaps,
    this.namaPenerima,
    this.noHpPenerima,
    required this.pesan,
  });

  factory DeliveryScanResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryScanResponse(
      memoId: json['memoId']?.toString() ?? '',
      nomorMemo: json['nomorMemo']?.toString() ?? '',
      penjadwalanId: int.tryParse(json['penjadwalanId']?.toString() ?? '0') ?? 0,
      alamatLengkap: json['alamatLengkap']?.toString(),
      alamatMaps: json['alamatMaps']?.toString(),
      namaPenerima: json['namaPenerima']?.toString(),
      noHpPenerima: json['noHpPenerima']?.toString(),
      pesan: json['pesan']?.toString() ?? '',
    );
  }
}
