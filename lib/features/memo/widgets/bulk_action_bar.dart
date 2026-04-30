import 'package:flutter/material.dart';

class BulkActionBar extends StatelessWidget {
  final String? userRole;
  final int count;
  final VoidCallback onClear;
  final VoidCallback onPrint;
  final VoidCallback onChangeStatus;
  final VoidCallback onAssignment;
  final VoidCallback onDropOff;
  final VoidCallback? onBulkStart;
  final VoidCallback? onBulkFinish;
  final VoidCallback? onComplete;

  const BulkActionBar({
    super.key,
    required this.count,
    this.userRole,
    required this.onClear,
    required this.onPrint,
    required this.onChangeStatus,
    required this.onAssignment,
    required this.onDropOff,
    this.onBulkStart,
    this.onBulkFinish,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = userRole?.toUpperCase() ?? '';
    final isDelivery = role == 'DELIVERY';
    final canDoDelivery = role == 'GUDANG' ||
        role == 'SPV_GUDANG' ||
        role == 'ADMIN' ||
        role.startsWith('MARKETING') ||
        role == 'SPV_MARKETING';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                tooltip: 'Batal',
              ),
              const SizedBox(width: 8),
              Text(
                '$count Terpilih',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 24),
              if (isDelivery) ...[
                _ActionButton(
                  icon: Icons.local_shipping_outlined,
                  label: 'Mulai Kirim',
                  onPressed: onBulkStart ?? () {},
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Selesai Kirim',
                  onPressed: onBulkFinish ?? () {},
                  color: Colors.greenAccent,
                ),
              ] else ...[
                _ActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Manifest',
                  onPressed: onPrint,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.update_rounded,
                  label: 'Status',
                  onPressed: onChangeStatus,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.assignment_ind_rounded,
                  label: 'Penugasan',
                  onPressed: onAssignment,
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.local_post_office_rounded,
                  label: 'Drop-off',
                  onPressed: onDropOff,
                  color: Colors.purpleAccent,
                ),
                if (canDoDelivery) ...[
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  _ActionButton(
                    icon: Icons.local_shipping_outlined,
                    label: 'Mulai Kirim',
                    onPressed: onBulkStart ?? () {},
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Selesai Kirim',
                    onPressed: onBulkFinish ?? () {},
                    color: Colors.greenAccent,
                  ),
                  if (onComplete != null) ...[
                    const SizedBox(width: 12),
                    _ActionButton(
                      icon: Icons.verified_rounded,
                      label: 'Selesaikan',
                      onPressed: onComplete!,
                      color: Colors.white,
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
