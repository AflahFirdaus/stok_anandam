import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stok_anandam/features/presence/models/user_session.dart';
import 'package:stok_anandam/injection.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';
import 'package:stok_anandam/data/api_new_endpoints.dart';

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
  final int activeUsersToday;
  final List<String> activeUsernames;
  final List<DailyActiveUserStat> dailyStats;

  const PresenceLoaded({
    required this.sessions,
    required this.onlineCount,
    required this.offlineCount,
    required this.activeUsersToday,
    required this.activeUsernames,
    required this.dailyStats,
  });

  PresenceLoaded copyWith({
    List<UserSession>? sessions,
    int? onlineCount,
    int? offlineCount,
    int? activeUsersToday,
    List<String>? activeUsernames,
    List<DailyActiveUserStat>? dailyStats,
  }) {
    return PresenceLoaded(
      sessions: sessions ?? this.sessions,
      onlineCount: onlineCount ?? this.onlineCount,
      offlineCount: offlineCount ?? this.offlineCount,
      activeUsersToday: activeUsersToday ?? this.activeUsersToday,
      activeUsernames: activeUsernames ?? this.activeUsernames,
      dailyStats: dailyStats ?? this.dailyStats,
    );
  }

  @override
  List<Object?> get props => [
        sessions,
        onlineCount,
        offlineCount,
        activeUsersToday,
        activeUsernames,
        dailyStats,
      ];
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
      final api = getIt<ApiNewEndpoints>();

      // Fetch active users today & daily stats via HTTP
      final activeToday = await api.getActiveUsersToday();
      final stats = await api.getDailyActiveUserStats(days: 30);

      // Subscribe ke stream presence
      _subscription?.cancel();
      _subscription = ws.presenceStream.listen((sessions) {
        add(PresenceSessionsUpdated(sessions));
      });

      // Emit loaded state
      emit(PresenceLoaded(
        sessions: const [],
        onlineCount: 0,
        offlineCount: 0,
        activeUsersToday: activeToday?.count ?? 0,
        activeUsernames: activeToday?.usernames ?? [],
        dailyStats: stats,
      ));
    } catch (e) {
      emit(PresenceError('Gagal memuat data presence: $e'));
    }
  }

  void _onSessionsUpdated(
      PresenceSessionsUpdated event, Emitter<PresenceState> emit) {
    final online = event.sessions.where((s) => s.isOnline).length;
    final offline = event.sessions.length - online;

    if (state is PresenceLoaded) {
      final current = state as PresenceLoaded;
      emit(current.copyWith(
        sessions: event.sessions,
        onlineCount: online,
        offlineCount: offline,
      ));
    } else {
      emit(PresenceLoaded(
        sessions: event.sessions,
        onlineCount: online,
        offlineCount: offline,
        activeUsersToday: 0,
        activeUsernames: const [],
        dailyStats: const [],
      ));
    }
  }

  Future<void> _onRefreshed(
      PresenceRefreshed event, Emitter<PresenceState> emit) async {
    if (state is PresenceLoaded) {
      final current = state as PresenceLoaded;
      try {
        final api = getIt<ApiNewEndpoints>();
        final activeToday = await api.getActiveUsersToday();
        final stats = await api.getDailyActiveUserStats(days: 30);

        emit(current.copyWith(
          activeUsersToday: activeToday?.count ?? current.activeUsersToday,
          activeUsernames: activeToday?.usernames ?? current.activeUsernames,
          dailyStats: stats.isNotEmpty ? stats : current.dailyStats,
        ));
      } catch (_) {}
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
