import 'dart:async';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:stok_anandam/core/env/app_env.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/injection.dart';

class WebSocketService {
  StompClient? _client;
  final _memoUpdateController = StreamController<String>.broadcast();

  Stream<String> get memoUpdateStream => _memoUpdateController.stream;

  void connect() {
    if (_client != null && (_client!.connected || _client!.isActive)) {
      print('WebSocket: Sudah terhubung atau sedang mencoba terhubung.');
      return;
    }

    final baseUrl = apiBaseUrl;
    final wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/ws';
    final token = getIt<TokenStorage>().token;

    if (token == null || token.isEmpty) {
      print('WebSocket: Gagal konek, token kosong.');
      return;
    }

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          print('WebSocket Connection Error: Halaman kosong atau protokol tidak didukung di $wsUrl');
          // Error "The document is empty" biasanya terjadi jika Nginx/Proxy tidak meneruskan header Upgrade
        },
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onDisconnect: (frame) => print('WebSocket: Terputus dari server'),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _client!.activate();
    print('WebSocket: Menghubungkan ke $wsUrl...');
  }

  void _onConnect(StompFrame frame) {
    print('WebSocket: Terhubung!');
    
    // Subscribe ke topik memo
    _client?.subscribe(
      destination: '/topic/memos',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          print('WebSocket: Menerima sinyal refresh memo');
          _memoUpdateController.add(frame.body!);
        }
      },
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    print('WebSocket: Terputus');
  }

  void dispose() {
    disconnect();
    _memoUpdateController.close();
  }
}
