import 'dart:convert';
import 'package:dio/dio.dart';

/// Script để discover ONVIF endpoints
void main() async {
  final host = 'fb000033.ddns.net';
  final port = 8082;
  final username = 'admin';
  final password = 'FB000033';

  print('=== ONVIF Endpoint Discovery ===\n');
  print('Target: http://$host:$port');
  print('Credentials: $username:$password\n');

  final dio = Dio(BaseOptions(
    validateStatus: (status) => true, // Accept all status codes
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));

  // Common ONVIF endpoints to test
  final endpoints = [
    // Standard ONVIF paths
    '/onvif/device_service',
    '/onvif/Device',
    '/onvif/Media',
    '/onvif/PTZ',
    '/onvif/Events',

    // Alternative paths
    '/device_service',
    '/Device',
    '/Media',
    '/PTZ',
    '/Events',

    // Vendor specific paths
    '/ISAPI/System/deviceInfo',
    '/cgi-bin/hi3510/param.cgi',
    '/axis-cgi/param.cgi',
    '/config/device_service',
    '/service/device_service',

    // Discovery paths
    '/probe',
    '/discovery',
    '/.well-known/onvif',

    // Common web interface paths
    '/web',
    '/webservice',
    '/api',
    '/soap',
  ];

  print('🔍 Testing endpoints...\n');

  final workingEndpoints = <String>[];
  final authEndpoints = <String>[];

  for (final endpoint in endpoints) {
    final url = 'http://$host:$port$endpoint';

    try {
      // Test without auth
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        print('✅ $endpoint - Status: ${response.statusCode}');
        print('   Content-Type: ${response.headers['content-type']}');

        final data = response.data.toString();
        if (data.contains('soap') ||
            data.contains('SOAP') ||
            data.contains('onvif') ||
            data.contains('ONVIF')) {
          print('   🎯 Contains SOAP/ONVIF keywords!');
          workingEndpoints.add(endpoint);
        }

        if (data.length < 200) {
          print('   Response: $data');
        } else {
          print('   Response preview: ${data.substring(0, 100)}...');
        }
      } else if (response.statusCode == 401) {
        print('🔐 $endpoint - Requires Authentication (401)');
        authEndpoints.add(endpoint);
      } else if (response.statusCode == 404) {
        print('❌ $endpoint - Not Found (404)');
      } else {
        print('⚠️  $endpoint - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ $endpoint - Error: ${e.toString().split('\n').first}');
    }

    print('');
  }

  // Test authenticated endpoints
  if (authEndpoints.isNotEmpty) {
    print('\n🔐 Testing endpoints with authentication...\n');

    final basicAuth = base64Encode(utf8.encode('$username:$password'));

    for (final endpoint in authEndpoints) {
      final url = 'http://$host:$port$endpoint';

      try {
        final response = await dio.get(
          url,
          options: Options(
            headers: {'Authorization': 'Basic $basicAuth'},
          ),
        );

        if (response.statusCode == 200) {
          print('✅ $endpoint - Authenticated Successfully');
          print('   Content-Type: ${response.headers['content-type']}');

          final data = response.data.toString();
          if (data.contains('soap') ||
              data.contains('SOAP') ||
              data.contains('onvif') ||
              data.contains('ONVIF')) {
            print('   🎯 Contains SOAP/ONVIF keywords!');
            workingEndpoints.add(endpoint);
          }

          if (data.length < 200) {
            print('   Response: $data');
          } else {
            print('   Response preview: ${data.substring(0, 100)}...');
          }
        } else {
          print('❌ $endpoint - Auth failed: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ $endpoint - Auth error: ${e.toString().split('\n').first}');
      }

      print('');
    }
  }

  // Test SOAP requests on working endpoints
  if (workingEndpoints.isNotEmpty) {
    print('\n🧪 Testing SOAP requests on potential ONVIF endpoints...\n');

    final soapRequest = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <soap:Header/>
  <soap:Body>
    <tds:GetDeviceInformation/>
  </soap:Body>
</soap:Envelope>''';

    final basicAuth = base64Encode(utf8.encode('$username:$password'));

    for (final endpoint in workingEndpoints.take(3)) {
      // Test top 3
      final url = 'http://$host:$port$endpoint';

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
          print('🎉 $endpoint - SOAP Request Success!');

          final data = response.data.toString();
          if (data.contains('<soap:') || data.contains('<Envelope')) {
            print('   ✅ Valid SOAP Response received!');
            print('   Response preview: ${data.substring(0, 300)}...');

            // This is likely the correct ONVIF endpoint
            print('\n🏆 FOUND WORKING ONVIF ENDPOINT: $endpoint');
            break;
          } else {
            print('   ⚠️  Not a SOAP response');
          }
        } else {
          print('❌ $endpoint - SOAP failed: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ $endpoint - SOAP error: ${e.toString().split('\n').first}');
      }

      print('');
    }
  }

  // Summary
  print('\n📊 Summary:');
  print('Working HTTP endpoints: ${workingEndpoints.length}');
  print('Auth required endpoints: ${authEndpoints.length}');

  if (workingEndpoints.isEmpty && authEndpoints.isEmpty) {
    print('\n💡 Suggestions:');
    print('1. This device might not support ONVIF');
    print('2. ONVIF might be on a different port (try 80, 8080, 8000, 554)');
    print('3. Check device documentation for ONVIF endpoint paths');
    print('4. Verify ONVIF is enabled in device settings');
  }

  dio.close();
}
