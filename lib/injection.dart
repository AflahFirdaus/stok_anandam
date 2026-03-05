import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:my_api_client/my_api_client.dart';

import 'core/auth/current_user_store.dart';
import 'core/auth/auth_service.dart';
import 'core/env/app_env.dart';
import 'data/api_new_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/auth_refresh_interceptor.dart';
import 'token_storage.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // 0. Penyimpanan token untuk Bearer auth
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<CurrentUserStore>(() => CurrentUserStore());
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // 1. Injeksi Dio (Base Network Client)
  // baseUrl dari .env (BASE_URL) atau --dart-define=BASE_URL=... atau default localhost.
  // Lihat .env.example untuk opsi: localhost, 10.0.2.2:8080 (emulator Android), atau server.
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  // Interceptor: tambah Authorization Bearer jika ada token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = getIt<TokenStorage>().token;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  // AuthRefreshInterceptor: on 401, try refresh token; if refresh fails, clear token
  // and TokenStorage.notifyListeners() will trigger GoRouter to redirect to /login.
  dio.interceptors.add(AuthRefreshInterceptor(dio));

  dio.interceptors.add(LogInterceptor(responseBody: true));

  getIt.registerSingleton<Dio>(dio);
  getIt.registerLazySingleton<ApiNewEndpoints>(() => ApiNewEndpoints(getIt<Dio>()));

  // 2. Injeksi SDK hasil OpenAPI
  getIt.registerLazySingleton<MyApiClient>(() => MyApiClient(dio: dio));

  // 3. Injeksi spesifik API
  getIt
      .registerLazySingleton(() => getIt<MyApiClient>().getUserControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getStockControllerApi());
  getIt
      .registerLazySingleton(() => getIt<MyApiClient>().getAuthControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getDashboardControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getMigrationControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getPurchaseControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getSalesControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getTkdnControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getCanvasingControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getDataCanvasingControllerApi());
}
