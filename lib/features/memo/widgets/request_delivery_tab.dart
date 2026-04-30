import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/features/shared/widgets/camera_screen.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import 'package:stok_anandam/data/models/penjadwalan.dart';
import 'package:stok_anandam/data/models/request_delivery.dart';
import 'package:stok_anandam/data/repositories/memo_repository.dart';
import 'package:stok_anandam/features/shared/responsive_table.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/features/memo/utils/memo_auth_utils.dart';
import 'bulk_action_bar.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';

class RequestDeliveryTab extends StatefulWidget {
  final bool showHeader;
  final String? selectedChildStatus;
  const RequestDeliveryTab({
    super.key,
    this.showHeader = true,
    this.selectedChildStatus,
  });

  @override
  State<RequestDeliveryTab> createState() => RequestDeliveryTabState();
}

class RequestDeliveryTabState extends State<RequestDeliveryTab> {
  void refresh() => _loadData();
  bool _isLoading = true;
  List<RequestDelivery> _requests = [];
  String? _error;

  // Sync state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late int _selectedStatusIndex;

  // Selection state
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    final userRole = getIt<CurrentUserStore>().userRole;
    // For delivery, default to index 1 (Perlu Dikirim) as index 0 (Semua) is hidden
    _selectedStatusIndex = (userRole == 'DELIVERY' ||
            userRole == 'GUDANG' ||
            userRole == 'SPV_GUDANG' ||
            userRole == 'ADMIN' ||
            (userRole != null && userRole.startsWith('MARKETING')))
        ? 1
        : 0;
    _loadData();
    
    // Auto refresh via WebSocket
    try {
      final ws = getIt<WebSocketService>();
      _wsSubscription = ws.memoUpdateStream.listen((data) {
        if (data.toUpperCase().contains('REFRESH')) {
          _loadData();
        }
      });
    } catch (_) {
      // WebSocket not available or failed to connect
    }
  }

  @override
  void didUpdateWidget(RequestDeliveryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChildStatus != widget.selectedChildStatus) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = getIt<ApiNewEndpoints>();
      final list = await api.getListRequestDelivery();
      if (mounted) {
        setState(() {
          _requests = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data request delivery';
          _isLoading = false;
        });
      }
    }
  }

  List<RequestDelivery> get _filteredRequests {
    return _requests.where((r) {
      // Filter by status
      bool matchStatus = true;
      if (widget.selectedChildStatus != null) {
        if (widget.selectedChildStatus == 'PERLU') {
          matchStatus = r.status == RequestDeliveryStatus.MENUNGGU_GUDANG ||
              r.status == RequestDeliveryStatus.MENUNGGU_PENGIRIMAN;
        } else if (widget.selectedChildStatus == 'SEDANG') {
          matchStatus = r.status == RequestDeliveryStatus.DALAM_PENGIRIMAN;
        } else if (widget.selectedChildStatus == 'SELESAI') {
          if (getIt<CurrentUserStore>().userRole == 'DELIVERY') {
            return false;
          }
          matchStatus = r.status == RequestDeliveryStatus.SELESAI;
        }
      } else {
        // Fallback to internal selection if needed (though it should be sync'd)
        if (_selectedStatusIndex == 1) {
          matchStatus = r.status == RequestDeliveryStatus.MENUNGGU_GUDANG ||
              r.status == RequestDeliveryStatus.MENUNGGU_PENGIRIMAN;
        } else if (_selectedStatusIndex == 2) {
          matchStatus = r.status == RequestDeliveryStatus.DALAM_PENGIRIMAN;
        } else if (_selectedStatusIndex == 3) {
          if (getIt<CurrentUserStore>().userRole == 'DELIVERY') {
            return false;
          }
          matchStatus = r.status == RequestDeliveryStatus.SELESAI;
        }
      }

      // Filter by search
      bool matchSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchSearch = r.nomorRequest.toLowerCase().contains(query) ||
            r.receiverName.toLowerCase().contains(query) ||
            (r.alamatLengkap?.toLowerCase().contains(query) ?? false);
      }

      return matchStatus && matchSearch;
    }).toList();
  }

  void _onSelectionChanged(int id, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    });
  }

  void _showBulkAssignmentDialog(BuildContext context) {
    if (_selectedIds.isEmpty) return;

    final repository = getIt<MemoRepository>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    Future.wait<List<UserAccount>>([
      repository.getUsersByRole('DELIVERY'),
      repository.getUsersByRole('TEKNISI'),
    ]).then((results) {
      if (!context.mounted) return;
      Navigator.pop(context); // Remove loading

      final drivers = results[0];
      final teknisi = results[1];

      int? selectedDriverId;
      int? selectedTeknisiId;
      DateTime selectedDate = DateTime.now();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Penugasan Manual Request Massal'),
          content: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menugaskan ${_selectedIds.length} manual request.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  const Text('Driver / Pengiriman:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedDriverId,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      hintText: 'Pilih Driver',
                      prefixIcon: const Icon(Icons.local_shipping, size: 20),
                    ),
                    items: drivers
                        .map((u) => DropdownMenuItem<int>(
                            value: u.id, child: Text(u.nama)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDriverId = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Teknisi (Opsional):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedTeknisiId,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      hintText: 'Pilih Teknisi',
                      prefixIcon: const Icon(Icons.build, size: 20),
                    ),
                    items: teknisi
                        .map((u) => DropdownMenuItem<int>(
                            value: u.id, child: Text(u.nama)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedTeknisiId = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tanggal Rencana:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                              "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDriverId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Pilih driver terlebih dahulu")));
                  return;
                }

                try {
                  final api = getIt<ApiNewEndpoints>();
                  await api.createBulkPenjadwalan(
                    requestDeliveryIds: _selectedIds.toList(),
                    personelId: selectedDriverId!,
                    tanggalRencana: selectedDate,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Penugasan berhasil dibuat')),
                    );
                    this.setState(() {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                    });
                    _loadData();
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membuat penugasan: $e')),
                    );
                  }
                }
              },
              child: const Text('Konfirmasi & Simpan'),
            ),
          ],
        ),
      );
    }).catchError((e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal mengambil data: $e")));
      }
    });
  }

  void _showBatchDropOffDialog(BuildContext context) {
    if (_selectedIds.isEmpty) return;
    final repository = getIt<MemoRepository>();
    final memoBloc = context.read<MemoBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    repository.getUsersByRole('DELIVERY').then((drivers) {
      if (!context.mounted) return;
      Navigator.pop(context); // Remove loading

      int? selectedDriverId;
      DateTime selectedDate = DateTime.now();
      final expeditionController = TextEditingController();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Buat Penugasan Drop-off Ekspedisi massal'),
          content: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menugaskan ${_selectedIds.length} manual request.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  const Text('Pilih Driver / Kurir Gudang:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedDriverId,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      hintText: 'Pilih Driver',
                      prefixIcon: const Icon(Icons.local_shipping, size: 20),
                    ),
                    items: drivers
                        .map((u) => DropdownMenuItem<int>(
                            value: u.id, child: Text(u.nama)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDriverId = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nama Ekspedisi (JNE, J&T, Wahana, dll):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: expeditionController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Contoh: JNE / J&T',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.local_post_office, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tanggal Drop-off:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                              "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (selectedDriverId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Pilih driver terlebih dahulu")));
                  return;
                }
                if (expeditionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Isi nama ekspedisi terlebih dahulu")));
                  return;
                }
                memoBloc.add(CreateBatchDropOffEvent(
                  requestDeliveryIds: _selectedIds.toList(),
                  personelId: selectedDriverId!,
                  tanggalRencana: selectedDate,
                  expeditionName: expeditionController.text,
                ));
                Navigator.pop(ctx);
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
                _loadData(); // Refresh current list
              },
              child: const Text('Buat Tugas Drop-off'),
            ),
          ],
        ),
      );
    }).catchError((e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal mengambil data: $e")));
      }
    });
  }

  void _handleBulkStartDelivery(BuildContext context) {
    final selectedRequests = _requests.where((r) => _selectedIds.contains(r.id)).toList();
    final penjadwalanIds = selectedRequests
        .map((r) => r.penjadwalanId)
        .whereType<int>()
        .toList();

    if (penjadwalanIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada jadwal aktif pada request yang dipilih'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    context.read<MemoBloc>().add(BulkMulaiDeliveryEvent(penjadwalanIds));
  }

  Future<void> _handleBulkFinishDelivery(BuildContext context) async {
    final selectedRequests = _requests.where((r) => _selectedIds.contains(r.id)).toList();
    final penjadwalanIds = selectedRequests
        .map((r) => r.penjadwalanId)
        .whereType<int>()
        .toList();

    if (penjadwalanIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada jadwal aktif pada request yang dipilih'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    XFile? photo;
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Selesaikan Kirim Massal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Akan menyelesaikan ${penjadwalanIds.length} pengiriman.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await Navigator.push<XFile>(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    );
                    if (picked != null) setModalState(() => photo = picked);
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: photo == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Ambil Foto Bukti (Wajib)',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(photo!.path),
                                fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima (Wajib)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (photo == null || nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Foto dan Nama Penerima wajib diisi'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                context.read<MemoBloc>().add(BulkSelesaikanDeliveryEvent(
                      penjadwalanIds: penjadwalanIds,
                      photo: photo!,
                      namaPenerima: nameController.text.trim(),
                      catatan: notesController.text.trim(),
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userStore = getIt<CurrentUserStore>();
    final userRole = userStore.userRole?.toUpperCase();
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final filteredList = _filteredRequests;

    return BlocListener<MemoBloc, MemoState>(
      listener: (context, state) {
        if (state is MemoOperationSuccess) {
          setState(() {
            _selectedIds.clear();
            _isSelectionMode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        } else if (state is MemoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showHeader) _buildHeader(isMobile, theme),
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState(context, 'Tidak ada data request delivery')
                    : (isMobile
                        ? _buildMobileList(filteredList)
                        : _buildDesktopTable(filteredList)),
              ),
            ],
          ),
          if (_isSelectionMode && _selectedIds.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: BulkActionBar(
                  count: _selectedIds.length,
                  userRole: userStore.userRole,
                  onClear: () => setState(() {
                    _selectedIds.clear();
                    _isSelectionMode = false;
                  }),
                  onPrint: () {},
                  onChangeStatus: () {},
                  onAssignment: () => _showBulkAssignmentDialog(context),
                  onDropOff: () => _showBatchDropOffDialog(context),
                  onBulkStart: () => _handleBulkStartDelivery(context),
                  onBulkFinish: () => _handleBulkFinishDelivery(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, ThemeData theme) {
    if (!widget.showHeader) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile) ...[
          _buildMobileStatusTabs(theme),
          const SizedBox(height: 16),
        ],
        _buildSearchField(isMobile, theme),
        const SizedBox(height: AppSpacing.md),
        if (!isMobile) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildDesktopFilters(theme),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildMobileStatusTabs(ThemeData theme) {
    final userRole = getIt<CurrentUserStore>().userRole;
    final List<Map<String, dynamic>> tabs = [
      if (userRole != 'DELIVERY') {'index': 0, 'label': 'Semua'},
      {'index': 1, 'label': 'Perlu Dikirim'},
      {'index': 2, 'label': 'Sedang Dikirim'},
      {'index': 3, 'label': 'Selesai Dikirim'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: tabs.map((tab) {
          final bool isSelected = _selectedStatusIndex == tab['index'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(tab['label']),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              selected: isSelected,
              onSelected: (_) =>
                  setState(() => _selectedStatusIndex = tab['index']),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade200,
                ),
              ),
              showCheckmark: false,
              elevation: isSelected ? 2 : 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField(bool isMobile, ThemeData theme) {
    final userStore = getIt<CurrentUserStore>();
    final userRole = userStore.userRole?.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari No. Request atau Pelanggan...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                      size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(
                        color: theme.colorScheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMobile &&
                    ['ADMIN', 'GUDANG', 'SPV_GUDANG'].contains(userRole)) ...[
                  IconButton(
                    onPressed: () =>
                        setState(() => _isSelectionMode = !_isSelectionMode),
                    icon: Icon(
                      _isSelectionMode
                          ? Icons.close_rounded
                          : Icons.checklist_rtl_rounded,
                      color: _isSelectionMode
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    tooltip: _isSelectionMode ? 'Batal Pilih' : 'Pilih Banyak',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ],
                if (!isMobile &&
                    ((userRole != null && userRole.startsWith('MARKETING')) ||
                        userRole == 'ADMIN' ||
                        userRole == 'SPV_MARKETING'))
                  IconButton(
                    onPressed: () async {
                      await context.push(AppRoutes.requestDeliveryCreate);
                      _loadData();
                    },
                    icon: Icon(Icons.add_rounded,
                        color: theme.colorScheme.primary),
                    tooltip: 'Tambah Request Baru',
                  ),
                IconButton(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh_rounded,
                      color: theme.colorScheme.primary),
                  tooltip: 'Segarkan',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          height: 40,
          child: SegmentedButton<int>(
            segments: getIt<CurrentUserStore>().userRole == 'DELIVERY'
                ? const [
                    ButtonSegment(
                        value: 1,
                        label: Text('Perlu Dikirim'),
                        icon: Icon(Icons.pending_actions_rounded, size: 18)),
                    ButtonSegment(
                        value: 2,
                        label: Text('Sedang Dikirim'),
                        icon: Icon(Icons.local_shipping_rounded, size: 18)),
                    ButtonSegment(
                        value: 3,
                        label: Text('Selesai Dikirim'),
                        icon: Icon(Icons.check_circle_rounded, size: 18)),
                  ]
                : const [
                    ButtonSegment(
                        value: 0,
                        label: Text('Semua'),
                        icon: Icon(Icons.all_inbox_rounded, size: 18)),
                    ButtonSegment(
                        value: 1,
                        label: Text('Perlu Dikirim'),
                        icon: Icon(Icons.pending_actions_rounded, size: 18)),
                    ButtonSegment(
                        value: 2,
                        label: Text('Sedang Dikirim'),
                        icon: Icon(Icons.local_shipping_rounded, size: 18)),
                    ButtonSegment(
                        value: 3,
                        label: Text('Selesai Dikirim'),
                        icon: Icon(Icons.check_circle_rounded, size: 18)),
                  ],
            selected: {_selectedStatusIndex},
            onSelectionChanged: (set) =>
                setState(() => _selectedStatusIndex = set.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              selectedBackgroundColor:
                  theme.colorScheme.primary.withOpacity(0.1),
              selectedForegroundColor: theme.colorScheme.primary,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(List<RequestDelivery> list) {
    final userStore = getIt<CurrentUserStore>();
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = _selectedIds.contains(item.id);
        final theme = Theme.of(context);

        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () async {
              if (_isSelectionMode || _selectedIds.isNotEmpty) {
                _onSelectionChanged(item.id!, !isSelected);
              } else {
                MemoAuthUtils.guardManualTaskAccess(
                  context,
                  role: userStore.userRole,
                  statusJadwal: item.status.name,
                  onGranted: () => context.pushNamed(AppRoutes.manualTaskDetail,
                      pathParameters: {'id': 'req-${item.id}'}),
                );
                _loadData();
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(item.id!);
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _toTitleCase(item.receiverName),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.nomorRequest,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                  ),
                  // Middle Section
                  Row(
                    children: [
                      Icon(Icons.map_outlined,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.alamatLengkap ?? 'Wilayah / Area',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bottom Section
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ReqStatusBadge(status: item.status),
                      if (item.isUrgen) _buildUrgentIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _toTitleCase(String str) {
    if (str.isEmpty) return str;
    return str.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildDesktopTable(List<RequestDelivery> list) {
    final userStore = getIt<CurrentUserStore>();
    return ResponsiveDataTable(
      dataRowMaxHeight: 60,
      dataRowMinHeight: 52,
      headingRowHeight: 48,
      horizontalMargin: 20,
      columnFlex: const [
        5,
        4,
        3,
        3,
        2,
        3
      ], // Sync with DeliveryDesktopTableView
      showCheckboxColumn: _isSelectionMode,
      onSelectAll: (val) {
        setState(() {
          if (val == true) {
            _selectedIds.addAll(list.map((e) => e.id!));
          } else {
            _selectedIds.clear();
          }
        });
      },
      columns: [
        buildDataColumn('PELANGGAN', alignment: Alignment.centerLeft),
        buildDataColumn('WILAYAH / AREA', alignment: Alignment.centerLeft),
        buildDataColumn('TGL JADWAL', alignment: Alignment.centerLeft),
        buildDataColumn('MARKETING', alignment: Alignment.centerLeft),
        buildDataColumn('TIPE', alignment: Alignment.centerLeft),
        buildDataColumn('STATUS', alignment: Alignment.centerLeft),
      ],
      rows: list.map((item) {
        final addressParts = (item.alamatLengkap ?? '-').split(',');
        final kabKota = addressParts.length > 1
            ? addressParts[addressParts.length - 2]
            : addressParts[0];
        final kecamatan = addressParts.isNotEmpty ? addressParts[0] : '';

        return DataRow(
          selected: _selectedIds.contains(item.id),
          onSelectChanged: _isSelectionMode
              ? (val) => _onSelectionChanged(item.id!, val)
              : (val) {
                  if (val == true) {
                    MemoAuthUtils.guardManualTaskAccess(
                      context,
                      role: userStore.userRole,
                      statusJadwal: item.status.name,
                      onGranted: () => context.pushNamed(AppRoutes.manualTaskDetail,
                          pathParameters: {'id': 'req-${item.id}'}),
                    );
                    _loadData();
                  }
                },
          cells: [
            // PELANGGAN
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.receiverName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF1E293B))),
                    if (item.receiverPhone != null)
                      Text(item.receiverPhone!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            // WILAYAH / AREA
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kabKota.trim().toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: 0.5)),
                    Text(kecamatan.trim().toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // TGL JADWAL
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    item.createdAt != null
                        ? DateFormat('dd-MM-yyyy').format(item.createdAt!)
                        : '-',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
              ),
            ),
            // MARKETING
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Text(item.creatorName ?? '-',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500)),
              ),
            ),
            // TIPE
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('DIRECT',
                      style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
              ),
            ),
            // STATUS
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReqStatusBadge(status: item.status),
                    if (item.isUrgen) ...[
                      const SizedBox(width: 6),
                      _buildUrgentIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ],
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(item.id!);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.note_alt_outlined,
                  size: 64, color: Colors.blue.shade200),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan coba filter atau pencarian lain',
              style: TextStyle(fontSize: 14, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.25), width: 1),
      ),
      child: const Text(
        'URGEN',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ReqStatusBadge extends StatelessWidget {
  final RequestDeliveryStatus status;
  const ReqStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String label = status.name.replaceAll('_', ' ');
    Color color = Colors.grey;

    switch (status) {
      case RequestDeliveryStatus.DRAFT:
        label = 'DRAFT';
        color = Colors.grey;
        break;
      case RequestDeliveryStatus.MENUNGGU_GUDANG:
        label = 'Menunggu Gudang';
        color = Colors.orange;
        break;
      case RequestDeliveryStatus.MENUNGGU_PENGIRIMAN:
        label = 'Menunggu Pengiriman';
        color = Colors.orange;
        break;
      case RequestDeliveryStatus.DALAM_PENGIRIMAN:
        label = 'Sedang Dikirim';
        color = Colors.indigo;
        break;
      case RequestDeliveryStatus.SELESAI:
        label = 'Selesai';
        color = Colors.green;
        break;
      case RequestDeliveryStatus.DIBATALKAN:
        label = 'Dibatalkan';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
