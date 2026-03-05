import 'dart:async';
import 'package:flutter/material.dart';
import '../../injection.dart';
import '../../data/api_new_endpoints.dart';
import '../dashboard/widgets/migration_dialog.dart';

mixin MigrationSyncMixin<T extends StatefulWidget> on State<T> {
  String lastSyncFormatted = '';

  Future<void> fetchLastSync() async {
    try {
      final api = getIt<ApiNewEndpoints>();
      final dt = await api.getLastSync();
      if (mounted && dt != null) {
        final local = dt.toLocal();
        final h = local.hour.toString().padLeft(2, '0');
        final m = local.minute.toString().padLeft(2, '0');
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        final day = local.day;
        final month = months[local.month - 1];
        if (mounted) {
          setState(() {
            lastSyncFormatted = 'Last sync: $day $month $h:$m';
          });
        }
      }
    } catch (_) {}
  }

  void showSyncMigrationDialog({VoidCallback? onCustomSuccess}) {
    showMigrationDialog(context, onSuccess: () {
      fetchLastSync();
      onCustomSuccess?.call();
    });
  }
}
