import 'package:flutter/material.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';
import 'package:stok_anandam/injection.dart';

/// Mixin untuk mengirim action user ke WebSocket setiap kali pindah halaman.
/// Gunakan di StatefulWidget pages.
///
/// Contoh:
/// class SalesPage extends StatefulWidget { ... }
/// class _SalesPageState extends State<SalesPage> with PresenceActionMixin { ... }
mixin PresenceActionMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendPresenceAction(_getActionLabel());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Override untuk memberikan label action yang sesuai dengan halaman.
  String _getActionLabel() {
    final typeStr = runtimeType.toString().replaceAll('_', '').replaceAll('State', '');
    switch (typeStr) {
      case 'StockPage':
      case 'StockContent':
        return 'Halaman Stok';
      case 'MemoPage':
        return 'Halaman Memo';
      case 'DashboardPage':
        return 'Halaman Dashboard';
      case 'SalesPage':
        return 'Halaman Penjualan';
      case 'PurchasePage':
        return 'Halaman Pembelian';
      case 'ServisPage':
        return 'Halaman Servis';
      case 'ProfilePage':
        return 'Halaman Profil';
      case 'UsersPage':
        return 'Halaman Manajemen User';
      case 'ActivityLogPage':
        return 'Halaman Log Aktivitas';
      case 'AdminPresenceScreen':
        return 'Halaman User Activity';
      case 'SimulasiPage':
      case 'SimulasiContent':
        return 'Halaman Simulasi SPJ';
      case 'RequestDeliveryPage':
        return 'Halaman Request Delivery';
      case 'PetaPengantaranPage':
        return 'Halaman Peta Pengantaran';
      case 'ItemSnPage':
      case 'ItemSnContent':
        return 'Halaman Item SN';
      case 'IjinImportPage':
      case 'IjinImportContent':
        return 'Halaman Ijin Import';
      case 'ShbjPage':
      case 'ShbjContent':
        return 'Halaman SHBJ';
      case 'DataWarehousePage':
        return 'Halaman Data Warehouse';
      case 'AnnouncementPage':
        return 'Halaman Pengumuman';
      default:
        // Kembalikan nama yang diformat dengan spasi jika tidak ada di map
        return typeStr.replaceAllMapped(
          RegExp(r'(?<!^)(?=[A-Z])'),
          (match) => ' ${match.group(0)}',
        );
    }
  }

  /// Kirim action ke WebSocket untuk presence tracking.
  void sendPresenceAction(String action) {
    _sendPresenceAction(action);
  }

  void _sendPresenceAction(String action) {
    try {
      final userStore = getIt<CurrentUserStore>();
      final userId = userStore.userId?.toString();
      final name = userStore.displayName;

      if (userId != null && userId.isNotEmpty) {
        getIt<WebSocketService>().sendUserAction(
          userId: userId,
          name: name,
          currentAction: action,
        );
      }
    } catch (e) {
      // Abaikan error (mungkin service belum siap)
    }
  }
}
