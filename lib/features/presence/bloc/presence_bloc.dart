import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stok_anandam/features/presence/models/user_session.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';

// Events
abstract class PresenceEvent extends Equatable {
  const PresenceEvent();

  @override
  List<Object?> get props => [];
}

class PresenceStarted extends PresenceEvent {}

class PresenceSessionsUpdated extends PresenceEvent {
  final List<UserSession> sessions;

  const PresenceSessionsUpdated(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class PresenceRefreshed extends PresenceEvent {}

// States
abstract class PresenceState extends Equatable {
  const PresenceState();

  @override
  List<Object?> get props => [];
}

class PresenceInitial extends PresenceState {}

class PresenceLoading extends PresenceState {}

class PresenceLoaded extends PresenceState {
  final List<UserSession> sessions;
  final int onlineCount;
  final int offlineCount;

  const PresenceLoaded({
    required this.sessions,
    required this.onlineCount,
    required this.offlineCount,
  });

  @override
  List<Object?> get props => [sessions, onlineCount, offlineCount];
}

class PresenceError extends PresenceState {
  final String message;

  const PresenceError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PresenceBloc extends Bloc<PresenceEvent, PresenceState> {
  StreamSubscription? _subscription;

  PresenceBloc() : super(PresenceInitial()) {
    on<PresenceStarted>(_onStarted);
    on<PresenceSessionsUpdated>(_onSessionsUpdated);
    on<PresenceRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
      PresenceStarted event, Emitter<PresenceState> emit) async {
    emit(PresenceLoading());

    try {
      final ws = getIt<WebSocketService>();

      // Subscribe ke stream presence
      _subscription?.cancel();
      _subscription = ws.presenceStream.listen((sessions) {
        add(PresenceSessionsUpdated(sessions));
      });

      // Jika belum ada data, emit empty
      emit(const PresenceLoaded(
        sessions: [],
        onlineCount: 0,
        offlineCount: 0,
      ));
    } catch (e) {
      emit(PresenceError('Gagal memuat data presence: $e'));
    }
  }

  void _onSessionsUpdated(
      PresenceSessionsUpdated event, Emitter<PresenceState> emit) {
    final online = event.sessions.where((s) => s.isOnline).length;
    final offline = event.sessions.length - online;

    emit(PresenceLoaded(
      sessions: event.sessions,
      onlineCount: online,
      offlineCount: offline,
    ));
  }

  Future<void> _onRefreshed(
      PresenceRefreshed event, Emitter<PresenceState> emit) async {
    // Stream akan otomatis mengirim update dari WebSocket
    // Tidak perlu melakukan apa-apa, data akan datang real-time
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
