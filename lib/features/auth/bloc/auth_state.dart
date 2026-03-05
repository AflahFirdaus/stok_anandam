import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final String token;
  AuthSuccess(this.token);
}
class AuthFailure extends AuthState {
  final String error;
  final bool isDeactivated;
  AuthFailure(this.error, {this.isDeactivated = false});

  @override
  List<Object?> get props => [error, isDeactivated];
}