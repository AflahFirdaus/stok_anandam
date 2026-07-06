import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import '../models/transaksi_servis.dart';
import '../repositories/servis_repository.dart';

class KlaimProvider extends ChangeNotifier {
  final ServisRepository _repository = getIt<ServisRepository>();
  final CurrentUserStore _userStore = getIt<CurrentUserStore>();

  List<TransaksiServis> _klaimList = [];
  List<TransaksiServis> get klaimList => _klaimList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  // Pagination (client-side)
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasNext = false;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNext => _hasNext;

  Timer? _debounce;

  /// Semua data klaim dari backend (sebelum pagination client-side).
  List<TransaksiServis> _allKlaimList = [];

  /// Jumlah item per halaman client-side.
  static const int _pageSize = 20;

  /// Apakah user internal (bukan NOTA/kasir)
  bool get isInternalUser {
    final role = _userStore.userRole?.toUpperCase() ?? '';
    return role != 'NOTA';
  }

  /// Filter status berdasarkan tab yang dipilih.
  List<String> get _selectedStatuses {
    switch (_selectedTab) {
      case 0:
        return ['KLAIM_MENUNGGU_PENGIRIMAN', 'KLAIM_DIKIRIM', 'KLAIM_SUDAH_DIKIRIM', 'KLAIM_SUDAH_DIAMBIL'];
      case 1:
        return ['KLAIM_MENUNGGU_PENGIRIMAN'];
      case 2:
        return ['KLAIM_DIKIRIM', 'KLAIM_SUDAH_DIKIRIM'];
      case 3:
        return ['KLAIM_SUDAH_DIAMBIL'];
      default:
        return ['KLAIM_MENUNGGU_PENGIRIMAN'];
    }
  }

  void setSelectedTab(int index) {
    _selectedTab = index;
    _currentPage = 0;
    notifyListeners();
    fetchKlaim();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchKlaim(resetPage: true);
    });
  }

  /// Fetch SEMUA data klaim sekaligus (size besar per status),
  /// lalu sorting & pagination dilakukan client-side agar urutan global benar.
  Future<void> fetchKlaim({bool resetPage = false}) async {
    if (resetPage) _currentPage = 0;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm = _searchQuery.isEmpty ? null : _searchQuery;
      final statuses = _selectedStatuses;

      // Ambil SEMUA data per status (page=0, size besar)
      final futures = statuses.map((s) => _repository.getTransaksiServisByStatus(
            status: s,
            search: searchTerm,
            page: 0,
            size: 500,
          ));
      final results = await Future.wait(futures);

      List<TransaksiServis> all = [];
      for (final pageable in results) {
        all.addAll(pageable.content);
      }

      // Sorting global DESC — paling lama di distributor di atas
      all.sort((a, b) {
        final ha = a.hariDiDistributor ?? 0;
        final hb = b.hariDiDistributor ?? 0;
        return hb.compareTo(ha);
      });

      // Simpan semua data untuk pagination client-side
      _allKlaimList = all;

      // Pagination client-side
      _updatePaginatedList();
    } catch (e) {
      _errorMessage = AppErrors.userMessageFromException(
        e,
        fallback: 'Gagal memuat data klaim distributor. Coba lagi.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Potong _allKlaimList berdasarkan page saat ini.
  void _updatePaginatedList() {
    final start = _currentPage * _pageSize;
    if (start >= _allKlaimList.length) {
      _klaimList = [];
    } else {
      final end = (start + _pageSize > _allKlaimList.length)
          ? _allKlaimList.length
          : start + _pageSize;
      _klaimList = _allKlaimList.sublist(start, end);
    }
    _totalPages = (_allKlaimList.length / _pageSize).ceil();
    if (_totalPages < 1) _totalPages = 1;
    _hasNext = _currentPage < _totalPages - 1;
  }

  Future<void> goToPage(int page) async {
    if (page < 0 || page >= _totalPages) return;
    _currentPage = page;
    _updatePaginatedList();
    notifyListeners();
  }

  /// Refresh dari server.
  Future<void> refreshKlaim() async {
    _currentPage = 0;
    await fetchKlaim(resetPage: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}