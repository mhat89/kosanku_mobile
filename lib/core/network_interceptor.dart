import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

class NetworkInterceptor extends Interceptor {
  // Menyimpan request yang gagal untuk retry
  final Map<String, RequestOptions> _failedRequests = {};

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Buat ID unik untuk request ini
    final requestId = '${err.requestOptions.uri.toString()}_${DateTime.now().millisecondsSinceEpoch}';
    _failedRequests[requestId] = err.requestOptions;

    // Tentukan jenis error dan pesan yang sesuai
    String errorMessage;
    String errorType;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorType = 'Timeout';
        errorMessage = 'Koneksi timeout: Server tidak merespon dalam ${err.requestOptions.connectTimeout?.inSeconds ?? 30} detik. Coba lagi nanti atau periksa koneksi internet Anda.';
        break;
      case DioExceptionType.connectionError:
        errorType = 'Offline';
        errorMessage = 'Tidak ada koneksi internet';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        errorType = 'Server Error';
        if (statusCode != null) {
          if (statusCode >= 500) {
            errorMessage = 'Server error ($statusCode)';
          } else if (statusCode == 401) {
            errorMessage = 'Sesi habis';
          } else if (statusCode == 403) {
            errorMessage = 'Akses ditolak';
          } else if (statusCode == 404) {
            errorMessage = 'Data tidak ditemukan';
          } else {
            errorMessage = 'Error $statusCode';
          }
        } else {
          errorMessage = 'Respons server tidak valid';
        }
        break;
      default:
        errorType = 'Error';
        errorMessage = 'Terjadi kesalahan';
    }

    // Tampilkan toast dengan opsi retry
    _showErrorToast(errorType, errorMessage, requestId);

    // Lanjutkan penanganan error
    handler.next(err);
  }

  void _showErrorToast(String errorType, String message, String requestId) {
    // Hanya tampilkan opsi retry jika request bisa di-retry
    final canRetry = _failedRequests.containsKey(requestId) &&
        (errorType == 'Timeout' || errorType == 'Offline' || errorType == 'Server Error');

    Widget toastWidget = Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xEE333333),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForErrorType(errorType),
                color: CupertinoColors.systemRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                errorType,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 14),
          ),
          if (canRetry) ...[  
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(20),
                minSize: 0,
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(fontSize: 14, color: CupertinoColors.white),
                ),
                onPressed: () => _retryRequest(requestId),
              ),
            ),
          ],
        ],
      ),
    );

    BotToast.showCustomNotification(
      toastBuilder: (_) => toastWidget,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 200),
      animationReverseDuration: const Duration(milliseconds: 200),
    );
  }

  IconData _getIconForErrorType(String errorType) {
    switch (errorType) {
      case 'Timeout':
        return CupertinoIcons.clock;
      case 'Offline':
        return CupertinoIcons.wifi_slash;
      case 'Server Error':
        return CupertinoIcons.exclamationmark_triangle;
      default:
        return CupertinoIcons.exclamationmark_circle;
    }
  }

  void _showSuccessToast(String message) {
    Widget toastWidget = Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xEE2E7D32),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle,
            color: CupertinoColors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );

    BotToast.showCustomNotification(
      toastBuilder: (_) => toastWidget,
      duration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 200),
      animationReverseDuration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _retryRequest(String requestId) async {
    final request = _failedRequests[requestId];
    if (request == null) return;

    // Hapus dari daftar request yang gagal
    _failedRequests.remove(requestId);

    try {
      // Buat instance Dio baru untuk retry
      final dio = Dio();
      
      // Salin semua header dan parameter dari request asli
      final response = await dio.request(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        options: Options(
          method: request.method,
          headers: request.headers,
          contentType: request.contentType,
          responseType: request.responseType,
        ),
      );

      // Tampilkan toast sukses jika berhasil
      _showSuccessToast('Koneksi berhasil dipulihkan');
    } catch (e) {
      // Jika retry gagal, tampilkan toast error lagi
      _showErrorToast('Error', 'Gagal mencoba ulang, silakan coba lagi nanti', '');
    }
  }
}