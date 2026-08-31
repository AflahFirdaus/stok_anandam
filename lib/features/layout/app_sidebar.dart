import 'package:flutter/material.dart';
import 'package:stok_anandam/core/routing/app_router.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
    this.onLoginTap,
    this.isLoggedIn = true,
    this.userRole,
  });

  final String currentRoute;
  final void Function(String route)? onNavigate;
  final VoidCallback? onLoginTap;
  final bool isLoggedIn;
  final String? userRole;

  static const double width = 240;

  // Helper untuk membuat menu tile lebih ringkas
  Widget _buildMenu({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return _SidebarTile(
      icon: icon,
      label: label,
      isSelected: currentRoute == route,
      onTap: () => onNavigate?.call(route),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Definisikan menu per kelompok (group)
    // Gunakan collection-if untuk filter berdasarkan hak akses (role)
    final groups = <List<Widget>>[
      // --- GROUP 0: Dashboard (Bawaan sebelumnya) ---
      if (userRole == 'ADMIN' ||
          (userRole != null && userRole!.startsWith('SPV_')))
        [
          _buildMenu(
              icon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
          if (userRole == 'MANAGER')
            _buildMenu(
                icon: Icons.assessment_rounded,
                label: 'Laporan Omset Marketing',
                route: AppRoutes.laporanOmset),
        ],

      // --- GROUP 1: Stok, TKDN, Canvas, Rakitan ---
      [
        if (userRole != 'DELIVERY' &&
            userRole != 'NOTA' &&
            userRole != 'TEKNISI')
          _buildMenu(icon: Icons.storage, label: 'Stok', route: '/stok'),
        _buildMenu(icon: Icons.verified, label: 'TKDN', route: '/tkdn'),
        _buildMenu(icon: Icons.palette, label: 'Canvas', route: '/canvas'),
        _buildMenu(
            icon: Icons.precision_manufacturing,
            label: 'Rakitan',
            route: '/rakitan'),
      ],

      // --- GROUP 2: Memo, Delivery, Pengiriman, Peta ---
      [
        if (userRole != 'DELIVERY')
          _buildMenu(
              icon: Icons.assignment_rounded, label: 'Memo', route: '/memo'),
        if (userRole != null && userRole!.startsWith('MARKETING'))
          _buildMenu(
              icon: Icons.local_shipping_outlined,
              label: 'Request Delivery',
              route: AppRoutes.requestDelivery),
        if (userRole == null ||
            (!userRole!.startsWith('MARKETING') &&
                userRole != 'NOTA' &&
                userRole != 'TEKNISI'))
          _buildMenu(
            icon: Icons.local_shipping_rounded,
            label: userRole == 'DELIVERY' ? 'Pengantaran' : 'Pengiriman',
            route: '/pengiriman',
          ),
        // KOMENTAR: Menu Peta Pengantaran dinonaktifkan sementara
        // untuk menggunakan pendekatan baru.
        // if (userRole == 'ADMIN' ||
        //     userRole == 'GUDANG' ||
        //     userRole == 'SPV_GUDANG' ||
        //     userRole == 'DELIVERY')
        //   _buildMenu(
        //       icon: Icons.map_rounded,
        //       label: 'Peta Pengantaran',
        //       route: AppRoutes.mapPengantaran),
      ],

      // --- GROUP 3: Pembelian, Penjualan, Item SN, Data Warehouse ---
      [
        if (userRole == 'ADMIN' ||
            userRole == 'SUPERVISOR' ||
            userRole == 'TEKNISI' ||
            userRole == 'SPV_MARKETING')
          _buildMenu(
              icon: Icons.shopping_bag,
              label: 'Pembelian',
              route: '/pembelian'),
        if (userRole == 'ADMIN' ||
            userRole == 'SUPERVISOR' ||
            userRole == 'TEKNISI' ||
            userRole == 'SPV_MARKETING')
          _buildMenu(
              icon: Icons.shopping_cart,
              label: 'Penjualan',
              route: '/penjualan'),
        _buildMenu(
            icon: Icons.qr_code_scanner, label: 'Item SN', route: '/item-sn'),
        if (userRole == 'ADMIN' || userRole == 'SPV_MARKETING')
          _buildMenu(
              icon: Icons.assignment_turned_in_rounded,
              label: 'Ijin Import',
              route: AppRoutes.ijinImport),
        if (userRole == 'ADMIN' || userRole == 'SPV_MARKETING')
          _buildMenu(
              icon: Icons.construction_rounded,
              label: 'SHBJ',
              route: AppRoutes.shbj),
        _buildMenu(
            icon: Icons.warehouse,
            label: 'Data Warehouse',
            route: '/data-warehouse'),
      ],

      // --- GROUP 4: Data Canvas, User, Log Aktivitas ---
      [
        _buildMenu(
            icon: Icons.dataset, label: 'Data Canvas', route: '/data-canvas'),
        if (userRole == 'ADMIN') // Asumsi User & Log hanya untuk ADMIN
          _buildMenu(icon: Icons.people, label: 'User', route: '/user'),
        if (userRole == 'ADMIN')
          _buildMenu(
              icon: Icons.history,
              label: 'Log Aktivitas',
              route: '/log-aktivitas'),
      ],
    ];

    // 2. Filter kelompok yang kosong (jika user tidak punya akses sama sekali di grup itu)
    final validGroups = groups.where((group) => group.isNotEmpty).toList();

    // 3. Susun widget menu beserta garis pembatasnya
    final menuWidgets = <Widget>[];
    for (int i = 0; i < validGroups.length; i++) {
      menuWidgets.addAll(validGroups[i]);

      // Tambahkan divider jika ini bukan kelompok terakhir
      if (i < validGroups.length - 1) {
        menuWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Colors.white24, height: 1, thickness: 1),
          ),
        );
      }
    }

    return Container(
      width: width,
      color: Colors.blue.shade900,
      child: SafeArea(
        // Tambahkan SafeArea agar aman dari notch/status bar mobile
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
            const SizedBox(height: 24),

            // Menu items dibungkus Expanded & SingleChildScrollView agar bisa di-scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: menuWidgets,
                ),
              ),
            ),

            // Tombol login / logout di bawah (tetap (fixed) tidak ikut terscroll)
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
              Expanded(
                // Tambahkan expanded agar teks panjang tidak error/overflow
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
