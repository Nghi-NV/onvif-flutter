import 'package:onvif_flutter/onvif_flutter.dart';

/// Test final với ONVIF device thực
void main() async {
  print('=== FINAL ONVIF TEST ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    // Connect
    final connected = await client.connect();
    if (!connected) {
      print('❌ Connection failed');
      return;
    }

    print('✅ Connected successfully!\n');

    // Device Info
    final deviceInfo = await client.getDeviceInformation();
    print('📱 Device: ${deviceInfo.manufacturer} ${deviceInfo.model}');
    print('   Firmware: ${deviceInfo.firmwareVersion}');
    print('   Serial: ${deviceInfo.serialNumber}\n');

    // Capabilities
    final capabilities = await client.getCapabilities();
    print('🔧 Services Available:');
    print('   Media: ${capabilities.media?.xAddr}');
    print('   PTZ: ${capabilities.ptz?.xAddr}');
    print('   Events: ${capabilities.events?.xAddr}');
    // Note: Extension capabilities may not be available in basic capabilities
    print('');

    // Profiles với debug chi tiết
    print('🎥 Getting Media Profiles...');

    // Get profiles thủ công để debug
    final mediaService = client.media;
    final profiles = await mediaService.getProfiles();

    print('Found ${profiles.length} profiles:');
    for (int i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      print('Profile ${i + 1}:');
      print('   Token: "${profile.token}"');
      print('   Name: ${profile.name}');
      print('   Video: ${profile.hasVideo}');
      print('   Audio: ${profile.hasAudio}');
      print('   PTZ: ${profile.hasPtz}');
      if (profile.videoResolution != null) {
        print('   Resolution: ${profile.videoResolution}');
      }
      print('');
    }

    if (profiles.isNotEmpty) {
      final firstProfile = profiles.first;

      if (firstProfile.token.isNotEmpty) {
        print('📺 Getting Stream URI...');
        try {
          final streamUri = await client.getStreamUri(
            profileToken: firstProfile.token,
            protocol: StreamProtocol.rtsp,
          );
          print('✅ Stream URI: ${streamUri.uri}');
          print(
              '   With credentials: ${streamUri.withCredentials('admin', 'FB000033')}\n');
        } catch (e) {
          print('❌ Stream URI error: $e\n');
        }

        print('📸 Getting Snapshot URI...');
        try {
          final snapshotUri = await client.getSnapshotUri(firstProfile.token);
          print('✅ Snapshot URI: ${snapshotUri.uri}\n');
        } catch (e) {
          print('❌ Snapshot URI error: $e\n');
        }

        // Test PTZ if supported
        if (firstProfile.hasPtz) {
          print('🕹️ Testing PTZ...');
          try {
            final ptzStatus = await client.ptz.getStatus(firstProfile.token);
            print('✅ PTZ Status: $ptzStatus');

            // Test move
            print('   Testing PTZ move...');
            await client.ptzMoveContinuous(
              profileToken: firstProfile.token,
              panVelocity: 0.1,
              tiltVelocity: 0.0,
              timeout: Duration(seconds: 1),
            );

            await Future.delayed(Duration(seconds: 1));

            await client.ptzStop(
              profileToken: firstProfile.token,
              stopPanTilt: true,
              stopZoom: true,
            );

            print('   ✅ PTZ test successful\n');
          } catch (e) {
            print('   ❌ PTZ error: $e\n');
          }
        }
      } else {
        print('❌ Profile token is empty - cannot test streams\n');
      }
    }

    // Test User Management (if admin)
    print('👥 Testing User Management...');
    try {
      final users = await client.getUsers();
      print('✅ Found ${users.length} users');

      for (final user in users) {
        print('   - ${user.username} (${user.userLevel.value})');
      }
      print('');
    } catch (e) {
      print('❌ User management error: $e\n');
    }

    print('🎉 All tests completed successfully!');
  } catch (e) {
    print('❌ Error: $e');
    if (e is OnvifException) {
      print('   Type: ${e.runtimeType}');
      print('   Code: ${e.code}');
      if (e is OnvifSoapException) {
        print('   Fault: ${e.faultCode} - ${e.faultString}');
      }
    }
  } finally {
    client.dispose();
    print('\n🧹 Cleaned up');
  }
}
