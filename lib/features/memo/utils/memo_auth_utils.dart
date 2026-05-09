import 'package:flutter/material.dart';
import 'package:stok_anandam/data/models/memo.dart';

class MemoAuthUtils {
  /// Main logic to check if a role can read a memo with a specific status
  static bool canAccessMemo(String? role, MemoStatus? status) {
    if (status == null) return false;
    final r = role?.toUpperCase();
    
    // Administrative and Supervision roles have full read access
    if (r == 'ADMIN' ||
        (r != null && r.startsWith('MARKETING')) ||
        (r != null && r.contains('SPV'))) {
      return true;
    }

    // Role-specific operational access
    switch (r) {
      case 'GUDANG':
        return [
          MemoStatus.PENDING,
          MemoStatus.MENUNGGU_PERSETUJUAN,
          MemoStatus.DISETUJUI,
          MemoStatus.DITOLAK,
          MemoStatus.MENUNGGU_GUDANG,
          MemoStatus.MENUNGGU_NOTA,
          MemoStatus.MENUNGGU_TEKNISI,
          MemoStatus.PROSES_TEKNISI,
          MemoStatus.BUFFER_ZONE,
          MemoStatus.MENUNGGU_PENGIRIMAN,
          MemoStatus.DALAM_PENGIRIMAN,
          MemoStatus.DITERIMA_USER,
          MemoStatus.TERKIRIM_SEBAGIAN,
          MemoStatus.KENDALA_BARANG,
          MemoStatus.SELESAI
        ].contains(status);
        
      case 'NOTA':
        return [
          MemoStatus.MENUNGGU_NOTA,
        ].contains(status);

      case 'TEKNISI':
        return [
          MemoStatus.MENUNGGU_TEKNISI,
          MemoStatus.PROSES_TEKNISI,
          MemoStatus.BUFFER_ZONE,
          MemoStatus.SELESAI,
        ].contains(status);

      case 'DELIVERY':
        return [
          MemoStatus.MENUNGGU_PENGIRIMAN,
          MemoStatus.DALAM_PENGIRIMAN,
          MemoStatus.DITERIMA_USER,
          MemoStatus.TERKIRIM_SEBAGIAN,
          MemoStatus.SELESAI
        ].contains(status);

      default:
        return false;
    }
  }

  /// Check access for Manual Tasks (Request Delivery)
  static bool canAccessManualTask(String? role, String? statusJadwal) {
    if (statusJadwal == null) return false;
    final r = role?.toUpperCase();

    // Administrative and Supervision roles have full access
    if (r == 'ADMIN' ||
        (r != null && r.startsWith('MARKETING')) ||
        (r != null && r.contains('SPV'))) {
      return true;
    }

    // Usually Delivery and Technician see these
    if (r == 'DELIVERY' || r == 'TEKNISI' || r == 'GUDANG') {
      return true; // Most operational roles can see request delivery details if they are in the list
    }

    return false;
  }

  /// A helper that checks access and shows an AlertDialog if denied.
  /// Calls [onGranted] only if access is allowed.
  static void guardAccess(
    BuildContext context, {
    required String? role,
    required MemoStatus? status,
    required VoidCallback onGranted,
    String? memoId,
  }) {
    if (canAccessMemo(role, status)) {
      onGranted();
    } else {
      _showDeniedDialog(context, status?.label ?? 'Unknown');
    }
  }

  /// Same as [guardAccess] but for Manual Tasks
  static void guardManualTaskAccess(
    BuildContext context, {
    required String? role,
    required String? statusJadwal,
    required VoidCallback onGranted,
  }) {
    if (canAccessManualTask(role, statusJadwal)) {
      onGranted();
    } else {
      _showDeniedDialog(context, statusJadwal ?? 'Unknown');
    }
  }

  static void _showDeniedDialog(BuildContext context, String statusLabel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_person_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Akses Dibatasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda tidak memiliki akses untuk melihat detail memo ini.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Status saat ini: $statusLabel\n\nLevel akses Anda tidak mengizinkan pembukaan detail pada tahap ini.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
