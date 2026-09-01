import 'package:dio/dio.dart';
import 'package:movies_app/core/constants/api_constants.dart';

class DioClient {
  DioClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                sendTimeout: ApiConstants.sendTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;

  Dio get client => _dio;
}
