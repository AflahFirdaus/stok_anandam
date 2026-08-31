import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// API layer untuk laporan omzet & margin per marketing.
/// Memakai Dio yang sama (baseUrl + auth) dari injection.
///
/// Mendukung rentang tanggal eksplisit (startDate & endDate) untuk mengambil
/// seluruh periode dalam SATU request (ringan untuk server). Jika rentang
/// tidak diberikan, backend akan menghitung rentang dari `period` + `date`.
class LaporanMarketingApi {
  LaporanMarketingApi(this._dio);

  final Dio _dio;
  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  /// Ringkasan omzet per marketing.
  /// [date] tanggal acuan periode; jika null -> hari ini (dipakai saat rentang kosong).
  /// [startDate] & [endDate] rentang inklusif (menggantikan period+date bila diberikan).
  /// [empCode] daftar kode marketing (opsional). null -> semua marketing.
  Future<Map<String, dynamic>> getOverview({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? empCodes,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/sales/reports/marketing/overview',
      queryParameters: _params(period, date, startDate, endDate, empCodes),
    );
    return _dataOf(response);
  }

  /// Detail nota untuk marketing pada periode (rentang).
  Future<Map<String, dynamic>> getNotas({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? empCode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/sales/reports/marketing/notas',
      queryParameters:
          _params(period, date, startDate, endDate,
              empCode == null ? null : [empCode]),
    );
    return _dataOf(response);
  }

  /// Detail per barang (item) untuk marketing pada periode (rentang).
  Future<Map<String, dynamic>> getItems({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? empCode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/sales/reports/marketing/items',
      queryParameters:
          _params(period, date, startDate, endDate,
              empCode == null ? null : [empCode]),
    );
    return _dataOf(response);
  }

  /// Titik grafik timeline agregat (sangat ringan — hanya N baris per period).
  Future<Map<String, dynamic>> getTimeline({
    required String period,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? empCode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/sales/reports/marketing/timeline',
      queryParameters:
          _params(period, date, startDate, endDate,
              empCode == null ? null : [empCode]),
    );
    return _dataOf(response);
  }

  /// Query parameter yang dipakai ketiga endpoint.
  Map<String, dynamic> _params(String period, DateTime? date, DateTime? startDate,
      DateTime? endDate, List<String>? empCodes) {
    return <String, dynamic>{
      'period': period,
      if (date != null) 'date': _dateFmt.format(date),
      if (startDate != null) 'startDate': _dateFmt.format(startDate),
      if (endDate != null) 'endDate': _dateFmt.format(endDate),
      // empCode dikirim sebagai daftar koma; jika kosong -> semua marketing.
      if (empCodes != null && empCodes.isNotEmpty)
        'empCode': empCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).join(','),
    };
  }

  /// Ambil bagian `data` dari envelope WebResponse backend.
  Map<String, dynamic> _dataOf(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return const {};
    final data = body['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }
}
