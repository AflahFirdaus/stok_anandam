import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

/// Login berhasil, token tersimpan.
class AuthSuccess extends AuthState {
  final String token;
  AuthSuccess(this.token);
}

/// Gagal login karena kredensial salah / akun dinonaktifkan / error auth lainnya.
class AuthFailure extends AuthState {
  final String error;
  final bool isDeactivated;
  AuthFailure(this.error, {this.isDeactivated = false});

  @override
  List<Object?> get props => [error, isDeactivated];
}

/// Server sedang sibuk / gangguan / restart.
/// User tetap ditahan di halaman login dengan pesan informatif.
class AuthServerBusy extends AuthState {
  final String message;
  final bool isRetrying;

  AuthServerBusy(this.message, {this.isRetrying = false});

  @override
  List<Object?> get props => [message, isRetrying];
}