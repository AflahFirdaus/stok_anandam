//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:my_api_client/src/auth/api_key_auth.dart';
import 'package:my_api_client/src/auth/basic_auth.dart';
import 'package:my_api_client/src/auth/bearer_auth.dart';
import 'package:my_api_client/src/auth/oauth.dart';
import 'package:my_api_client/src/api/auth_controller_api.dart';
import 'package:my_api_client/src/api/canvasing_controller_api.dart';
import 'package:my_api_client/src/api/dashboard_controller_api.dart';
import 'package:my_api_client/src/api/data_canvasing_controller_api.dart';
import 'package:my_api_client/src/api/migration_controller_api.dart';
import 'package:my_api_client/src/api/purchase_controller_api.dart';
import 'package:my_api_client/src/api/sales_controller_api.dart';
import 'package:my_api_client/src/api/stock_controller_api.dart';
import 'package:my_api_client/src/api/tkdn_controller_api.dart';
import 'package:my_api_client/src/api/user_controller_api.dart';

class MyApiClient {
  static const String basePath = r'https://api.anandamcomputer.com';

  final Dio dio;
  MyApiClient({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  }) : this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
              as OAuthInterceptor)
          .tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
              as BearerAuthInterceptor)
          .tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this
                  .dio
                  .interceptors
                  .firstWhere((element) => element is ApiKeyAuthInterceptor)
              as ApiKeyAuthInterceptor)
          .apiKeys[name] = apiKey;
    }
  }

  /// Get AuthControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthControllerApi getAuthControllerApi() {
    return AuthControllerApi(dio);
  }

  /// Get CanvasingControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CanvasingControllerApi getCanvasingControllerApi() {
    return CanvasingControllerApi(dio);
  }

  /// Get DashboardControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DashboardControllerApi getDashboardControllerApi() {
    return DashboardControllerApi(dio);
  }

  /// Get DataCanvasingControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  DataCanvasingControllerApi getDataCanvasingControllerApi() {
    return DataCanvasingControllerApi(dio);
  }

  /// Get MigrationControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MigrationControllerApi getMigrationControllerApi() {
    return MigrationControllerApi(dio);
  }

  /// Get PurchaseControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PurchaseControllerApi getPurchaseControllerApi() {
    return PurchaseControllerApi(dio);
  }

  /// Get SalesControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SalesControllerApi getSalesControllerApi() {
    return SalesControllerApi(dio);
  }

  /// Get StockControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  StockControllerApi getStockControllerApi() {
    return StockControllerApi(dio);
  }

  /// Get TkdnControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TkdnControllerApi getTkdnControllerApi() {
    return TkdnControllerApi(dio);
  }

  /// Get UserControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  UserControllerApi getUserControllerApi() {
    return UserControllerApi(dio);
  }
}
