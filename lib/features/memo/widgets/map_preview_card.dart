import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'map_monitoring_viewer.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sebaran Pengantaran Hari Ini',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.pushNamed(AppRoutes.mapPengantaran),
                  child: Text(
                    'Lihat Penuh',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: MapMonitoringViewer(
              isMini: true,
              onExpand: () => context.pushNamed(AppRoutes.mapPengantaran),
            ),
          ),
        ],
      ),
    );
  }
}
