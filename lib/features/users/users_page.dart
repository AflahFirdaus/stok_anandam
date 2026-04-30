import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:stok_anandam/core/network/response_utils.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/widgets/app_feedback.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/global_state_resetter.dart';
import '../../injection.dart';
import '../layout/dashboard_shell.dart';
import '../shared/responsive_table.dart';
import '../shared/responsive_padding.dart';
import '../shared/item_deck_card.dart';
import '../shared/migration_sync_mixin.dart';
import './services/user_session_service.dart';

/// State filter Manajemen User (halaman) disimpan agar saat pindah menu lalu balik, tetap.
class _UsersFilterState {
  _UsersFilterState._();
  static int page = 0;
  static int size = 50;

  static void reset() {
    page = 0;
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  void initState() {
    super.initState();
    GlobalStateResetter.register(_UsersFilterState.reset);
  }

  @override
  Widget build(BuildContext context) {
    return const _UsersContent();
  }
}

class _UsersContent extends StatefulWidget {
  const _UsersContent();

  @override
  State<_UsersContent> createState() => _UsersContentState();
}

class _UsersContentState extends State<_UsersContent> with MigrationSyncMixin {
  bool _loading = true;
  String? _error;
  List<UserResponse> _items = [];
  int _page = 0;
  final int _size = 50;
  int _totalElements = 0;
  int _totalPages = 0;

  void _restoreFilterState() {
    _page = _UsersFilterState.page;
  }

  void _persistFilterState() {
    _UsersFilterState.page = _page;
  }

  @override
  void initState() {
    super.initState();
    _restoreFilterState();
    fetchLastSync();
    _loadUsers();
  }

  static List<UserResponse> _parseContent(Object? content) {
    if (content == null) {
      debugPrint('_parseContent: content is null');
      return [];
    }
    if (content is List) {
      debugPrint('_parseContent: content is List with ${content.length} items');
      final parsed = content
          .map((e) {
            if (e is UserResponse) return e;
            if (e is Map) {
              try {
                return UserResponse.fromJson(Map<String, dynamic>.from(e));
              } catch (ex) {
                debugPrint('_parseContent: Error parsing item: $ex');
                return null;
              }
            }
            debugPrint('_parseContent: Unknown item type: ${e.runtimeType}');
            return null;
          })
          .whereType<UserResponse>()
          .toList();
      debugPrint('_parseContent: Parsed ${parsed.length} UserResponse items');
      return parsed;
    }
    debugPrint(
        '_parseContent: content is not List, type: ${content.runtimeType}');
    return [];
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = getIt<UserControllerApi>();
      final response = await api.getAllUsers(page: _page, size: _size);
      final data = response.data;

      // Debug: log response structure
      debugPrint('API Response status: ${data?.status}');
      debugPrint('API Response data type: ${data?.data.runtimeType}');
      debugPrint('API Response paging: ${data?.paging}');

      if (isResponseSuccess(data?.status)) {
        final content = data?.data;
        final paging = data?.paging;
        final items = _parseContent(content);
        final total = paging?.totalItem;
        final pages = paging?.totalPage;
        setState(() {
          _items = items;
          _totalElements = total is int
              ? total
              : int.tryParse(total?.toString() ?? '0') ?? 0;
          _totalPages = pages is int
              ? pages
              : int.tryParse(pages?.toString() ?? '0') ?? 0;
          _loading = false;
          _persistFilterState();
        });
      } else {
        setState(() {
          _error = data?.message?.toString() ?? 'Gagal memuat data.';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final body = e.response!.data as Map<Object?, Object?>;
        final status = body['status'];
        final dataPayload = body['data'];
        final pagingPayload = body['paging'];
        if (isResponseSuccess(status) && dataPayload is List) {
          final items = _parseContent(dataPayload);
          int totalElements = 0;
          int totalPages = 0;
          if (pagingPayload is Map) {
            final p = Map<String, dynamic>.from(
                pagingPayload.map((k, v) => MapEntry(k?.toString() ?? '', v)));
            totalElements =
                int.tryParse(p['totalItem']?.toString() ?? '0') ?? 0;
            totalPages = int.tryParse(p['totalPage']?.toString() ?? '0') ?? 0;
          }
          if (mounted) {
            setState(() {
              _items = items;
              _totalElements = totalElements;
              _totalPages = totalPages > 0 ? totalPages : 1;
              _loading = false;
              _persistFilterState();
            });
          }
          return;
        }
      }
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
    }
  }

  Future<void> _createUser(UserRequest request) async {
    try {
      final api = getIt<UserControllerApi>();
      await api.createUser(userRequest: request);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'User berhasil ditambah.');
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context,
          e.toString().length > 80 ? 'Gagal menambah user.' : e.toString());
    }
  }

  Future<void> _updateUser(Object id, UserRequest request) async {
    try {
      final api = getIt<UserControllerApi>();
      await api.updateUser(id: id, userRequest: request);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'User berhasil diubah.');
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context,
          e.toString().length > 80 ? 'Gagal mengubah user.' : e.toString());
    }
  }

  Future<void> _deleteUser(Object id) async {
    try {
      final api = getIt<UserControllerApi>();
      await api.deleteUser(id: id);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'User berhasil dihapus.');
      _loadUsers();
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Gagal menghapus user.';

      // Handle error 409 (Conflict) dengan pesan yang lebih spesifik
      if (e.response?.statusCode == 409) {
        final body = e.response?.data;
        if (body is Map) {
          final serverMessage = body['message']?.toString() ?? '';
          // Cek apakah error terkait foreign key constraint (refresh_token)
          if (serverMessage.contains('refresh_token') ||
              serverMessage.contains('foreign key')) {
            message =
                'User tidak dapat dihapus karena masih memiliki sesi aktif. '
                'Silakan logout user tersebut terlebih dahulu atau tunggu sesi habis.';
          } else {
            // Gunakan message dari server jika tidak terlalu teknis
            final cleanMessage = _extractUserFriendlyMessage(serverMessage);
            if (cleanMessage != null) {
              message = cleanMessage;
            } else {
              message =
                  'User tidak dapat dihapus karena masih terhubung dengan data lain.';
            }
          }
        } else {
          message =
              'User tidak dapat dihapus karena masih terhubung dengan data lain.';
        }
      } else {
        // Untuk error lainnya, gunakan AppErrors
        message = AppErrors.userMessageFromDio(e);
        // Coba extract message dari response body jika ada
        final body = e.response?.data;
        if (body is Map && body['message'] != null) {
          final serverMsg =
              _extractUserFriendlyMessage(body['message'].toString());
          if (serverMsg != null && serverMsg.length < 100) {
            message = serverMsg;
          }
        }
      }

      AppFeedback.showError(context, message);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context,
          AppErrors.userMessageFromException(e, 'Gagal menghapus user.'));
    }
  }

  Future<void> _clearUserSessions(UserResponse user) async {
    final id = user.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Bersihkan Sesi Aktif?'),
          ],
        ),
        content: Text(
          'Tindakan ini akan menghapus semua token sesi aktif untuk user "${user.username}" di database backend. '
          'User akan ter-logout secara paksa dari semua perangkat/browser.\n\n'
          'Gunakan ini jika jumlah perangkat terlihat tidak wajar atau status user terus-menerus "Online".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('Ya, Bersihkan Semua Sesi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await getIt<UserSessionService>().clearUserSessions(id);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Sesi berhasil dibersihkan.');
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppFeedback.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _toggleUserStatus(UserResponse user) async {
    final id = user.id;
    if (id == null) return;

    final currentUsername = getIt<CurrentUserStore>().me?.username;
    if (user.username == currentUsername) {
      AppFeedback.showError(context,
          'Anda tidak dapat menonaktifkan akun sendiri yang sedang digunakan!');
      return;
    }

    try {
      final api = getIt<UserControllerApi>();
      await api.toggleUserStatus(id: id);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Status user berhasil diperbarui.');
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Gagal memperbarui status user.');
    }
  }

  /// Extract pesan yang user-friendly dari error message server
  /// Mengembalikan null jika pesan terlalu teknis (constraint, foreign key detail, dll)
  static String? _extractUserFriendlyMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim().toLowerCase();
    // Skip pesan teknis yang tidak perlu ditampilkan ke user
    if (t.contains('constraint') ||
        t.contains('violates') ||
        t.contains('relation') ||
        t.contains('failing row') ||
        t.contains('detail:') ||
        t.contains('exception') ||
        t.contains('dioexception') ||
        t.length > 150) {
      return null;
    }
    return raw.trim();
  }

  void _openForm([UserResponse? existing]) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _UserFormDialog(
        existing: existing,
        onCreate: _createUser,
        onUpdate:
            existing != null ? (req) => _updateUser(existing.id!, req) : null,
      ),
    );
  }

  void _confirmDelete(UserResponse user) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteUserDialog(
        user: user,
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          if (user.id != null) await _deleteUser(user.id!);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    return DashboardShell(
      currentRoute: AppRoutes.users,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () =>
          showSyncMigrationDialog(onCustomSuccess: _loadUsers),
      lastSync: lastSyncFormatted,
      onScan: () => context.pushNamed(AppRoutes.scanner),
      showHeaderActionInAppBar: true,
      onRefresh: _loading ? null : _loadUsers,
      onNavigate: (route) {
        if (route != AppRoutes.users) context.go(route);
      },
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
      child: RefreshIndicator(
        onRefresh: _loadUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsivePadding.all(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tambah User'),
                  ),
                ],
              ),
              SizedBox(height: ResponsivePadding.spacingLarge(context)),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _ErrorSection(message: _error!, onRetry: _loadUsers)
              else if (_items.isEmpty)
                _EmptySection(onRetry: _loadUsers)
              else ...[
                if (isMobile)
                  _UsersDeckList(
                    items: _items,
                    onEdit: _openForm,
                    onDelete: _confirmDelete,
                    onToggleStatus: _toggleUserStatus,
                    onClearSessions: _clearUserSessions,
                  )
                else
                  _UsersTable(
                    items: _items,
                    onEdit: _openForm,
                    onDelete: _confirmDelete,
                    onToggleStatus: _toggleUserStatus,
                    onClearSessions: _clearUserSessions,
                  ),
                if (_items.isNotEmpty) ...[
                  SizedBox(height: ResponsivePadding.spacingLarge(context)),
                  _PaginationBar(
                    page: _page,
                    totalPages: _totalPages,
                    totalElements: _totalElements,
                    onPrev: (_totalPages > 0 && _page > 0)
                        ? () {
                            setState(() {
                              _page--;
                              _persistFilterState();
                            });
                            _loadUsers();
                          }
                        : null,
                    onNext: (_totalPages > 0 && _page < _totalPages - 1)
                        ? () {
                            setState(() {
                              _page++;
                              _persistFilterState();
                            });
                            _loadUsers();
                          }
                        : null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onClearSessions,
  });
  final List<UserResponse> items;
  final void Function(UserResponse) onEdit;
  final void Function(UserResponse) onDelete;
  final void Function(UserResponse) onToggleStatus;
  final void Function(UserResponse) onClearSessions;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  static String _formatRole(Object? role) {
    if (role == null) return '—';
    final roleStr = role.toString();
    if (roleStr.contains('.')) return roleStr.split('.').last;
    return roleStr;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDataTable(
      minColumnWidth: 180.0,
      columnSpacing: 24.0,
      horizontalMargin: 0.0,
      headingRowColor: Colors.grey.shade50,
      headingRowHeight: 40,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 50,
      columns: [
        buildDataColumn('Nama'),
        buildDataColumn('Username'),
        buildDataColumn('Role'),
        buildDataColumn('Aktif'),
        buildDataColumn('Status'),
        buildDataColumn('Sesi'),
        buildDataColumn('Aksi'),
      ],
      rows: items.map((u) {
        final currentUsername = getIt<CurrentUserStore>().me?.username;
        final isSelf = u.username == currentUsername;
        final isOnline = u.isOnline ?? false;
        final deviceCount = u.deviceCount ?? 0;

        return DataRow(
          cells: [
            buildDataCell(_v(u.nama)),
            buildDataCell(_v(u.username)),
            buildDataCell(_formatRole(u.role)),
            DataCell(
              Tooltip(
                message: isSelf
                    ? 'Tidak bisa menonaktifkan diri sendiri'
                    : (u.active == true
                        ? 'Klik untuk nonaktifkan'
                        : 'Klik untuk aktifkan'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (u.active ?? true)
                            ? const Color.fromARGB(255, 17, 75, 201)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (u.active ?? true) ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        color: (u.active ?? true)
                            ? const Color.fromARGB(255, 17, 75, 201)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: u.active ?? true,
                        onChanged: isSelf ? null : (val) => onToggleStatus(u),
                        activeColor: Colors.blue.shade600,
                        activeTrackColor: Colors.blue.shade100,
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DataCell(
              Tooltip(
                message: isOnline
                    ? 'User memiliki sesi login aktif.'
                    : 'User tidak memiliki sesi aktif (offline).',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        boxShadow: isOnline
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green.shade700 : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DataCell(
              Tooltip(
                message: deviceCount > 1
                    ? '$deviceCount sesi tercatat (kemungkinan ada sesi lama yang belum dibersihkan). Klik untuk membersihkan.'
                    : deviceCount > 0
                        ? '1 sesi aktif.'
                        : 'Tidak ada sesi aktif.',
                child: InkWell(
                  onTap: deviceCount > 1 ? () => onClearSessions(u) : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: deviceCount > 1
                          ? Colors.orange.shade50
                          : (deviceCount > 0
                              ? Colors.blue.shade50
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(6),
                      border: deviceCount > 1
                          ? Border.all(color: Colors.orange.shade200)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          deviceCount > 1
                              ? Icons.warning_amber_rounded
                              : (deviceCount > 0
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.remove_circle_outline_rounded),
                          size: 14,
                          color: deviceCount > 1
                              ? Colors.orange.shade700
                              : (deviceCount > 0
                                  ? Colors.green.shade600
                                  : Colors.grey.shade500),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          deviceCount > 1
                              ? '$deviceCount (stale?)'
                              : '$deviceCount',
                          style: TextStyle(
                            color: deviceCount > 1
                                ? Colors.orange.shade800
                                : (deviceCount > 0
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.cleaning_services_rounded, size: 20),
                    onPressed: () => onClearSessions(u),
                    tooltip: 'Bersihkan Sesi (Logout Semua Perangkat)',
                    color: Colors.orange.shade700,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => onEdit(u),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: Colors.red.shade700),
                    onPressed: () => onDelete(u),
                    tooltip: 'Hapus',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _UsersDeckList extends StatelessWidget {
  const _UsersDeckList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onClearSessions,
  });
  final List<UserResponse> items;
  final void Function(UserResponse) onEdit;
  final void Function(UserResponse) onDelete;
  final void Function(UserResponse) onToggleStatus;
  final void Function(UserResponse) onClearSessions;

  static String _v(Object? x) =>
      x?.toString().trim().isEmpty ?? true ? '—' : x.toString();

  static String _formatRole(Object? role) {
    if (role == null) return '—';
    final roleStr = role.toString();
    if (roleStr.contains('.')) return roleStr.split('.').last;
    return roleStr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUsername = getIt<CurrentUserStore>().me?.username;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final u = items[i];
        final isSelf = u.username == currentUsername;

        return DataDeckCard(
          title: _v(u.nama),
          subtitle: _v(u.username),
          rows: [
            (label: 'Role', value: _formatRole(u.role)),
            (
              label: 'Status',
              value: (u.active ?? true) ? 'Aktif' : 'Nonaktif',
            ),
            (
              label: 'Koneksi',
              value: (u.isOnline ?? false) ? 'Online' : 'Offline',
            ),
            (
              label: 'Sesi',
              value: (u.deviceCount ?? 0) > 1
                  ? '${u.deviceCount} (Perlu dibersihkan)'
                  : '${u.deviceCount ?? 0} sesi aktif',
            ),
          ],
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: isSelf
                    ? 'Tidak bisa menonaktifkan diri sendiri'
                    : (u.active == true
                        ? 'Klik untuk nonaktifkan'
                        : 'Klik untuk aktifkan'),
                child: Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    value: u.active ?? true,
                    onChanged: isSelf ? null : (val) => onToggleStatus(u),
                    activeColor: Colors.blue.shade600,
                    activeTrackColor: Colors.blue.shade100,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cleaning_services_rounded, size: 20),
                onPressed: () => onClearSessions(u),
                tooltip: 'Bersihkan Sesi',
                color: Colors.orange.shade700,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => onEdit(u),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: theme.colorScheme.error),
                onPressed: () => onDelete(u),
                tooltip: 'Hapus',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.existing, required this.onCreate, this.onUpdate});
  final UserResponse? existing;
  final void Function(UserRequest) onCreate;
  final void Function(UserRequest)? onUpdate;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRequestRoleEnum _role = UserRequestRoleEnum.ADMIN;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _namaController.text = e.nama?.toString() ?? '';
      _usernameController.text = e.username?.toString() ?? '';
      final r = e.role?.toString().toUpperCase();
      _role = UserRequestRoleEnum.values.firstWhere(
        (x) => x.name == r,
        orElse: () => UserRequestRoleEnum.ADMIN,
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final nama = _namaController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (nama.isEmpty || username.isEmpty) {
      AppFeedback.showError(context, 'Nama dan username wajib diisi.');
      return;
    }
    final isEdit = widget.existing != null;
    if (!isEdit && password.isEmpty) {
      AppFeedback.showError(context, 'Password wajib diisi untuk user baru.');
      return;
    }
    final request = UserRequest(
      nama: nama,
      username: username,
      password: password.isEmpty ? null : password,
      role: _role,
    );
    if (isEdit && widget.onUpdate != null) {
      widget.onUpdate!(request);
    } else {
      widget.onCreate(request);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit User' : 'Tambah User Baru',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit
                              ? 'Ubah data user'
                              : 'Isi form di bawah untuk menambah user',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _namaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Contoh: Ahmad Wijaya',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Untuk login',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      enabled: !isEdit,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'Password (kosongkan jika tidak diubah)'
                            : 'Password',
                        hintText: isEdit
                            ? 'Biarkan kosong untuk tetap'
                            : 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRequestRoleEnum>(
                      value: _role,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon:
                            const Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: UserRequestRoleEnum.values.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.name));
                      }).toList(),
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded,
                        size: 20),
                    label: Text(isEdit ? 'Simpan' : 'Tambah User'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteUserDialog extends StatefulWidget {
  const _DeleteUserDialog({
    required this.user,
    required this.onCancel,
    required this.onConfirm,
  });
  final UserResponse user;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<_DeleteUserDialog> {
  bool _deleting = false;

  Future<void> _handleConfirm() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    await widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.user.nama?.toString().trim().isNotEmpty == true
        ? widget.user.nama
        : widget.user.username;
    final subtitle = widget.user.username?.toString() ?? '—';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 28),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Icon(
                  Icons.person_remove_rounded,
                  size: 48,
                  color: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Hapus User?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'User yang dihapus tidak dapat dikembalikan. Pastikan Anda yakin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (displayName?.toString().substring(0, 1).toUpperCase() ??
                          '?'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName?.toString() ?? '—',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != '—')
                          Text(
                            '@$subtitle',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _deleting ? null : widget.onCancel,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _deleting ? null : _handleConfirm,
                      icon: _deleting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onError,
                              ),
                            )
                          : const Icon(Icons.delete_forever_rounded, size: 20),
                      label: Text(_deleting ? 'Menghapus...' : 'Ya, Hapus'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Text(message, style: TextStyle(color: Colors.red.shade800)),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Belum ada user',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
              'Halaman ${page + 1} dari ${totalPages == 0 ? 1 : totalPages} (total: $totalElements)',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPrev != null)
              FilledButton.tonalIcon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Sebelumnya')),
            if (onPrev != null && onNext != null) const SizedBox(width: 8),
            if (onNext != null)
              FilledButton.tonalIcon(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Selanjutnya')),
          ],
        ),
      ],
    );
  }
}
