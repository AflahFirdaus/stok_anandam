import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
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

  int _selectedTab = 0; // 0 = Semua Klaim, 1 = Menunggu Kirim, 2 = Dikirim, 3 = Selesai
  int get selectedTab => _selectedTab;

  // Pagination
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasNext = false;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNext => _hasNext;

  Timer? _debounce;

  /// Apakah user internal (bukan NOTA/kasir)
  bool get isInternalUser {
    final role = _userStore.userRole?.toUpperCase() ?? '';
    return role != 'NOTA';
  }

  /// Filter status berdasarkan tab yang dipilih (hanya untuk internal)
  List<String> get _selectedStatuses {
    if (!isInternalUser) {
      // Untuk user eksternal, ambil semua status KLAIM
      return [
        'KLAIM_MENUNGGU_PENGIRIMAN',
        'KLAIM_DIKIRIM',
        'KLAIM_SUDAH_DIKIRIM',
        'KLAIM_SUDAH_DIAMBIL',
      ];
    }
    switch (_selectedTab) {
      case 0:
        // Semua status KLAIM
        return [
          'KLAIM_MENUNGGU_PENGIRIMAN',
          'KLAIM_DIKIRIM',
          'KLAIM_SUDAH_DIKIRIM',
          'KLAIM_SUDAH_DIAMBIL',
        ];
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

  Future<void> fetchKlaim({bool resetPage = false}) async {
    if (resetPage) _currentPage = 0;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm = _searchQuery.isEmpty ? null : _searchQuery;
      final statuses = _selectedStatuses;

      // Fetch semua status Klaim secara paralel
      final futures = statuses.map((s) =>
          _repository.getTransaksiServisByStatus(
            status: s,
            search: searchTerm,
            page: _currentPage,
            size: 20,
          ));
      final results = await Future.wait(futures);

      List<TransaksiServis> all = [];
      int maxTotalPages = 0;
      bool hasAnyNext = false;
      for (final pageable in results) {
        all.addAll(pageable.content);
        if (pageable.totalPages > maxTotalPages) {
          maxTotalPages = pageable.totalPages;
        }
        if (pageable.hasNext) hasAnyNext = true;
      }

      if (_currentPage == 0 || resetPage) {
        _klaimList = all;
      } else {
        _klaimList.addAll(all);
      }
      _totalPages = maxTotalPages;
      _hasNext = hasAnyNext;
    } catch (e) {
      _errorMessage = 'Gagal memuat data klaim: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int page) async {
    if (page < 0 || (_totalPages > 0 && page >= _totalPages)) return;
    _currentPage = page;
    await fetchKlaim();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}