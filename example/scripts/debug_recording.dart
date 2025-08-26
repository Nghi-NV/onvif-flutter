import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug Recording và Playback capabilities
void main() async {
  print('=== Debug Recording & Playback ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    await client.connect();
    print('✅ Connected successfully!\n');

    // 1. Kiểm tra chi tiết capabilities
    print('🔍 Checking detailed capabilities...');

    final transport = OnvifTransport(
      baseUrl: 'http://fb000033.ddns.net:8080',
      timeout: Duration(seconds: 30),
    );

    // Raw GetCapabilities với category All để lấy đầy đủ thông tin
    final capabilitiesRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<tds:GetCapabilities xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
        <tds:Category>All</tds:Category>
      </tds:GetCapabilities>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/device/wsdl/GetCapabilities',
      headers: {'tds': 'http://www.onvif.org/ver10/device/wsdl'},
    );

    final capResponse = await transport.sendSoapRequest(
      path: '/onvif/device_service',
      soapBody: capabilitiesRequest,
      soapAction: 'http://www.onvif.org/ver10/device/wsdl/GetCapabilities',
    );

    // Parse capabilities để tìm recording services
    final parsed = OnvifResponseParser.parseXmlResponse(capResponse);
    print('📄 Capabilities structure:');
    _printMapStructure(parsed, '');

    // Tìm recording và replay services
    final recordingService = _findInResponse(parsed, 'Recording');
    final replayService = _findInResponse(parsed, 'Replay');
    final searchService = _findInResponse(parsed, 'Search');

    print('\n🎬 Recording Services:');
    if (recordingService != null) {
      print('✅ Recording Service found:');
      _printMapStructure(recordingService, '  ');
    } else {
      print('❌ Recording Service not found');
    }

    print('\n🔍 Search Services:');
    if (searchService != null) {
      print('✅ Search Service found:');
      _printMapStructure(searchService, '  ');
    } else {
      print('❌ Search Service not found');
    }

    print('\n▶️ Replay Services:');
    if (replayService != null) {
      print('✅ Replay Service found:');
      _printMapStructure(replayService, '  ');
    } else {
      print('❌ Replay Service not found');
    }

    // 2. Test Recording service endpoints
    if (recordingService != null) {
      final recordingXAddr = _findInResponse(recordingService, 'XAddr');
      if (recordingXAddr != null) {
        print('\n🎬 Testing Recording Service at: $recordingXAddr');

        try {
          // Test GetRecordings
          final getRecordingsRequest =
              OnvifRequestBuilder.createSecureSoapEnvelope(
            body:
                '<trc:GetRecordings xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
            username: 'admin',
            password: 'FB000033',
            action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
            headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
          );

          final recordingsResponse = await transport.sendSoapRequest(
            path: '/onvif/recording_service',
            soapBody: getRecordingsRequest,
            soapAction:
                'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
          );

          print('✅ GetRecordings successful');
          print('Response: ${recordingsResponse.substring(0, 300)}...');

          final recordingsParsed =
              OnvifResponseParser.parseXmlResponse(recordingsResponse);
          final recordings = _findInResponse(recordingsParsed, 'Recordings');
          if (recordings != null) {
            print('Found recordings:');
            _printMapStructure(recordings, '  ');
          }
        } catch (e) {
          print('❌ GetRecordings failed: $e');
        }
      }
    }

    // 3. Test Search service endpoints
    if (searchService != null) {
      final searchXAddr = _findInResponse(searchService, 'XAddr');
      if (searchXAddr != null) {
        print('\n🔍 Testing Search Service at: $searchXAddr');

        try {
          // Test GetSearchState first
          final getSearchStateRequest =
              OnvifRequestBuilder.createSecureSoapEnvelope(
            body:
                '<tse:GetSearchState xmlns:tse="http://www.onvif.org/ver10/search/wsdl"/>',
            username: 'admin',
            password: 'FB000033',
            action: 'http://www.onvif.org/ver10/search/wsdl/GetSearchState',
            headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
          );

          final searchStateResponse = await transport.sendSoapRequest(
            path: '/onvif/search_service',
            soapBody: getSearchStateRequest,
            soapAction: 'http://www.onvif.org/ver10/search/wsdl/GetSearchState',
          );

          print('✅ GetSearchState successful');
          print('Response: ${searchStateResponse.substring(0, 300)}...');
        } catch (e) {
          print('❌ GetSearchState failed: $e');
        }

        try {
          // Test FindRecordings với time range
          final now = DateTime.now();
          final yesterday = now.subtract(Duration(days: 1));

          final findRecordingsRequest =
              OnvifRequestBuilder.createSecureSoapEnvelope(
            body:
                '''<tse:FindRecordings xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
              <tse:StartPoint>${yesterday.toIso8601String()}</tse:StartPoint>
              <tse:EndPoint>${now.toIso8601String()}</tse:EndPoint>
              <tse:MaxMatches>10</tse:MaxMatches>
            </tse:FindRecordings>''',
            username: 'admin',
            password: 'FB000033',
            action: 'http://www.onvif.org/ver10/search/wsdl/FindRecordings',
            headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
          );

          final findResponse = await transport.sendSoapRequest(
            path: '/onvif/search_service',
            soapBody: findRecordingsRequest,
            soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindRecordings',
          );

          print('✅ FindRecordings successful');
          print('Response: ${findResponse.substring(0, 300)}...');
        } catch (e) {
          print('❌ FindRecordings failed: $e');
        }
      }
    }

    // 4. Test Replay service
    if (replayService != null) {
      final replayXAddr = _findInResponse(replayService, 'XAddr');
      if (replayXAddr != null) {
        print('\n▶️ Testing Replay Service at: $replayXAddr');

        try {
          // Test GetReplayConfiguration
          final getReplayConfigRequest =
              OnvifRequestBuilder.createSecureSoapEnvelope(
            body:
                '<trp:GetReplayConfiguration xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
            username: 'admin',
            password: 'FB000033',
            action:
                'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
            headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
          );

          final replayConfigResponse = await transport.sendSoapRequest(
            path: '/onvif/replay_service',
            soapBody: getReplayConfigRequest,
            soapAction:
                'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
          );

          print('✅ GetReplayConfiguration successful');
          print('Response: ${replayConfigResponse.substring(0, 300)}...');
        } catch (e) {
          print('❌ GetReplayConfiguration failed: $e');
        }
      }
    }

    transport.dispose();
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

void _printMapStructure(dynamic data, String indent) {
  if (data is Map<String, dynamic>) {
    for (final entry in data.entries) {
      print('$indent${entry.key}: ${_getValueType(entry.value)}');
      if (entry.value is Map || entry.value is List) {
        if (entry.value is Map && (entry.value as Map).length > 5) {
          print('$indent  ... (${(entry.value as Map).length} keys)');
        } else if (entry.value is List && (entry.value as List).length > 3) {
          print('$indent  ... (${(entry.value as List).length} items)');
        } else {
          _printMapStructure(entry.value, indent + '  ');
        }
      } else if (entry.value is String && entry.value.toString().length < 100) {
        print('$indent  -> "${entry.value}"');
      }
    }
  } else if (data is List) {
    for (int i = 0; i < data.length && i < 2; i++) {
      print('$indent[$i]: ${_getValueType(data[i])}');
      if (data[i] is Map || data[i] is List) {
        _printMapStructure(data[i], indent + '  ');
      }
    }
    if (data.length > 2) {
      print('$indent... and ${data.length - 2} more items');
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

dynamic _findInResponse(Map<String, dynamic> data, String key) {
  if (data.containsKey(key)) {
    return data[key];
  }

  for (final value in data.values) {
    if (value is Map<String, dynamic>) {
      final found = _findInResponse(value, key);
      if (found != null) return found;
    } else if (value is List) {
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          final found = _findInResponse(item, key);
          if (found != null) return found;
        }
      }
    }
  }

  return null;
}
