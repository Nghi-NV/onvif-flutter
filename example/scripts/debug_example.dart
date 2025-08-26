import 'package:onvif_flutter/onvif_flutter.dart';

/// Debug example để kiểm tra kết nối ONVIF
void main() async {
  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8082,
    username: 'admin',
    password: 'FB000033',
    useHttps: false,
    timeout: Duration(seconds: 30),
  );

  try {
    print('=== ONVIF Debug Example ===\n');
    print('Device URI: ${client.deviceUri}');
    print('Username: ${client.username}');
    print('Has credentials: ${client.credentials != null}\n');

    // Test kết nối cơ bản
    print('📡 Testing basic connection...');
    final testResult = await client.testConnection();
    print('Basic connection test: ${testResult ? "✅ Success" : "❌ Failed"}\n');

    if (!testResult) {
      print('🔍 Trying to get device information directly...');
      try {
        final deviceInfo = await client.device.getDeviceInformation();
        print(
            '✅ Got device info: ${deviceInfo.manufacturer} ${deviceInfo.model}');
      } catch (e) {
        print('❌ Device info error: $e');
        print('Error type: ${e.runtimeType}');

        if (e is OnvifException) {
          print('ONVIF Error code: ${e.code}');
          print('Original error: ${e.originalError}');
        }
      }
    }

    // Test capabilities
    print('\n🔧 Testing capabilities...');
    try {
      final capabilities = await client.device.getCapabilities();
      print('✅ Got capabilities:');
      print('   Device: ${capabilities.device?.xAddr}');
      print('   Media: ${capabilities.media?.xAddr}');
      print('   PTZ: ${capabilities.ptz?.xAddr}');
      print('   Events: ${capabilities.events?.xAddr}');
    } catch (e) {
      print('❌ Capabilities error: $e');
    }

    // Test với connect method
    print('\n🔌 Testing connect method...');
    try {
      final connected = await client.connect();
      print('Connect result: ${connected ? "✅ Success" : "❌ Failed"}');

      if (connected) {
        print('\n📱 Device Information:');
        final deviceInfo = await client.getDeviceInformation();
        print('   Manufacturer: ${deviceInfo.manufacturer}');
        print('   Model: ${deviceInfo.model}');
        print('   Firmware: ${deviceInfo.firmwareVersion}');
        print('   Serial: ${deviceInfo.serialNumber}');

        print('\n🎥 Media Profiles:');
        final profiles = await client.getProfiles();
        print('   Found ${profiles.length} profile(s)');

        for (final profile in profiles) {
          print('   - ${profile.name} (${profile.token})');
          print(
              '     Video: ${profile.hasVideo}, Audio: ${profile.hasAudio}, PTZ: ${profile.hasPtz}');
        }

        if (profiles.isNotEmpty) {
          print('\n📺 Stream URI:');
          try {
            final streamUri = await client.getStreamUri(
              profileToken: profiles.first.token,
            );
            print('   URI: ${streamUri.uri}');
            print(
                '   With credentials: ${streamUri.withCredentials(client.username!, client.password!)}');
          } catch (e) {
            print('   ❌ Stream URI error: $e');
          }

          print('\n📸 Snapshot URI:');
          try {
            final snapshotUri =
                await client.getSnapshotUri(profiles.first.token);
            print('   URI: ${snapshotUri.uri}');
          } catch (e) {
            print('   ❌ Snapshot URI error: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Connect error: $e');
      print('Error type: ${e.runtimeType}');

      if (e is OnvifException) {
        print('ONVIF Error details:');
        print('   Message: ${e.message}');
        print('   Code: ${e.code}');
        print('   Original error: ${e.originalError}');

        if (e is OnvifSoapException) {
          print('   Fault code: ${e.faultCode}');
          print('   Fault string: ${e.faultString}');
          print('   Detail: ${e.detail}');
        }
      }
    }
  } finally {
    client.dispose();
    print('\n🧹 Resources cleaned up');
  }
}
