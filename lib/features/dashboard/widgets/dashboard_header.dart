import 'package:flutter/material.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.actionLabel = 'Sync Migrasi',
    this.actionIcon,
    this.userName = 'User',
    this.userRole,
    this.onSearch,
    this.onAction,
    this.onProfileTap,
    this.onRefresh,
    this.onLogout,
    this.lastSync = '',
    this.actions = const [],
  });

  final String actionLabel;
  final IconData? actionIcon;
  final String userName;
  final String? userRole;
  final void Function(String)? onSearch;
  final VoidCallback? onAction;
  final VoidCallback? onProfileTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  final String lastSync;
  final List<HeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 20,
        vertical: isNarrow ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: Colors.blue.shade600),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              hoverColor: Colors.blue.shade100,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAction != null) ...[
                if (!isNarrow) const SizedBox(width: 8),
                Flexible(
                  child: _ActionButton(
                    label: actionLabel,
                    icon: actionIcon,
                    onPressed: onAction,
                    lastSync: lastSync,
                  ),
                ),
              ],
              for (final action in actions) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _ActionButton(
                    label: action.label,
                    icon: action.icon,
                    onPressed: action.onPressed,
                    color: action.color,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _ProfileChip(
                name: userName,
                role: userRole,
                onLogout: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Branding moved to sidebar

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.lastSync = '',
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String lastSync;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconToUse = icon ?? Icons.add;
    final primaryColor = color ?? Colors.blue.shade600;
    final secondaryColor =
        color != null ? color?.withOpacity(0.8) : Colors.blue.shade400;

    return Material(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 20,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [secondaryColor!, primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconToUse, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                    if (lastSync.isNotEmpty)
                      Text(
                        lastSync,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.name, this.role, this.onLogout});

  final String name;
  final String? role;
  final VoidCallback? onLogout;

  void _showUserDetail(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height + 6,
      offset.dx + size.width,
      offset.dy + size.height + 200,
    );
    showMenu<void>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.transparent,
      elevation: 0,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _UserDetailCard(
            userName: name,
            userRole: role ?? 'User',
            onLogout: onLogout,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showUserDetail(context),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            if (MediaQuery.sizeOf(context).width >= 400)
              Text(
                name,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                    fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailCard extends StatelessWidget {
  const _UserDetailCard({
    required this.userName,
    required this.userRole,
    this.onLogout,
    required this.onDismiss,
  });

  final String userName;
  final String userRole;
  final VoidCallback? onLogout;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDismiss,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty
                        ? userName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '@${userName.toLowerCase().replaceAll(' ', '_')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Text(
                  userRole,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (onLogout != null) ...[
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      onDismiss();
                      onLogout?.call();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Keluar dari Akun'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
