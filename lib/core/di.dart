import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
//import '../services/ors_routing_service.dart';
import '../services/google_routing_service.dart';
import 'theme.dart';
import '../services/biometric_service.dart';   // <<< add
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'app_config.dart'; //

class DioClient {
  static Dio create({required String baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          String msg = 'Terjadi kesalahan koneksi';

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            msg = 'Koneksi lambat atau server tidak merespon';
          } else if (e.type == DioExceptionType.connectionError) {
            msg = 'Tidak ada internet, cek wifi/data';
          } else if (e.response != null) {
            msg = 'Server error [${e.response?.statusCode}]';
          }

          BotToast.showText(
            text: msg,
            contentColor: const Color(0xFF333333),
            textStyle: const TextStyle(color: CupertinoColors.white),
            duration: const Duration(seconds: 3),
          );

          handler.next(e);
        },
      ),
    );

    return dio;
  }
}

class DI {
  static final storage = const FlutterSecureStorage();
  static final dio = Dio();
  static late final ApiClient api;
  static late final AuthService auth;
  static late final LocationService location;
  static late final ThemeController theme; // <<< add
  static late final BiometricService biometric; // <<< add
  // Routing interface
  static late final IRoutingService routing;

  static void init() {
    api = ApiClient(dio);
    auth = AuthService(api, storage);
    location = LocationService();

    // ====== PILIH PROVIDER ROUTING DI SINI ======
    // 1) OpenRouteService (ORS) – butuh API KEY
    //routing = ORSRoutingService(Dio(), 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZiNDRlMjE5MzJiNTQ4OGZiY2JiYTI4NTg2NjQ2NTc1IiwiaCI6Im11cm11cjY0In0=');

    // 2) Google Directions (uncomment baris di bawah dan comment ORS di atas)
    routing = GoogleRoutingService(Dio(), 'AIzaSyC69pQRvVxNZFmih5QF2U5t-v_y72NT1Nc');
    theme = ThemeController(storage); // <<< add
    biometric = BiometricService(storage);      // <<< add
  }
}
