import 'dart:convert';
import 'package:dio/dio.dart';

/// Script để scan các port ONVIF phổ biến
void main() async {
  final host = 'fb000033.ddns.net';
  final username = 'admin';
  final password = 'FB000033';

  // Common ONVIF ports
  final ports = [80, 554, 8080, 8000, 8081, 8082, 8443, 443, 8888, 9000];
  final onvifPaths = [
    '/onvif/device_service',
    '/onvif/Device',
    '/device_service'
  ];

  print('=== ONVIF Port Scanner ===\n');
  print('Target: $host');
  print('Testing ports: ${ports.join(', ')}\n');

  final dio = Dio(BaseOptions(
    validateStatus: (status) => true,
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
  ));

  final basicAuth = base64Encode(utf8.encode('$username:$password'));

  for (final port in ports) {
    print('🔍 Testing port $port...');

    // Test basic HTTP connection first
    try {
      final response = await dio.get('http://$host:$port/');
      print('  ✅ Port $port is open (${response.statusCode})');

      // Test ONVIF endpoints on this port
      for (final path in onvifPaths) {
        await _testOnvifEndpoint(dio, host, port, path, basicAuth);
      }
    } catch (e) {
      print('  ❌ Port $port: ${e.toString().split('\n').first}');
    }

    print('');
  }

  dio.close();
}

Future<void> _testOnvifEndpoint(
    Dio dio, String host, int port, String path, String basicAuth) async {
  final url = 'http://$host:$port$path';

  // Test HTTP GET first
  try {
    final getResponse = await dio.get(
      url,
      options: Options(headers: {'Authorization': 'Basic $basicAuth'}),
    );

    if (getResponse.statusCode == 200) {
      final data = getResponse.data.toString();
      if (data.contains('soap') ||
          data.contains('onvif') ||
          data.contains('wsdl')) {
        print('    🎯 $path: Potential ONVIF endpoint found!');

        // Try SOAP request
        await _testSoapRequest(dio, url, basicAuth);
        return;
      }
    }
  } catch (e) {
    // Ignore GET errors, try SOAP directly
  }

  // Try SOAP request directly
  await _testSoapRequest(dio, url, basicAuth);
}

Future<void> _testSoapRequest(Dio dio, String url, String basicAuth) async {
  final soapRequest = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <soap:Header/>
  <soap:Body>
    <tds:GetDeviceInformation/>
  </soap:Body>
</soap:Envelope>''';

  try {
    final response = await dio.post(
      url,
      data: soapRequest,
      options: Options(
        headers: {
          'Content-Type': 'application/soap+xml; charset=utf-8',
          'SOAPAction':
              'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
          'Authorization': 'Basic $basicAuth',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data.toString();

      if (data.contains('<soap:') ||
          data.contains('<Envelope') ||
          data.contains('GetDeviceInformationResponse')) {
        print('    🏆 WORKING ONVIF ENDPOINT FOUND: $url');
        print('    Response: ${data.substring(0, 300)}...');
      } else {
        print('    ⚠️  $url: Response not SOAP format');
      }
    } else {
      print('    ❌ $url: SOAP request failed (${response.statusCode})');
    }
  } catch (e) {
    // Most endpoints will fail, don't spam output
    if (e.toString().contains('401')) {
      print('    🔐 $url: Authentication required');
    }
  }
}
