import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/repositories/memo_repository.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:stok_anandam/features/shared/widgets/simple_barcode_scanner.dart';
import 'dart:async';
import 'package:stok_anandam/data/repositories/map_repository.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class CreateMemoPage extends StatefulWidget {
  final String memoType;
  final MemoDetail? initialData;
  final String? continuationId;
  final bool isNewDuplicate;

  const CreateMemoPage({
    super.key,
    this.memoType = 'BIASA',
    this.initialData,
    this.continuationId,
    this.isNewDuplicate = false,
  });

  @override
  State<CreateMemoPage> createState() => _CreateMemoPageState();
}

class _CreateMemoPageState extends State<CreateMemoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _marketingController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _paymentController = TextEditingController();
  final _tempoController = TextEditingController();
  final _namaFocusNode = FocusNode();
  final _marketingFocusNode = FocusNode();
  final _api = getIt<ApiNewEndpoints>();

  // Selected Customer IDs
  int? _customerId;
  int? _pelangganMybizId;
  double? _limitPiutang;

  // Scheduling State
  final _repository = getIt<MemoRepository>();

  // Delivery Request State Variables
  DateTime _tanggalKirimJadwal = DateTime.now();
  final _waktuKirimController = TextEditingController(text: '08:00');
  final _kodeposController = TextEditingController();
  final _alamatMapsController = TextEditingController();
  final _alamatLengkapController = TextEditingController();
  final _catatanKirimController = TextEditingController();

  List<Map<String, dynamic>> _kodeposResults = [];
  bool _isSearchingKodepos = false;
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedDesa;
  bool _isCoordinateLoading = false;
  Timer? _kodeposDebounce;

  // Technician Request State Variables
  DateTime _tanggalTeknisJadwal = DateTime.now();
  final _waktuTeknisController = TextEditingController(text: '08:00');
  final _catatanTeknisController = TextEditingController();

  // State Variables
  List<EmployeeOption> _employeeCodes = [];
  bool _isLoadingEmployees = false;
  EmployeeOption? _selectedMarketing;
  bool _isPending = false;
  bool _prosesTeknis = true;
  bool _prosesKirim = false;
  String? _tipeOngkir = 'FREE ONGKIR';
  String? _selectedPayment = 'Cash';

  // New Memo Type Fields
  late String _memoType;
  final _orderIdController = TextEditingController();
  final _resiController = TextEditingController();
  String? _selectedPlatform;
  String? _selectedEkspedisi;
  String? _selectedSubEkspedisi;
  String? _selectedBadanUsaha;

  final _ekspedisiController = TextEditingController();
  final _ekspedisiFocusNode = FocusNode();

  final List<MemoItem> _items = [];
  final List<TextEditingController> _itemNameControllers = [];
  final List<TextEditingController> _itemPriceControllers = [];
  final List<FocusNode> _itemNameFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _memoType = widget.memoType;
    if (_memoType == 'PENDING') {
      _isPending = true;
    }
    if (_memoType == 'ONLINE' || _memoType == 'DISTRIBUSI') {
      _prosesTeknis = false; // Default false, but toggleable
      _prosesKirim = true; // Always true for Online/Distribusi
    }

    // Populate from initialData if provided
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _customerId = data.customerId;
      _pelangganMybizId = data.pelangganMybizId;
      _namaController.text = data.customerName ?? '';
      _noHpController.text = data.customerPhone ?? '';
      _tanggalController.text = data.tanggalMemo != null
          ? "${data.tanggalMemo!.day.toString().padLeft(2, '0')}-${data.tanggalMemo!.month.toString().padLeft(2, '0')}-${data.tanggalMemo!.year}"
          : '';
      _deskripsiController.text = data.deskripsi ?? '';
      if (data.marketingName != null && data.marketingEmpCode != null) {
        _selectedMarketing = EmployeeOption(
          empCode: data.marketingEmpCode!,
          empName: data.marketingName!,
        );
        _marketingController.text = data.marketingName!;
      }
      _isPending = data.statusAkhir == MemoStatus.DISETUJUI ||
          data.statusAkhir == MemoStatus.MENUNGGU_PERSETUJUAN;
      _prosesTeknis = data.isTeknisRequired;
      _prosesKirim = data.isDeliveryRequired;
      _tipeOngkir = data.tipeOngkir ?? 'FREE ONGKIR';
      _selectedPayment = data.metodePembayaran;
      _orderIdController.text = data.orderIdMarketplace ?? '';
      _resiController.text = data.resi ?? '';
      _selectedEkspedisi = data.ekspedisi;
      if (data.ekspedisi != null) {
        _ekspedisiController.text = data.ekspedisi!;
      }
      _selectedSubEkspedisi = data.subEkspedisi;
      _selectedPlatform = data.platform;
      _selectedBadanUsaha = data.badanUsaha;
      _tempoController.text = data.tempo ?? '';

      if (data.items.isNotEmpty) {
        _items.addAll(data.items);
      } else {
        _items
            .add(MemoItem(namaBarang: '', qty: 0, hargaSatuan: 0, subtotal: 0));
      }
    } else {
      _items.add(MemoItem(namaBarang: '', qty: 0, hargaSatuan: 0, subtotal: 0));
      // Default to today's date
      final now = DateTime.now();
      _tanggalController.text =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    }

    // Initialize controllers for items
    for (var item in _items) {
      _itemNameControllers.add(TextEditingController(text: item.namaBarang));
      _itemPriceControllers.add(TextEditingController(
          text: item.hargaSatuan > 0 ? _formatNumber(item.hargaSatuan) : ''));
      _itemNameFocusNodes.add(FocusNode());
    }

    _loadEmployeeCodes();

    if (_memoType == 'ONLINE' && widget.initialData == null) {
      _marketingController.text = 'MARKETING ONLINE';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    _tanggalController.dispose();
    _marketingController.dispose();
    _deskripsiController.dispose();
    _paymentController.dispose();
    _orderIdController.dispose();
    _resiController.dispose();
    _tempoController.dispose();
    _namaFocusNode.dispose();
    _marketingFocusNode.dispose();
    _ekspedisiController.dispose();
    _ekspedisiFocusNode.dispose();
    for (var c in _itemNameControllers) {
      c.dispose();
    }
    for (var c in _itemPriceControllers) {
      c.dispose();
    }
    for (var f in _itemNameFocusNodes) {
      f.dispose();
    }

    // Dispose scheduling controllers
    _waktuKirimController.dispose();
    _kodeposController.dispose();
    _alamatMapsController.dispose();
    _alamatLengkapController.dispose();
    _catatanKirimController.dispose();
    _waktuTeknisController.dispose();
    _catatanTeknisController.dispose();
    _kodeposDebounce?.cancel();

    super.dispose();
  }

  Future<void> _loadEmployeeCodes() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final options = await _api.getEmployeeCodes();
      setState(() {
        _employeeCodes = options;
        _isLoadingEmployees = false;

        // Pre-select logic
        if (_selectedMarketing == null) {
          if (_memoType == 'ONLINE') {
            try {
              _selectedMarketing = _employeeCodes.firstWhere(
                  (e) => e.empName.toUpperCase() == 'MARKETING ONLINE');
              _marketingController.text = _selectedMarketing!.empName;
            } catch (_) {
              _marketingController.text = 'MARKETING ONLINE';
            }
          } else {
            final currentUser = getIt<CurrentUserStore>();
            final currentEmpCode = currentUser.employeeCode;

            if (currentEmpCode != null) {
              try {
                _selectedMarketing = _employeeCodes
                    .firstWhere((e) => e.empCode == currentEmpCode);
                _marketingController.text = _selectedMarketing!.empName;
              } catch (_) {
                // If not found by code, try by name as fallback
                final currentName = currentUser.displayName;
                try {
                  _selectedMarketing = _employeeCodes
                      .firstWhere((e) => e.empName == currentName);
                  _marketingController.text = _selectedMarketing!.empName;
                } catch (_) {}
              }
            }
          }
        }
      });
    } catch (_) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A85FA),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        String formattedDate =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
        _tanggalController.text = formattedDate;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(MemoItem(
        namaBarang: '',
        qty: 0,
        hargaSatuan: 0,
        subtotal: 0,
      ));
      _itemNameControllers.add(TextEditingController());
      _itemPriceControllers.add(TextEditingController());
      _itemNameFocusNodes.add(FocusNode());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _itemNameControllers[index].dispose();
      _itemNameControllers.removeAt(index);
      _itemPriceControllers[index].dispose();
      _itemPriceControllers.removeAt(index);
      _itemNameFocusNodes[index].dispose();
      _itemNameFocusNodes.removeAt(index);
    });
  }

  double get _totalHarga {
    return _items.fold(0, (sum, item) => sum + (item.qty * item.hargaSatuan));
  }

  double get _totalQty {
    return _items.fold(0, (sum, item) => sum + item.qty);
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.shopping_basket_outlined, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                    child: Text('Tambahkan minimal satu barang ke dalam memo!',
                        style: TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      // Ensure no items have 0 quantity
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].qty <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Kuantitas untuk "${_items[i].namaBarang ?? 'Item ${i + 1}'}" harus lebih dari 0',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }
        if (_items[i].namaBarang == null ||
            _items[i].namaBarang!.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.label_off_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Nama barang pada baris ${i + 1} tidak boleh kosong',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }
      }

      final request = {
        // Customer Info
        'namaCustomer': _namaController.text,
        'nama_customer': _namaController.text,
        'customerName': _namaController.text,
        'customer_name': _namaController.text,
        'noHpCustomer': _noHpController.text,
        'no_hp_customer': _noHpController.text,
        'customerPhone': _noHpController.text,
        'customer_phone': _noHpController.text,
        'customerId': _customerId,
        'customer_id': _customerId,
        'pelangganMybizId': _pelangganMybizId,
        'pelanggan_mybiz_id': _pelangganMybizId,

        // Transaction Info
        'tanggal': _tanggalController.text,
        'tanggalMemo': _tanggalController.text,
        'tanggal_memo': _tanggalController.text,
        'namaMarketing':
            _selectedMarketing?.empName ?? _marketingController.text,
        'nama_marketing':
            _selectedMarketing?.empName ?? _marketingController.text,
        'marketingName':
            _selectedMarketing?.empName ?? _marketingController.text,
        'marketing_name':
            _selectedMarketing?.empName ?? _marketingController.text,
        'marketingEmpCode': _selectedMarketing?.empCode,
        'marketing_emp_code': _selectedMarketing?.empCode,

        'deskripsi': _deskripsiController.text,

        'isTeknisi': _prosesTeknis,
        'is_teknisi': _prosesTeknis,
        'isTeknisRequired': _prosesTeknis,
        'is_teknis_required': _prosesTeknis,

        'isKirim': _prosesKirim,
        'is_kirim': _prosesKirim,
        'isDeliveryRequired': _prosesKirim,
        'is_delivery_required': _prosesKirim,

        'opsiPengiriman': _prosesKirim ? 'Kirim' : 'Ambil di Toko',
        'opsi_pengiriman': _prosesKirim ? 'Kirim' : 'Ambil di Toko',

        'tipeOngkir': _tipeOngkir,
        'tipe_ongkir': _tipeOngkir,

        'metodePembayaran': _memoType == 'ONLINE'
            ? 'Online Marketplace'
            : (_selectedPayment ?? _paymentController.text),
        'metode_pembayaran': _memoType == 'ONLINE'
            ? 'Online Marketplace'
            : (_selectedPayment ?? _paymentController.text),

        'items': _items.map((e) => e.toJson()).toList(),
        'totalHarga': _totalHarga,
        'total_harga': _totalHarga,

        'memoType': _memoType,
        'memo_type': _memoType,

        'orderIdMarketplace':
            _orderIdController.text.isNotEmpty ? _orderIdController.text : null,
        'order_id_marketplace':
            _orderIdController.text.isNotEmpty ? _orderIdController.text : null,
        'resi': _resiController.text.isNotEmpty ? _resiController.text : null,
        'nomor_resi':
            _resiController.text.isNotEmpty ? _resiController.text : null,
        'nomorResi':
            _resiController.text.isNotEmpty ? _resiController.text : null,
        'ekspedisi': _selectedEkspedisi,
        'subEkspedisi': _selectedSubEkspedisi,
        'sub_ekspedisi': _selectedSubEkspedisi,
        'platform': _selectedPlatform,
        'badanUsaha': _memoType == 'PROJECT' ? _selectedBadanUsaha : null,
        'badan_usaha': _memoType == 'PROJECT' ? _selectedBadanUsaha : null,
        'tempo':
            _tempoController.text.isNotEmpty ? _tempoController.text : null,
        'revisedFromId': widget.initialData?.revisedFromId,
        'revised_from_id': widget.initialData?.revisedFromId,
      };

      if (widget.initialData?.id != null && widget.continuationId == null) {
        context
            .read<MemoBloc>()
            .add(UpdateMemoEvent(widget.initialData!.id!, request));
      } else if (widget.continuationId != null) {
        context
            .read<MemoBloc>()
            .add(ContinuePendingMemoEvent(widget.continuationId!, request));
      } else {
        context
            .read<MemoBloc>()
            .add(CreateMemoEvent(request, isPending: _isPending));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final horizontalPadding = isDesktop ? 32.0 : 16.0;

    return BlocProvider(
      create: (context) => MemoBloc(getIt()),
      child: Builder(builder: (context) {
        return DashboardShell(
          currentRoute: AppRoutes.memo,
          onScan: () => context.pushNamed(AppRoutes.scanner),
          userName: userStore.displayName,
          userRole: userStore.userRole,
          title: widget.initialData != null && widget.continuationId == null
              ? 'Edit Memo'
              : 'Buat Memo Baru',
          onNavigate: (route) => context.go(route),
          onLogout: () async {
            await getIt<AuthService>().logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
          child: BlocConsumer<MemoBloc, MemoState>(
            listener: (context, state) {
              if (state is MemoOperationSuccess) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green),
                );
                if (state.id != null &&
                    widget.initialData == null &&
                    widget.continuationId == null) {
                  _applySchedulingIfConfigured(state.id!);
                } else {
                  _navigateAfterSuccess(state.id);
                }
              } else if (state is MemoError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.error), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              size: 24, color: Colors.black87),
                          onPressed: () => context.go(AppRoutes.memo),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Buat Memo ${_memoType.toLowerCase().capitalize()}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      padding: EdgeInsets.all(isDesktop ? 32 : 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIdentitasPelanggan(isDesktop),
                            const SizedBox(height: 32),
                            _buildDetailTransaksi(isDesktop),
                            const SizedBox(height: 32),
                            _buildLogikaProses(isDesktop),
                            const SizedBox(height: 32),
                            _buildInformasiTambahan(isDesktop),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),
                            _buildItemsSection(isDesktop),
                            const SizedBox(height: 24),
                            _buildTotalSection(isDesktop),
                            const SizedBox(height: 24),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Tambah Barang'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildPendingSection(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: isDesktop ? 300 : double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: state is MemoLoading
                              ? null
                              : () => _submit(context),
                          child: state is MemoLoading
                              ? const CircularProgressIndicator()
                              : const Text('Simpan Memo',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitasPelanggan(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'Identitas Pelanggan', Icons.person_outline_rounded),
        const SizedBox(height: 20),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildCustomerDropdown()),
              if (_memoType != 'ONLINE') ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildFigmaTextField(
                    label: 'No. HP Pelanggan',
                    controller: _noHpController,
                    hint: 'Contoh: 0812xxxx',
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ],
          )
        else
          Column(
            children: [
              _buildCustomerDropdown(),
              if (_memoType != 'ONLINE') ...[
                const SizedBox(height: 20),
                _buildFigmaTextField(
                  label: 'No. HP Pelanggan',
                  controller: _noHpController,
                  hint: 'Contoh: 0812xxxx',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ],
          ),
        if (_limitPiutang != null) ...[
          const SizedBox(height: 20),
          _buildCreditLimitBanner(),
        ],
      ],
    );
  }

  Widget _buildCreditLimitBanner() {
    Theme.of(context);
    final limitStr = _limitPiutang != null
        ? 'Rp ${NumberFormat.decimalPattern('id-ID').format(_limitPiutang)}'
        : 'Tidak Ada Limit';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIMIT PIUTANG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  limitStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTransaksi(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Detail Transaksi', Icons.receipt_long_outlined),
        const SizedBox(height: 20),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMarketingDropdown()),
              const SizedBox(width: 24),
              Expanded(
                child: _buildFigmaTextField(
                  label: 'Tanggal Memo',
                  controller: _tanggalController,
                  hint: 'Pilih Tanggal',
                  readOnly: true,
                  onTap: () => _pilihTanggal(context),
                ),
              ),
              if (_memoType != 'ONLINE') ...[
                const SizedBox(width: 24),
                Expanded(child: _buildPaymentDropdown()),
              ],
              if (_memoType == 'ONLINE') ...[
                const SizedBox(width: 24),
                Expanded(
                  child: _buildFigmaTextField(
                    label: 'Order ID Marketplace *',
                    controller: _orderIdController,
                    hint: 'Contoh: ORD-12345',
                    validator: (v) => (_memoType == 'ONLINE' &&
                            (v == null || v.trim().isEmpty))
                        ? 'Order ID wajib diisi'
                        : null,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      onPressed: () async {
                        final scanned = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SimpleBarcodeScanner(
                              title: 'Scan Order ID',
                            ),
                          ),
                        );
                        if (scanned != null) {
                          setState(() => _orderIdController.text = scanned);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          )
        else
          Column(
            children: [
              _buildMarketingDropdown(),
              const SizedBox(height: 20),
              _buildFigmaTextField(
                label: 'Tanggal Memo',
                controller: _tanggalController,
                hint: 'Pilih Tanggal',
                readOnly: true,
                onTap: () => _pilihTanggal(context),
              ),
              if (_memoType != 'ONLINE') ...[
                const SizedBox(height: 20),
                _buildPaymentDropdown(),
              ],
              if (_memoType == 'ONLINE') ...[
                const SizedBox(height: 20),
                _buildFigmaTextField(
                  label: 'Order ID Marketplace *',
                  controller: _orderIdController,
                  hint: 'Contoh: ORD-12345',
                  validator: (v) =>
                      (_memoType == 'ONLINE' && (v == null || v.trim().isEmpty))
                          ? 'Order ID wajib diisi'
                          : null,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: () async {
                      final scanned = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SimpleBarcodeScanner(
                            title: 'Scan Order ID',
                          ),
                        ),
                      );
                      if (scanned != null) {
                        setState(() => _orderIdController.text = scanned);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        if (_selectedPayment == 'Tempo') ...[
          const SizedBox(height: 20),
          _buildFigmaTextField(
            label: 'Tempo (Wajib)',
            controller: _tempoController,
            hint: 'Contoh: 30 Hari',
            validator: (v) =>
                (_selectedPayment == 'Tempo' && (v == null || v.isEmpty))
                    ? 'Tempo wajib diisi'
                    : null,
          ),
        ],
      ],
    );
  }

  Widget _buildLogikaProses(bool isDesktop) {
    if (_memoType == 'ONLINE') return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Konfigurasi Proses', Icons.settings_suggest_outlined),
          const SizedBox(height: 24),
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _SelectionTile(
                    label: 'Proses Teknis',
                    subtitle: 'Memerlukan penanganan teknisi',
                    icon: Icons.build_circle_outlined,
                    value: _prosesTeknis,
                    onChanged: (v) => setState(() => _prosesTeknis = v),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _SelectionTile(
                    label: 'Proses Kirim',
                    subtitle: 'Barang perlu dikirim ke lokasi',
                    icon: Icons.local_shipping_outlined,
                    value: _prosesKirim,
                    enabled: true,
                    onChanged: (v) {
                      if (_memoType == 'ONLINE') return;
                      setState(() => _prosesKirim = v);
                    },
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _SelectionTile(
                  label: 'Proses Teknis',
                  subtitle: 'Memerlukan teknisi',
                  icon: Icons.build_circle_outlined,
                  value: _prosesTeknis,
                  onChanged: (v) => setState(() => _prosesTeknis = v),
                ),
                const SizedBox(height: 16),
                _SelectionTile(
                  label: 'Proses Kirim',
                  subtitle: 'Barang dikirim',
                  icon: Icons.local_shipping_outlined,
                  value: _prosesKirim,
                  enabled: true,
                  onChanged: (v) {
                    if (_memoType == 'ONLINE') return;
                    setState(() => _prosesKirim = v);
                  },
                ),
              ],
            ),
          _buildSchedulingFields(),
        ],
      ),
    );
  }

  Widget _buildInformasiTambahan(bool isDesktop) {
    final bool showExtraFields = _memoType == 'PROJECT' ||
        _memoType == 'ONLINE' ||
        _memoType == 'DISTRIBUSI';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Informasi Tambahan', Icons.info_outline_rounded),
        const SizedBox(height: 20),
        if (showExtraFields) ...[
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_memoType == 'PROJECT' || _memoType == 'ONLINE') ...[
                  Expanded(child: _buildPlatformDropdown()),
                ],
                if (_memoType == 'ONLINE' || _memoType == 'DISTRIBUSI') ...[
                  if (_memoType == 'PROJECT' || _memoType == 'ONLINE')
                    const SizedBox(width: 24),
                  Expanded(
                    child: _buildFigmaTextField(
                      label: 'No. Resi (Opsional)',
                      controller: _resiController,
                      hint: 'Contoh: JNT-12345',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        onPressed: () async {
                          final scanned = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SimpleBarcodeScanner(
                                title: 'Scan Nomor Resi',
                              ),
                            ),
                          );
                          if (scanned != null) {
                            setState(() => _resiController.text = scanned);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildEkspedisiDropdown(),
                        if (_memoType == 'ONLINE' &&
                            _selectedEkspedisi == 'REGULER') ...[
                          const SizedBox(height: 16),
                          _buildSubEkspedisiDropdown(),
                        ],
                      ],
                    ),
                  ),
                ],
                if (_memoType == 'PROJECT') ...[
                  const SizedBox(width: 24),
                  Expanded(child: _buildBadanUsahaDropdown()),
                ],
              ],
            )
          else
            Column(
              children: [
                if (_memoType == 'PROJECT') ...[
                  _buildBadanUsahaDropdown(),
                  const SizedBox(height: 20),
                ],
                if (_memoType == 'PROJECT' || _memoType == 'ONLINE') ...[
                  _buildPlatformDropdown(),
                  const SizedBox(height: 20),
                ],
                if (_memoType == 'ONLINE' || _memoType == 'DISTRIBUSI') ...[
                  _buildFigmaTextField(
                    label: 'No. Resi (Opsional)',
                    controller: _resiController,
                    hint: 'Contoh: JNT-12345',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      onPressed: () async {
                        final scanned = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SimpleBarcodeScanner(
                              title: 'Scan Nomor Resi',
                            ),
                          ),
                        );
                        if (scanned != null) {
                          setState(() => _resiController.text = scanned);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildEkspedisiDropdown(),
                  if (_memoType == 'ONLINE' &&
                      _selectedEkspedisi == 'REGULER') ...[
                    const SizedBox(height: 20),
                    _buildSubEkspedisiDropdown(),
                  ],
                  const SizedBox(height: 20),
                ],
              ],
            ),
          const SizedBox(height: 20),
        ],
        _buildFigmaTextField(
          label: 'Deskripsi Tambahan',
          controller: _deskripsiController,
          hint: 'Contoh: Titip di satpam / Lantai 2',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPlatformDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Platform',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedPlatform,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: const Text('Pilih Platform'),
          items: (_memoType == 'ONLINE'
                  ? ['Shopee', 'Tokopedia', 'Blibli']
                  : ['SIPLAH', 'INAPROC', 'MBIZ', 'GO', 'DRM', 'TISERA', 'PPL'])
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedPlatform = v),
        ),
      ],
    );
  }

  Widget _buildEkspedisiDropdown() {
    final theme = Theme.of(context);
    final isOnline = _memoType == 'ONLINE';
    final isDistribusi = _memoType == 'DISTRIBUSI';
    final List<String> rawItems = isOnline
        ? ['REGULER', 'INSTANT', 'ANDI']
        : isDistribusi
            ? [
                'GP TRANS',
                'SABILA SHUTTLE',
                'WIDHI UTAMA',
                'J&T',
                'JNE',
                'MAC CARGO',
                'BARAKA EXPRES',
                'ADEX',
                'KALOG',
                'KI8 LOGISTICS',
                'HERONA EXPRESS',
                'MERAH JAYA',
                'PMS',
                'TAM CARGO',
                'TUKONI CARGO',
                'STAR TRAVEL',
                'SUMBER ALAM',
                'EFISIENSI',
                'BUANA TRAVEL',
                'LOVINDRA TRAVEL',
                'MELATI TRAVEL',
                'LANGGENG JAYA',
                'MAXTRANS TRAVEL',
                'RAHAYU TRAVEL',
                'RAMA SAKTI',
                'BINTANG TRAVEL',
                'JAWARA TRAVEL',
                'JOGLOSEMAR',
                'CITITRANS',
                'DAYTRANS',
                'AGUS FAST',
                'PAXEL'
              ]
            : [
                'GP TRANS',
                'SABILA SHUTTLE',
                'WIDHI UTAMA',
                'REGULER',
                'INSTANT',
                'ANDI'
              ];
    final items = List<String>.from(rawItems)..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ekspedisi',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<String>(
            textEditingController: _ekspedisiController,
            focusNode: _ekspedisiFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return items;
              }
              return items.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _selectedEkspedisi = selection;
                _ekspedisiController.text = selection;
                _selectedSubEkspedisi =
                    null; // Reset sub-ekspedisi when main changes
                if (isOnline) {
                  _prosesKirim =
                      (selection != 'INSTANT' && selection != 'ANDI');
                }
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Cari Ekspedisi...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: Colors.grey),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedEkspedisi = value.isNotEmpty ? value : null;
                    if (isOnline) {
                      _prosesKirim = (value != 'INSTANT' && value != 'ANDI');
                    }
                  });
                },
                onFieldSubmitted: (value) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option,
                              style: const TextStyle(fontSize: 14)),
                          onTap: () => onSelected(option),
                          hoverColor:
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubEkspedisiDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Layanan Ekspedisi',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSubEkspedisi,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: const Text('Pilih JNE, JNT, dsb'),
          items: ['JNE', 'JNT', 'JNT KARGO', 'SPX']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSubEkspedisi = v),
          validator: (v) => (_memoType == 'ONLINE' &&
                  _selectedEkspedisi == 'REGULER' &&
                  (v == null || v.isEmpty))
              ? 'Layanan ekspedisi wajib dipilih'
              : null,
        ),
      ],
    );
  }

  Widget _buildBadanUsahaDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Badan Usaha',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedBadanUsaha,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          hint: const Text('Pilih Badan Usaha'),
          items: ['ANC', 'MGC', 'SGI', 'SSS', 'PDB', 'GBH']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          validator: (v) => (_memoType == 'PROJECT' && (v == null || v.isEmpty))
              ? 'Badan usaha wajib dipilih'
              : null,
          onChanged: (v) => setState(() => _selectedBadanUsaha = v),
        ),
      ],
    );
  }

  Widget _buildPendingSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isPending
            ? theme.colorScheme.primary.withValues(alpha: 0.03)
            : Colors.transparent,
        border: Border.all(
          color: _isPending
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isPending ? Icons.lock_clock_rounded : Icons.lock_open_rounded,
            color: _isPending ? theme.colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajukan Sebagai PENDING',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isPending
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Stok akan dikunci sementara (Menunggu ACC)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPending,
            onChanged: (v) => setState(() => _isPending = v),
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Nama Customer',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<CustomerOption>(
            textEditingController: _namaController,
            focusNode: _namaFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<CustomerOption>.empty();
              }
              try {
                return await _api.searchCustomers(textEditingValue.text);
              } catch (e) {
                return const Iterable<CustomerOption>.empty();
              }
            },
            displayStringForOption: (CustomerOption option) =>
                option.namaPelanggan ?? '',
            onSelected: (CustomerOption selection) {
              setState(() {
                _namaController.text = selection.namaPelanggan ?? '';
                if (selection.noHp != null && selection.noHp!.isNotEmpty) {
                  _noHpController.text = selection.noHp!;
                }

                // Auto-populate address regardless of source
                if (selection.alamat != null && selection.alamat!.isNotEmpty) {
                  _alamatLengkapController.text = selection.alamat!;
                  if (_memoType == 'DISTRIBUSI' ||
                      _deskripsiController.text.isEmpty) {
                    _deskripsiController.text = selection.alamat!;
                  }
                } else {
                  _alamatLengkapController.clear();
                  if (_memoType == 'DISTRIBUSI') {
                    _deskripsiController.clear();
                  }
                }

                if (selection.source == 'MYBIZ' ||
                    selection.source == 'SPREADSHEET') {
                  _pelangganMybizId = selection.id;
                  _customerId = null;
                  _limitPiutang = selection.limitPiutang;

                  // Auto-populate marketing details from PelangganMybiz
                  if (selection.namaMarketing != null) {
                    _marketingController.text = selection.namaMarketing!;
                    try {
                      _selectedMarketing = _employeeCodes.firstWhere((e) =>
                          e.empCode == selection.kodeMarketing ||
                          e.empName.toUpperCase() ==
                              selection.namaMarketing!.toUpperCase());
                    } catch (_) {
                      _selectedMarketing = EmployeeOption(
                        empCode: selection.kodeMarketing ?? '',
                        empName: selection.namaMarketing!,
                      );
                    }
                  }

                  // Auto-populate payment and terms from PelangganMybiz
                  if (selection.terminPiutang != null &&
                      selection.terminPiutang! > 0) {
                    _selectedPayment = 'Tempo';
                    _tempoController.text = '${selection.terminPiutang} Hari';
                  } else {
                    _selectedPayment = 'Cash';
                  }
                } else {
                  _customerId = selection.id;
                  _pelangganMybizId = null;
                  _limitPiutang = null;
                }
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: theme.textTheme.bodyLarge,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama customer wajib diisi'
                    : null,
                onChanged: (v) {
                  setState(() {
                    _customerId = null;
                    _pelangganMybizId = null;
                    _limitPiutang = null;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Ketik nama pelanggan...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: Colors.grey),
                ),
                onFieldSubmitted: (value) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final CustomerOption option = options.elementAt(index);
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(option.namaPelanggan ?? '-',
                                    style: const TextStyle(fontSize: 14)),
                              ),
                              if (option.source != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: option.source == 'MYBIZ' ||
                                            option.source == 'SPREADSHEET'
                                        ? Colors.blue.shade50
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: option.source == 'MYBIZ' ||
                                              option.source == 'SPREADSHEET'
                                          ? Colors.blue.shade200
                                          : Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    option.source == 'MYBIZ' ||
                                            option.source == 'SPREADSHEET'
                                        ? 'SPREADSHEET'
                                        : 'PELANGGAN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: option.source == 'MYBIZ' ||
                                              option.source == 'SPREADSHEET'
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: option.noHp != null
                              ? Text(option.noHp!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey))
                              : null,
                          onTap: () => onSelected(option),
                          hoverColor:
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMarketingDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Marketing',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<EmployeeOption>(
            textEditingController: _marketingController,
            focusNode: _marketingFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _employeeCodes;
              }
              return _employeeCodes.where((EmployeeOption option) {
                return option.empName
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()) ||
                    option.empCode
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
              });
            },
            displayStringForOption: (EmployeeOption option) => option.empName,
            onSelected: (EmployeeOption selection) {
              setState(() {
                _selectedMarketing = selection;
                _marketingController.text = selection.empName;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Cari Marketing...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _isLoadingEmployees
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ))
                      : const Icon(Icons.search_rounded,
                          size: 20, color: Colors.grey),
                ),
                onFieldSubmitted: (value) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final EmployeeOption option = options.elementAt(index);
                        return ListTile(
                          title: Text(option.empName,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(option.empCode,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          onTap: () => onSelected(option),
                          hoverColor:
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulingFields() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_prosesKirim) ...[
          const SizedBox(height: 24),
          Text('Tipe Ongkir',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _tipeOngkir,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
            ),
            items: ['FREE ONGKIR', 'BAYAR TUJUAN']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _tipeOngkir = val);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Request Pengiriman',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Rencana Kirim',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _tanggalKirimJadwal,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 7)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _tanggalKirimJadwal = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('dd-MM-yyyy')
                                        .format(_tanggalKirimJadwal),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildFigmaTextField(
                        label: 'Estimasi Waktu',
                        controller: _waktuKirimController,
                        hint: 'Contoh: 08:00',
                        suffixIcon: Icon(Icons.access_time_rounded,
                            size: 18, color: theme.colorScheme.primary),
                        validator: (v) =>
                            (_prosesKirim && (v == null || v.isEmpty))
                                ? 'Wajib diisi'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFigmaTextField(
                  label: 'Pencarian Kode Pos / Wilayah',
                  controller: _kodeposController,
                  hint: 'Ketik minimal 3 karakter...',
                  onChanged: _searchKodepos,
                  suffixIcon: _isSearchingKodepos
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search, size: 20),
                ),
                if (_kodeposResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _kodeposResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final kp = _kodeposResults[index];
                        return ListTile(
                          title: Text(kp['name'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(kp['fullAddress'] ?? ''),
                          leading: const Icon(Icons.place_outlined),
                          onTap: () => _onLocationSelected(kp),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildFigmaTextField(
                  label: 'Link Google Maps / Koordinat Lokasi',
                  controller: _alamatMapsController,
                  hint: 'Contoh: -7.96, 112.63 atau link maps',
                  suffixIcon: _isCoordinateLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.location_searching,
                              color: Colors.blue),
                          onPressed: _searchByCoordinate,
                          tooltip: 'Cari Alamat dari Koordinat',
                        ),
                ),
                const SizedBox(height: 16),
                _buildFigmaTextField(
                  label: 'Alamat Pengiriman Lengkap',
                  controller: _alamatLengkapController,
                  hint: 'Isi alamat detail...',
                  maxLines: 2,
                  validator: (v) => (_prosesKirim && (v == null || v.isEmpty))
                      ? 'Alamat wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildFigmaTextField(
                  label: 'Catatan Khusus Pengiriman',
                  controller: _catatanKirimController,
                  hint: 'Tambahkan instruksi pengiriman jika ada...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
        if (_prosesTeknis) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_circle_rounded,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Request Jadwal Teknisi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Jadwal Teknis',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _tanggalTeknisJadwal,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 7)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _tanggalTeknisJadwal = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 18, color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('dd-MM-yyyy')
                                        .format(_tanggalTeknisJadwal),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildFigmaTextField(
                        label: 'Estimasi Waktu',
                        controller: _waktuTeknisController,
                        hint: 'Contoh: 08:00',
                        suffixIcon: Icon(Icons.access_time_rounded,
                            size: 18, color: Colors.orange.shade700),
                        validator: (v) =>
                            (_prosesTeknis && (v == null || v.isEmpty))
                                ? 'Wajib diisi'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFigmaTextField(
                  label: 'Catatan Khusus Teknisi',
                  controller: _catatanTeknisController,
                  hint: 'Tambahkan instruksi teknisi jika ada...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _searchKodepos(String query) async {
    if (_kodeposDebounce?.isActive ?? false) _kodeposDebounce!.cancel();
    _kodeposDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 3) {
        setState(() => _kodeposResults = []);
        return;
      }
      setState(() => _isSearchingKodepos = true);
      try {
        final results =
            await getIt<MapRepository>().searchLocationPhoton(query);
        setState(() => _kodeposResults = results);
      } catch (_) {
        setState(() => _kodeposResults = []);
      } finally {
        setState(() => _isSearchingKodepos = false);
      }
    });
  }

  Future<void> _searchByCoordinate() async {
    final input = _alamatMapsController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isCoordinateLoading = true);
    try {
      double? lat;
      double? lon;

      final coordRegExp =
          RegExp(r'([-+]?\d{1,2}(?:\.\d+)?),\s*([-+]?\d{1,3}(?:\.\d+)?)');
      final match = coordRegExp.firstMatch(input);
      if (match != null) {
        lat = double.tryParse(match.group(1)!);
        lon = double.tryParse(match.group(2)!);
      } else if (input.contains('google.com/maps')) {
        final urlMatch =
            RegExp(r'q=([-+]?\d{1,2}(?:\.\d+)?),([-+]?\d{1,3}(?:\.\d+)?)')
                .firstMatch(input);
        if (urlMatch != null) {
          lat = double.tryParse(urlMatch.group(1)!);
          lon = double.tryParse(urlMatch.group(2)!);
        } else {
          final atMatch =
              RegExp(r'@([-+]?\d{1,2}(?:\.\d+)?),([-+]?\d{1,3}(?:\.\d+)?)')
                  .firstMatch(input);
          if (atMatch != null) {
            lat = double.tryParse(atMatch.group(1)!);
            lon = double.tryParse(atMatch.group(2)!);
          }
        }
      }

      if (lat != null && lon != null) {
        final result =
            await getIt<MapRepository>().reverseGeocodePhoton(lat, lon);
        if (result != null) {
          result['latitude'] = lat;
          result['longitude'] = lon;
          _onLocationSelected(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Lokasi ditemukan!'),
                backgroundColor: Colors.green),
          );
        } else {
          throw Exception('Lokasi tidak ditemukan');
        }
      } else {
        throw Exception(
            'Format koordinat tidak valid. Gunakan format: lat, lon');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mencari koordinat: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isCoordinateLoading = false);
    }
  }

  void _onLocationSelected(Map<String, dynamic> loc) {
    setState(() {
      final pc = loc['postalCode']?.toString() ?? '';
      final city = loc['city']?.toString() ?? '';
      final dist = loc['district']?.toString() ?? '';

      _alamatLengkapController.text = loc['fullAddress'] ?? '';

      if (pc.isNotEmpty && pc != '-') {
        _kodeposController.text =
            "$pc - ${dist.isNotEmpty ? dist : city}".trim();
      } else {
        _kodeposController.text = loc['name'] ?? loc['fullAddress'] ?? '';
      }

      if (loc['latitude'] != null && loc['longitude'] != null) {
        _alamatMapsController.text =
            "https://www.google.com/maps?q=${loc['latitude']},${loc['longitude']}";
        _selectedLat = loc['latitude'];
        _selectedLon = loc['longitude'];
      }
      _selectedCity = city;
      _selectedDistrict = dist;
      _selectedDesa =
          loc['village']?.toString() ?? loc['desa']?.toString() ?? '';
      _kodeposResults = [];
    });
  }

  Future<void> _applySchedulingIfConfigured(String memoId) async {
    final hasKirim = _prosesKirim;
    final hasTeknis = _prosesTeknis;

    if (!hasKirim && !hasTeknis) {
      _navigateAfterSuccess(memoId);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tglKirimStr =
          "${_tanggalKirimJadwal.day.toString().padLeft(2, '0')}-${_tanggalKirimJadwal.month.toString().padLeft(2, '0')}-${_tanggalKirimJadwal.year}";
      final tglTeknisStr =
          "${_tanggalTeknisJadwal.day.toString().padLeft(2, '0')}-${_tanggalTeknisJadwal.month.toString().padLeft(2, '0')}-${_tanggalTeknisJadwal.year}";

      if (hasKirim) {
        final Map<String, dynamic> payload = {
          "tipeTugas": "PENGIRIMAN",
          "tanggalJadwal": tglKirimStr,
          "estimasiWaktu": _waktuKirimController.text,
          "catatan": _catatanKirimController.text.isNotEmpty
              ? _catatanKirimController.text
              : null,
          "idKodepos": _selectedLat != null
              ? null
              : int.tryParse(_kodeposController.text),
          "alamatLengkap": _alamatLengkapController.text,
          "alamatMaps": _alamatMapsController.text,
          "latitude": _selectedLat,
          "longitude": _selectedLon,
          "kabupatenKota": _selectedCity,
          "kecamatan": _selectedDistrict,
          "desaKelurahan": _selectedDesa,
        };
        await _repository.createPenjadwalan(memoId, payload);
      }

      if (hasTeknis) {
        final Map<String, dynamic> payload = {
          "tipeTugas": "TEKNISI",
          "tanggalJadwal": tglTeknisStr,
          "estimasiWaktu": _waktuTeknisController.text,
          "catatan": _catatanTeknisController.text.isNotEmpty
              ? _catatanTeknisController.text
              : null,
        };
        await _repository.createPenjadwalan(memoId, payload);
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        _navigateAfterSuccess(memoId);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim request penjadwalan: $e"),
            backgroundColor: Colors.red,
          ),
        );
        _navigateAfterSuccess(memoId); // Fallback: still navigate
      }
    }
  }

  void _navigateAfterSuccess(String? memoId) {
    if (widget.initialData != null && widget.continuationId == null) {
      if (context.canPop()) {
        context.pop();
      } else if (memoId != null) {
        context.goNamed(AppRoutes.memoDetail, pathParameters: {'id': memoId});
      } else {
        context.go(AppRoutes.memo);
      }
    } else if (memoId != null) {
      context.goNamed(AppRoutes.memoDetail, pathParameters: {'id': memoId});
    } else {
      context.go(AppRoutes.memo);
    }
  }

  Widget _buildPaymentDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: ['Cash', 'Transfer', 'Tempo', 'Lainnya']
                  .contains(_selectedPayment)
              ? _selectedPayment
              : null,
          style: theme.textTheme.bodyLarge,
          items: ['Cash', 'Transfer', 'Tempo', 'Lainnya']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedPayment = v;
              if (v != 'Tempo') {
                _tempoController.clear();
              }
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daftar Barang',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final item = _items[index];
            final priceController = _itemPriceControllers[index];

            final fieldLayout = isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildItemNameAutocomplete(index),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildQtyField(index, item),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildFigmaTextField(
                          label: index == 0 ? 'Harga Satuan' : '',
                          controller: priceController,
                          hint: '0',
                          // 1. Ubah keyboard type agar memunculkan koma di HP
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [ThousandSeparatorFormatter()],
                          onChanged: (v) {
                            // 2. Hapus semua huruf/simbol KECUALI angka dan koma
                            String cleanString =
                                v.replaceAll(RegExp(r'[^0-9,]'), '');
                            // 3. Ubah koma menjadi titik agar dimengerti oleh Dart sebagai desimal
                            cleanString = cleanString.replaceAll(',', '.');

                            final p = num.tryParse(cleanString) ?? 0;

                            setState(() {
                              _items[index] = MemoItem(
                                namaBarang: item.namaBarang,
                                qty: item.qty,
                                hargaSatuan: p,
                                subtotal: item.qty * p,
                              );
                            });
                          },
                        ),
                      ),
                      if (_items.length > 1) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 32 : 8),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        )
                      ]
                    ],
                  )
                : Column(
                    children: [
                      _buildItemNameAutocomplete(index,
                          label: 'Nama Barang #${index + 1}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildQtyField(index, item, label: 'Qty')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFigmaTextField(
                              label: 'Harga Satuan',
                              controller: priceController,
                              hint: '0',
                              // 1. Ubah keyboard type
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [ThousandSeparatorFormatter()],
                              onChanged: (v) {
                                // 2. Perbaiki regex dan konversi koma ke titik
                                String cleanString =
                                    v.replaceAll(RegExp(r'[^0-9,]'), '');
                                cleanString = cleanString.replaceAll(',', '.');

                                final p = num.tryParse(cleanString) ?? 0;

                                setState(() {
                                  _items[index] = MemoItem(
                                    namaBarang: item.namaBarang,
                                    qty: item.qty,
                                    hargaSatuan: p,
                                    subtotal: item.qty * p,
                                  );
                                });
                              },
                            ),
                          ),
                          if (_items.length > 1) ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red),
                              onPressed: () => _removeItem(index),
                            )
                          ]
                        ],
                      ),
                    ],
                  );

            return fieldLayout;
          },
        ),
      ],
    );
  }

  Widget _buildItemNameAutocomplete(int index, {String? label}) {
    final theme = Theme.of(context);
    final item = _items[index];
    final controller = _itemNameControllers[index];
    final focusNode = _itemNameFocusNodes[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index == 0 || label != null) ...[
          Text(label ?? 'Nama Barang',
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<ItemSuggestion>(
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<ItemSuggestion>.empty();
              }
              try {
                return await _api.searchItemSuggestions(textEditingValue.text);
              } catch (e) {
                return const Iterable<ItemSuggestion>.empty();
              }
            },
            displayStringForOption: (ItemSuggestion option) => option.itemName,
            onSelected: (ItemSuggestion selection) {
              setState(() {
                controller.text = selection.itemName;
                final newPrice = selection.price ?? item.hargaSatuan;
                _itemPriceControllers[index].text =
                    newPrice > 0 ? _formatNumber(newPrice) : '';
                _items[index] = MemoItem(
                  namaBarang: selection.itemName,
                  qty: item.qty,
                  hargaSatuan: newPrice,
                  subtotal: item.qty * newPrice,
                );
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Ketik nama barang...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) {
                  setState(() {
                    _items[index] = MemoItem(
                      namaBarang: v,
                      qty: item.qty,
                      hargaSatuan: item.hargaSatuan,
                      subtotal: item.qty * item.hargaSatuan,
                    );
                  });
                },
                onFieldSubmitted: (value) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final ItemSuggestion option = options.elementAt(index);
                        return ListTile(
                          title: Text(option.itemName,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: option.source == 'STOK'
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  option.source,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: option.source == 'STOK'
                                        ? Colors.blue
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (option.price != null && option.price! > 0)
                                Text('Rp ${_formatNumber(option.price!)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          onTap: () => onSelected(option),
                          hoverColor:
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQtyField(int index, MemoItem item, {String? label}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index == 0 || label != null) ...[
          Text(label ?? 'Qty',
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: item.qty.toString())
                    ..selection = TextSelection.collapsed(
                        offset: item.qty.toString().length),
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 16, bottom: 8),
                    filled: false,
                  ),
                  onChanged: (v) {
                    final newQty = num.tryParse(v) ?? 0;
                    setState(() {
                      _items[index] = MemoItem(
                        namaBarang: item.namaBarang,
                        qty: newQty,
                        hargaSatuan: item.hargaSatuan,
                        subtotal: newQty * item.hargaSatuan,
                      );
                    });
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _items[index] = MemoItem(
                          namaBarang: item.namaBarang,
                          qty: item.qty + 1,
                          hargaSatuan: item.hargaSatuan,
                          subtotal: (item.qty + 1) * item.hargaSatuan,
                        );
                      });
                    },
                    child: const Icon(Icons.expand_less_rounded,
                        size: 20, color: Colors.black54),
                  ),
                  InkWell(
                    onTap: () {
                      if (item.qty > 1) {
                        setState(() {
                          _items[index] = MemoItem(
                            namaBarang: item.namaBarang,
                            qty: item.qty - 1,
                            hargaSatuan: item.hargaSatuan,
                            subtotal: (item.qty - 1) * item.hargaSatuan,
                          );
                        });
                      }
                    },
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFigmaTextField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller != null ? null : initialValue,
          maxLines: maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            suffixIcon: suffixIcon ??
                (readOnly
                    ? Icon(Icons.calendar_today_rounded,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        size: 18)
                    : null),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: theme.colorScheme.surface,
            errorStyle: const TextStyle(height: 1),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection(bool isDesktop) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ITEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_totalQty.toString().replaceAll(RegExp(r'\.0$'), '')} Pcs',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL HARGA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupiah(_totalHarga),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } else {
      List<String> parts = value.toString().split('.');
      String intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '$intPart,${parts[1]}';
    }
  }

  String _formatRupiah(num v) => "Rp ${_formatNumber(v)}";
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SelectionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value;

    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !enabled
              ? Colors.grey.shade50
              : isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !enabled
                ? Colors.grey.shade200
                : isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanString = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    if (cleanString.isEmpty) return oldValue;

    List<String> parts = cleanString.split(',');
    String integerPart = parts[0];
    String fractionalPart =
        parts.length > 1 ? ',${parts.sublist(1).join('')}' : '';

    String digits = integerPart;
    final chars = digits.split('').toList();
    String formatted = '';
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += chars[i];
    }

    formatted += fractionalPart;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
