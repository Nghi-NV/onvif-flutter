import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../exceptions/onvif_exceptions.dart';
import '../utils/constants.dart';

/// HTTP Transport cho ONVIF Communications
/// Xử lý tất cả HTTP/HTTPS requests tới ONVIF devices
class OnvifTransport {
  late final Dio _dio;
  final String baseUrl;
  final Duration timeout;
  final Map<String, String> defaultHeaders;

  OnvifTransport({
    required this.baseUrl,
    this.timeout = OnvifConstants.defaultTimeout,
    Map<String, String>? headers,
    bool allowSelfSignedCerts = true,
  }) : defaultHeaders = headers ?? {} {
    _initializeDio(allowSelfSignedCerts);
  }

  void _initializeDio(bool allowSelfSignedCerts) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'Content-Type': 'application/soap+xml; charset=utf-8',
        'SOAPAction': '',
        ...defaultHeaders,
      },
      responseType: ResponseType.plain,
      validateStatus: (status) => status != null && status < 500,
    ));

    // Configure HTTPS certificate validation
    if (allowSelfSignedCerts) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          // TODO: Implement proper logging
          // print('ONVIF HTTP: $object');
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final onvifError = _convertDioErrorToOnvifException(error);
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: onvifError,
            type: error.type,
            response: error.response,
          ));
        },
      ),
    );
  }

  /// Gửi SOAP request tới ONVIF device
  Future<String> sendSoapRequest({
    required String path,
    required String soapBody,
    String? soapAction,
    Map<String, String>? headers,
  }) async {
    try {
      final requestHeaders = <String, String>{
        ...?headers,
      };

      if (soapAction != null) {
        requestHeaders['SOAPAction'] = soapAction;
      }

      final response = await _dio.post(
        path,
        data: soapBody,
        options: Options(
          headers: requestHeaders,
          contentType: 'application/soap+xml; charset=utf-8',
        ),
      );

      if (response.statusCode != 200) {
        throw OnvifConnectionException(
          'HTTP ${response.statusCode}: ${response.statusMessage}',
          code: response.statusCode.toString(),
        );
      }

      final responseData = response.data as String;

      // Kiểm tra SOAP Fault trong response
      if (responseData.contains('soap:Fault') ||
          responseData.contains('SOAP-ENV:Fault')) {
        throw _parseSoapFault(responseData);
      }

      return responseData;
    } on DioException catch (e) {
      if (e.error is OnvifException) {
        rethrow;
      }
      throw _convertDioErrorToOnvifException(e);
    } catch (e) {
      throw OnvifConnectionException(
        'Unexpected error during SOAP request: $e',
        originalError: e,
      );
    }
  }

  /// Gửi HTTP GET request (cho snapshots, streams, etc.)
  Future<Response> sendGetRequest({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ResponseType responseType = ResponseType.bytes,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      throw _convertDioErrorToOnvifException(e);
    }
  }

  /// Gửi HTTP POST request
  Future<Response> sendPostRequest({
    required String path,
    dynamic data,
    Map<String, String>? headers,
    ResponseType responseType = ResponseType.plain,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      throw _convertDioErrorToOnvifException(e);
    }
  }

  /// Download file (cho recordings, etc.)
  Future<void> downloadFile({
    required String url,
    required String savePath,
    void Function(int, int)? onReceiveProgress,
    Map<String, String>? headers,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw _convertDioErrorToOnvifException(e);
    }
  }

  /// Chuyển đổi DioException thành OnvifException
  OnvifException _convertDioErrorToOnvifException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return OnvifTimeoutException(
          'Request timeout: ${error.message}',
          timeout,
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return OnvifConnectionException(
          'Connection failed: ${error.message}',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return const OnvifAuthenticationException('Authentication failed');
        } else if (statusCode == 404) {
          return const OnvifDeviceNotFoundException();
        }
        return OnvifConnectionException(
          'HTTP $statusCode: ${error.response?.statusMessage ?? error.message}',
          code: statusCode?.toString(),
          originalError: error,
        );

      case DioExceptionType.cancel:
        return OnvifConnectionException(
          'Request cancelled',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return OnvifConnectionException(
          'SSL certificate error: ${error.message}',
          originalError: error,
        );

      case DioExceptionType.unknown:
        return OnvifConnectionException(
          'Unknown error: ${error.message}',
          originalError: error,
        );
    }
  }

  /// Parse SOAP Fault từ response
  OnvifSoapException _parseSoapFault(String responseBody) {
    // Simple parsing - trong thực tế nên dùng XML parser
    String? faultCode;
    String? faultString;
    String? detail;

    try {
      // Tìm fault code
      final faultCodeMatch =
          RegExp(r'<(?:soap:|SOAP-ENV:)?faultcode[^>]*>([^<]+)</')
              .firstMatch(responseBody);
      faultCode = faultCodeMatch?.group(1)?.trim();

      // Tìm fault string
      final faultStringMatch =
          RegExp(r'<(?:soap:|SOAP-ENV:)?faultstring[^>]*>([^<]+)</')
              .firstMatch(responseBody);
      faultString = faultStringMatch?.group(1)?.trim();

      // Tìm detail
      final detailMatch = RegExp(r'<(?:soap:|SOAP-ENV:)?detail[^>]*>([^<]+)</')
          .firstMatch(responseBody);
      detail = detailMatch?.group(1)?.trim();
    } catch (e) {
      // Nếu parsing thất bại, sử dụng toàn bộ response
    }

    return OnvifSoapException(
      'SOAP Fault received',
      faultCode: faultCode,
      faultString: faultString,
      detail: detail,
    );
  }

  /// Đóng transport và giải phóng resources
  void dispose() {
    _dio.close();
  }

  /// Cập nhật base URL
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Thêm header mặc định
  void addDefaultHeader(String key, String value) {
    _dio.options.headers[key] = value;
    defaultHeaders[key] = value;
  }

  /// Xóa header mặc định
  void removeDefaultHeader(String key) {
    _dio.options.headers.remove(key);
    defaultHeaders.remove(key);
  }

  /// Cập nhật timeout
  void updateTimeout(Duration newTimeout) {
    _dio.options.connectTimeout = newTimeout;
    _dio.options.receiveTimeout = newTimeout;
    _dio.options.sendTimeout = newTimeout;
  }
}
