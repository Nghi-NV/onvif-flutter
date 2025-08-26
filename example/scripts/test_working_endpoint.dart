import 'package:onvif_flutter/onvif_flutter.dart';

/// Test với endpoint đã biết hoạt động
void main() async {
  print('=== Testing Working ONVIF Endpoint ===\n');

  // Test direct với transport
  final transport = OnvifTransport(
    baseUrl: 'http://fb000033.ddns.net:8080',
    timeout: Duration(seconds: 30),
  );

  // Test SOAP request trực tiếp
  print('📡 Testing direct SOAP request...');

  try {
    final soapBody = '''<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <soap:Header/>
  <soap:Body>
    <tds:GetDeviceInformation/>
  </soap:Body>
</soap:Envelope>''';

    final response = await transport.sendSoapRequest(
      path: '/onvif/device_service',
      soapBody: soapBody,
      soapAction: 'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
    );

    print('✅ SOAP request successful!');
    print('Response length: ${response.length}');
    print('Response preview: ${response.substring(0, 500)}...\n');

    // Parse response để xem cấu trúc
    print('🔍 Parsing response...');
    try {
      final parsed = OnvifResponseParser.parseXmlResponse(response);
      print('✅ Parsing successful!');
      print('Parsed keys: ${parsed.keys.join(', ')}');

      // Tìm device information
      final deviceInfo =
          OnvifResponseParser.parseGetDeviceInformationResponse(response);
      print('Device info keys: ${deviceInfo.keys.join(', ')}');

      if (deviceInfo.isNotEmpty) {
        print('📱 Device Information:');
        print('   Manufacturer: ${deviceInfo['Manufacturer']}');
        print('   Model: ${deviceInfo['Model']}');
        print('   FirmwareVersion: ${deviceInfo['FirmwareVersion']}');
        print('   SerialNumber: ${deviceInfo['SerialNumber']}');
      }
    } catch (e) {
      print('❌ Parsing failed: $e');
      print('Error type: ${e.runtimeType}');
    }
  } catch (e) {
    print('❌ SOAP request failed: $e');
    print('Error type: ${e.runtimeType}');

    if (e is OnvifException) {
      print('Details: ${e.message}');
      print('Code: ${e.code}');
      print('Original: ${e.originalError}');
    }
  }

  // Test với credentials
  print('\n🔐 Testing with authentication...');

  final secureTransport = OnvifTransport(
    baseUrl: 'http://fb000033.ddns.net:8080',
    timeout: Duration(seconds: 30),
    headers: {
      'Authorization': 'Basic ${_encodeBasicAuth('admin', 'FB000033')}',
    },
  );

  try {
    final soapBodyWithAuth = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<tds:GetDeviceInformation xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
      headers: {'tds': 'http://www.onvif.org/ver10/device/wsdl'},
    );

    final response = await secureTransport.sendSoapRequest(
      path: '/onvif/device_service',
      soapBody: soapBodyWithAuth,
      soapAction: 'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
    );

    print('✅ Authenticated SOAP request successful!');
    print('Response preview: ${response.substring(0, 500)}...');

    // Parse với credentials
    final parsed =
        OnvifResponseParser.parseGetDeviceInformationResponse(response);
    if (parsed.isNotEmpty) {
      final deviceInfo = OnvifDeviceInformation.fromXml(parsed);
      print('\n📱 Device Information (Authenticated):');
      print('   Manufacturer: ${deviceInfo.manufacturer}');
      print('   Model: ${deviceInfo.model}');
      print('   Firmware: ${deviceInfo.firmwareVersion}');
      print('   Serial: ${deviceInfo.serialNumber}');
    }
  } catch (e) {
    print('❌ Authenticated request failed: $e');
  }

  // Test OnvifClient với debug
  print('\n🔧 Testing OnvifClient...');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    final connected = await client.connect();
    print('Client connect result: $connected');

    if (connected) {
      final deviceInfo = await client.getDeviceInformation();
      print(
          '✅ Client working! Device: ${deviceInfo.manufacturer} ${deviceInfo.model}');
    }
  } catch (e) {
    print('❌ Client failed: $e');
  } finally {
    client.dispose();
  }

  transport.dispose();
  secureTransport.dispose();
}

String _encodeBasicAuth(String username, String password) {
  final credentials = '$username:$password';
  final bytes = credentials.codeUnits;
  String result = '';

  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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
