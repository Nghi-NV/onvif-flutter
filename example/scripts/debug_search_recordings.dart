import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug Search Recordings - tìm hiểu tại sao không tìm thấy recordings
void main() async {
  print('=== Debug Search Recordings ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    await client.connect();
    print('✅ Connected successfully!\n');

    final transport = OnvifTransport(
      baseUrl: 'http://fb000033.ddns.net:8080',
      timeout: Duration(seconds: 30),
    );

    // ==================== 1. TEST RECORDING SERVICE ====================
    print('🎬 Testing Recording Service...');

    try {
      final getRecordingsRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
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
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
      );

      print('✅ GetRecordings response:');
      print('Length: ${recordingsResponse.length}');
      print(
          'First 500 chars: ${recordingsResponse.substring(0, recordingsResponse.length > 500 ? 500 : recordingsResponse.length)}');

      final recordingsParsed =
          OnvifResponseParser.parseXmlResponse(recordingsResponse);
      print('\n📄 Parsed structure:');
      _printMapStructure(recordingsParsed, '');
    } catch (e) {
      print('❌ GetRecordings failed: $e');
    }

    // ==================== 2. TEST SEARCH SERVICE - RAW ====================
    print('\n\n🔍 Testing Search Service (Raw)...');

    // Test các time range khác nhau
    final timeRanges = [
      {
        'name': 'Last 24 hours',
        'start': DateTime.now().subtract(Duration(hours: 24)),
        'end': DateTime.now(),
      },
      {
        'name': 'Last 7 days',
        'start': DateTime.now().subtract(Duration(days: 7)),
        'end': DateTime.now(),
      },
      {
        'name': 'Last 30 days',
        'start': DateTime.now().subtract(Duration(days: 30)),
        'end': DateTime.now(),
      },
      {
        'name': 'All time (very broad)',
        'start': DateTime(2020, 1, 1),
        'end': DateTime.now(),
      },
    ];

    for (final range in timeRanges) {
      print('\n--- Testing ${range['name']} ---');
      print('From: ${range['start']}');
      print('To: ${range['end']}');

      try {
        // Method 1: FindRecordings
        print('Method 1: FindRecordings...');
        final findRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
          body:
              '''<tse:FindRecordings xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
            <tse:StartPoint>${(range['start'] as DateTime).toIso8601String()}</tse:StartPoint>
            <tse:EndPoint>${(range['end'] as DateTime).toIso8601String()}</tse:EndPoint>
            <tse:MaxMatches>100</tse:MaxMatches>
          </tse:FindRecordings>''',
          username: 'admin',
          password: 'FB000033',
          action: 'http://www.onvif.org/ver10/search/wsdl/FindRecordings',
          headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
        );

        final findResponse = await transport.sendSoapRequest(
          path: '/onvif/search_service',
          soapBody: findRequest,
          soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindRecordings',
        );

        print('✅ FindRecordings successful');
        print('Response length: ${findResponse.length}');
        print(
            'First 300 chars: ${findResponse.substring(0, findResponse.length > 300 ? 300 : findResponse.length)}');

        final findParsed = OnvifResponseParser.parseXmlResponse(findResponse);
        print('Parsed structure:');
        _printMapStructure(findParsed, '  ');

        final searchToken = _findInResponse(findParsed, 'SearchToken');
        print('Search Token: $searchToken');

        if (searchToken != null) {
          // Method 2: GetRecordingSearchResults
          print('\nMethod 2: GetRecordingSearchResults...');
          final getResultsRequest =
              OnvifRequestBuilder.createSecureSoapEnvelope(
            body:
                '''<tse:GetRecordingSearchResults xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
              <tse:SearchToken>$searchToken</tse:SearchToken>
              <tse:MinResults>1</tse:MinResults>
              <tse:MaxResults>100</tse:MaxResults>
              <tse:WaitTime>PT10S</tse:WaitTime>
            </tse:GetRecordingSearchResults>''',
            username: 'admin',
            password: 'FB000033',
            action:
                'http://www.onvif.org/ver10/search/wsdl/GetRecordingSearchResults',
            headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
          );

          final resultsResponse = await transport.sendSoapRequest(
            path: '/onvif/search_service',
            soapBody: getResultsRequest,
            soapAction:
                'http://www.onvif.org/ver10/search/wsdl/GetRecordingSearchResults',
          );

          print('✅ GetRecordingSearchResults successful');
          print('Response length: ${resultsResponse.length}');
          print(
              'Response: ${resultsResponse.substring(0, resultsResponse.length > 500 ? 500 : resultsResponse.length)}');

          final resultsParsed =
              OnvifResponseParser.parseXmlResponse(resultsResponse);
          print('Results structure:');
          _printMapStructure(resultsParsed, '  ');

          // End search
          try {
            final endSearchRequest =
                OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '''<tse:EndSearch xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
                <tse:SearchToken>$searchToken</tse:SearchToken>
              </tse:EndSearch>''',
              username: 'admin',
              password: 'FB000033',
              action: 'http://www.onvif.org/ver10/search/wsdl/EndSearch',
              headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
            );

            await transport.sendSoapRequest(
              path: '/onvif/search_service',
              soapBody: endSearchRequest,
              soapAction: 'http://www.onvif.org/ver10/search/wsdl/EndSearch',
            );
          } catch (e) {
            print('EndSearch error (ignored): $e');
          }
        }
      } catch (e) {
        print('❌ Search failed for ${range['name']}: $e');
      }

      print('\n' + '=' * 50);
    }

    // ==================== 3. TEST ALTERNATIVE METHODS ====================
    print('\n\n🔄 Testing Alternative Methods...');

    // Method A: FindEvents instead of FindRecordings
    try {
      print('Method A: FindEvents...');
      final findEventsRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
        body:
            '''<tse:FindEvents xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
          <tse:StartPoint>${DateTime.now().subtract(Duration(days: 30)).toIso8601String()}</tse:StartPoint>
          <tse:EndPoint>${DateTime.now().toIso8601String()}</tse:EndPoint>
          <tse:MaxMatches>100</tse:MaxMatches>
        </tse:FindEvents>''',
        username: 'admin',
        password: 'FB000033',
        action: 'http://www.onvif.org/ver10/search/wsdl/FindEvents',
        headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
      );

      final eventsResponse = await transport.sendSoapRequest(
        path: '/onvif/search_service',
        soapBody: findEventsRequest,
        soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindEvents',
      );

      print('✅ FindEvents successful');
      print(
          'Response: ${eventsResponse.substring(0, eventsResponse.length > 300 ? 300 : eventsResponse.length)}');
    } catch (e) {
      print('❌ FindEvents failed: $e');
    }

    // Method B: GetRecordingSummary
    try {
      print('\nMethod B: GetRecordingSummary...');
      final summaryRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
        body:
            '''<tse:GetRecordingSummary xmlns:tse="http://www.onvif.org/ver10/search/wsdl"/>''',
        username: 'admin',
        password: 'FB000033',
        action: 'http://www.onvif.org/ver10/search/wsdl/GetRecordingSummary',
        headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
      );

      final summaryResponse = await transport.sendSoapRequest(
        path: '/onvif/search_service',
        soapBody: summaryRequest,
        soapAction:
            'http://www.onvif.org/ver10/search/wsdl/GetRecordingSummary',
      );

      print('✅ GetRecordingSummary successful');
      print(
          'Response: ${summaryResponse.substring(0, summaryResponse.length > 300 ? 300 : summaryResponse.length)}');
    } catch (e) {
      print('❌ GetRecordingSummary failed: $e');
    }

    // ==================== 4. TEST CLIENT METHOD ====================
    print('\n\n🔧 Testing Client Method...');

    try {
      final results = await client.searchRecordings(
        startTime: DateTime.now().subtract(Duration(days: 30)),
        endTime: DateTime.now(),
        maxResults: 100,
      );

      print('✅ Client searchRecordings result: ${results.length} recordings');
      for (int i = 0; i < results.length && i < 3; i++) {
        print('Recording $i: ${results[i]}');
      }
    } catch (e) {
      print('❌ Client searchRecordings failed: $e');
    }

    transport.dispose();
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

void _printMapStructure(dynamic data, String indent,
    {int maxDepth = 3, int currentDepth = 0}) {
  if (currentDepth >= maxDepth) {
    print('$indent... (max depth reached)');
    return;
  }

  if (data is Map<String, dynamic>) {
    for (final entry in data.entries) {
      print('$indent${entry.key}: ${_getValueType(entry.value)}');
      if (entry.value is Map || entry.value is List) {
        if (entry.value is Map && (entry.value as Map).length > 10) {
          print('$indent  ... (${(entry.value as Map).length} keys)');
        } else if (entry.value is List && (entry.value as List).length > 5) {
          print('$indent  ... (${(entry.value as List).length} items)');
        } else {
          _printMapStructure(entry.value, indent + '  ',
              maxDepth: maxDepth, currentDepth: currentDepth + 1);
        }
      } else if (entry.value is String && entry.value.toString().length < 200) {
        print('$indent  -> "${entry.value}"');
      }
    }
  } else if (data is List) {
    for (int i = 0; i < data.length && i < 3; i++) {
      print('$indent[$i]: ${_getValueType(data[i])}');
      if (data[i] is Map || data[i] is List) {
        _printMapStructure(data[i], indent + '  ',
            maxDepth: maxDepth, currentDepth: currentDepth + 1);
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
