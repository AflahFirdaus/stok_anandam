import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';

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

  const CreateMemoPage({
    super.key,
    this.memoType = 'BIASA',
    this.initialData,
    this.continuationId,
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
  final _api = getIt<ApiNewEndpoints>();

  // State Variables
  List<EmployeeOption> _employeeCodes = [];
  bool _isLoadingEmployees = false;
  EmployeeOption? _selectedMarketing;
  bool _isPending = false;
  bool _prosesTeknis = true;
  bool _prosesKirim = false;
  String? _driverValue = 'Marketing';
  String? _selectedPayment = 'Cash';

  // New Memo Type Fields
  late String _memoType;
  final _orderIdController = TextEditingController();
  final _resiController = TextEditingController();
  String? _selectedEkspedisi;
  String? _selectedPlatform;

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
      }
      _isPending = data.statusAkhir == MemoStatus.DISETUJUI ||
          data.statusAkhir == MemoStatus.MENUNGGU_PERSETUJUAN;
      _prosesTeknis = data.isTeknisRequired;
      _prosesKirim = data.isDeliveryRequired;
      _selectedPayment = data.metodePembayaran;
      _orderIdController.text = data.orderIdMarketplace ?? '';
      _resiController.text = data.resi ?? '';
      _selectedEkspedisi = data.ekspedisi;
      _selectedPlatform = data.platform;
      _tempoController.text = data.tempo ?? '';
      _tempoController.text = data.tempo ?? '';

      if (data.items.isNotEmpty) {
        _items.addAll(data.items);
      } else {
        _items.add(MemoItem(namaBarang: '', qty: 1, hargaSatuan: 0, subtotal: 0));
      }
    } else {
      _items.add(MemoItem(namaBarang: '', qty: 1, hargaSatuan: 0, subtotal: 0));
    }

    // Initialize controllers for items
    for (var item in _items) {
      _itemNameControllers.add(TextEditingController(text: item.namaBarang));
      _itemPriceControllers.add(TextEditingController(
          text: item.hargaSatuan > 0 ? _formatNumber(item.hargaSatuan) : ''));
      _itemNameFocusNodes.add(FocusNode());
    }

    _loadEmployeeCodes();
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
    for (var c in _itemNameControllers) {
      c.dispose();
    }
    for (var c in _itemPriceControllers) {
      c.dispose();
    }
    for (var f in _itemNameFocusNodes) {
      f.dispose();
    }
    _tempoController.dispose();
    super.dispose();
  }


  Future<void> _loadEmployeeCodes() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final options = await _api.getEmployeeCodes();
      setState(() {
        _employeeCodes = options;
        _isLoadingEmployees = false;

        // Pre-select current user if not already set (e.g. from initialData)
        if (_selectedMarketing == null) {
          final currentUser = getIt<CurrentUserStore>();
          final currentEmpCode = currentUser.employeeCode;

          if (currentEmpCode != null) {
            try {
              _selectedMarketing =
                  _employeeCodes.firstWhere((e) => e.empCode == currentEmpCode);
            } catch (_) {
              // If not found by code, try by name as fallback
              final currentName = currentUser.displayName;
              if (currentName != null) {
                try {
                  _selectedMarketing = _employeeCodes
                      .firstWhere((e) => e.empName == currentName);
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
        qty: 1,
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

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan minimal satu barang')),
        );
        return;
      }

      final request = {
        'namaCustomer': _namaController.text,
        'nama_customer': _namaController.text,
        'noHpCustomer': _noHpController.text,
        'no_hp_customer': _noHpController.text,
        'tanggal': _tanggalController.text,
        'namaMarketing':
            _selectedMarketing?.empName ?? _marketingController.text,
        'nama_marketing':
            _selectedMarketing?.empName ?? _marketingController.text,
        'marketingEmpCode': _selectedMarketing?.empCode,
        'marketing_emp_code': _selectedMarketing?.empCode,
        'deskripsi': _deskripsiController.text,
        'isTeknisi': _prosesTeknis,
        'is_teknisi': _prosesTeknis,
        'isKirim': _memoType == 'ONLINE' ? true : _prosesKirim,
        'is_kirim': _memoType == 'ONLINE' ? true : _prosesKirim,
        'opsiPengiriman': (_memoType == 'ONLINE' || _prosesKirim)
            ? _driverValue
            : 'Ambil di Toko',
        'opsi_pengiriman': (_memoType == 'ONLINE' || _prosesKirim)
            ? _driverValue
            : 'Ambil di Toko',
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
        'ekspedisi': _selectedEkspedisi,
        'platform': _selectedPlatform,
        'tempo':
            _tempoController.text.isNotEmpty ? _tempoController.text : null,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green),
              );
              if (state.id != null) {
                context.goNamed(AppRoutes.memoDetail,
                    pathParameters: {'id': state.id!});
              } else {
                context.go(AppRoutes.memo);
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
                          color: Colors.black.withOpacity(0.04),
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
                          if (_memoType == 'ONLINE' ||
                              _memoType == 'DISTRIBUSI' ||
                              _memoType == 'PROJECT') ...[
                            _buildInformasiTambahan(isDesktop),
                            const SizedBox(height: 32),
                          ],
                          const Divider(),
                          const SizedBox(height: 32),
                          _buildItemsSection(isDesktop),
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
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
      ],
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
                    label: 'Order ID Marketplace',
                    controller: _orderIdController,
                    hint: 'Contoh: ORD-12345',
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
                  label: 'Order ID Marketplace',
                  controller: _orderIdController,
                  hint: 'Contoh: ORD-12345',
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
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
          if (_prosesKirim && _memoType != 'ONLINE') ...[
            const SizedBox(height: 24),
            _buildDriverSelectionDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildInformasiTambahan(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Informasi Tambahan', Icons.info_outline_rounded),
        const SizedBox(height: 20),
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
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: _buildEkspedisiDropdown()),
              ],
            ],
          )
        else
          Column(
            children: [
              if (_memoType == 'PROJECT' || _memoType == 'ONLINE') ...[
                _buildPlatformDropdown(),
                const SizedBox(height: 20),
              ],
              if (_memoType == 'ONLINE' || _memoType == 'DISTRIBUSI') ...[
                _buildFigmaTextField(
                  label: 'No. Resi (Opsional)',
                  controller: _resiController,
                  hint: 'Contoh: JNT-12345',
                ),
                const SizedBox(height: 20),
                _buildEkspedisiDropdown(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        const SizedBox(height: 20),
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
          value: _selectedPlatform,
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
                  : ['SIPLAH', 'INAPROC', 'MBIZ', 'GO', 'DRM', 'TISERA'])
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedPlatform = v),
        ),
      ],
    );
  }

  Widget _buildEkspedisiDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ekspedisi',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedEkspedisi,
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
          hint: const Text('Pilih Ekspedisi'),
          items: [
            'GP TRANS',
            'SABILA SHUTTLE',
            'WIDHI UTAMA',
            'REGULER',
            'INSTAN',
            'ANDI'
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedEkspedisi = v),
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
            ? theme.colorScheme.primary.withOpacity(0.03)
            : Colors.transparent,
        border: Border.all(
          color: _isPending
              ? theme.colorScheme.primary.withOpacity(0.2)
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
            activeColor: theme.colorScheme.primary,
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
        const Text('Nama Customer',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
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
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: theme.textTheme.bodyLarge,
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
                          title: Text(option.namaPelanggan ?? '-',
                              style: const TextStyle(fontSize: 14)),
                          subtitle: option.noHp != null
                              ? Text(option.noHp!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey))
                              : null,
                          onTap: () => onSelected(option),
                          hoverColor:
                              theme.colorScheme.primary.withOpacity(0.05),
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
        DropdownButtonFormField<EmployeeOption>(
          value: _employeeCodes.contains(_selectedMarketing)
              ? _selectedMarketing
              : null,
          icon: _isLoadingEmployees
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey),
          decoration: InputDecoration(
            hintText: 'Pilih Marketing',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary)),
          ),
          items: _employeeCodes
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.empName, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (v) {
            setState(() => _selectedMarketing = v);
          },
          // Removed validator to make marketing optional (backend will default to creator)
        ),
      ],
    );
  }

  Widget _buildDriverSelectionDropdown() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pengirim',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: ['Marketing', 'Driver', 'Lainnya'].contains(_driverValue)
              ? _driverValue
              : null,
          style: theme.textTheme.bodyLarge,
          items: ['Marketing', 'Driver', 'Lainnya']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _driverValue = v),
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
          value: ['Cash', 'Transfer', 'Tempo', 'Lainnya']
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
            final nameController = _itemNameControllers[index];
            final priceController = _itemPriceControllers[index];
            final nameFocusNode = _itemNameFocusNodes[index];

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
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandSeparatorFormatter()],
                          onChanged: (v) {
                            final p = num.tryParse(
                                    v.replaceAll(RegExp(r'[^0-9]'), '')) ??
                                0;
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [ThousandSeparatorFormatter()],
                              onChanged: (v) {
                                final p = num.tryParse(
                                        v.replaceAll(RegExp(r'[^0-9]'), '')) ??
                                    0;
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
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
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
                              theme.colorScheme.primary.withOpacity(0.05),
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
                        color: theme.colorScheme.primary.withOpacity(0.7),
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

  String _formatNumber(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
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
                    color: theme.colorScheme.primary.withOpacity(0.3),
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
                    ? Colors.white.withOpacity(0.2)
                    : theme.colorScheme.primary.withOpacity(0.05),
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
                          ? Colors.white.withOpacity(0.8)
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

    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return oldValue;

    final chars = digits.split('').toList();
    String formatted = '';
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += chars[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
