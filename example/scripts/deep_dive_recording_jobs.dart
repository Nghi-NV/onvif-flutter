import 'package:onvif_flutter/onvif_flutter.dart';

/// Deep dive into Recording Jobs để hiểu recording segmentation
void main() async {
  print('=== Deep Dive Recording Jobs ===\n');

  final transport = OnvifTransport(
    baseUrl: 'http://fb000033.ddns.net:8080',
    timeout: Duration(seconds: 30),
  );

  try {
    // ==================== 1. GET RECORDING JOBS DETAILED ====================
    print('🎬 Getting Recording Jobs Detailed...\n');

    final getJobsRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trc:GetRecordingJobs xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    final jobsResponse = await transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: getJobsRequest,
      soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
    );

    print('📄 Raw GetRecordingJobs Response:');
    print(jobsResponse);
    print('\n' + '=' * 80 + '\n');

    final jobsParsed = OnvifResponseParser.parseXmlResponse(jobsResponse);
    print('📊 Parsed Structure:');
    _printMapStructure(jobsParsed, '', maxDepth: 8);

    // Extract JobTokens
    final jobItems = _findInResponse(jobsParsed, 'JobItem') ?? [];
    final jobTokens = <String>[];

    if (jobItems is List) {
      for (final item in jobItems) {
        if (item is Map<String, dynamic>) {
          final token = item['JobToken']?.toString();
          if (token != null) {
            jobTokens.add(token);
            print('\n🎯 Found Job Token: $token');
          }
        }
      }
    } else if (jobItems is Map<String, dynamic>) {
      final token = jobItems['JobToken']?.toString();
      if (token != null) {
        jobTokens.add(token);
        print('\n🎯 Found Job Token: $token');
      }
    }

    // ==================== 2. GET RECORDING JOB STATE FOR EACH JOB ====================
    for (final jobToken in jobTokens) {
      print('\n' + '-' * 60);
      print('🔍 Getting state for Job: $jobToken');

      try {
        final getStateRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
          body:
              '''<trc:GetRecordingJobState xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
            <trc:JobToken>$jobToken</trc:JobToken>
          </trc:GetRecordingJobState>''',
          username: 'admin',
          password: 'FB000033',
          action:
              'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
          headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
        );

        final stateResponse = await transport.sendSoapRequest(
          path: '/onvif/recording_service',
          soapBody: getStateRequest,
          soapAction:
              'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
        );

        print('📄 Job State Response:');
        print(stateResponse);

        final stateParsed = OnvifResponseParser.parseXmlResponse(stateResponse);
        print('\n📊 State Structure:');
        _printMapStructure(stateParsed, '  ', maxDepth: 6);
      } catch (e) {
        print('❌ Failed to get state for $jobToken: $e');
      }
    }

    // ==================== 3. GET REPLAY URI WITH RECENT TIME ====================
    print('\n' + '=' * 80);
    print('▶️ Testing GetReplayUri with recent time range...\n');

    // Test với time range very recent (last 10 minutes)
    final endTime = DateTime.now();
    final startTime = endTime.subtract(Duration(minutes: 10));

    print(
        'Time Range: ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');

    try {
      final getReplayRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
        body:
            '''<trp:GetReplayUri xmlns:trp="http://www.onvif.org/ver10/replay/wsdl">
          <trp:StreamSetup>
            <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
            <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
              <tt:Protocol>RTSP</tt:Protocol>
            </tt:Transport>
          </trp:StreamSetup>
          <trp:RecordingToken>RecordMediaProfile00000</trp:RecordingToken>
          <trp:Time>
            <tt:From xmlns:tt="http://www.onvif.org/ver10/schema">${startTime.toIso8601String()}</tt:From>
            <tt:Until xmlns:tt="http://www.onvif.org/ver10/schema">${endTime.toIso8601String()}</tt:Until>
          </trp:Time>
        </trp:GetReplayUri>''',
        username: 'admin',
        password: 'FB000033',
        action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
        headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
      );

      final replayResponse = await transport.sendSoapRequest(
        path: '/onvif/replay_service',
        soapBody: getReplayRequest,
        soapAction: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
      );

      print('📄 GetReplayUri Response:');
      print(replayResponse);

      final replayParsed = OnvifResponseParser.parseXmlResponse(replayResponse);
      final replayUri = _findInResponse(replayParsed, 'Uri');

      if (replayUri != null) {
        print('\n🎯 REPLAY URI FOUND: $replayUri');
        print('This is the RTSP URI for recorded video playback!');
      } else {
        print('\n❌ No replay URI found in response');
      }
    } catch (e) {
      print('❌ GetReplayUri failed: $e');
    }

    // ==================== 4. TEST DIFFERENT TIME RANGES ====================
    print('\n' + '=' * 80);
    print('⏰ Testing different time ranges...\n');

    final timeRanges = [
      {
        'name': 'Last 5 minutes',
        'start': DateTime.now().subtract(Duration(minutes: 5)),
        'end': DateTime.now(),
      },
      {
        'name': 'Last 30 minutes',
        'start': DateTime.now().subtract(Duration(minutes: 30)),
        'end': DateTime.now().subtract(Duration(minutes: 25)),
      },
      {
        'name': 'Last hour segment',
        'start': DateTime.now().subtract(Duration(hours: 1)),
        'end': DateTime.now().subtract(Duration(minutes: 58)),
      },
    ];

    for (final range in timeRanges) {
      print('\n--- ${range['name']} ---');

      try {
        final testReplayRequest = OnvifRequestBuilder.createSecureSoapEnvelope(
          body:
              '''<trp:GetReplayUri xmlns:trp="http://www.onvif.org/ver10/replay/wsdl">
            <trp:StreamSetup>
              <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
              <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
                <tt:Protocol>RTSP</tt:Protocol>
              </tt:Transport>
            </trp:StreamSetup>
            <trp:RecordingToken>RecordMediaProfile00000</trp:RecordingToken>
            <trp:Time>
              <tt:From xmlns:tt="http://www.onvif.org/ver10/schema">${(range['start'] as DateTime).toIso8601String()}</tt:From>
              <tt:Until xmlns:tt="http://www.onvif.org/ver10/schema">${(range['end'] as DateTime).toIso8601String()}</tt:Until>
            </trp:Time>
          </trp:GetReplayUri>''',
          username: 'admin',
          password: 'FB000033',
          action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
          headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
        );

        final testResponse = await transport.sendSoapRequest(
          path: '/onvif/replay_service',
          soapBody: testReplayRequest,
          soapAction: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
        );

        final testParsed = OnvifResponseParser.parseXmlResponse(testResponse);
        final testUri = _findInResponse(testParsed, 'Uri');

        if (testUri != null) {
          print('✅ SUCCESS: $testUri');
        } else {
          print('❌ No URI for this time range');
        }
      } catch (e) {
        print('❌ Failed: $e');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    transport.dispose();
  }
}

void _printMapStructure(dynamic data, String indent,
    {int maxDepth = 5, int currentDepth = 0}) {
  if (currentDepth >= maxDepth) {
    print('$indent... (max depth reached)');
    return;
  }

  if (data is Map<String, dynamic>) {
    for (final entry in data.entries) {
      print('$indent${entry.key}: ${_getValueType(entry.value)}');
      if (entry.value is Map || entry.value is List) {
        if (entry.value is Map && (entry.value as Map).length > 15) {
          print('$indent  ... (${(entry.value as Map).length} keys)');
        } else if (entry.value is List && (entry.value as List).length > 10) {
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
    for (int i = 0; i < data.length && i < 5; i++) {
      print('$indent[$i]: ${_getValueType(data[i])}');
      if (data[i] is Map || data[i] is List) {
        _printMapStructure(data[i], indent + '  ',
            maxDepth: maxDepth, currentDepth: currentDepth + 1);
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
