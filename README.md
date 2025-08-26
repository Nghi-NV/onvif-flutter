# ONVIF Flutter

A comprehensive Flutter library for ONVIF (Open Network Video Interface Forum) protocol implementation. Supports camera streaming, playback, PTZ control, snapshots, events recording, and multi-channel NVR management.

## Features

- 📹 **Camera Streaming**: Support for RTSP, HTTP/HTTPS streams
- 🔄 **Playback**: Recording search and playback with time-based queries
- 🕹️ **PTZ Control**: Pan/Tilt/Zoom operations with precise control
- 📸 **Snapshot Capture**: High-quality image capture
- 📊 **Event Recording**: Real-time event handling and recording
- 🎛️ **Multi-Channel Support**: NVR/DVR with multiple camera channels
- 🔐 **Authentication**: WS-Security and Digest authentication
- 👥 **User Management**: Complete user/admin/group management
- 🛡️ **Error Handling**: Comprehensive error handling and recovery
- 📋 **Type Safety**: Full type-safe models and APIs
- 📚 **Documentation**: Extensive documentation and examples

## Supported ONVIF Profiles

- **Profile S**: Video streaming
- **Profile G**: Video recording and storage  
- **Profile T**: Advanced video streaming
- **Profile M**: Metadata and analytics

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  onvif_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:onvif_flutter/onvif_flutter.dart';

// Create ONVIF client
final client = OnvifClient(
  host: '192.168.1.100',
  port: 8080,
  username: 'admin',
  password: 'password',
);

// Connect to device
try {
  final connected = await client.connect();
  if (connected) {
    print('Connected to ONVIF device');
    
    // Get device information
    final deviceInfo = await client.getDeviceInformation();
    print('Device: ${deviceInfo.manufacturer} ${deviceInfo.model}');
    
    // Get available profiles
    final profiles = await client.getProfiles();
    print('Found ${profiles.length} profiles');
    
    // Get stream URI for first profile
    if (profiles.isNotEmpty) {
      final streamUri = await client.getStreamUri(
        profileToken: profiles.first.token,
        protocol: StreamProtocol.rtsp,
      );
      print('Stream URI: ${streamUri.uri}');
    }
  }
} catch (e) {
  print('Error: $e');
} finally {
  client.dispose();
}
```

### Camera Streaming

```dart
// Get RTSP stream
final streamUri = await client.getStreamUri(
  profileToken: profileToken,
  protocol: StreamProtocol.rtsp,
);

// Use with video player
final videoPlayerController = VideoPlayerController.network(
  streamUri.withCredentials(username, password),
);
```

### Snapshot Capture

```dart
// Capture snapshot as bytes
final snapshotBytes = await client.captureSnapshot(profileToken);

// Save to file
final file = File('snapshot.jpg');
await file.writeAsBytes(snapshotBytes);

// Or display in app
final image = Image.memory(snapshotBytes);
```

### PTZ Control

```dart
// Continuous movement
await client.ptzMoveContinuous(
  profileToken: profileToken,
  panVelocity: 0.5,   // Move right
  tiltVelocity: 0.2,  // Move up
  zoomVelocity: 0.0,  // No zoom
  timeout: Duration(seconds: 5),
);

// Stop movement
await client.ptzStop(
  profileToken: profileToken,
  stopPanTilt: true,
  stopZoom: true,
);

// Relative movement
await client.ptz.relativeMove(
  profileToken: profileToken,
  panTranslation: 0.1,
  tiltTranslation: 0.1,
  zoomTranslation: 0.0,
);
```

### Recording Search

```dart
// Search recordings in time range
final recordings = await client.searchRecordings(
  startTime: DateTime.now().subtract(Duration(hours: 24)),
  endTime: DateTime.now(),
  profileToken: profileToken,
  maxResults: 100,
);

print('Found ${recordings.length} recordings');

// Search events
final events = await client.search.searchEvents(
  startTime: DateTime.now().subtract(Duration(hours: 1)),
  endTime: DateTime.now(),
  maxResults: 50,
);
```

### User Management

```dart
// Get all users
final users = await client.getUsers();
print('Found ${users.length} users');

// Create new user
await client.createUser(
  username: 'operator1',
  password: 'secure123',
  userLevel: UserLevel.operator,
  accessRights: AccessRights.operatorRights,
  userInformation: UserInformation(
    firstName: 'John',
    lastName: 'Operator',
    emailAddress: 'john@company.com',
  ),
);

// Update user
await client.updateUser(
  username: 'operator1',
  newPassword: 'newsecure123',
  userInformation: UserInformation(
    firstName: 'John',
    lastName: 'Senior Operator',
    emailAddress: 'john.senior@company.com',
  ),
);

// Create group
await client.createGroup(
  groupName: 'Operators',
  description: 'Camera operators group',
  accessRights: AccessRights.operatorRights,
  members: ['operator1'],
);

// Add user to group
await client.addUserToGroup(
  username: 'operator1',
  groupName: 'Operators',
);

// Change password
await client.changeUserPassword(
  username: 'operator1',
  newPassword: 'newpassword123',
);

// Delete user
await client.deleteUser('operator1');
```

### Multi-Channel Support

```dart
// Check if device supports multiple channels
final isMultiChannel = await client.isMultiChannelDevice();
print('Multi-channel device: $isMultiChannel');

// Get channel count
final channelCount = await client.getChannelCount();
print('Number of channels: $channelCount');

// Get all profiles (one per channel typically)
final profiles = await client.getProfiles();
for (final profile in profiles) {
  print('Profile: ${profile.name} (${profile.token})');
  
  // Get stream for each profile/channel
  final streamUri = await client.getStreamUri(
    profileToken: profile.token,
  );
  print('Channel stream: ${streamUri.uri}');
}
```

### Device Discovery

```dart
// Note: Device discovery requires platform-specific UDP multicast implementation
// This is a placeholder for the discovery functionality

class OnvifDiscovery {
  static Future<List<OnvifDevice>> discover({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Implementation would use WS-Discovery protocol
    // to find ONVIF devices on the network
    throw UnimplementedError('Discovery requires platform-specific implementation');
  }
}
```

## Advanced Usage

### Custom Transport Configuration

```dart
final client = OnvifClient(
  host: '192.168.1.100',
  port: 8080,
  username: 'admin',
  password: 'password',
  useHttps: true,
  timeout: Duration(seconds: 30),
  allowSelfSignedCerts: true,
);
```

### Error Handling

```dart
try {
  final profiles = await client.getProfiles();
} on OnvifAuthenticationException catch (e) {
  print('Authentication failed: ${e.message}');
} on OnvifConnectionException catch (e) {
  print('Connection failed: ${e.message}');
} on OnvifTimeoutException catch (e) {
  print('Request timeout: ${e.message}');
} on OnvifException catch (e) {
  print('ONVIF error: ${e.message}');
}
```

### Service-Level Access

```dart
// Access specific services directly
final deviceService = client.device;
final mediaService = client.media;
final ptzService = client.ptz;
final searchService = client.search;
final userService = client.userManagement;

// Device management
final dateTime = await deviceService.getSystemDateTime();
await deviceService.setSystemDateTime(DateTime.now());

// Media operations
final videoSources = await mediaService.getVideoSources();
final audioSources = await mediaService.getAudioSources();

// PTZ operations
final ptzStatus = await ptzService.getStatus(profileToken);
final configOptions = await ptzService.getConfigurationOptions(configToken);

// User management operations
final users = await userService.getUsers();
final groups = await userService.getGroups();
final userOptions = await userService.getUserOptions();
```

## Models

### Device Information

```dart
final deviceInfo = await client.getDeviceInformation();
print('Manufacturer: ${deviceInfo.manufacturer}');
print('Model: ${deviceInfo.model}');
print('Firmware: ${deviceInfo.firmwareVersion}');
print('Serial: ${deviceInfo.serialNumber}');
```

### Media Profile

```dart
final profile = profiles.first;
print('Token: ${profile.token}');
print('Name: ${profile.name}');
print('Has Video: ${profile.hasVideo}');
print('Has Audio: ${profile.hasAudio}');
print('Has PTZ: ${profile.hasPtz}');
print('Resolution: ${profile.videoResolution}');
print('Frame Rate: ${profile.frameRate}');
```

### Stream URI

```dart
final streamUri = await client.getStreamUri(profileToken: profileToken);
print('URI: ${streamUri.uri}');
print('Protocol: ${streamUri.protocol}');
print('Is RTSP: ${streamUri.isRtsp}');
print('Host: ${streamUri.host}');
print('Port: ${streamUri.port}');
```

### User Information

```dart
final user = users.first;
print('Username: ${user.username}');
print('Level: ${user.userLevel.value}');
print('Is Admin: ${user.isAdministrator}');
print('Is Operator: ${user.isOperator}');
print('Access Rights: ${user.accessRights.length}');
print('Groups: ${user.groups.join(', ')}');

if (user.userInformation != null) {
  final info = user.userInformation!;
  print('Full Name: ${info.fullName}');
  print('Email: ${info.emailAddress}');
  print('Phone: ${info.phoneNumber}');
}
```

## Constants

```dart
// ONVIF Constants
OnvifConstants.defaultOnvifPort        // 8080
OnvifConstants.defaultTimeout          // 30 seconds
OnvifConstants.h264Encoding           // "H264"
OnvifConstants.resolution1080p        // "1920x1080"
OnvifConstants.frameRate30            // 30

// Stream Protocols
StreamProtocol.rtsp
StreamProtocol.http
StreamProtocol.https
StreamProtocol.tcp
StreamProtocol.udp

// PTZ Movement Types
PtzMovementType.continuous
PtzMovementType.relative
PtzMovementType.absolute

// User Levels
UserLevel.administrator
UserLevel.operator
UserLevel.user
UserLevel.anonymous

// Access Rights
AccessRights.administratorRights    // Full system access
AccessRights.operatorRights         // Camera operation access
AccessRights.userRights            // View-only access
```

## Testing

The library includes comprehensive tests. Run them with:

```bash
flutter test
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `cd example && flutter run`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [ONVIF Forum](https://www.onvif.org/) for the ONVIF specifications
- [Dio](https://pub.dev/packages/dio) for HTTP client functionality
- [XML](https://pub.dev/packages/xml) for XML parsing

## Roadmap

- [ ] Device Discovery (WS-Discovery)
- [ ] Audio Streaming Support
- [ ] Analytics and Metadata
- [ ] Recording Control
- [ ] Replay Service
- [ ] Events Subscription
- [ ] Two-way Audio
- [ ] Mobile Push Notifications
- [ ] Video Analytics Integration

## FAQ

### Q: Does this work with all ONVIF cameras?
A: This library implements ONVIF Profile S, G, T standards. Most ONVIF-compliant cameras should work, but specific features depend on device capabilities.

### Q: Can I use this for live streaming apps?
A: Yes! The library provides stream URIs that work with video players like `video_player` or `vlc_player`.

### Q: Is recording search supported?
A: Yes, the library supports searching recordings by time range and other criteria through the Search Service.

### Q: What about device discovery?
A: Device discovery requires platform-specific UDP multicast implementation and is not yet included but is planned for future releases.

### Q: Does it support authentication?
A: Yes, both WS-Security Username Token and HTTP Digest authentication are supported.

---

For more examples and detailed documentation, visit our [Documentation](https://github.com/nghinguyen/onvif-flutter/wiki).
