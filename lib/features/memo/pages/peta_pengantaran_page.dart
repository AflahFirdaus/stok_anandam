import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/map_monitoring_viewer.dart';
import '../../../core/routing/app_router.dart';
import '../../../features/layout/dashboard_shell.dart';
import '../../../core/auth/current_user_store.dart';
import '../../../core/auth/auth_service.dart';
import '../../../injection.dart';

import 'package:stok_anandam/features/presence/mixins/presence_action_mixin.dart';

class PetaPengantaranPage extends StatefulWidget {
  const PetaPengantaranPage({super.key});

  @override
  State<PetaPengantaranPage> createState() => _PetaPengantaranPageState();
}

class _PetaPengantaranPageState extends State<PetaPengantaranPage> with PresenceActionMixin {
  @override
  Widget build(BuildContext context) {
    final userStore = getIt<CurrentUserStore>();

    return DashboardShell(
      currentRoute: AppRoutes.mapPengantaran,
      title: 'Peta Pengantaran',
      userName: userStore.displayName,
      userRole: userStore.userRole,
      onNavigate: (route) => context.go(route),
      onLogout: () async {
        await getIt<AuthService>().logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
      child: const MapMonitoringViewer(),
    );
  }
}
