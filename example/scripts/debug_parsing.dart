import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug chi tiết parsing của response
void main() async {
  print('=== Debug ONVIF Parsing ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    // Test GetDeviceInformation với raw response
    print('🔍 Testing GetDeviceInformation parsing...');

    final deviceService = client.device;

    // Call SOAP service để lấy raw response
    final transport = OnvifTransport(
      baseUrl: 'http://fb000033.ddns.net:8080',
      timeout: Duration(seconds: 30),
    );

    final soapRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<tds:GetDeviceInformation xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
      headers: {'tds': 'http://www.onvif.org/ver10/device/wsdl'},
    );

    final rawResponse = await transport.sendSoapRequest(
      path: '/onvif/device_service',
      soapBody: soapRequest,
      soapAction: 'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation',
    );

    print('📄 Raw Response:');
    print(rawResponse);
    print('\n');

    // Parse thành Map
    print('🧩 Parsing to Map...');
    final parsed = OnvifResponseParser.parseXmlResponse(rawResponse);
    print('Parsed keys: ${parsed.keys.join(', ')}');

    // Print structure đệ quy
    _printMapStructure(parsed, '');

    print('\n🎯 Parsing GetDeviceInformation...');
    final deviceData =
        OnvifResponseParser.parseGetDeviceInformationResponse(rawResponse);
    print('Device data keys: ${deviceData.keys.join(', ')}');
    _printMapStructure(deviceData, '');

    // Test với OnvifDeviceInformation
    if (deviceData.isNotEmpty) {
      print('\n📱 Creating OnvifDeviceInformation...');
      try {
        final deviceInfo = OnvifDeviceInformation.fromXml(deviceData);
        print('✅ Device Info created successfully:');
        print('   Manufacturer: ${deviceInfo.manufacturer}');
        print('   Model: ${deviceInfo.model}');
        print('   Firmware: ${deviceInfo.firmwareVersion}');
        print('   Serial: ${deviceInfo.serialNumber}');
      } catch (e) {
        print('❌ Failed to create DeviceInformation: $e');
      }
    }

    // Test GetCapabilities
    print('\n🔧 Testing GetCapabilities...');

    final capabilitiesRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<tds:GetCapabilities xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/device/wsdl/GetCapabilities',
      headers: {'tds': 'http://www.onvif.org/ver10/device/wsdl'},
    );

    final capRawResponse = await transport.sendSoapRequest(
      path: '/onvif/device_service',
      soapBody: capabilitiesRequest,
      soapAction: 'http://www.onvif.org/ver10/device/wsdl/GetCapabilities',
    );

    print('📄 Capabilities Raw Response:');
    print(capRawResponse.substring(0, 500) + '...');

    final capParsed =
        OnvifResponseParser.parseGetCapabilitiesResponse(capRawResponse);
    print('\nCapabilities data keys: ${capParsed.keys.join(', ')}');
    _printMapStructure(capParsed, '  ');

    transport.dispose();
  } catch (e) {
    print('❌ Error: $e');
    print('Error type: ${e.runtimeType}');
  } finally {
    client.dispose();
  }
}

void _printMapStructure(dynamic data, String indent) {
  if (data is Map<String, dynamic>) {
    for (final entry in data.entries) {
      print('$indent${entry.key}: ${_getValueType(entry.value)}');
      if (entry.value is Map || entry.value is List) {
        _printMapStructure(entry.value, indent + '  ');
      } else if (entry.value is String && entry.value.toString().length < 100) {
        print('$indent  -> "${entry.value}"');
      }
    }
  } else if (data is List) {
    for (int i = 0; i < data.length && i < 3; i++) {
      print('$indent[$i]: ${_getValueType(data[i])}');
      if (data[i] is Map || data[i] is List) {
        _printMapStructure(data[i], indent + '  ');
      }
    }
    if (data.length > 3) {
      print('$indent... and ${data.length - 3} more items');
    }
  }
}

String _getValueType(dynamic value) {
  if (value is String) return 'String(${value.length})';
  if (value is Map) return 'Map(${value.length})';
  if (value is List) return 'List(${value.length})';
  if (value == null) return 'null';
  return value.runtimeType.toString();
}
