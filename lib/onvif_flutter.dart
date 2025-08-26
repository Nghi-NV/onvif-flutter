/// ONVIF Flutter Library
/// A comprehensive Flutter library for ONVIF (Open Network Video Interface Forum) protocol implementation.
///
/// Supports:
/// - Camera streaming (RTSP, HTTP/HTTPS)
/// - Playback and recording search with time-based queries
/// - PTZ (Pan/Tilt/Zoom) control
/// - Snapshot capture
/// - Event recording and management
/// - Multi-channel NVR/DVR support
/// - Device discovery and management
///
/// Features:
/// - Full ONVIF Profile S, G, T support
/// - WS-Security authentication
/// - Comprehensive error handling
/// - Type-safe models and APIs
/// - Extensive documentation
///
/// Usage:
/// ```dart
/// import 'package:onvif_flutter/onvif_flutter.dart';
///
/// // Create client
/// final client = OnvifClient(
///   host: '192.168.1.100',
///   port: 8080,
///   username: 'admin',
///   password: 'password',
/// );
///
/// // Connect and get device info
/// await client.connect();
/// final deviceInfo = await client.getDeviceInformation();
///
/// // Get profiles and stream
/// final profiles = await client.getProfiles();
/// final streamUri = await client.getStreamUri(profileToken: profiles.first.token);
///
/// // PTZ control
/// await client.ptzMoveContinuous(
///   profileToken: profiles.first.token,
///   panVelocity: 0.5,
///   tiltVelocity: 0.0,
/// );
///
/// // Capture snapshot
/// final snapshotBytes = await client.captureSnapshot(profiles.first.token);
///
/// // Search recordings
/// final recordings = await client.searchRecordings(
///   startTime: DateTime.now().subtract(Duration(hours: 1)),
///   endTime: DateTime.now(),
/// );
/// ```
library onvif_flutter;

// Client
export 'client/onvif_client.dart';
export 'client/transport.dart';

// Services
export 'services/device_service.dart';
export 'services/media_service.dart';
export 'services/ptz_service.dart';
export 'services/search_service.dart';
export 'services/user_management_service.dart';
export 'services/recording_service.dart';
export 'services/recording_segments_service.dart';

// Models
export 'models/device_information.dart';
export 'models/media_profile.dart';
export 'models/stream_uri.dart';
export 'models/video_source.dart' hide VideoResolution, Extension;
export 'models/ptz_configuration.dart' hide Extension;
export 'models/user_management.dart';

// Parsers
export 'parsers/response_parser.dart';

// Utils
export 'utils/constants.dart';
export 'utils/onvif_request.dart';

// Exceptions
export 'exceptions/onvif_exceptions.dart';
