import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
    this.onLoginTap,
    this.isLoggedIn = true,
  });

  final String currentRoute;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLoginTap;
  final bool isLoggedIn;

  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Colors.blue.shade900,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stok Anandam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Menu items
          _SidebarTile(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: currentRoute == '/dashboard',
            onTap: () => onNavigate?.call('/dashboard'),
          ),
          _SidebarTile(
            icon: Icons.storage,
            label: 'Stok',
            isSelected: currentRoute == '/stok',
            onTap: () => onNavigate?.call('/stok'),
          ),
          _SidebarTile(
            icon: Icons.shopping_cart,
            label: 'Penjualan',
            isSelected: currentRoute == '/penjualan',
            onTap: () => onNavigate?.call('/penjualan'),
          ),
          _SidebarTile(
            icon: Icons.shopping_bag,
            label: 'Pembelian',
            isSelected: currentRoute == '/pembelian',
            onTap: () => onNavigate?.call('/pembelian'),
          ),
          _SidebarTile(
            icon: Icons.verified,
            label: 'TKDN',
            isSelected: currentRoute == '/tkdn',
            onTap: () => onNavigate?.call('/tkdn'),
          ),
          _SidebarTile(
            icon: Icons.qr_code_scanner,
            label: 'Item SN',
            isSelected: currentRoute == '/item-sn',
            onTap: () => onNavigate?.call('/item-sn'),
          ),
          const Spacer(),
          // Tombol login / logout di bawah
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLoginTap,
                icon: Icon(
                  isLoggedIn ? Icons.logout : Icons.login,
                  size: 20,
                  color: Colors.white70,
                ),
                label: Text(
                  isLoggedIn ? 'Logout' : 'Login',
                  style: const TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.white12 : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
