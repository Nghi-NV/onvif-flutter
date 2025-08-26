import 'package:dio/dio.dart';
import 'package:onvif_flutter/onvif_flutter.dart';

/// Raw debug để kiểm tra response từ server
void main() async {
  final host = 'fb000033.ddns.net';
  final port = 8082;
  final username = 'admin';
  final password = 'FB000033';

  print('=== Raw ONVIF Debug ===\n');

  // Test 1: Kiểm tra HTTP connection cơ bản
  print('1. Testing basic HTTP connection...');
  final dio = Dio();

  try {
    final response = await dio.get('http://$host:$port');
    print('✅ HTTP connection OK');
    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Response: ${response.data.toString().substring(0, 200)}...\n');
  } catch (e) {
    print('❌ HTTP connection failed: $e\n');
  }

  // Test 2: Thử các ONVIF endpoints phổ biến
  final endpoints = [
    '/onvif/device_service',
    '/onvif/Device',
    '/device_service',
    '/Device',
    '/',
  ];

  for (final endpoint in endpoints) {
    print('2. Testing endpoint: $endpoint');
    try {
      final response = await dio.get('http://$host:$port$endpoint');
      print('✅ Endpoint $endpoint responded');
      print('Status: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      if (response.data is String && response.data.toString().length < 500) {
        print('Response: ${response.data}');
      }
    } catch (e) {
      print('❌ Endpoint $endpoint failed: $e');
    }
    print('');
  }

  // Test 3: Thử SOAP request trực tiếp
  print('3. Testing SOAP request...');

  final soapBody = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <soap:Header/>
  <soap:Body>
    <tds:GetDeviceInformation/>
  </soap:Body>
</soap:Envelope>''';

  for (final endpoint in endpoints) {
    try {
      final response = await dio.post(
        'http://$host:$port$endpoint',
        data: soapBody,
        options: Options(
          headers: {
            'Content-Type': 'application/soap+xml; charset=utf-8',
            'SOAPAction':
                'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
          },
        ),
      );

      print('✅ SOAP request to $endpoint successful');
      print('Status: ${response.statusCode}');
      print('Response length: ${response.data.toString().length}');
      print(
          'Response preview: ${response.data.toString().substring(0, 300)}...');
      break;
    } catch (e) {
      print('❌ SOAP request to $endpoint failed: $e');
    }
  }

  // Test 4: Thử với authentication
  print('\n4. Testing with authentication...');

  // HTTP Basic Auth
  try {
    final response = await dio.get(
      'http://$host:$port/onvif/device_service',
      options: Options(
        headers: {
          'Authorization': 'Basic ${_encodeBasicAuth(username, password)}',
        },
      ),
    );
    print('✅ Basic Auth successful');
    print('Response: ${response.data.toString().substring(0, 200)}...');
  } catch (e) {
    print('❌ Basic Auth failed: $e');
  }

  // Test 5: Thử tạo ONVIF client với debug
  print('\n5. Testing ONVIF client with detailed error...');

  final client = OnvifClient(
    host: host,
    port: port,
    username: username,
    password: password,
  );

  try {
    // Tạo request thủ công để debug
    final transport = client.device;

    print('Attempting GetDeviceInformation...');
    final deviceInfo = await transport.getDeviceInformation();
    print('✅ ONVIF client successful!');
    print('Device: ${deviceInfo.manufacturer} ${deviceInfo.model}');
  } catch (e) {
    print('❌ ONVIF client failed: $e');
    print('Error type: ${e.runtimeType}');

    if (e is OnvifException) {
      print('Details: ${e.message}');
      print('Code: ${e.code}');
      print('Original: ${e.originalError}');
    }
  } finally {
    client.dispose();
  }

  dio.close();
}

String _encodeBasicAuth(String username, String password) {
  final credentials = '$username:$password';
  final bytes = credentials.codeUnits;
  final base64 = '';
  // Simple base64 encoding implementation
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  String result = '';
  for (int i = 0; i < bytes.length; i += 3) {
    int b1 = bytes[i];
    int b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    int b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

    int bitmap = (b1 << 16) | (b2 << 8) | b3;

    result += chars[(bitmap >> 18) & 63];
    result += chars[(bitmap >> 12) & 63];
    result += i + 1 < bytes.length ? chars[(bitmap >> 6) & 63] : '=';
    result += i + 2 < bytes.length ? chars[bitmap & 63] : '=';
  }
  return result;
}
