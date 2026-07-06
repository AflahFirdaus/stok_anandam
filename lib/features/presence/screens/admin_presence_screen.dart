import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stok_anandam/features/presence/bloc/presence_bloc.dart';
import 'package:stok_anandam/features/presence/models/user_session.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';

class AdminPresenceScreen extends StatefulWidget {
  const AdminPresenceScreen({super.key});

  @override
  State<AdminPresenceScreen> createState() => _AdminPresenceScreenState();
}

class _AdminPresenceScreenState extends State<AdminPresenceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PresenceBloc>().add(PresenceStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PresenceBloc, PresenceState>(
      builder: (context, state) {
        if (state is PresenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PresenceError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PresenceLoaded) {
          return _buildContent(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showActiveUsersBottomSheet(BuildContext context, List<String> usernames) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Aktif Hari Ini (${usernames.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (usernames.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Belum ada user yang aktif hari ini',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: usernames.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  usernames[index].isNotEmpty ? usernames[index][0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                usernames[index],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, PresenceLoaded state) {
    final theme = Theme.of(context);
    final sessions = state.sessions;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PresenceBloc>().add(PresenceRefreshed());
      },
      child: ListView(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update real-time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.wifi, size: 16, color: Colors.green.shade400),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      icon: Icons.circle,
                      iconColor: Colors.green,
                      label: 'Online',
                      count: state.onlineCount,
                    ),
                    _SummaryChip(
                      icon: Icons.circle,
                      iconColor: Colors.grey,
                      label: 'Offline',
                      count: state.offlineCount,
                    ),
                    _SummaryChip(
                      icon: Icons.flash_on,
                      iconColor: Colors.orange,
                      label: 'Aktif Hari Ini',
                      count: state.activeUsersToday,
                      onTap: () => _showActiveUsersBottomSheet(context, state.activeUsernames),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trend Chart Section
          if (state.dailyStats.isNotEmpty) _buildTrendChart(context, state.dailyStats),

          // User list header
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
            child: Text(
              'Aktivitas User Sekarang',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // User list inline in ListView to share scroll
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada user aktif',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User akan muncul saat terhubung ke WebSocket',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _UserActivityCard(session: sessions[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<DailyActiveUserStat> stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We take the last 7 or 10 stats to avoid cluttering.
    // Let's show up to 10 points for good spacing.
    final displayStats = stats.length > 10 ? stats.sublist(stats.length - 10) : stats;

    // Y Axis setup: Max Y is 70 to encompass all expected user active ranges.
    const double maxY = 70.0;

    final spots = <FlSpot>[];
    for (int i = 0; i < displayStats.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayStats[i].userCount.toDouble()));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren User Aktif Harian',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jumlah user unik yang aktif per hari',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final valInt = value.toInt();
                          // Display left titles only for values: 0, 10, 30, 50, 70
                          if (valInt == 0 || valInt == 10 || valInt == 30 || valInt == 50 || valInt == 70) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Text(
                                valInt.toString(),
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= displayStats.length) return const SizedBox.shrink();
                          // Only show alternating dates or start/end to avoid cluttering
                          if (displayStats.length > 5 && idx % 2 != 0 && idx != displayStats.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = displayStats[idx].date; // yyyy-MM-dd
                          String formatted = '';
                          try {
                            final parsed = DateTime.parse(dateStr);
                            formatted = DateFormat('dd/MM').format(parsed);
                          } catch (_) {
                            formatted = dateStr;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              formatted,
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.55),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (displayStats.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          colorScheme.primaryContainer,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          String dateLabel = '';
                          if (idx >= 0 && idx < displayStats.length) {
                            try {
                              final parsed = DateTime.parse(displayStats[idx].date);
                              dateLabel = DateFormat('dd MMM yyyy').format(parsed);
                            } catch (_) {
                              dateLabel = displayStats[idx].date;
                            }
                          }
                          return LineTooltipItem(
                            '$dateLabel\n${spot.y.toInt()} user',
                            TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 5,
                          color: colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _SummaryChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClickable = onTap != null;

    final widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: isClickable ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (isClickable) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: theme.colorScheme.primary),
          ],
        ],
      ),
    );

    if (isClickable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: widget,
      );
    }
    return widget;
  }
}

class _UserActivityCard extends StatelessWidget {
  final UserSession session;

  const _UserActivityCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = session.isOnline;

    // Format lastActive
    String timeAgo = '';
    if (session.lastActive != null) {
      try {
        final lastActive = DateTime.parse(session.lastActive!);
        final now = DateTime.now();
        final diff = now.difference(lastActive);

        if (diff.inSeconds < 60) {
          timeAgo = '${diff.inSeconds}d yang lalu';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m yang lalu';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}j yang lalu';
        } else {
          timeAgo = DateFormat('HH:mm').format(lastActive);
        }
      } catch (_) {
        timeAgo = '';
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                border: Border.all(
                  color: isOnline ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(session.name ?? '?'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isOnline ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.name ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.currentAction ?? 'idle',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
