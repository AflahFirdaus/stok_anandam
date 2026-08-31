import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:my_api_client/my_api_client.dart';
import 'data/repositories/map_repository.dart';

import 'core/auth/current_user_store.dart';
import 'core/auth/auth_service.dart';
import 'core/env/app_env.dart';
import 'data/api_new_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/auth_refresh_interceptor.dart';
import 'token_storage.dart';
import 'data/repositories/memo_repository.dart';
import 'data/repositories/announcement_repository.dart';
import 'features/users/services/user_session_service.dart';
import 'core/network/websocket_service.dart';
import 'features/shared/autocomplete_service.dart';
import 'core/network/retry_interceptor.dart';
import 'core/network/cache_interceptor.dart';
import 'features/servis/api/servis_api.dart';
import 'features/servis/repositories/servis_repository.dart';
import 'features/laporan_marketing/api/laporan_marketing_api.dart';
import 'features/laporan_marketing/repositories/laporan_marketing_repository.dart';
import 'features/Biometric/api/biometric_api.dart';
import 'features/Biometric/repositories/biometric_repository.dart';
import 'features/Biometric/services/biometric_crypto_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // 0. Penyimpanan token untuk Bearer auth
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);

  final tokenStorage = TokenStorage();
  await tokenStorage.init();
  getIt.registerLazySingleton<TokenStorage>(() => tokenStorage);
  getIt.registerLazySingleton<CurrentUserStore>(() => CurrentUserStore());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<UserSessionService>(() => UserSessionService());
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // 1. Injeksi Dio (Base Network Client)
  // baseUrl dari .env (BASE_URL) atau --dart-define=BASE_URL=... atau default localhost.
  // Lihat .env.example untuk opsi: localhost, 10.0.2.2:9099 (emulator Android), atau server.
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
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

  // Retry & Deduplication Interceptor
  dio.interceptors.add(RetryInterceptor(dio: dio));

  // Cache Interceptor
  final cacheInterceptor = InMemoryCacheInterceptor();
  getIt.registerSingleton<InMemoryCacheInterceptor>(cacheInterceptor);
  dio.interceptors.add(cacheInterceptor);

  dio.interceptors.add(LogInterceptor(responseBody: true));

  getIt.registerSingleton<Dio>(dio);
  getIt.registerLazySingleton<ApiNewEndpoints>(
      () => ApiNewEndpoints(getIt<Dio>()));

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
  getIt
      .registerLazySingleton(() => getIt<MyApiClient>().getTkdnControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getCanvasingControllerApi());
  getIt.registerLazySingleton(
      () => getIt<MyApiClient>().getDataCanvasingControllerApi());
  getIt.registerLazySingleton<MemoRepository>(
      () => MemoRepository(getIt<ApiNewEndpoints>()));
  getIt.registerLazySingleton<AnnouncementRepository>(
      () => AnnouncementRepository(getIt<ApiNewEndpoints>(), getIt<SharedPreferences>()));
  getIt.registerLazySingleton<MapRepository>(() => MapRepository(getIt<Dio>()));
  getIt.registerLazySingleton<AutocompleteService>(() => AutocompleteService());

  // Servis Management
  getIt.registerLazySingleton<ServisApi>(() => ServisApi(getIt<Dio>()));
  getIt.registerLazySingleton<ServisRepository>(() => ServisRepository(getIt<ServisApi>()));

  // Biometric
  getIt.registerLazySingleton<BiometricApi>(() => BiometricApi(getIt<Dio>()));
  getIt.registerLazySingleton<BiometricCryptoService>(() => BiometricCryptoService(const FlutterSecureStorage()));
  getIt.registerLazySingleton<BiometricRepository>(() => BiometricRepository(
    getIt<BiometricApi>(),
    getIt<BiometricCryptoService>(),
  ));

  // Laporan Omset Marketing
  getIt.registerLazySingleton<LaporanMarketingApi>(() => LaporanMarketingApi(getIt<Dio>()));
  getIt.registerLazySingleton<LaporanMarketingRepository>(() => LaporanMarketingRepository(
    getIt<LaporanMarketingApi>(),
    getIt<ApiNewEndpoints>(),
  ));
}

//
