import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stok_anandam/core/auth/auth_service.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/routing/app_router.dart';
import 'package:stok_anandam/core/widgets/deck_view.dart';
import 'package:stok_anandam/features/layout/dashboard_shell.dart';
import 'package:stok_anandam/features/memo/bloc/memo_bloc.dart';
import 'package:stok_anandam/features/memo/widgets/request_delivery_tab.dart';
import 'package:stok_anandam/injection.dart';

class RequestDeliveryPage extends StatefulWidget {
  const RequestDeliveryPage({super.key});

  @override
  State<RequestDeliveryPage> createState() => _RequestDeliveryPageState();
}

class _RequestDeliveryPageState extends State<RequestDeliveryPage> {
  final GlobalKey<RequestDeliveryTabState> _tabKey =
      GlobalKey<RequestDeliveryTabState>();
  late final MemoBloc _memoBloc;

  @override
  void initState() {
    super.initState();
    _memoBloc = MemoBloc(getIt());
  }

  @override
  void dispose() {
    _memoBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();
    final userRole = userStore.userRole?.toUpperCase();
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _memoBloc,
      child: DashboardShell(
        currentRoute: AppRoutes.requestDelivery,
        userName: userStore.displayName,
        userRole: userStore.userRole,
        title: 'Request Delivery',
        onNavigate: (route) => context.go(route),
        headerActions: const [],
        floatingActionButton: isMobile &&
                ((userRole != null && userRole.startsWith('MARKETING')) ||
                    userRole == 'ADMIN' ||
                    userRole == 'SPV_MARKETING')
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await context.push(AppRoutes.requestDeliveryCreate);
                  _tabKey.currentState?.refresh();
                },
                label: const Text('Tambah Request'),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              )
            : null,
        onLogout: () async {
          await getIt<AuthService>().logout();
          if (context.mounted) context.go(AppRoutes.login);
        },
        child: DeckView(
          title: 'Request Delivery',
          useScrollView: false,
          actions: [
            if (!isMobile &&
                ((userRole != null && userRole.startsWith('MARKETING')) ||
                    userRole == 'ADMIN' ||
                    userRole == 'SPV_MARKETING'))
              FilledButton.icon(
                onPressed: () async {
                  await context.push(AppRoutes.requestDeliveryCreate);
                  _tabKey.currentState?.refresh();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Request'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
          ],
          child: RequestDeliveryTab(key: _tabKey, showHeader: true),
        ),
      ),
    );
  }
}
