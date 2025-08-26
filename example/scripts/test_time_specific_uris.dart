import 'package:onvif_flutter/onvif_flutter.dart';

/// Test Time-Specific URIs để xem differentiation
void main() async {
  print('=== Test Time-Specific URIs ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    await client.connect();
    print('✅ Connected successfully!\n');

    // ==================== CREATE TIME-SPECIFIC URIS ====================
    print('🎬 Creating Time-Specific URIs...\n');

    // Create different time ranges
    final now = DateTime.now();
    final timeRanges = [
      {
        'name': 'Segment 1 (5 mins ago)',
        'start': now.subtract(Duration(minutes: 5)),
        'end': now.subtract(Duration(minutes: 3)),
      },
      {
        'name': 'Segment 2 (3 mins ago)',
        'start': now.subtract(Duration(minutes: 3)),
        'end': now.subtract(Duration(minutes: 1)),
      },
      {
        'name': 'Segment 3 (1 min ago)',
        'start': now.subtract(Duration(minutes: 1)),
        'end': now,
      },
    ];

    for (final range in timeRanges) {
      print('--- ${range['name']} ---');

      final startTime = range['start'] as DateTime;
      final endTime = range['end'] as DateTime;

      print('Time Range: ${_formatTime(startTime)} - ${_formatTime(endTime)}');

      try {
        final uri = await client.getReplayUriForTimeRange(
          recordingToken: 'RecordMediaProfile00000',
          startTime: startTime,
          endTime: endTime,
        );

        if (uri != null) {
          // Manually create time-specific URI
          final timeSpecificUri =
              _createTimeSpecificUri(uri, startTime, endTime);

          print('Base URI: $uri');
          print('Time-Specific URI: $timeSpecificUri');
          print('');
        } else {
          print('❌ No URI generated');
          print('');
        }
      } catch (e) {
        print('❌ Error: $e');
        print('');
      }
    }

    // ==================== TEST DIFFERENT FORMATS ====================
    print('🔧 Testing Different Time Parameter Formats...\n');

    final testStart = now.subtract(Duration(minutes: 10));
    final testEnd = now.subtract(Duration(minutes: 8));

    print(
        'Test Time Range: ${_formatTime(testStart)} - ${_formatTime(testEnd)}');
    print('');

    try {
      final baseUri = await client.getReplayUriForTimeRange(
        recordingToken: 'RecordMediaProfile00000',
        startTime: testStart,
        endTime: testEnd,
      );

      if (baseUri != null) {
        // Test different URI formats
        final formats = [
          _createTimeSpecificUri(baseUri, testStart, testEnd),
          _createDahuaTimeUri(baseUri, testStart, testEnd),
          _createRTSPTimeUri(baseUri, testStart, testEnd),
          _createQueryTimeUri(baseUri, testStart, testEnd),
        ];

        print('1. Full Format URI:');
        print('   ${formats[0]}');
        print('');

        print('2. Dahua Format URI:');
        print('   ${formats[1]}');
        print('');

        print('3. RTSP Range Format URI:');
        print('   ${formats[2]}');
        print('');

        print('4. Simple Query Format URI:');
        print('   ${formats[3]}');
        print('');
      }
    } catch (e) {
      print('❌ Error: $e');
    }

    // ==================== SUMMARY ====================
    print('=' * 60);
    print('📊 Time-Specific URI Summary:');
    print('');
    print('🎯 Different approaches để handle time ranges:');
    print('   1. URL query parameters (start/end)');
    print('   2. RTSP Range headers trong URL');
    print('   3. Epoch timestamps');
    print('   4. ISO datetime strings');
    print('');
    print('💡 Camera behavior:');
    print('   - Base URI là same cho all time ranges');
    print('   - Time control có thể via RTSP protocol');
    print('   - Hoặc via proprietary URL parameters');
    print('');
    print('🚀 Next steps:');
    print('   - Test playback với different URI formats');
    print('   - Determine best approach cho your camera');
    print('   - Implement trong production app');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
}

String _createTimeSpecificUri(
    String baseUri, DateTime startTime, DateTime endTime) {
  final uri = Uri.parse(baseUri);
  final newParams = Map<String, String>.from(uri.queryParameters);

  newParams['start'] = startTime.toIso8601String();
  newParams['end'] = endTime.toIso8601String();
  newParams['startepoch'] =
      (startTime.millisecondsSinceEpoch ~/ 1000).toString();
  newParams['endepoch'] = (endTime.millisecondsSinceEpoch ~/ 1000).toString();

  final startISO = startTime
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceFirst('.', '')
          .substring(0, 15) +
      'Z';
  final endISO = endTime
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceFirst('.', '')
          .substring(0, 15) +
      'Z';
  newParams['range'] = 'clock=$startISO-$endISO';

  return uri.replace(queryParameters: newParams).toString();
}

String _createDahuaTimeUri(
    String baseUri, DateTime startTime, DateTime endTime) {
  final uri = Uri.parse(baseUri);
  final newParams = Map<String, String>.from(uri.queryParameters);

  // Dahua format
  newParams['starttime'] = startTime.toIso8601String();
  newParams['endtime'] = endTime.toIso8601String();

  return uri.replace(queryParameters: newParams).toString();
}

String _createRTSPTimeUri(
    String baseUri, DateTime startTime, DateTime endTime) {
  final uri = Uri.parse(baseUri);
  final newParams = Map<String, String>.from(uri.queryParameters);

  // RTSP Range format
  final startStr = startTime
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceFirst('.', '')
          .substring(0, 15) +
      'Z';
  final endStr = endTime
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceFirst('.', '')
          .substring(0, 15) +
      'Z';
  newParams['t'] = '$startStr-$endStr';

  return uri.replace(queryParameters: newParams).toString();
}

String _createQueryTimeUri(
    String baseUri, DateTime startTime, DateTime endTime) {
  final uri = Uri.parse(baseUri);
  final newParams = Map<String, String>.from(uri.queryParameters);

  // Simple query format
  newParams['from'] = (startTime.millisecondsSinceEpoch ~/ 1000).toString();
  newParams['to'] = (endTime.millisecondsSinceEpoch ~/ 1000).toString();

  return uri.replace(queryParameters: newParams).toString();
}
