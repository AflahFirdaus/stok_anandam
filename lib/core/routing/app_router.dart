import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/features/canvas/canvas_page.dart';
import 'package:stok_anandam/features/dashboard/dashboard_page.dart';
import 'package:stok_anandam/features/data_canvas/data_canvas_page.dart';
import 'package:stok_anandam/features/auth/bloc/screens/login_page.dart';
import 'package:stok_anandam/features/purchase/purchase_page.dart';
import 'package:stok_anandam/features/sales/sales_page.dart';
import 'package:stok_anandam/features/splash/splash_page.dart';
import 'package:stok_anandam/features/stock/stock_page.dart';
import 'package:stok_anandam/features/tkdn/tkdn_page.dart';
import 'package:stok_anandam/features/item_sn/item_sn_page.dart';
import 'package:stok_anandam/features/users/users_page.dart';
import 'package:stok_anandam/features/activity_log/activity_log_page.dart';
import 'package:stok_anandam/features/assembly/assembly_page.dart';
import 'package:stok_anandam/features/auth/bloc/screens/access_denied_page.dart';
import 'package:stok_anandam/features/data_warehouse/data_warehouse_page.dart';
import 'package:stok_anandam/features/data_warehouse/old_sales_page.dart';
import 'package:stok_anandam/features/data_warehouse/old_purchase_page.dart';
import 'package:stok_anandam/features/data_warehouse/old_item_sn_page.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/token_storage.dart';

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
}

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: Listenable.merge([
    getIt<TokenStorage>(),
    getIt<CurrentUserStore>(),
  ]),
  redirect: (BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    
    // Don't redirect from splash screen - let it handle navigation
    if (location == AppRoutes.splash) return null;
    
    final token = getIt<TokenStorage>().token;
    final hasToken = token != null && token.isNotEmpty;
    final isLoginRoute = location == AppRoutes.login;
    final isAccessDeniedRoute = location == AppRoutes.accessDenied;

    if (!hasToken && !isLoginRoute && !isAccessDeniedRoute) return AppRoutes.login;
    
    // If logged in and on login/splash, ALWAYS go to dashboard first.
    // This avoids the complex hop to access-denied during login transition.
    if (hasToken && (isLoginRoute || location == AppRoutes.splash)) {
       final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();
       if (userRole == 'MARKETING') return AppRoutes.stok;
       return AppRoutes.dashboard;
    }

    // From here on, we assume the user is logged in and not on login/splash.
    final userRole = getIt<CurrentUserStore>().userRole?.toUpperCase();

    // If role not loaded yet, we should allow them to proceed to their destination
    // so the page itself can show a loading state, or the API interceptor can force a logout.
    if (userRole == null) return null;
    
    // RBAC: Role-based access control for specific pages
    // Always allow Access Denied page itself to avoid loops
    if (location == AppRoutes.accessDenied) return null;
    
    // 1. Admin has full access
    if (userRole == 'ADMIN') return null;

    // 2. SPV Marketing privileges
    if (userRole == 'SPV_MARKETING') {
      final allowed = [
        AppRoutes.dashboard,
        AppRoutes.stok,
        AppRoutes.rakitan,
        AppRoutes.tkdn,
        AppRoutes.itemSn,
        AppRoutes.canvas,
        AppRoutes.dataCanvas,
      ];
      if (allowed.contains(location)) return null;
    }

    // 3. Marketing privileges
    else if (userRole == 'MARKETING') {
      final allowed = [
        AppRoutes.stok,
        AppRoutes.rakitan,
        AppRoutes.tkdn,
        AppRoutes.canvas,
      ];
      if (allowed.contains(location)) return null;
      
      // Langsung ke stok jika mencoba akses dashboard
      if (location == AppRoutes.dashboard) return AppRoutes.stok;
    }

    // 4. Default: If logged in but location not recognized or not allowed for role
    // Except /dashboard which we allowed everyone to go to first
    if (location == AppRoutes.dashboard) {
       if (userRole != 'ADMIN' && userRole != 'SPV_MARKETING' && userRole != 'MARKETING') {
         return AppRoutes.accessDenied;
       }
       return null; 
    }

    return AppRoutes.accessDenied;
  },
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.splash, const SplashPage()),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.login, const LoginPage()),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.dashboard, const DashboardPage()),
    ),
    GoRoute(
      path: AppRoutes.stok,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.stok, const StockPage()),
    ),
    GoRoute(
      path: AppRoutes.penjualan,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.penjualan, const SalesPage()),
    ),
    GoRoute(
      path: AppRoutes.pembelian,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.pembelian, const PurchasePage()),
    ),
    GoRoute(
      path: AppRoutes.tkdn,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.tkdn, const TkdnPage()),
    ),
    GoRoute(
      path: AppRoutes.itemSn,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.itemSn, const ItemSnPage()),
    ),
    GoRoute(
      path: AppRoutes.canvas,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.canvas, const CanvasPage()),
    ),
    GoRoute(
      path: AppRoutes.dataCanvas,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.dataCanvas, const DataCanvasPage()),
    ),
    GoRoute(
      path: AppRoutes.users,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.users, const UsersPage()),
    ),
    GoRoute(
      path: AppRoutes.activityLog,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.activityLog, const ActivityLogPage()),
    ),
    GoRoute(
      path: AppRoutes.rakitan,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.rakitan, const AssemblyPage()),
    ),
    GoRoute(
      path: AppRoutes.dataWarehouse,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.dataWarehouse, const DataWarehousePage()),
    ),
    GoRoute(
      path: AppRoutes.oldSales,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.oldSales, const OldSalesPage()),
    ),
    GoRoute(
      path: AppRoutes.oldPurchase,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.oldPurchase, const OldPurchasePage()),
    ),
    GoRoute(
      path: AppRoutes.oldItemSn,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.oldItemSn, const OldItemSnPage()),
    ),
    GoRoute(
      path: AppRoutes.accessDenied,
      pageBuilder: (context, state) => _buildPage(state, AppRoutes.accessDenied, const AccessDeniedPage()),
    ),
  ],
);

CustomTransitionPage<void> _buildPage(GoRouterState state, String name, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: name,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOutCubic;
      final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
      final opacity = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
      final offset = Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(curvedAnimation);
      return FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
