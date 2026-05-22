import 'package:flutter/material.dart';
import 'package:stok_anandam/data/models/memo.dart';

class MemoTimelineSection extends StatelessWidget {
  final MemoDetail memo;

  const MemoTimelineSection({super.key, required this.memo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: memo.logs.length,
      itemBuilder: (context, index) {
        final log = memo.logs[index];
        final isLast = index == memo.logs.length - 1;
        final statusColor = _getTimelineColor(log.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline vertical line and dot
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              // Activity Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeStatus(log.status),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A), // High contrast
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            log.actorName ?? 'System',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: log.actorName == 'System'
                                  ? const Color(0xFF3B82F6)
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "•",
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.createdAt != null
                                ? _formatDateTime(log.createdAt!)
                                : '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (log.keterangan != null && log.keterangan!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            log.keterangan!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blueGrey.shade700,
                              height: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _capitalizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'Aktivitas';
    return status.split('_').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Color _getTimelineColor(String? status) {
    if (status == null) return Colors.grey;
    final s = status.toUpperCase();
    if (s == 'SELESAI' || s == 'DITERIMA_USER') {
      return const Color(0xFF22C55E); // Green
    }
    if (s == 'DALAM_PENGIRIMAN' ||
        s == 'PROSES_GUDANG' ||
        s == 'PROSES_TEKNISI') {
      return const Color(0xFF1E40AF); // Dark Blue
    }
    if (s == 'MENUNGGU_PENGIRIMAN' ||
        s == 'MENUNGGU_GUDANG' ||
        s == 'MENUNGGU_NOTA' ||
        s == 'BUFFER_ZONE' ||
        s == 'MENUNGGU_TEKNISI' ||
        s == 'MENUNGGU_PERSETUJUAN') {
      return const Color(0xFFF59E0B); // Orange
    }
    if (s == 'SIAP_PENUGASAN' || s == 'PENDING' || s == 'DRAFT') {
      return const Color(0xFF3B82F6); // Blue
    }
    return Colors.grey;
  }

  String _formatDateTime(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
}
