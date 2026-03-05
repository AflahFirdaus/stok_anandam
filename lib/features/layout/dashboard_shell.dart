import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/routing/app_router.dart';
import 'app_sidebar_modern.dart';
import '../dashboard/widgets/dashboard_header.dart';
import '../dashboard/widgets/dashboard_header.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.onNavigate,
    this.onLogout,
    this.userName = 'User',
    this.userRole,
    this.headerActionLabel = 'Sync Migrasi',
    this.headerActionIcon,
    this.onHeaderAction,
    this.onRefresh,
    this.showHeaderActionInAppBar = true,
    this.lastSync = '',
    this.headerActions = const [],
  });

  final String currentRoute;
  final Widget child;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLogout;
  final String userName;
  final String? userRole;
  final String headerActionLabel;
  final IconData? headerActionIcon;
  final VoidCallback? onHeaderAction;
  final VoidCallback? onRefresh;
  final bool showHeaderActionInAppBar;
  final String lastSync;
  final List<HeaderAction> headerActions;

  static const double _breakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= _breakpoint;

    if (isDesktop) {
      return _DesktopLayout(
        currentRoute: currentRoute,
        onNavigate: onNavigate,
        onLogout: onLogout,
        userName: userName,
        userRole: userRole,
        headerActionLabel: headerActionLabel,
        headerActionIcon: headerActionIcon,
        onHeaderAction: onHeaderAction,
        onRefresh: onRefresh,
        lastSync: lastSync,
        headerActions: headerActions,
        child: child,
      );
    } else {
      return _MobileLayout(
        currentRoute: currentRoute,
        onNavigate: onNavigate,
        onLogout: onLogout,
        userName: userName,
        userRole: userRole,
        headerActionLabel: headerActionLabel,
        headerActionIcon: headerActionIcon,
        onHeaderAction: onHeaderAction,
        onRefresh: onRefresh,
        showHeaderActionInAppBar: showHeaderActionInAppBar,
        lastSync: lastSync,
        headerActions: headerActions,
        child: child,
      );
    }
  }
}

class _DesktopLayout extends StatefulWidget {
  const _DesktopLayout({
    required this.currentRoute,
    required this.child,
    this.onNavigate,
    this.onLogout,
    this.userName = 'User',
    this.userRole,
    this.headerActionLabel = 'Sync Migrasi',
    this.headerActionIcon,
    this.onHeaderAction,
    this.onRefresh,
    this.lastSync = '',
    this.headerActions = const [],
  });

  final String currentRoute;
  final Widget child;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLogout;
  final String userName;
  final String? userRole;
  final String headerActionLabel;
  final IconData? headerActionIcon;
  final VoidCallback? onHeaderAction;
  final VoidCallback? onRefresh;
  final String lastSync;
  final List<HeaderAction> headerActions;

  @override
  State<_DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<_DesktopLayout> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentBg = theme.colorScheme.surfaceContainerLow.withOpacity(0.5);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSidebarModern(
            currentRoute: widget.currentRoute,
            onNavigate: widget.onNavigate,
            onLoginTap: widget.onLogout,
            isLoggedIn: true,
            isCollapsed: _isCollapsed,
            userRole: widget.userRole,
            onToggle: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardHeader(
                  userName: widget.userName,
                  userRole: widget.userRole,
                  actionLabel: widget.headerActionLabel,
                  actionIcon: widget.headerActionIcon,
                  onAction: (widget.userRole?.toUpperCase() == 'ADMIN' || 
                             widget.userRole?.toUpperCase() == 'SPV_MARKETING' || 
                             widget.userRole?.toUpperCase() == 'MARKETING')
                      ? widget.onHeaderAction
                      : null,
                  onRefresh: widget.onRefresh,
                  onLogout: widget.onLogout,
                  lastSync: widget.lastSync,
                  actions: widget.headerActions,
                ),
                Expanded(
                  child: Container(
                    color: contentBg,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.currentRoute,
    required this.child,
    this.onNavigate,
    this.onLogout,
    this.userName = 'User',
    this.userRole,
    this.headerActionLabel = 'Sync Migrasi',
    this.headerActionIcon,
    this.onHeaderAction,
    this.onRefresh,
    this.showHeaderActionInAppBar = true,
    this.lastSync = '',
    this.headerActions = const [],
  });

  final String currentRoute;
  final Widget child;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLogout;
  final String userName;
  final String? userRole;
  final String headerActionLabel;
  final IconData? headerActionIcon;
  final VoidCallback? onHeaderAction;
  final VoidCallback? onRefresh;
  final bool showHeaderActionInAppBar;
  final String lastSync;
  final List<HeaderAction> headerActions;

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required String? currentRoute,
    required Function(String)? onNavigate,
  }) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(label,
          style: TextStyle(color: isSelected ? Colors.blue : Colors.black87)),
      selected: isSelected,
      selectedTileColor:
          Colors.blue.withOpacity(0.1), // Efek highlight biru muda
      onTap: () {
        Navigator.pop(context);
        onNavigate?.call(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Movva ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color.fromARGB(223, 9, 5, 89),
                ),
              ),
              TextSpan(
                text: 'by Anandam.id',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Color.fromARGB(255, 53, 205, 15),
                ),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'User Menu',
            offset: const Offset(0, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.person_rounded, size: 20),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (userRole != null)
                      Text(userRole!,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (onHeaderAction != null && (userRole?.toUpperCase() == 'ADMIN' || 
                                              userRole?.toUpperCase() == 'SPV_MARKETING' || 
                                              userRole?.toUpperCase() == 'MARKETING')) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(headerActionIcon ?? Icons.sync_rounded,
                            size: 18, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(headerActionLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            if (lastSync.isNotEmpty)
                              Text(
                                lastSync,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onLogout != null) ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.logout_rounded,
                            size: 18, color: Colors.red.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Text('Logout',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
            onSelected: (value) {
              if (value == 1) onHeaderAction?.call();
              if (value == 2) onLogout?.call();
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
      ),
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width > 0
            ? (MediaQuery.sizeOf(context).width * 0.85).clamp(256.0, 360.0)
            : 304.0,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    'assets/images/anandamid-logo.svg',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      route: '/dashboard',
                      currentRoute: currentRoute,
                      onNavigate: onNavigate,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.inventory_2_rounded,
                      label: 'Stok',
                      route: '/stok',
                      currentRoute: currentRoute,
                      onNavigate: onNavigate,
                    ),
                    if (userRole == 'ADMIN' || userRole == 'SUPERVISOR' || userRole == 'SPV_MARKETING' || userRole == 'MARKETING') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.computer_rounded,
                        label: 'Rakitan',
                        route: AppRoutes.rakitan,
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                    if (userRole == 'ADMIN' || userRole == 'SUPERVISOR') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.shopping_cart_rounded,
                        label: 'Penjualan',
                        route: '/penjualan',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.shopping_bag_rounded,
                        label: 'Pembelian',
                        route: '/pembelian',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                    if (userRole == 'ADMIN' || userRole == 'SPV_MARKETING' || userRole == 'MARKETING') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.verified_rounded,
                        label: 'TKDN',
                        route: '/tkdn',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                    if (userRole == 'ADMIN' || userRole == 'SPV_MARKETING') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Item SN',
                        route: '/item-sn',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                    if (userRole == 'ADMIN' || userRole == 'SPV_MARKETING' || userRole == 'MARKETING') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.palette_rounded,
                        label: 'Canvas',
                        route: '/canvas',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                    if (userRole == 'ADMIN' || userRole == 'SPV_MARKETING') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.analytics_rounded,
                        label: 'Data Canvas',
                        route: '/data_canvas',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                    if (userRole == 'ADMIN') ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.people_rounded,
                        label: 'User',
                        route: '/users',
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.history_rounded,
                        label: 'Log Aktivitas',
                        route: AppRoutes.activityLog,
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.warehouse_rounded,
                        label: 'Data Warehouse',
                        route: AppRoutes.dataWarehouse,
                        currentRoute: currentRoute,
                        onNavigate: onNavigate,
                      ),
                    ],
                  ],
                ),
              ),

              // --- FOOTER (LOGOUT) ---
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onLogout?.call();
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }
}

class HeaderAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const HeaderAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });
}
