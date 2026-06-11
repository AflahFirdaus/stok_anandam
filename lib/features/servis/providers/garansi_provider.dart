import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaksi_servis.dart';
import '../repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';

class GaransiProvider extends ChangeNotifier {
  final ServisRepository _repository = getIt<ServisRepository>();

  List<TransaksiServis> _garansiAktif = [];
  List<TransaksiServis> get garansiAktif => _garansiAktif;

  List<TransaksiServis> _garansiExpired = [];
  List<TransaksiServis> get garansiExpired => _garansiExpired;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _selectedTab = 0; // 0 = Aktif, 1 = Expired
  int get selectedTab => _selectedTab;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Pagination state
  int _currentPageAktif = 0;
  int _totalPagesAktif = 0;
  bool _hasNextAktif = false;

  int _currentPageExpired = 0;
  int _totalPagesExpired = 0;
  bool _hasNextExpired = false;

  bool get hasNext =>
      _selectedTab == 0 ? _hasNextAktif : _hasNextExpired;
  int get currentPage =>
      _selectedTab == 0 ? _currentPageAktif : _currentPageExpired;
  int get totalPages =>
      _selectedTab == 0 ? _totalPagesAktif : _totalPagesExpired;

  Timer? _debounce;
  Timer? _countdownTimer;

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  /// Debounced search
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchGaransi(resetPage: true);
    });
  }

  Future<void> fetchGaransi({bool resetPage = false}) async {
    if (resetPage) {
      _currentPageAktif = 0;
      _currentPageExpired = 0;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm =
          _searchQuery.isEmpty ? null : _searchQuery;

      // Fetch both in parallel
      final [aktif, expired] = await Future.wait([
        _repository.getGaransiAktif(
          search: searchTerm,
          page: _currentPageAktif,
          size: 20,
        ),
        _repository.getGaransiExpired(
          search: searchTerm,
          page: _currentPageExpired,
          size: 20,
        ),
      ]);

      if (resetPage || _currentPageAktif == 0) {
        _garansiAktif = aktif.content;
      } else {
        _garansiAktif.addAll(aktif.content);
      }
      _totalPagesAktif = aktif.totalPages;
      _hasNextAktif = aktif.hasNext;

      if (resetPage || _currentPageExpired == 0) {
        _garansiExpired = expired.content;
      } else {
        _garansiExpired.addAll(expired.content);
      }
      _totalPagesExpired = expired.totalPages;
      _hasNextExpired = expired.hasNext;
    } catch (e) {
      _errorMessage = 'Gagal memuat data garansi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int page) async {
    if (_selectedTab == 0) {
      if (page < 0 || (_totalPagesAktif > 0 && page >= _totalPagesAktif))
        return;
      _currentPageAktif = page;
    } else {
      if (page < 0 || (_totalPagesExpired > 0 && page >= _totalPagesExpired))
        return;
      _currentPageExpired = page;
    }
    await fetchGaransi();
  }

  /// Start a periodic timer to update countdown every minute
  void startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      notifyListeners();
    });
  }

  void stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    stopCountdown();
    _debounce?.cancel();
    super.dispose();
  }

  /// Calculate remaining days from tglJatuhTempo
  static int? getSisaHari(String? tglJatuhTempo) {
    if (tglJatuhTempo == null || tglJatuhTempo.isEmpty) return null;
    try {
      final jatuhTempo = DateTime.tryParse(tglJatuhTempo);
      if (jatuhTempo == null) return null;
      final now = DateTime.now();
      return jatuhTempo.difference(now).inDays;
    } catch (_) {
      return null;
    }
  }

  /// Get formatted countdown string
  static String getCountdownString(String? tglJatuhTempo) {
    final sisaHari = getSisaHari(tglJatuhTempo);
    if (sisaHari == null) return '-';
    if (sisaHari < 0) return 'Kedaluwarsa';
    if (sisaHari == 0) return 'Hari terakhir!';
    if (sisaHari == 1) return '1 hari lagi';
    return '$sisaHari hari lagi';
  }
}