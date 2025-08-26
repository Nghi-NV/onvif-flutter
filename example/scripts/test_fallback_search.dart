import 'package:onvif_flutter/onvif_flutter.dart';

/// Test fallback search directly
void main() async {
  print('=== Test Fallback Search ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    await client.connect();
    print('✅ Connected successfully!\n');

    // Test direct fallback method from search service
    print('🔍 Testing search service directly...');

    final searchService = client.search;

    final results = await searchService.searchRecordings(
      startTime: DateTime.now().subtract(Duration(days: 7)),
      endTime: DateTime.now(),
      maxResults: 100,
    );

    print('✅ Search completed!');
    print('Number of results: ${results.length}');

    for (int i = 0; i < results.length; i++) {
      print('\nRecording $i:');
      for (final entry in results[i].entries) {
        print('  ${entry.key}: ${entry.value}');
      }
    }

    // Test dùng GetRecordings trực tiếp
    print('\n' + '=' * 60);
    print('🎬 Testing GetRecordings directly...');

    final recordingService = client.recording;
    final recordings = await recordingService.getRecordings();

    print('✅ GetRecordings completed!');
    print('Number of recordings: ${recordings.length}');

    for (int i = 0; i < recordings.length; i++) {
      final recording = recordings[i];
      print('\nRecording $i:');
      print('  Token: ${recording.token}');
      print('  Configuration: ${recording.configuration}');
      print('  Tracks: ${recording.tracks.length}');
      for (final track in recording.tracks) {
        print(
            '    - ${track.token} (${track.trackType}): ${track.description}');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
    if (e is OnvifSoapException) {
      print('SOAP Fault: ${e.faultString}');
    }
  } finally {
    client.dispose();
  }
}
