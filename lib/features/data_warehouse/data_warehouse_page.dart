import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/features/shared/responsive_padding.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';
import '../shared/migration_sync_mixin.dart';

class DataWarehousePage extends StatefulWidget {
  const DataWarehousePage({super.key});

  @override
  State<DataWarehousePage> createState() => _DataWarehousePageState();
}

class _DataWarehousePageState extends State<DataWarehousePage>
    with MigrationSyncMixin {
  OldDataMeta? _meta;

  @override
  void initState() {
    super.initState();
    fetchLastSync();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final meta = await getIt<ApiNewEndpoints>().getOldDataMeta();
    if (mounted) setState(() => _meta = meta);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: AppRoutes.dataWarehouse,
      userName: getIt<CurrentUserStore>().displayName,
      userRole: getIt<CurrentUserStore>().userRole,
      headerActionLabel: 'Sync Migrasi',
      headerActionIcon: Icons.sync_rounded,
      onHeaderAction: () =>
          showSyncMigrationDialog(onCustomSuccess: fetchLastSync),
      showHeaderActionInAppBar: true,
      lastSync: lastSyncFormatted,
      onNavigate: (route) {
        if (route != AppRoutes.dataWarehouse) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },
      child: Padding(
        padding: ResponsivePadding.all(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Warehouse',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih kategori data historis yang ingin Anda tinjau.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _CategoryCard(
                    title: _meta != null
                        ? 'Penjualan ${_meta!.salesRange}'
                        : 'Penjualan ...',
                    description: 'Data transaksi penjualan historis.',
                    icon: Icons.shopping_cart_rounded,
                    color: Colors.blue,
                    onTap: () => context.push(AppRoutes.oldSales),
                  ),
                  _CategoryCard(
                    title: _meta != null
                        ? 'Pembelian ${_meta!.purchaseRange}'
                        : 'Pembelian ...',
                    description: 'Data transaksi pembelian historis.',
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.green,
                    onTap: () => context.push(AppRoutes.oldPurchase),
                  ),
                  _CategoryCard(
                    title: _meta != null
                        ? 'Item SN ${_meta!.itemSnRange}'
                        : 'Item SN ...',
                    description: 'Data serial number historis.',
                    icon: Icons.qr_code_scanner_rounded,
                    color: Colors.orange,
                    onTap: () => context.push(AppRoutes.oldItemSn),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
