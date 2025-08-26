import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug GetRecordings để hiểu cấu trúc recording data
void main() async {
  print('=== Debug GetRecordings Data ===\n');

  final transport = OnvifTransport(
    baseUrl: 'http://fb000033.ddns.net:8080',
    timeout: Duration(seconds: 30),
  );

  try {
    final getRecordingsRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trc:GetRecordings xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: getRecordingsRequest,
      soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
    );

    print('📄 Raw Response:');
    print(response);
    print('\n' + '=' * 80 + '\n');

    final parsed = OnvifResponseParser.parseXmlResponse(response);
    print('📊 Parsed Structure:');
    _printMapStructure(parsed, '', maxDepth: 10);

    print('\n' + '=' * 80 + '\n');

    // Extract recordings specifically
    final recordingItems = _findInResponse(parsed, 'RecordingItem');
    if (recordingItems != null) {
      print('🎬 Found Recording Items:');
      if (recordingItems is List) {
        print('Number of recordings: ${recordingItems.length}');
        for (int i = 0; i < recordingItems.length; i++) {
          print('\n--- Recording $i ---');
          _printMapStructure(recordingItems[i], '  ', maxDepth: 8);
        }
      } else {
        print('Single recording:');
        _printMapStructure(recordingItems, '  ', maxDepth: 8);
      }
    } else {
      print('❌ No RecordingItem found');
    }

    // Test với OnvifRecording model
    print('\n' + '=' * 80 + '\n');
    print('🔧 Testing OnvifRecording Model...');

    try {
      if (recordingItems is List) {
        for (int i = 0; i < recordingItems.length; i++) {
          if (recordingItems[i] is Map<String, dynamic>) {
            final recording = OnvifRecording.fromXml(recordingItems[i]);
            print('Recording $i: $recording');
            print('  Token: ${recording.token}');
            print('  Configuration: ${recording.configuration}');
            print('  Tracks: ${recording.tracks.length}');
            for (final track in recording.tracks) {
              print('    Track: ${track.token} (${track.trackType})');
              if (track.dataFrom != null)
                print('      From: ${track.dataFrom}');
              if (track.dataTo != null) print('      To: ${track.dataTo}');
            }
          }
        }
      }
    } catch (e) {
      print('❌ OnvifRecording parsing failed: $e');
    }

    // ==================== TEST GETTRACKS FOR EACH RECORDING ====================
    print('\n' + '=' * 80 + '\n');
    print('🎯 Testing GetTracks for each recording...');

    if (recordingItems is List) {
      for (int i = 0; i < recordingItems.length; i++) {
        if (recordingItems[i] is Map<String, dynamic>) {
          final recordingToken =
              recordingItems[i]['RecordingToken']?.toString() ??
                  recordingItems[i]['@token']?.toString() ??
                  recordingItems[i]['token']?.toString();

          if (recordingToken != null && recordingToken.isNotEmpty) {
            print(
                '\n--- GetTracks for Recording $i (Token: $recordingToken) ---');
            await _testGetTracks(transport, recordingToken);
          }
        }
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  transport.dispose();
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

/// Test GetTracks request cho recording token cụ thể
Future<void> _testGetTracks(
    OnvifTransport transport, String recordingToken) async {
  try {
    print('📡 Sending GetTracks request...');

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

    final response = await transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: getTracksRequest,
      soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetTracks',
    );

    print('📄 GetTracks Raw Response:');
    print(response);
    print('\n' + '-' * 60 + '\n');

    final parsed = OnvifResponseParser.parseXmlResponse(response);
    print('📊 GetTracks Parsed Structure:');
    _printMapStructure(parsed, '', maxDepth: 8);

    // Extract tracks specifically
    final tracksData = _findInResponse(parsed, 'Track');
    if (tracksData != null) {
      print('\n🎬 Found Tracks:');
      if (tracksData is List) {
        print('Number of tracks: ${tracksData.length}');
        for (int i = 0; i < tracksData.length; i++) {
          print('\n--- Track $i ---');
          _printMapStructure(tracksData[i], '  ', maxDepth: 6);

          // Extract track information
          final trackToken = tracksData[i]['TrackToken']?.toString() ??
              tracksData[i]['@token']?.toString() ??
              tracksData[i]['token']?.toString();
          final trackType =
              tracksData[i]['Configuration']?['TrackType']?.toString() ??
                  tracksData[i]['TrackType']?.toString() ??
                  'Unknown';
          final description =
              tracksData[i]['Configuration']?['Description']?.toString() ??
                  tracksData[i]['Description']?.toString() ??
                  'No description';

          print('  📋 Track Info:');
          print('    Token: $trackToken');
          print('    Type: $trackType');
          print('    Description: $description');
        }
      } else {
        print('Single track:');
        _printMapStructure(tracksData, '  ', maxDepth: 6);
      }
    } else {
      print('❌ No Track data found in GetTracks response');
    }
  } catch (e) {
    print('❌ GetTracks failed: $e');
  }
}
