import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';
import '../../data/api_new_endpoints.dart';
import '../../injection.dart';
import '../layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import '../shared/responsive_padding.dart';
import '../shared/item_deck_card.dart';
import '../shared/modern_filter.dart';
import '../shared/responsive_table.dart';
import 'bloc/canvas_list_bloc.dart';
import 'bloc/canvas_list_event.dart';
import 'bloc/canvas_list_state.dart';
import '../shared/migration_sync_mixin.dart';
import 'package:stok_anandam/features/presence/mixins/presence_action_mixin.dart';

/// Mengubah pesan error dari server/teknis jadi pesan yang mudah dipahami user.
/// Mengembalikan null jika pesan terlihat teknis (DB, constraint, exception), agar dipakai pesan default.
String? _pesanErrorUser(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final t = raw.trim().toLowerCase();
  if (t.contains('constraint') ||
      t.contains('violates') ||
      t.contains('relation') ||
      t.contains('failing row') ||
      t.contains('detail:') ||
      t.contains('exception') ||
      t.contains('dioexception') ||
      t.length > 120) {
    return null;
  }
  return raw.trim();
}

/// State filter Canvas disimpan agar saat pindah menu lalu balik, filter tetap.
class _CanvasFilterState {
  _CanvasFilterState._();
  static String search = '';
  static String sortBy = 'namaInstansi';
  static String direction = 'asc';
  static int size = 50;

  static void reset() {
    search = '';
    sortBy = 'namaInstansi';
    direction = 'asc';
    size = 20;
  }
}

class CanvasPage extends StatelessWidget {
  const CanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CanvasListBloc(),
      child: const _CanvasContent(),
    );
  }
}

class _CanvasContent extends StatefulWidget {
  const _CanvasContent();

  @override
  State<_CanvasContent> createState() => _CanvasContentState();
}

class _CanvasContentState extends State<_CanvasContent>
    with MigrationSyncMixin, PresenceActionMixin {
  String _sortBy = 'namaInstansi';
  String _direction = 'asc';
  int _size = 50;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);

  void _restoreFilterState() {
    _searchController.text = _CanvasFilterState.search;
    _sortBy = _CanvasFilterState.sortBy;
    _direction = _CanvasFilterState.direction;
    _size = _CanvasFilterState.size;
  }

  void _persistFilterState() {
    _CanvasFilterState.search = _searchController.text;
    _CanvasFilterState.sortBy = _sortBy;
    _CanvasFilterState.direction = _direction;
    _CanvasFilterState.size = _size;
  }

  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_CanvasFilterState.reset);
    _restoreFilterState();
    fetchLastSync();
    _searchController.addListener(_onCanvasSearchChanged);
    // Load with restored filter state (BlocProvider already created with default; first real load here)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(0);
    });
  }

  void _onCanvasSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      _persistFilterState();
      _load(0);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onCanvasSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _load(int page) {
    context.read<CanvasListBloc>().add(CanvasListRequested(
          page: page,
          size: _size,
          sortBy: _sortBy,
          direction: _direction,
          search: _searchController.text,
        ));
  }

  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateDataCanvasSheet(
        onSaved: () {
          // Refresh canvas list if needed
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    return BlocBuilder<CanvasListBloc, CanvasListState>(
      builder: (context, state) {
        final isLoading =
            state is CanvasListLoading || state is CanvasListInitial;
        final isLoaded = state is CanvasListLoaded;
        final items = isLoaded ? state.items : <Canvasing>[];
        final page = isLoaded ? state.page : 0;
        final totalPages = isLoaded ? state.totalPages : 0;
        final totalElements = isLoaded ? state.totalElements : 0;

        return DashboardShell(
          currentRoute: AppRoutes.canvas,
          onScan: () => context.pushNamed(AppRoutes.scanner),
          userName: getIt<CurrentUserStore>().displayName,
          userRole: getIt<CurrentUserStore>().userRole,
          headerActionLabel: 'Sync Migrasi',
          headerActionIcon: Icons.sync_rounded,
          onHeaderAction: () =>
              showSyncMigrationDialog(onCustomSuccess: () => _load(0)),
          lastSync: lastSyncFormatted,
          showHeaderActionInAppBar: true,
          onRefresh: isLoading ? null : () => _load(0),
          onNavigate: (route) {
            if (route != AppRoutes.canvas) context.go(route);
          },
          onLogout: () async {
            await getIt<AuthService>().logout();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
          child: Padding(
            padding: ResponsivePadding.all(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: isLoading ? null : _openCreateSheet,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Tambah Data Canvas'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _FiltersSection(
                    searchController: _searchController,
                    searchFocus: _searchFocus,
                    onSearchSubmitted: () {
                      _persistFilterState();
                      _load(0);
                    },
                    sortBy: _sortBy,
                    direction: _direction,
                    size: _size,
                    onApply: (sortBy, direction, size) {
                      setState(() {
                        _sortBy = sortBy;
                        _direction = direction;
                        _size = size;
                        _persistFilterState();
                      });
                      _load(0);
                    },
                    content: RefreshIndicator(
                      onRefresh: () async => _load(0),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (state is CanvasListError)
                              _ErrorSection(
                                message: state.message,
                                onRetry: () => _load(0),
                              )
                            else if (items.isEmpty)
                              _EmptySection(onRetry: () => _load(0))
                            else
                              isMobile
                                  ? _CanvasDeckList(items: items)
                                  : _CanvasTable(items: items),
                            if (isLoaded && items.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _PaginationBar(
                                page: page,
                                totalPages: totalPages,
                                totalElements: totalElements,
                                onPrev: totalPages > 0 && page > 0
                                    ? () => _load(page - 1)
                                    : null,
                                onNext: totalPages > 0 && page < totalPages - 1
                                    ? () => _load(page + 1)
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FiltersSection extends StatefulWidget {
  const _FiltersSection({
    required this.searchController,
    required this.searchFocus,
    required this.onSearchSubmitted,
    required this.sortBy,
    required this.direction,
    required this.size,
    required this.onApply,
    required this.content,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchSubmitted;
  final String sortBy;
  final String direction;
  final int size;
  final void Function(
    String sortBy,
    String direction,
    int size,
  ) onApply;
  final Widget content;

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  late String _sortBy;
  late String _direction;
  late int _size;

  @override
  void initState() {
    super.initState();
    _resetToCurrent();
  }

  void _resetToCurrent() {
    _sortBy = widget.sortBy;
    _direction = widget.direction;
    _size = widget.size;
  }

  @override
  void didUpdateWidget(_FiltersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy ||
        oldWidget.direction != widget.direction ||
        oldWidget.size != widget.size) {
      _resetToCurrent();
    }
  }

  static const _sortOptions = [
    ('namaInstansi', 'Nama Instansi'),
    ('kategori', 'Kategori'),
    ('provinsi', 'Provinsi'),
    ('kabupaten', 'Kabupaten'),
    ('kecamatan', 'Kecamatan'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return FixedSearchFilterLayout(
      searchBar: ModernSearchBar(
        controller: widget.searchController,
        focusNode: widget.searchFocus,
        onSubmitted: widget.onSearchSubmitted,
        hintText: 'Cari nama instansi, kategori, lokasi...',
        onChanged: (_) {},
      ),
      filterTitle: 'Filter & Urutkan',
      filterContentBuilder: (close, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Urutkan berdasarkan',
            icon: Icons.sort_rounded,
            children: _sortOptions.map<Widget>((option) {
              return CustomFilterChip(
                label: option.$2,
                selected: _sortBy == option.$1,
                onTap: () {
                  setState(() => _sortBy = option.$1);
                  refresh();
                },
              );
            }).toList(),
          ),
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Arah urutan',
            icon: Icons.swap_vert_rounded,
            children: [
              FilterSegmentedButton<String>(
                value: _direction,
                onChanged: (v) {
                  setState(() => _direction = v);
                  refresh();
                },
                segments: const {
                  'asc': (
                    label: 'A–Z',
                    icon: Icons.arrow_upward_rounded,
                  ),
                  'desc': (
                    label: 'Z–A',
                    icon: Icons.arrow_downward_rounded,
                  ),
                },
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 20),
          FilterGroup(
            title: 'Per halaman',
            icon: Icons.view_list_rounded,
            children: [10, 20, 50, 100].map<Widget>((s) {
              return CustomFilterChip(
                label: '$s',
                selected: _size == s,
                onTap: () {
                  setState(() => _size = s);
                  refresh();
                },
              );
            }).toList(),
          ),
          FilterFooter(
            onApply: () {
              widget.onApply(_sortBy, _direction, _size);
              close();
            },
            onReset: () {
              setState(() {
                _sortBy = 'namaInstansi';
                _direction = 'asc';
                _size = 50;
              });
              widget.onApply(_sortBy, _direction, _size);
              close();
            },
          ),
        ],
      ),
      child: widget.content,
    );
  }
}

class _CanvasTable extends StatelessWidget {
  const _CanvasTable({required this.items});
  final List<Canvasing> items;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable(
      minColumnWidth: 120.0,
      columnSpacing: 12.0,
      headingRowColor: Colors.grey.shade50,
      columns: [
        buildDataColumn('Nama Instansi'),
        buildDataColumn('Kategori'),
        buildDataColumn('Provinsi'),
        buildDataColumn('Kabupaten'),
        buildDataColumn('Kecamatan'),
      ],
      rows: items
          .map(
            (c) => DataRow(
              cells: [
                buildDataCell(_v(c.namaInstansi)),
                buildDataCell(_v(c.kategori)),
                buildDataCell(_v(c.provinsi)),
                buildDataCell(_v(c.kabupaten)),
                buildDataCell(_v(c.kecamatan)),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _CanvasDeckList extends StatelessWidget {
  const _CanvasDeckList({required this.items});
  final List<Canvasing> items;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = items[i];
        return DataDeckCard(
          title: _v(c.namaInstansi),
          subtitle: _v(c.kategori),
          rows: [
            (label: 'Provinsi', value: _v(c.provinsi)),
            (label: 'Kabupaten', value: _v(c.kabupaten)),
            (label: 'Kecamatan', value: _v(c.kecamatan)),
          ],
        );
      },
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Tidak ada data canvas',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalElements,
    this.onPrev,
    this.onNext,
  });
  final int page;
  final int totalPages;
  final int totalElements;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Halaman ${page + 1} dari ${totalPages > 0 ? totalPages : 1} • Total $totalElements item',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              IconButton.filled(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Helper: Highlight matching text in search results ---

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.query,
    this.fontSize = 14,
  });

  final String text;
  final String query;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(fontSize: fontSize),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchStart = lowerText.indexOf(lowerQuery);

    if (matchStart == -1) {
      return Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(fontSize: fontSize),
      );
    }

    final matchEnd = matchStart + lowerQuery.length;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Text.rich(
      TextSpan(
        children: [
          if (matchStart > 0)
            TextSpan(
              text: text.substring(0, matchStart),
              style: TextStyle(fontSize: fontSize),
            ),
          TextSpan(
            text: text.substring(matchStart, matchEnd),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              backgroundColor: primaryColor.withValues(alpha: 0.08),
            ),
          ),
          if (matchEnd < text.length)
            TextSpan(
              text: text.substring(matchEnd),
              style: TextStyle(fontSize: fontSize),
            ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

// --- Create Data Canvas bottom sheet ---

class _CreateDataCanvasSheet extends StatefulWidget {
  const _CreateDataCanvasSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<_CreateDataCanvasSheet> createState() => _CreateDataCanvasSheetState();
}

/// Opsi dropdown Kunjungan Canvas: CANVAS / VISIT (huruf kapital semua)
const _canvasVisitOptions = [
  ('CANVAS', 'CANVAS'),
  ('VISIT', 'VISIT'),
];

class _CreateDataCanvasSheetState extends State<_CreateDataCanvasSheet> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _catatanController = TextEditingController();
  bool _saving = false;
  String? _error;
  List<CanvasingOption> _canvasingList = [];
  bool _loadingCanvasing = true;
  List<CanvasingOption>? _serverSearchResults;
  String? _serverSearchQuery;
  bool _isSearchingServer = false;
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 300);

  static String _optionLabel(CanvasingOption o) =>
      o.namaInstansi?.trim().isEmpty != true ? (o.namaInstansi ?? '') : '—';

  Object? _selectedCanvasingId;
  DateTime? _tanggal;
  String? _selectedCanvasVisit;

  @override
  void initState() {
    super.initState();
    _loadCanvasingOptions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _keteranganController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadCanvasingOptions() async {
    try {
      final api = getIt<ApiNewEndpoints>();
      final options = await api.getCanvasingOptions(limit: 200);
      if (mounted) {
        setState(() {
          _canvasingList = options;
          _loadingCanvasing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCanvasing = false);
    }
  }

  Future<void> _searchCanvasingOnServer(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    if (mounted) setState(() => _isSearchingServer = true);
    try {
      final api = getIt<ApiNewEndpoints>();
      final options = await api.getCanvasingOptions(search: q, limit: 100);
      if (!mounted) return;
      setState(() {
        _serverSearchResults = options;
        _serverSearchQuery = q.toLowerCase();
        _isSearchingServer = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _serverSearchResults = [];
          _serverSearchQuery = query.trim().toLowerCase();
          _isSearchingServer = false;
        });
      }
    }
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCanvasingId == null) {
      setState(() => _error = 'Pilih instansi canvas.');
      return;
    }
    if (_tanggal == null) {
      setState(() => _error = 'Pilih tanggal.');
      return;
    }
    if (_selectedCanvasVisit == null || _selectedCanvasVisit!.isEmpty) {
      setState(() => _error = 'Pilih jenis kunjungan (Canvas / Visit).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final tanggalStr =
          '${_tanggal!.year}-${_tanggal!.month.toString().padLeft(2, '0')}-${_tanggal!.day.toString().padLeft(2, '0')}';
      final api = getIt<DataCanvasingControllerApi>();
      final req = DataCanvasingRequest(
        canvasingId: _selectedCanvasingId,
        tanggal: tanggalStr,
        canvasVisit: _selectedCanvasVisit,
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
      );
      final response = await api.create(dataCanvasingRequest: req);
      if (isResponseSuccess(response.data?.status) && mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      } else {
        if (mounted) {
          setState(() {
            _saving = false;
            _error = _pesanErrorUser(response.data?.message?.toString()) ??
                'Data tidak berhasil disimpan.';
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String message = 'Data tidak berhasil disimpan. Coba lagi.';
        if (e.response?.statusCode == 409) {
          message =
              'Data sudah ada. Cek instansi, tanggal, dan jenis kunjungan (CANVAS/VISIT).';
        } else {
          final body = e.response?.data;
          if (body is Map && body['message'] != null) {
            final msg = _pesanErrorUser(body['message'].toString());
            if (msg != null && msg.isNotEmpty) message = msg;
          }
        }
        setState(() {
          _saving = false;
          _error = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Data tidak berhasil disimpan. Coba lagi.';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final screenW = media.size.width;
            final _ = screenW < 600; // isMobile reserved for future use
            const horizontalPadding = 24.0 * 2;
            final fieldWidth = (constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : screenW - horizontalPadding)
                .clamp(0.0, screenW - 24);
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: fieldWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Tambah Data Canvas',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                  color: Colors.red.shade800, fontSize: 13),
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text('Instansi Canvas',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700)),
                        const SizedBox(height: 6),
                        _loadingCanvasing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()))
                            : Autocomplete<CanvasingOption>(
                                displayStringForOption: (c) => _optionLabel(c),
                                optionsBuilder: (value) {
                                  final q = value.text.trim().toLowerCase();
                                  // Jika kosong, tampilkan semua cache
                                  if (q.isEmpty) {
                                    return _canvasingList;
                                  }
                                  // Prioritaskan hasil server jika ada
                                  final server = _serverSearchResults;
                                  final serverQ = _serverSearchQuery;
                                  if (server != null && serverQ != null) {
                                    // Gunakan server results jika query cocok atau lebih spesifik
                                    if (q.contains(serverQ) ||
                                        serverQ.contains(q)) {
                                      return server.where((c) => _optionLabel(c)
                                          .toLowerCase()
                                          .contains(q));
                                    }
                                  }
                                  // Fallback: filter dari cache lokal
                                  return _canvasingList.where((c) =>
                                      _optionLabel(c)
                                          .toLowerCase()
                                          .contains(q));
                                },
                                onSelected: (c) =>
                                    setState(() => _selectedCanvasingId = c.id),
                                fieldViewBuilder: (context, controller,
                                    focusNode, onFieldSubmitted) {
                                  return StatefulBuilder(
                                    builder: (ctx, setLocalState) {
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          hintText: 'Ketik untuk mencari instansi...',
                                          prefixIcon: _isSearchingServer
                                              ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.search_rounded,
                                                  size: 20),
                                          suffixIcon: controller.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                      Icons.close_rounded,
                                                      size: 18),
                                                  tooltip: 'Hapus pencarian',
                                                  onPressed: () {
                                                    controller.clear();
                                                    setLocalState(() {});
                                                    setState(() {
                                                      _selectedCanvasingId =
                                                          null;
                                                      _serverSearchResults =
                                                          null;
                                                      _serverSearchQuery = null;
                                                      _isSearchingServer =
                                                          false;
                                                    });
                                                    _searchDebounce?.cancel();
                                                  },
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: Theme.of(ctx)
                                                  .colorScheme
                                                  .primary,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                          isDense: true,
                                        ),
                                        onChanged: (text) {
                                          setLocalState(() {});
                                          setState(() =>
                                              _selectedCanvasingId = null);
                                          final trimmed = text.trim();
                                          _searchDebounce?.cancel();
                                          if (trimmed.isEmpty) {
                                            setState(() {
                                              _serverSearchResults = null;
                                              _serverSearchQuery = null;
                                              _isSearchingServer = false;
                                            });
                                            return;
                                          }
                                          // Trigger server search dari 1 karakter
                                          _searchDebounce = Timer(
                                              _searchDebounceDuration, () {
                                            if (mounted &&
                                                controller.text
                                                        .trim()
                                                        .isNotEmpty) {
                                              _searchCanvasingOnServer(
                                                  controller.text.trim());
                                            }
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                optionsViewBuilder:
                                    (context, onSelected, options) {
                                  final ctx = context;
                                  final isNarrow =
                                      MediaQuery.sizeOf(ctx).width < 600;
                                  final itemPadding = EdgeInsets.symmetric(
                                    horizontal: isNarrow ? 20 : 16,
                                    vertical: isNarrow ? 14 : 10,
                                  );
                                  final maxHeight = isNarrow ? 240.0 : 260.0;
                                  // Ambil query saat ini untuk highlight
                                  final currentQuery = _serverSearchQuery ?? '';

                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 12 : 0,
                                      ),
                                      child: Material(
                                        elevation: 6,
                                        shadowColor:
                                            Colors.black.withValues(alpha: 0.15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: fieldWidth,
                                            maxHeight: maxHeight,
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: _isSearchingServer &&
                                                    options.isEmpty
                                                // Loading state
                                                ? const Padding(
                                                    padding:
                                                        EdgeInsets.all(20),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          'Mencari...',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .grey,
                                                              fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : options.isEmpty
                                                    // Empty state
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .search_off_rounded,
                                                              color: Colors
                                                                  .grey
                                                                  .shade400,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                              'Instansi tidak ditemukan',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey
                                                                    .shade500,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    // Results list
                                                    : ListView.separated(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        shrinkWrap: true,
                                                        itemCount:
                                                            options.length,
                                                        separatorBuilder:
                                                            (_, __) => Divider(
                                                          height: 1,
                                                          color: Colors
                                                              .grey
                                                              .shade100,
                                                        ),
                                                        itemBuilder:
                                                            (context, index) {
                                                          final c = options
                                                              .elementAt(index);
                                                          final label =
                                                              _optionLabel(c);
                                                          return InkWell(
                                                            onTap: () =>
                                                                onSelected(c),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            child: Padding(
                                                              padding:
                                                                  itemPadding,
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .business_rounded,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .indigo
                                                                        .shade300,
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 10),
                                                                  Expanded(
                                                                    child:
                                                                        _HighlightText(
                                                                      text:
                                                                          label,
                                                                      query:
                                                                          currentQuery,
                                                                      fontSize:
                                                                          isNarrow
                                                                              ? 15
                                                                              : 14,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 16),
                        Text('Tanggal',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTanggal,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              isDense: true,
                            ),
                            child: Text(_tanggal == null
                                ? 'Pilih tanggal'
                                : '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Kunjungan Canvas *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _canvasVisitOptions
                                  .any((e) => e.$1 == _selectedCanvasVisit)
                              ? _selectedCanvasVisit
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          hint: const Text('Pilih Canvas / Visit'),
                          items: _canvasVisitOptions
                              .map((e) => DropdownMenuItem<String>(
                                  value: e.$1, child: Text(e.$2)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCanvasVisit = v),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib dipilih' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _keteranganController,
                          decoration: const InputDecoration(
                            labelText: 'Keterangan (opsional)',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _catatanController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (opsional)',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Simpan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
