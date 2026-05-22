import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/data/models/memo.dart';
import 'package:stok_anandam/features/canvas/canvas_page.dart';
import 'package:stok_anandam/features/dashboard/dashboard_page.dart';
import 'package:stok_anandam/features/data_canvas/data_canvas_page.dart';
import 'package:stok_anandam/features/auth/bloc/screens/login_page.dart';
import 'package:stok_anandam/features/purchase/purchase_page.dart';
import 'package:stok_anandam/features/sales/sales_page.dart';
import 'package:stok_anandam/features/splash/splash_page.dart';
import 'package:stok_anandam/features/stock/stock_page.dart';
import 'package:stok_anandam/features/tkdn/tkdn_page.dart';
import 'package:stok_anandam/features/memo/pages/memo_page.dart';
import 'package:stok_anandam/features/memo/pages/create_memo_page.dart';
import 'package:stok_anandam/features/memo/pages/memo_detail_page.dart';
import 'package:stok_anandam/features/item_sn/item_sn_page.dart';
import 'package:stok_anandam/features/penjadwalan/manual_request_page.dart';
import 'package:stok_anandam/features/users/users_page.dart';
import 'package:stok_anandam/features/activity_log/activity_log_page.dart';
import 'package:stok_anandam/features/assembly/assembly_page.dart';
import 'package:stok_anandam/features/auth/bloc/screens/access_denied_page.dart';
import 'package:stok_anandam/features/data_warehouse/data_warehouse_page.dart';
import 'package:stok_anandam/features/data_warehouse/old_sales_page.dart';
import 'package:stok_anandam/features/data_warehouse/old_purchase_page.dart';
import 'package:stok_anandam/features/data_warehouse/old_item_sn_page.dart';
import 'package:stok_anandam/features/profile/pages/profile_page.dart';
import 'package:stok_anandam/features/memo/pages/scanner_page.dart';
import 'package:stok_anandam/features/memo/pages/pengiriman_page.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/features/shared/widgets/camera_screen.dart';
import 'package:stok_anandam/features/memo/pages/delivery_detail_page.dart';
import 'package:stok_anandam/features/memo/pages/peta_pengantaran_page.dart';
import 'package:stok_anandam/features/memo/pages/manual_task_detail_page.dart';
import 'package:stok_anandam/features/penjadwalan/request_delivery_page.dart';
import 'package:stok_anandam/features/memo/pages/create_request_delivery_page.dart';
import 'package:stok_anandam/features/announcement/pages/announcement_page.dart';
import 'package:stok_anandam/features/announcement/pages/announcement_form_page.dart';
import 'package:stok_anandam/data/models/announcement.dart';
import 'package:stok_anandam/features/simulasi/simulasi_page.dart';

/// Route names untuk navigasi (hindari magic string).
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String stok = '/stok';
  static const String penjualan = '/penjualan';
  static const String pembelian = '/pembelian';
  static const String tkdn = '/tkdn';
  static const String canvas = '/canvas';
  static const String dataCanvas = '/data_canvas';
  static const String users = '/users';
  static const String activityLog = '/activity-log';
  static const String itemSn = '/item-sn';
  static const String rakitan = '/rakitan';
  static const String dataWarehouse = '/data-warehouse';
  static const String oldSales = '/old-sales';
  static const String oldPurchase = '/old-purchase';
  static const String oldItemSn = '/old-item-sn';
  static const String accessDenied = '/access-denied';
  static const String memo = '/memo';
  static const String memoCreate = '/memo/create';
  static const String memoDetail = '/memo/detail/:id';
  static const String camera = '/camera';
  static const String profile = '/profile';
  static const String scanner = '/scanner';
  static const String pengiriman = '/pengiriman';
  static const String mapPengantaran = '/map-pengantaran';
  static const String deliveryDetail = '/pengantaran/detail/:id';
  static const String manualRequest = '/penjadwalan/manual';
  static const String requestDelivery = '/request-delivery';
  static const String requestDeliveryCreate = '/request-delivery/create';
  static const String manualTaskDetail = '/manual-task/:id';
  static const String announcement = '/announcement';
  static const String announcementForm = '/announcement/form';
  static const String simulasi = '/simulasi';
}

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: Listenable.merge([
    getIt<TokenStorage>(),
    getIt<CurrentUserStore>(),
  ]),
  redirect: (BuildContext context, GoRouterState state) {
    final location = state.uri.path;

    // Don't redirect from splash screen - let it handle navigation
    if (location == AppRoutes.splash) return null;

    final token = getIt<TokenStorage>().token;
    final hasToken = token != null && token.isNotEmpty;
    final isLoginRoute = location == AppRoutes.login;
    final isAccessDeniedRoute = location == AppRoutes.accessDenied;

    if (!hasToken && !isLoginRoute && !isAccessDeniedRoute)
      return AppRoutes.login;

    // If logged in and on login/splash, redirect to appropriate home page.
    if (hasToken && (isLoginRoute || location == AppRoutes.splash)) {
      final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();

      // If role not yet loaded, don't redirect yet - let the app finish loading user info.
      if (userRole == null) return null;

      // Management → Dashboard
      if (userRole == 'ADMIN' || userRole.startsWith('SPV_')) return AppRoutes.dashboard;
      // Delivery & Teknisi → Pengantaran task list
      if (userRole == 'TEKNISI' || userRole == 'DELIVERY') return AppRoutes.pengiriman;
      // Nota → Memo
      if (userRole.contains('NOTA')) return AppRoutes.memo;
      // Gudang & Marketing → Stok
      if (userRole == 'GUDANG' || userRole.startsWith('MARKETING')) return AppRoutes.stok;

      // Default for other logged-in users who don't have a specific home page
      return AppRoutes.stok;
    }

    // From here on, we assume the user is logged in and not on login/splash.
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();

    // If role not loaded yet, allow progress (page will handle loading)
    if (userRole == null) return null;

    // RBAC: Role-based access control for specific pages
    if (location == AppRoutes.accessDenied) return null;

    // 1. Admin & Spvs have full access
    if (userRole == 'ADMIN' || userRole.startsWith('SPV_')) return null;

    // Dashboard page: ONLY accessible to ADMIN and SPV roles.
    if (location == AppRoutes.dashboard) {
      // If not Admin/SPV, redirect to stok
      return AppRoutes.stok;
    }

    // RBAC: Check Pengiriman Access specifically
    if (location == AppRoutes.pengiriman ||
        location == AppRoutes.mapPengantaran) {
      if (userRole == 'GUDANG' ||
          userRole == 'DELIVERY' ||
          userRole == 'TEKNISI' ||
          userRole.startsWith('MARKETING')) return null;
      return AppRoutes.accessDenied;
    }

    // 3. Marketing privileges (Sub-roles: TOKO, PROJECT, DISTRIBUSI)
    if (userRole != null && userRole.startsWith('MARKETING')) {
      final allowed = [
        AppRoutes.stok,
        AppRoutes.rakitan,
        AppRoutes.tkdn,
        AppRoutes.canvas,
        AppRoutes.dataCanvas,
        AppRoutes.memo,
        AppRoutes.memoDetail,
        AppRoutes.memoCreate,
        AppRoutes.requestDelivery,
        AppRoutes.requestDeliveryCreate,
        AppRoutes.pengiriman,
        AppRoutes.deliveryDetail,
        AppRoutes.mapPengantaran,
        AppRoutes.camera,
        AppRoutes.manualRequest,
        AppRoutes.simulasi,
      ];
      if (allowed.contains(location) ||
          location.startsWith('/memo/detail/') ||
          location.startsWith('/pengantaran/detail/') ||
          location.startsWith('/manual-task/')) return null;
    }

    // 4. Gudang privileges
    if (userRole == 'GUDANG') {
      final allowed = [
        AppRoutes.dashboard,
        AppRoutes.stok,
        AppRoutes.rakitan,
        AppRoutes.itemSn,
        AppRoutes.memo,
        AppRoutes.memoDetail,
        AppRoutes.pengiriman,
        '/pengiriman',
        '/profile',
        AppRoutes.profile,
        AppRoutes.deliveryDetail,
        AppRoutes.camera,
      ];
      if (allowed.contains(location) ||
          location.startsWith('/memo/detail/') ||
          location.startsWith('/pengantaran/detail/') ||
          location.startsWith('/manual-task/')) return null;
    }

// 5. Delivery privileges
    if (userRole == 'DELIVERY') {
      final allowed = [
        AppRoutes.memo,
        AppRoutes.memoDetail,
        AppRoutes.camera,
        AppRoutes.pengiriman,
        '/pengiriman',
        AppRoutes.deliveryDetail,
        AppRoutes.mapPengantaran,
      ];
      if (allowed.contains(location) ||
          location.startsWith('/memo/detail/') ||
          location.startsWith('/pengantaran/detail/') ||
          location.startsWith('/manual-task/')) return null;
    }

    // 6. Teknisi privileges
    if (userRole == 'TEKNISI') {
      final allowed = [
        AppRoutes.memo,
        AppRoutes.memoDetail,
        AppRoutes.camera,
        AppRoutes.pengiriman,
        '/pengiriman',
        AppRoutes.deliveryDetail,
      ];
      if (allowed.contains(location) ||
          location.startsWith('/memo/detail/') ||
          location.startsWith('/pengantaran/detail/') ||
          location.startsWith('/manual-task/')) return null;
    }

    // 7. Nota Role
    if (userRole != null && userRole.contains('NOTA')) {
      final allowed = [
        AppRoutes.memo,
        AppRoutes.memoDetail,
        AppRoutes.profile,
        AppRoutes.scanner,
        AppRoutes.camera,
      ];
      if (allowed.contains(location) ||
          location.startsWith('/memo/detail/') ||
          location.startsWith('/manual-task/')) return null;
    }

    // Default: Allow profile and scanner for everyone who is logged in
    if (location == AppRoutes.profile || location == AppRoutes.scanner)
      return null;

    return AppRoutes.accessDenied;
  },
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splash,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.splash, const SplashPage()),
    ),
    GoRoute(
      path: '/pengiriman',
      name: 'pengiriman',
      pageBuilder: (context, state) =>
          _buildPage(state, '/pengiriman', const PengirimanPage()),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.login,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.login, const LoginPage()),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRoutes.dashboard,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.dashboard, const DashboardPage()),
    ),
    GoRoute(
      path: AppRoutes.stok,
      name: AppRoutes.stok,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.stok, const StockPage()),
    ),
    GoRoute(
      path: AppRoutes.penjualan,
      name: AppRoutes.penjualan,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.penjualan, const SalesPage()),
    ),
    GoRoute(
      path: AppRoutes.pembelian,
      name: AppRoutes.pembelian,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.pembelian, const PurchasePage()),
    ),
    GoRoute(
      path: AppRoutes.tkdn,
      name: AppRoutes.tkdn,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.tkdn, const TkdnPage()),
    ),
    GoRoute(
      path: AppRoutes.itemSn,
      name: AppRoutes.itemSn,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.itemSn, const ItemSnPage()),
    ),
    GoRoute(
      path: AppRoutes.canvas,
      name: AppRoutes.canvas,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.canvas, const CanvasPage()),
    ),
    GoRoute(
      path: AppRoutes.dataCanvas,
      name: AppRoutes.dataCanvas,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.dataCanvas, const DataCanvasPage()),
    ),
    GoRoute(
      path: AppRoutes.users,
      name: AppRoutes.users,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.users, const UsersPage()),
    ),
    GoRoute(
      path: AppRoutes.activityLog,
      name: AppRoutes.activityLog,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.activityLog, const ActivityLogPage()),
    ),
    GoRoute(
      path: AppRoutes.rakitan,
      name: AppRoutes.rakitan,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.rakitan, const AssemblyPage()),
    ),
    GoRoute(
      path: AppRoutes.dataWarehouse,
      name: AppRoutes.dataWarehouse,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.dataWarehouse, const DataWarehousePage()),
    ),
    GoRoute(
      path: AppRoutes.oldSales,
      name: AppRoutes.oldSales,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.oldSales, const OldSalesPage()),
    ),
    GoRoute(
      path: AppRoutes.oldPurchase,
      name: AppRoutes.oldPurchase,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.oldPurchase, const OldPurchasePage()),
    ),
    GoRoute(
      path: AppRoutes.oldItemSn,
      name: AppRoutes.oldItemSn,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.oldItemSn, const OldItemSnPage()),
    ),
    GoRoute(
      path: AppRoutes.accessDenied,
      name: AppRoutes.accessDenied,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.accessDenied, const AccessDeniedPage()),
    ),
    GoRoute(
      path: AppRoutes.memo,
      name: AppRoutes.memo,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.memo, const MemoPage()),
    ),
    GoRoute(
      path: AppRoutes.memoCreate,
      name: AppRoutes.memoCreate,
      pageBuilder: (context, state) {
        final memoType = state.uri.queryParameters['type'] ?? 'BIASA';
        final continuationId = state.uri.queryParameters['continuationId'];
        final isNewDuplicate = state.uri.queryParameters['isNewDuplicate'] == 'true';
        final initialData =
            state.extra is MemoDetail ? state.extra as MemoDetail : null;

        return _buildPage(
            state,
            AppRoutes.memoCreate,
            CreateMemoPage(
              memoType: memoType,
              initialData: initialData,
              continuationId: continuationId,
              isNewDuplicate: isNewDuplicate,
            ));
      },
    ),
    GoRoute(
      path: AppRoutes.memoDetail,
      name: AppRoutes.memoDetail,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _buildPage(state, AppRoutes.memoDetail, MemoDetailPage(id: id));
      },
    ),
    GoRoute(
      path: AppRoutes.camera,
      name: AppRoutes.camera,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.camera, const CameraScreen()),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: AppRoutes.profile,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.profile, const ProfilePage()),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      name: AppRoutes.scanner,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.scanner, const ScannerPage()),
    ),
    GoRoute(
      path: AppRoutes.mapPengantaran,
      name: AppRoutes.mapPengantaran,
      pageBuilder: (context, state) => _buildPage(
          state, AppRoutes.mapPengantaran, const PetaPengantaranPage()),
    ),
    GoRoute(
      path: AppRoutes.deliveryDetail,
      name: AppRoutes.deliveryDetail,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _buildPage(
            state, AppRoutes.deliveryDetail, DeliveryDetailPage(id: id));
      },
    ),
    GoRoute(
      path: AppRoutes.manualRequest,
      name: AppRoutes.manualRequest,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.manualRequest, const ManualRequestPage()),
    ),
    GoRoute(
      path: AppRoutes.manualTaskDetail,
      name: AppRoutes.manualTaskDetail,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _buildPage(
            state, AppRoutes.manualTaskDetail, ManualTaskDetailPage(id: id));
      },
    ),
    GoRoute(
      path: AppRoutes.requestDelivery,
      name: AppRoutes.requestDelivery,
      pageBuilder: (context, state) => _buildPage(
          state, AppRoutes.requestDelivery, const RequestDeliveryPage()),
    ),
    GoRoute(
      path: AppRoutes.requestDeliveryCreate,
      name: AppRoutes.requestDeliveryCreate,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.requestDeliveryCreate, const CreateRequestDeliveryPage()),
    ),
    GoRoute(
      path: AppRoutes.announcement,
      name: AppRoutes.announcement,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.announcement, const AnnouncementPage()),
    ),
    GoRoute(
      path: AppRoutes.announcementForm,
      name: AppRoutes.announcementForm,
      pageBuilder: (context, state) {
        final announcement = state.extra is Announcement ? state.extra as Announcement : null;
        return _buildPage(state, AppRoutes.announcementForm, AnnouncementFormPage(announcement: announcement));
      },
    ),
    GoRoute(
      path: AppRoutes.simulasi,
      name: AppRoutes.simulasi,
      pageBuilder: (context, state) =>
          _buildPage(state, AppRoutes.simulasi, const SimulasiPage()),
    ),
  ],
);

CustomTransitionPage<void> _buildPage(
    GoRouterState state, String name, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: name,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOutCubic;
      final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
      final opacity = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
      final offset =
          Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero)
              .animate(curvedAnimation);
      return FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
