import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:stok_anandam/core/env/app_env.dart';
import 'package:stok_anandam/features/presence/models/user_session.dart';
import 'package:stok_anandam/token_storage.dart';
import 'package:stok_anandam/injection.dart';

class WebSocketService {
  StompClient? _client;
  final _memoUpdateController = StreamController<String>.broadcast();
  final _presenceController = StreamController<List<UserSession>>.broadcast();

  // Menyimpan data presence yang tertunda (saat connect() dipanggil duluan)
  String? _pendingUserId;
  String? _pendingName;

  Stream<String> get memoUpdateStream => _memoUpdateController.stream;
  Stream<List<UserSession>> get presenceStream => _presenceController.stream;

  /// Koneksi WebSocket untuk presence tracking.
  /// Dipanggil setelah login berhasil dengan userId dan name.
  void connectPresence({
    required String userId,
    required String name,
  }) {
    final baseUrl = apiBaseUrl;
    final wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/ws-connect';

    // Jika sudah terhubung, subscribe langsung ke topic presence
    if (_client != null && _client!.connected) {
      print(
          'WebSocket Presence: Already connected, subscribing to presence topic...');
      _subscribePresence(userId, name);
      sendUserAction(userId: userId, name: name, currentAction: 'connected');
      return;
    }

    // Jika sedang dalam proses koneksi, simpan data untuk diproses setelah connected
    if (_client != null && _client!.isActive) {
      print('WebSocket Presence: Connection in progress, saving for later...');
      _pendingUserId = userId;
      _pendingName = name;
      return;
    }

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) => _onConnectPresence(frame, userId, name),
        onWebSocketError: (dynamic error) {
          print('WebSocket Presence Error: $error');
        },
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onDisconnect: (frame) => print('WebSocket Presence: Disconnected'),
        stompConnectHeaders: {
          'userId': userId,
          'name': name,
        },
        webSocketConnectHeaders: {
          'userId': userId,
          'name': name,
        },
        reconnectDelay: const Duration(seconds: 3),
      ),
    );

    _client!.activate();
    print('WebSocket Presence: Connecting to $wsUrl as $userId ($name)...');
  }

  void _subscribePresence(String userId, String name) {
    _client?.subscribe(
      destination: '/topic/admin-dashboard',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(frame.body!);
            final sessions = jsonList
                .map((e) => UserSession.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            _presenceController.add(sessions);
          } catch (e) {
            print('WebSocket Presence: Error parsing sessions: $e');
          }
        }
      },
    );
  }

  void _onConnectPresence(StompFrame frame, String userId, String name) {
    print('WebSocket Presence: Connected!');

    // Subscribe ke admin dashboard (untuk admin screen)
    _subscribePresence(userId, name);

    // Kirim action awal
    sendUserAction(userId: userId, name: name, currentAction: 'connected');
  }

  /// Kirim action user ke backend via STOMP.
  void sendUserAction({
    required String userId,
    required String currentAction,
    String? name,
  }) {
    if (_client == null || !_client!.connected) {
      return;
    }

    _client!.send(
      destination: '/app/user-action',
      body: jsonEncode({
        'userId': userId,
        'name': name,
        'currentAction': currentAction,
      }),
    );
  }

  /// Koneksi WebSocket untuk memo updates (legacy).
  /// Juga mengirim userId/name agar WebSocketEventListener di backend bisa menyimpan session.
  void connect({String? userId, String? name}) {
    if (_client != null && (_client!.connected || _client!.isActive)) {
      print('WebSocket: Sudah terhubung atau sedang mencoba terhubung.');
      return;
    }

    final baseUrl = apiBaseUrl;
    final wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/ws-connect';
    final token = getIt<TokenStorage>().token;

    if (token == null || token.isEmpty) {
      print('WebSocket: Gagal konek, token kosong.');
      return;
    }

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) => _onConnect(frame, userId, name),
        onWebSocketError: (dynamic error) {
          print(
              'WebSocket Connection Error: Halaman kosong atau protokol tidak didukung di $wsUrl');
        },
        onStompError: (frame) => print('Stomp Error: ${frame.body}'),
        onDisconnect: (frame) => print('WebSocket: Terputus dari server'),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
          if (userId != null) 'userId': userId,
          if (name != null) 'name': name,
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
          if (userId != null) 'userId': userId,
          if (name != null) 'name': name,
        },
      ),
    );

    _client!.activate();
    print('WebSocket: Menghubungkan ke $wsUrl...');
  }

  void _onConnect(StompFrame frame, [String? userId, String? name]) {
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

    // Jika ada pending presence dari connectPresence(), proses sekarang
    if (_pendingUserId != null && _pendingName != null) {
      print('WebSocket: Processing pending presence for $_pendingUserId...');
      _subscribePresence(_pendingUserId!, _pendingName!);
      sendUserAction(
          userId: _pendingUserId!,
          name: _pendingName!,
          currentAction: 'connected');
      _pendingUserId = null;
      _pendingName = null;
    }
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _pendingUserId = null;
    _pendingName = null;
    print('WebSocket: Terputus');
  }

  void dispose() {
    disconnect();
    _memoUpdateController.close();
    _presenceController.close();
  }
}
