class MapDelivery {
  final String idMemo;
  final String nomorMemo;
  final String customerName;
  final String desa;
  final String kecamatan;
  final String kabupaten;
  final String kodePos;
  final double? lat;
  final double? lng;
  final String status;
  final String memoStatus;
  final String? mapUrl;
  final String senderName;
  final String alamatLengkap;
  final bool isUrgen;
  final bool isManual;
  final bool isExpedition;

  MapDelivery({
    required this.idMemo,
    required this.nomorMemo,
    required this.customerName,
    required this.desa,
    required this.kecamatan,
    required this.kabupaten,
    required this.kodePos,
    this.lat,
    this.lng,
    required this.status,
    required this.memoStatus,
    this.mapUrl,
    this.senderName = '',
    this.alamatLengkap = '',
    this.isUrgen = false,
    this.isManual = false,
    this.isExpedition = false,
  });

  factory MapDelivery.fromJson(Map<String, dynamic> json) {
    return MapDelivery(
      idMemo: json['idMemo'] ?? '',
      nomorMemo: json['nomorMemo'] ?? '',
      customerName: json['customerName'] ?? '',
      desa: json['desa'] ?? '',
      kecamatan: json['kecamatan'] ?? '',
      kabupaten: json['kabupaten'] ?? '',
      kodePos: json['kodePos'] ?? '',
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      status: json['status'] ?? '',
      memoStatus: json['memoStatus'] ?? '',
      mapUrl: json['mapUrl'],
      senderName: json['senderName'] ?? '',
      alamatLengkap: json['alamatLengkap'] ?? '',
      isUrgen: json['isUrgen'] == true,
      isManual: json['isManual'] == true,
      isExpedition: json['isExpedition'] == true,
    );
  }
}
