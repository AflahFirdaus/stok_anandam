import 'package:flutter/material.dart';

class HubControlCenter extends StatelessWidget {
  final VoidCallback? onAssignment;
  final VoidCallback onPickup;
  final VoidCallback? onPartialShipment;

  const HubControlCenter({
    super.key,
    this.onAssignment,
    required this.onPickup,
    this.onPartialShipment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 720) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.blueGrey.shade100.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hub_rounded,
                    color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "Pusat Kendali (Hub)",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (onAssignment != null) ...[
                Expanded(
                  child: _HubCard(
                    title: 'Jalur Pengiriman',
                    description:
                        'Tugaskan rute pengiriman ke tim lapangan (Driver/Teknisi).',
                    icon: Icons.local_shipping_rounded,
                    iconColor: Colors.blue.shade600,
                    buttonLabel: 'Lihat Rute',
                    onTap: onAssignment!,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: _HubCard(
                  title: 'Serah Terima Langsung',
                  description:
                      'Konfirmasi serah terima paket di lokasi secara mandiri/langsung.',
                  icon: Icons.person_pin_circle_rounded,
                  iconColor: Colors.green.shade600,
                  buttonLabel: 'Mulai Pickup',
                  onTap: onPickup,
                ),
              ),
              if (onPartialShipment != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _HubCard(
                    title: 'Kirim Sebagian',
                    description:
                        'Kelola pengiriman parsial jika stok tidak tersedia sepenuhnya.',
                    icon: Icons.inventory_2_rounded,
                    iconColor: Colors.blueGrey.shade600,
                    buttonLabel: 'Lihat Pesanan',
                    onTap: onPartialShipment!,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.blueGrey.shade100.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded,
                  color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Pusat Kendali (Hub)",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (onAssignment != null) ...[
            _MobileHubItem(
              title: 'Jalur Pengiriman',
              description: 'Tugaskan rute pengiriman ke tim lapangan.',
              icon: Icons.local_shipping_rounded,
              iconColor: Colors.blue.shade600,
              onTap: onAssignment!,
            ),
            const SizedBox(height: 12),
          ],
          _MobileHubItem(
            title: 'Serah Terima Langsung',
            description: 'Konfirmasi serah terima di lokasi.',
            icon: Icons.person_pin_circle_rounded,
            iconColor: Colors.green.shade600,
            onTap: onPickup,
          ),
          if (onPartialShipment != null) ...[
            const SizedBox(height: 12),
            _MobileHubItem(
              title: 'Kirim Sebagian',
              description: 'Kelola pengiriman parsial stok.',
              icon: Icons.inventory_2_rounded,
              iconColor: Colors.blueGrey.shade600,
              onTap: onPartialShipment!,
            ),
          ],
        ],
      ),
    );
  }
}

class _HubCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String buttonLabel;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.iconColor.withValues(alpha: 0.5)
                : Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.buttonLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHubItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MobileHubItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
