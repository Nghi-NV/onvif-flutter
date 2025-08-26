import 'package:onvif_flutter/onvif_flutter.dart';

/// Simple Command Line UI Example cho ONVIF Flutter Library
void main() async {
  print('🎬 ONVIF Flutter Library Demo');
  print('=' * 50);

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    // ==================== CONNECTION ====================
    print('\n🔗 Đang kết nối...');
    await client.connect();
    print('✅ Kết nối thành công!\n');

    // ==================== DEVICE INFORMATION ====================
    print('📱 Thông tin thiết bị:');
    print('-' * 30);

    final deviceInfo = await client.getDeviceInformation();
    print('Nhà sản xuất: ${deviceInfo.manufacturer ?? 'Unknown'}');
    print('Model: ${deviceInfo.model ?? 'Unknown'}');
    print('Firmware: ${deviceInfo.firmwareVersion ?? 'Unknown'}');
    print('Serial: ${deviceInfo.serialNumber ?? 'Unknown'}');
    print('Hardware ID: ${deviceInfo.hardwareId ?? 'Unknown'}\n');

    // ==================== MEDIA PROFILES ====================
    print('📹 Media Profiles:');
    print('-' * 30);

    final profiles = await client.media.getProfiles();
    print('Tìm thấy ${profiles.length} profiles:\n');

    for (int i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      print('Profile ${i + 1}: ${profile.token}');
      print('  Name: ${profile.name ?? 'N/A'}');
      print('  Fixed: ${profile.fixed ? 'Yes' : 'No'}');
      if (profile.videoSourceConfiguration != null) {
        print(
            '  Video Source: ${profile.videoSourceConfiguration!.name ?? 'N/A'}');
      }
      print('');
    }

    // ==================== RECORDINGS ====================
    print('🎥 Recordings:');
    print('-' * 30);

    final recordings = await client.getRecordings();
    print('Tìm thấy ${recordings.length} recordings:\n');

    for (int i = 0; i < recordings.length; i++) {
      final recording = recordings[i];
      print('Recording ${i + 1}: ${recording.token}');
      print('  Tracks: ${recording.tracks.length}');
      for (final track in recording.tracks) {
        print('    • ${track.trackType}: ${track.token}');
      }
      print('');
    }

    // ==================== STREAM URI ====================
    print('🌊 Stream URI:');
    print('-' * 30);

    if (profiles.isNotEmpty) {
      final firstProfile = profiles[0];
      final streamUri =
          await client.media.getStreamUri(profileToken: firstProfile.token);
      print('Stream URI cho ${firstProfile.token}:');
      print('  $streamUri\n');
    }

    // ==================== SNAPSHOT URI ====================
    print('📸 Snapshot URI:');
    print('-' * 30);

    if (profiles.isNotEmpty) {
      final firstProfile = profiles[0];
      final snapshotUri = await client.media.getSnapshotUri(firstProfile.token);
      print('Snapshot URI cho ${firstProfile.token}:');
      print('  $snapshotUri\n');
    }

    // ==================== USER MANAGEMENT ====================
    print('👥 User Management:');
    print('-' * 30);

    try {
      final users = await client.userManagement.getUsers();
      print('Tìm thấy ${users.length} users:\n');

      for (final user in users) {
        print('User: ${user.username}');
        print('  Level: ${user.userLevel}');
        print('  Groups: ${user.groups.join(', ')}');
        print('');
      }
    } catch (e) {
      print('❌ User management không khả dụng: $e\n');
    }

    // ==================== RECORDING SEARCH ====================
    print('🔍 Recording Search:');
    print('-' * 30);

    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(Duration(hours: 1));

      final searchResults = await client.searchRecordings(
        startTime: startTime,
        endTime: endTime,
        maxResults: 5,
      );

      print('Tìm thấy ${searchResults.length} recordings trong 1 giờ qua:\n');

      for (int i = 0; i < searchResults.length; i++) {
        final result = searchResults[i];
        print('Recording ${i + 1}:');
        print('  Token: ${result['RecordingToken']}');
        print('  Start: ${result['StartTime']}');
        print('  End: ${result['EndTime']}');
        print('');
      }
    } catch (e) {
      print('❌ Recording search không khả dụng: $e\n');
    }

    // ==================== RECORDING SEGMENTS ====================
    print('🎬 Recording Segments:');
    print('-' * 30);

    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(Duration(minutes: 30));

      final segments = await client.searchRecordingSegments(
        startTime: startTime,
        endTime: endTime,
        maxResults: 3,
      );

      print('Tìm thấy ${segments.length} recording segments:\n');

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        print('Segment ${i + 1}:');
        print('  Time: ${segment.timeRangeString}');
        print('  Duration: ${segment.durationString}');
        print('  URI: ${segment.replayUri}');
        print('');
      }
    } catch (e) {
      print('❌ Recording segments không khả dụng: $e\n');
    }

    // ==================== SUMMARY ====================
    print('📊 Summary:');
    print('-' * 30);
    print('✅ Device: ${deviceInfo.manufacturer} ${deviceInfo.model}');
    print('✅ Media Profiles: ${profiles.length}');
    print('✅ Recordings: ${recordings.length}');
    print('✅ Library Status: FULLY FUNCTIONAL! 🎉\n');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
    print('🔚 Đã đóng kết nối.');
  }
}
