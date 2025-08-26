import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug SOAP Fault chi tiết để hiểu lỗi FindRecordings
void main() async {
  print('=== Debug SOAP Fault Details ===\n');

  final transport = OnvifTransport(
    baseUrl: 'http://fb000033.ddns.net:8080',
    timeout: Duration(seconds: 30),
  );

  try {
    // Test FindRecordings và in chi tiết SOAP Fault
    final findRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<tse:FindRecordings xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
        <tse:StartPoint>${DateTime.now().subtract(Duration(days: 7)).toIso8601String()}</tse:StartPoint>
        <tse:EndPoint>${DateTime.now().toIso8601String()}</tse:EndPoint>
        <tse:MaxMatches>10</tse:MaxMatches>
      </tse:FindRecordings>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/search/wsdl/FindRecordings',
      headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/search_service',
      soapBody: findRequest,
      soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindRecordings',
    );

    print('📄 Raw SOAP Response:');
    print(response);
    print('\n' + '=' * 80 + '\n');

    // Parse để xem chi tiết fault
    try {
      final parsed = OnvifResponseParser.parseXmlResponse(response);
      print('📊 Parsed Structure:');
      _printMapStructure(parsed, '');
    } catch (e) {
      print('❌ Parsing failed: $e');
      print('Will parse manually...');

      // Manual parsing để tìm fault
      if (response.contains('Fault')) {
        final faultStart = response.indexOf('<');
        final faultEnd = response.lastIndexOf('>') + 1;
        final faultSection = response.substring(faultStart, faultEnd);
        print('📋 SOAP Fault Section:');
        print(faultSection);
      }
    }
  } catch (e) {
    print('❌ Request failed: $e');
    if (e is OnvifSoapException) {
      print('SOAP Fault Details: ${e.faultString}');
    }
  }

  transport.dispose();
}

void _printMapStructure(dynamic data, String indent) {
  if (data is Map<String, dynamic>) {
    for (final entry in data.entries) {
      print('$indent${entry.key}: ${_getValueType(entry.value)}');
      if (entry.value is Map || entry.value is List) {
        _printMapStructure(entry.value, indent + '  ');
      } else if (entry.value is String) {
        print('$indent  -> "${entry.value}"');
      }
    }
  } else if (data is List) {
    for (int i = 0; i < data.length; i++) {
      print('$indent[$i]: ${_getValueType(data[i])}');
      if (data[i] is Map || data[i] is List) {
        _printMapStructure(data[i], indent + '  ');
      } else if (data[i] is String) {
        print('$indent  -> "${data[i]}"');
      }
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
