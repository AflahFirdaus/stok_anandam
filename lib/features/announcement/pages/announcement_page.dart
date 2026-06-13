import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stok_anandam/injection.dart';
import '../../../data/models/announcement.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/auth/current_user_store.dart';
import '../../../core/auth/auth_service.dart';
import '../../layout/dashboard_shell.dart';
import '../../shared/responsive_padding.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final AnnouncementRepository _repository = getIt<AnnouncementRepository>();
  bool _isLoading = false;
  List<Announcement> _announcements = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getAnnouncements();
      if (mounted) setState(() => _announcements = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pengumuman: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: theme.colorScheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Pengumuman?',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        content: Text(
          'Tindakan ini akan menghapus pengumuman secara permanen dari server. Data yang terhapus tidak dapat dikembalikan.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await _repository.deleteAnnouncement(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Pengumuman berhasil dihapus'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _fetchAnnouncements();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<Announcement> _getFilteredItems() {
    if (_searchQuery.isEmpty) return _announcements;
    final q = _searchQuery.toLowerCase();
    return _announcements.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  // Returns status config: (label, color, icon)
  _StatusConfig _getStatus(Announcement item) {
    final now = DateTime.now();
    final isStarted = item.startDate == null || now.isAfter(item.startDate!);
    final isExpired =
        item.expiredDate != null && now.isAfter(item.expiredDate!);

    if (isExpired) {
      return const _StatusConfig('Kedaluwarsa', Colors.red, Icons.cancel_rounded);
    } else if (!isStarted) {
      return const _StatusConfig('Terjadwal', Colors.orange, Icons.schedule_rounded);
    }
    return const _StatusConfig('Aktif', Colors.green, Icons.check_circle_rounded);
  }

  Widget _buildStatusBadge(Announcement item) {
    final s = _getStatus(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 11, color: s.color),
          const SizedBox(width: 4),
          Text(
            s.label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: s.color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;
    final filteredItems = _getFilteredItems();
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm');

    return DashboardShell(
      currentRoute: AppRoutes.announcement,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      onScan: () => context.pushNamed(AppRoutes.scanner),
      onRefresh: _isLoading ? null : _fetchAnnouncements,
      onNavigate: (route) {
        if (route != AppRoutes.announcement) context.go(route);
      },
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
      child: RefreshIndicator(
        onRefresh: _fetchAnnouncements,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsivePadding.all(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ───────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.campaign_rounded,
                                size: 20,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Kelola Pengumuman',
                              style: (isMobile
                                      ? theme.textTheme.titleLarge
                                      : theme.textTheme.headlineSmall)
                                  ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text(
                            'Buat dan atur informasi penting yang tampil saat pengguna login.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final result =
                          await context.push<bool>(AppRoutes.announcementForm);
                      if (result == true) _fetchAnnouncements();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isMobile ? 'Tambah' : 'Tambah Pengumuman'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Stats Summary Row ─────────────────────────────────────────
              if (!_isLoading && _announcements.isNotEmpty) ...[
                _buildStatRow(theme),
                const SizedBox(height: 20),
              ],

              // ─── Search Box ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari pengumuman...',
                    hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Content ──────────────────────────────────────────────────
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else if (filteredItems.isEmpty)
                _buildEmptyState(theme)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final status = _getStatus(item);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow
                                .withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            // Status indicator strip on top
                            Container(
                              height: 3,
                              color: status.color,
                            ),
                            Theme(
                              data: theme.copyWith(
                                  dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusBadge(item),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: theme
                                              .colorScheme.outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Full content
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? theme.colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.5)
                                                : theme.colorScheme.primary
                                                    .withValues(alpha: 0.03),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: theme
                                                  .colorScheme.outlineVariant
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            item.subtitle,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.85),
                                              height: 1.55,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // Scheduling info
                                        if (item.startDate != null ||
                                            item.expiredDate != null)
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              if (item.startDate != null)
                                                _buildScheduleChip(
                                                  Icons.play_arrow_rounded,
                                                  'Mulai: ${dateFormat.format(item.startDate!)}',
                                                  Colors.green.shade600,
                                                ),
                                              if (item.expiredDate != null)
                                                _buildScheduleChip(
                                                  Icons.stop_rounded,
                                                  'Berakhir: ${dateFormat.format(item.expiredDate!)}',
                                                  Colors.red.shade600,
                                                ),
                                            ],
                                          ),

                                        const SizedBox(height: 16),

                                        // Action Buttons
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final result =
                                                    await context.push<bool>(
                                                  AppRoutes.announcementForm,
                                                  extra: item,
                                                );
                                                if (result == true) {
                                                  _fetchAnnouncements();
                                                }
                                              },
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 15),
                                              label: const Text('Edit'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.primary,
                                                side: BorderSide(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.4),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _deleteAnnouncement(item.id!),
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 15),
                                              label: const Text('Hapus'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.error,
                                                side: BorderSide(
                                                  color: theme.colorScheme.error
                                                      .withValues(alpha: 0.4),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme) {
    final now = DateTime.now();
    final active = _announcements.where((a) {
      final afterStart = a.startDate == null || now.isAfter(a.startDate!);
      final notExpired = a.expiredDate == null || now.isBefore(a.expiredDate!);
      return afterStart && notExpired;
    }).length;
    final scheduled = _announcements
        .where((a) => a.startDate != null && now.isBefore(a.startDate!))
        .length;
    final expired = _announcements
        .where((a) => a.expiredDate != null && now.isAfter(a.expiredDate!))
        .length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard(theme, 'Total', _announcements.length,
                Icons.campaign_rounded, theme.colorScheme.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(theme, 'Aktif', active,
                Icons.check_circle_rounded, Colors.green)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(theme, 'Terjadwal', scheduled,
                Icons.schedule_rounded, Colors.orange)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(theme, 'Kedaluwarsa', expired,
                Icons.cancel_rounded, Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(
      ThemeData theme, String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada hasil pencarian'
                : 'Belum ada pengumuman',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba kata kunci yang berbeda.'
                : 'Tambah pengumuman baru untuk dipublikasikan kepada pengguna.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final result =
                    await context.push<bool>(AppRoutes.announcementForm);
                if (result == true) _fetchAnnouncements();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Pengumuman'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusConfig(this.label, this.color, this.icon);
}
