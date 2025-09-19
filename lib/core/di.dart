import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../services/ors_routing_service.dart';
//import '../services/google_routing_service.dart';
import 'theme.dart';
import '../services/biometric_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'app_config.dart';
import 'network_interceptor.dart';

class DioClient {
  static Dio create({required String baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Tambahkan network interceptor dengan fitur retry
    dio.interceptors.add(NetworkInterceptor());

    return dio;
  }
}

class DI {
  static const storage = FlutterSecureStorage();
  static late final Dio dio;
  static late final ApiClient api;
  static late final AuthService auth;
  static late final LocationService location;
  static late final ThemeController theme; // <<< add
  static late final BiometricService biometric; // <<< add
  // Routing interface
  static late final IRoutingService routing;

  static void init() {
    dio = DioClient.create(baseUrl: AppConfig.baseUrl);
    api = ApiClient(dio);
    auth = AuthService(api, storage);
    location = LocationService();

    // ====== PILIH PROVIDER ROUTING DI SINI ======
    // 1) OpenRouteService (ORS) – butuh API KEY
    routing = ORSRoutingService(Dio(),
        'API KEY');

    // 2) Google Directions (uncomment baris di bawah dan comment ORS di atas)
    //routing = GoogleRoutingService(Dio(), 'API KEY');
    theme = ThemeController(storage); // <<< add
    biometric = BiometricService(storage); // <<< add
  }
}
