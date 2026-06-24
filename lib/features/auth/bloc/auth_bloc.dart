import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:my_api_client/my_api_client.dart';
import 'package:stok_anandam/core/network/websocket_service.dart';
import '../../../../injection.dart';
import '../../../../token_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final authApi = getIt<AuthControllerApi>();

  AuthBloc() : super(AuthInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        debugPrint(
            '[AuthBloc] Attempting login with username: ${event.username}');
        final response = await authApi.login(
          loginUserRequest: LoginUserRequest(
            username: event.username,
            password: event.password,
          ),
        );

        final data = response.data?.data;
        debugPrint('[AuthBloc] Login response data: $data');
        final token = data?.accessToken?.toString() ?? "";
        final refresh = data?.refreshToken?.toString();

        if (token.isNotEmpty) {
          await getIt<TokenStorage>()
              .setTokens(accessToken: token, refreshToken: refresh);

          // Load user data with a short timeout to keep login feeling fast.
          // The app_router will handle subsequent redirects when the data eventually arrives.
          try {
            debugPrint('AuthBloc: Background loading user info...');
            // We don't await this indefinitely; we give it a short window
            // and then proceed to AuthSuccess to allow the UI to transition.
            await getIt<CurrentUserStore>().loadFromApi().timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint(
                    'AuthBloc: User info load is taking longer than 3s, proceeding in background.');
                return;
              },
            ).catchError((e) {
              debugPrint('AuthBloc: Background user info load error: $e');
            });
          } catch (e) {
            debugPrint('AuthBloc: Error initiating user info load: $e');
          }

          // Aktifkan WebSocket setelah login berhasil, kirim userId/name untuk presence tracking
          final userId = getIt<CurrentUserStore>().userId?.toString();
          final name = getIt<CurrentUserStore>().displayName;
          getIt<WebSocketService>().connect(userId: userId, name: name);
          emit(AuthSuccess(token));
        } else {
          emit(AuthFailure("Login Gagal: Token tidak ditemukan."));
        }
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final body = e.response?.data;

        if (status == 403) {
          final serverMsg = _extractMessage(body);
          emit(AuthFailure(
            serverMsg ?? 'Akun Anda telah dinonaktifkan.',
            isDeactivated: true,
          ));
          return;
        }

        String message = 'Password salah atau username salah.';

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          message = AppErrors.userMessageFromDio(e);
        }

        emit(AuthFailure(message));
      } catch (e) {
        emit(AuthFailure(AppErrors.userMessageFromException(e,
            fallback: 'Login gagal. Coba lagi.')));
      }
    });
  }

  static String? _extractMessage(dynamic body) {
    if (body == null) return null;
    if (body is Map && body['message'] != null)
      return body['message'].toString();
    if (body is String) return body.isNotEmpty ? body : null;
    return null;
  }
}
