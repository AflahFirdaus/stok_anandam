import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';
import '../models/transaksi_servis.dart';
import '../providers/servis_provider.dart';
import '../providers/garansi_provider.dart';
import '../providers/klaim_provider.dart';
import '../widgets/pelanggan_form_dialog.dart';
import '../widgets/servis_form_dialog.dart';
import 'views/servis_proses_view.dart';
import 'views/servis_pelanggan_view.dart';
import 'views/servis_garansi_view.dart';
import 'views/servis_placeholders.dart';
import 'views/klaim_garansi_view.dart';

class ServisPage extends StatelessWidget {
  const ServisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServisProvider()..fetchTransaksi(),
      child: const _ServisPageContent(),
    );
  }
}

class _ServisPageContent extends StatefulWidget {
  const _ServisPageContent();

  @override
  State<_ServisPageContent> createState() => _ServisPageContentState();
}

class _ServisPageContentState extends State<_ServisPageContent>
    with TickerProviderStateMixin {
  // 1. Wajib tambahkan TickerProvider
  late TabController _tabController;
  int _pelangganRefreshKey = 0;

  // --- VARIABEL ANIMASI PREMIUM ---
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Inisialisasi controller animasi (250ms untuk responsivitas maksimal)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Animasi pantulan halus saat menu membesar dari bawah
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    // Animasi perubahan opasitas
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi untuk membuka/menutup menu
  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Fungsi untuk menutup menu (dipakai saat klik di luar area)
  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
        _animationController.reverse();
      });
    }
  }

  Future<void> _showAddPelangganDialog(BuildContext context) async {
    final refresh = await showDialog<bool>(
      context: context,
      builder: (ctx) => const PelangganFormDialog(),
    );
    if (refresh == true && mounted) {
      setState(() => _pelangganRefreshKey++);
    }
  }

  // --- WIDGET HELPER UNTUK ITEM MENU ---
  // --- WIDGET HELPER UNTUK ITEM MENU ---
  Widget _buildPremiumMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        _closeMenu(); // Tutup menu terlebih dahulu
        onTap(); // Jalankan aksi
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // Ikon bergaya Enterprise
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            // Wajib pakai Expanded agar kotak tidak tertular melebar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServisProvider>();
    final userStore = getIt<CurrentUserStore>();
    final theme = Theme.of(context);

    return DashboardShell(
      currentRoute: AppRoutes.servis,
      userName: userStore.displayName,
      userRole: userStore.userRole,
      title: 'Pusat Layanan Servis',
      onNavigate: (route) {
        if (route != AppRoutes.servis) context.go(route);
      },
      onLogout: () {
        getIt<TokenStorage>().clear();
        getIt<CurrentUserStore>().clear();
        context.go(AppRoutes.login);
      },

      // --- PENEMPATAN KUSTOM FAB & MENU ---
      // --- PENEMPATAN KUSTOM FAB & MENU ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. KOTAK MENU MELAYANG (Dengan Animasi)
          ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight, // Membesar dari sudut FAB
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                // BATASAN UKURAN AGAR TIDAK FULL WIDTH & AMAN DI MOBILE
                constraints: const BoxConstraints(maxWidth: 320),
                margin: const EdgeInsets.only(
                    bottom: 16), // Jarak bebas dengan tombol Buat Baru
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPremiumMenuItem(
                        icon: Icons.person_add_rounded,
                        color: Colors.blue.shade600,
                        title: 'Tambah Pelanggan Baru',
                        subtitle: 'Daftarkan pelanggan sebelum buat servis',
                        onTap: () => _showAddPelangganDialog(context),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                      ),
                      _buildPremiumMenuItem(
                        icon: Icons.receipt_long_rounded,
                        color: Colors.indigo.shade600,
                        title: 'Buat Nota Servis',
                        subtitle: 'Untuk pelanggan yang sudah terdaftar',
                        onTap: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (context) => const ServisFormDialog(),
                          );
                          if (result is TransaksiServis) {
                            provider.fetchTransaksi();
                            if ((result.statusTerkini ?? '')
                                .startsWith('KLAIM')) {
                              _tabController.animateTo(3);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. TOMBOL UTAMA (FAB)
          FloatingActionButton.extended(
            onPressed: _toggleMenu,
            elevation: _isMenuOpen ? 0 : 4,
            backgroundColor:
                _isMenuOpen ? Colors.red.shade50 : theme.colorScheme.primary,
            foregroundColor:
                _isMenuOpen ? Colors.red.shade700 : theme.colorScheme.onPrimary,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                _isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
                key: ValueKey(_isMenuOpen ? 'close' : 'add'),
              ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _isMenuOpen ? 'Tutup' : 'Buat Baru',
                key: ValueKey(_isMenuOpen ? 'close' : 'add'),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),

      // --- INTERAKSI KLIK LUAR ---
      // GestureDetector ini memungkinkan pengguna menutup menu hanya dengan
      // mengklik area mana saja di layar (fitur yang sangat User Friendly)
      child: GestureDetector(
        onTap: _isMenuOpen ? _closeMenu : null,
        behavior: HitTestBehavior.opaque,
        child: AbsorbPointer(
          absorbing:
              _isMenuOpen, // Mencegah klik nyasar ke TabBar saat menu terbuka
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: theme.colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.normal),
                  tabs: const [
                    Tab(
                        icon: Icon(Icons.people_alt_rounded),
                        text: 'Pelanggan'),
                    Tab(
                        icon: Icon(Icons.build_circle_rounded),
                        text: 'Proses Servis'),
                    Tab(
                        icon: Icon(Icons.security_rounded),
                        text: 'Garansi Servis'),
                    Tab(
                        icon: Icon(Icons.local_shipping_rounded),
                        text: 'Klaim Distributor'),
                    Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Laporan'),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ServisPelangganView(key: ValueKey(_pelangganRefreshKey)),
                    ServisProsesView(provider: provider),
                    ChangeNotifierProvider(
                      create: (_) => GaransiProvider(),
                      child: const ServisGaransiView(),
                    ),
                    ChangeNotifierProvider(
                      create: (_) => KlaimProvider(),
                      child: const KlaimGaransiView(),
                    ),
                    const ServisLaporanView(),
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
