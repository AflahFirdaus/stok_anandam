import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaksi_servis.dart';
import '../repositories/servis_repository.dart';
import 'package:stok_anandam/injection.dart';

class ServisProvider extends ChangeNotifier {
  final ServisRepository _repository = getIt<ServisRepository>();

  List<TransaksiServis> _transaksiList = [];
  List<TransaksiServis> get transaksiList => _transaksiList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _currentFilter = 'SEMUA';
  String get currentFilter => _currentFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  bool _hasNext = false;
  bool get hasNext => _hasNext;

  Timer? _debounce;

  // Constants for Status — hanya nilai yang diterima backend
  static const List<String> statusOptions = [
    'SEMUA',
    'BELUM_CEK',
    'SEDANG_CEK',
    'SEDANG_DIKERJAKAN',
    'SEDANG_TES',
    'TUNGGU_KONFIRMASI',
    'TUNGGU_SPAREPART',
    'BISA_DIAMBIL',
    'BATAL',
    'SUDAH_DIAMBIL',
    'KLAIM_MENUNGGU_PENGIRIMAN',
    'KLAIM_DIKIRIM',
    'KLAIM_SUDAH_DIKIRIM',
    'KLAIM_SUDAH_DIAMBIL',
  ];

  // Single-source method untuk fetch data — dipanggil dari filter, search, pagination.
  Future<void> _fetchData({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentFilter == 'SEMUA') {
        // Fetch all statuses in parallel
        final statuses = statusOptions.where((s) => s != 'SEMUA').toList();
        final futures = statuses.map((s) =>
            _repository.getTransaksiServisByStatus(
                status: s,
                search: _searchQuery.isEmpty ? null : _searchQuery,
                page: _currentPage,
                size: 20));
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

        if (_currentPage == 0) {
          _transaksiList = all;
        } else {
          _transaksiList.addAll(all);
        }
        _totalPages = maxTotalPages;
        _hasNext = hasAnyNext;
      } else {
        // Single status
        final pageable = await _repository.getTransaksiServisByStatus(
          status: _currentFilter,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          page: _currentPage,
          size: 20,
        );

        if (_currentPage == 0) {
          _transaksiList = pageable.content;
        } else {
          _transaksiList.addAll(pageable.content);
        }
        _totalPages = pageable.totalPages;
        _hasNext = pageable.hasNext;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data servis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Debounced search — called from UI on every keystroke.
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchData(resetPage: true);
    });
  }

  Future<void> fetchTransaksi({String? status, bool resetPage = false}) async {
    if (status != null) {
      _currentFilter = status;
    }
    await _fetchData(resetPage: resetPage);
  }

  Future<void> goToPage(int page) async {
    if (page < 0 || (_totalPages > 0 && page >= _totalPages)) return;
    _currentPage = page;
    await _fetchData();
  }

  Future<void> setFilter(String status) async {
    _currentFilter = status;
    await _fetchData(resetPage: true);
  }

  Future<bool> updateStatus(String id, String newStatus,
      {String? catatan}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateStatusTransaksi(id, {
        'statusBaru': newStatus,
        if (catatan != null && catatan.isNotEmpty) 'catatanPublikLog': catatan,
      });
      await fetchTransaksi(resetPage: true);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui status: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
