import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug GetTracks request theo ONVIF specification
void main() async {
  print('=== Debug GetTracks Request ===\n');

  final transport = OnvifTransport(
    baseUrl: 'http://fb000033.ddns.net:8080',
    timeout: Duration(seconds: 30),
  );

  try {
    // ==================== TEST 1: GETTRACKS WITH RECORDING TOKEN ====================
    print('🎯 Test 1: GetTracks with Recording Token...\n');

    final recordingToken = 'RecordMediaProfile00000';

    final getTracksRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<trc:GetTracks xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
        <trc:RecordingToken>$recordingToken</trc:RecordingToken>
      </trc:GetTracks>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetTracks',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    print('📡 SOAP Request:');
    print(getTracksRequest);
    print('\n' + '-' * 60 + '\n');

    try {
      final response = await transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: getTracksRequest,
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetTracks',
      );

      print('📄 GetTracks Response:');
      print(response);
      print('\n' + '=' * 80 + '\n');

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      print('📊 Parsed Structure:');
      _printMapStructure(parsed, '', maxDepth: 10);
    } catch (e) {
      print('❌ GetTracks failed: $e');
      print('Error type: ${e.runtimeType}');

      // Try to get more details about the error
      if (e.toString().contains('DioException')) {
        print('\n🔍 DioException details:');
        print('  Error: $e');
      }
    }

    // ==================== TEST 2: GETTRACKS WITHOUT RECORDING TOKEN ====================
    print('\n' + '=' * 80 + '\n');
    print(
        '🎯 Test 2: GetTracks without Recording Token (should fail gracefully)...\n');

    final getTracksNoTokenRequest =
        OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trc:GetTracks xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetTracks',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    try {
      final response2 = await transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: getTracksNoTokenRequest,
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetTracks',
      );

      print('📄 GetTracks (no token) Response:');
      print(response2);
    } catch (e) {
      print('❌ GetTracks (no token) failed: $e');
    }

    // ==================== TEST 3: GETTRACKCONFIGURATION ====================
    print('\n' + '=' * 80 + '\n');
    print('🎯 Test 3: GetTrackConfiguration...\n');

    final trackToken = 'VIDEO001';

    final getTrackConfigRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<trc:GetTrackConfiguration xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
        <trc:RecordingToken>$recordingToken</trc:RecordingToken>
        <trc:TrackToken>$trackToken</trc:TrackToken>
      </trc:GetTrackConfiguration>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetTrackConfiguration',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    try {
      final response3 = await transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: getTrackConfigRequest,
        soapAction:
            'http://www.onvif.org/ver10/recording/wsdl/GetTrackConfiguration',
      );

      print('📄 GetTrackConfiguration Response:');
      print(response3);
    } catch (e) {
      print('❌ GetTrackConfiguration failed: $e');
    }

    // ==================== TEST 4: GETRECORDINGCONFIGURATION ====================
    print('\n' + '=' * 80 + '\n');
    print('🎯 Test 4: GetRecordingConfiguration...\n');

    final getRecordingConfigRequest =
        OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<trc:GetRecordingConfiguration xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
        <trc:RecordingToken>$recordingToken</trc:RecordingToken>
      </trc:GetRecordingConfiguration>''',
      username: 'admin',
      password: 'FB000033',
      action:
          'http://www.onvif.org/ver10/recording/wsdl/GetRecordingConfiguration',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    try {
      final response4 = await transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: getRecordingConfigRequest,
        soapAction:
            'http://www.onvif.org/ver10/recording/wsdl/GetRecordingConfiguration',
      );

      print('📄 GetRecordingConfiguration Response:');
      print(response4);
    } catch (e) {
      print('❌ GetRecordingConfiguration failed: $e');
    }

    // ==================== SUMMARY ====================
    print('\n' + '=' * 80 + '\n');
    print('📊 GetTracks Testing Summary:');
    print('');
    print('🎯 Based on ONVIF Recording Control Service Specification:');
    print('   - GetTracks: Retrieves track information for a recording');
    print('   - GetTrackConfiguration: Gets configuration for specific track');
    print('   - GetRecordingConfiguration: Gets configuration for recording');
    print('');
    print('💡 Camera behavior:');
    print('   - GetRecordings: ✅ Working (returns 3 recordings)');
    print('   - GetTracks: ❌ Failing (DioException)');
    print('   - Track info already available in GetRecordings response');
    print('');
    print('🔍 Analysis:');
    print('   - Camera có thể không support GetTracks method');
    print('   - Hoặc GetTracks có different endpoint/parameters');
    print('   - Track information đã có sẵn trong GetRecordings response');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    transport.dispose();
  }
}

void _printMapStructure(dynamic data, String indent,
    {int maxDepth = 5, int currentDepth = 0}) {
  if (currentDepth >= maxDepth) {
    print('$indent... (max depth $maxDepth reached)');
    return;
  }

  if (data is Map<String, dynamic>) {
    for (final entry in data.entries) {
      print('$indent${entry.key}: ${_getValueType(entry.value)}');
      if (entry.value is Map || entry.value is List) {
        if (entry.value is Map && (entry.value as Map).length > 20) {
          print(
              '$indent  ... (${(entry.value as Map).length} keys, too many to display)');
        } else if (entry.value is List && (entry.value as List).length > 10) {
          print(
              '$indent  ... (${(entry.value as List).length} items, too many to display)');
        } else {
          _printMapStructure(entry.value, indent + '  ',
              maxDepth: maxDepth, currentDepth: currentDepth + 1);
        }
      } else if (entry.value is String && entry.value.toString().length < 100) {
        print('$indent  -> "${entry.value}"');
      } else if (entry.value is String) {
        final str = entry.value.toString();
        print('$indent  -> "${str.substring(0, 50)}..." (${str.length} chars)');
      }
    }
  } else if (data is List) {
    for (int i = 0; i < data.length && i < 5; i++) {
      print('$indent[$i]: ${_getValueType(data[i])}');
      if (data[i] is Map || data[i] is List) {
        _printMapStructure(data[i], indent + '  ',
            maxDepth: maxDepth, currentDepth: currentDepth + 1);
      } else if (data[i] is String && data[i].toString().length < 100) {
        print('$indent  -> "${data[i]}"');
      }
    }
    if (data.length > 5) {
      print('$indent... and ${data.length - 5} more items');
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
