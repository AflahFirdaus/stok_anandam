import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stok_anandam/core/auth/current_user_store.dart';
import 'package:stok_anandam/core/errors/app_errors.dart';
import 'package:my_api_client/my_api_client.dart';
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
        final response = await authApi.login(
          loginUserRequest: LoginUserRequest(
            username: event.username,
            password: event.password,
          ),
        );

        final data = response.data?.data;
        final token = data?.accessToken?.toString() ?? "";
        final refresh = data?.refreshToken?.toString();

        if (token.isNotEmpty) {
          await getIt<TokenStorage>().setTokens(accessToken: token, refreshToken: refresh);
          await getIt<CurrentUserStore>().loadFromApi();
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

        String message = AppErrors.userMessageFromDio(e);
        if (status == 401 || status == 400) {
          message = 'Username atau password salah.';
          final serverMsg = _extractMessage(body);
          if (serverMsg != null && serverMsg.isNotEmpty && serverMsg.length < 100) {
            message = serverMsg;
          }
        }
        emit(AuthFailure(message));
      } catch (e) {
        emit(AuthFailure(AppErrors.userMessageFromException(e, 'Login gagal. Coba lagi.')));
      }
    });
  }

  static String? _extractMessage(dynamic body) {
    if (body == null) return null;
    if (body is Map && body['message'] != null) return body['message'].toString();
    if (body is String) return body.isNotEmpty ? body : null;
    return null;
  }
}