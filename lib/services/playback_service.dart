import '../client/transport.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Playback Service
/// Quản lý playback và tìm kiếm recorded videos
class OnvifPlaybackService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = '/onvif/replay_service';

  OnvifPlaybackService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  /// Tìm kiếm recorded videos trong khoảng thời gian
  /// Approach 1: Dùng Replay Service để tìm actual recorded footage
  Future<List<OnvifRecordedVideo>> searchRecordedVideos({
    required DateTime startTime,
    required DateTime endTime,
    String? profileToken,
    int maxResults = 100,
  }) async {
    try {
      // Method 1: GetReplayConfiguration để tìm hiểu capabilities
      final replayConfig = await getReplayConfiguration();
      print('Replay configuration: $replayConfig');

      // Method 2: Try GetServiceCapabilities
      final capabilities = await getServiceCapabilities();
      print('Service capabilities: $capabilities');

      // Method 3: Fallback - return recordings as potential playback sources
      final recordings = await _getRecordingConfigurations();
      final videos = <OnvifRecordedVideo>[];

      for (final recording in recordings) {
        // Create video object với estimated time range
        videos.add(OnvifRecordedVideo(
          recordingToken: recording.token,
          profileToken: profileToken,
          startTime: startTime, // Estimated - actual video có thể khác
          endTime: endTime, // Estimated - actual video có thể khác
          tracks: recording.tracks,
          source: recording.configuration,
          streamUri: null, // Will be resolved later
        ));
      }

      return videos;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to search recorded videos: $e',
        originalError: e,
      );
    }
  }

  /// Lấy replay configuration
  Future<Map<String, dynamic>> getReplayConfiguration() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trp:GetReplayConfiguration xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trp:GetReplayConfiguration xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
              action:
                  'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return parsed;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get replay configuration: $e',
        originalError: e,
      );
    }
  }

  /// Lấy service capabilities
  Future<Map<String, dynamic>> getServiceCapabilities() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trp:GetServiceCapabilities xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/replay/wsdl/GetServiceCapabilities',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trp:GetServiceCapabilities xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
              action:
                  'http://www.onvif.org/ver10/replay/wsdl/GetServiceCapabilities',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            'http://www.onvif.org/ver10/replay/wsdl/GetServiceCapabilities',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return parsed;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get service capabilities: $e',
        originalError: e,
      );
    }
  }

  /// Lấy replay URI cho recorded video
  Future<String?> getReplayUri({
    required String recordingToken,
    String? profileToken,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '''<trp:GetReplayUri xmlns:trp="http://www.onvif.org/ver10/replay/wsdl">
                <trp:StreamSetup>
                  <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
                  <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
                    <tt:Protocol>RTSP</tt:Protocol>
                  </tt:Transport>
                </trp:StreamSetup>
                <trp:RecordingToken>$recordingToken</trp:RecordingToken>
              </trp:GetReplayUri>''',
              username: _username!,
              password: _password!,
              action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '''<trp:GetReplayUri xmlns:trp="http://www.onvif.org/ver10/replay/wsdl">
                <trp:StreamSetup>
                  <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
                  <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
                    <tt:Protocol>RTSP</tt:Protocol>
                  </tt:Transport>
                </trp:StreamSetup>
                <trp:RecordingToken>$recordingToken</trp:RecordingToken>
              </trp:GetReplayUri>''',
              action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _findInResponse(parsed, 'Uri')?.toString();
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get replay URI: $e',
        originalError: e,
      );
    }
  }

  // ==================== HELPER METHODS ====================

  /// Lấy recording configurations từ recording service
  Future<List<OnvifRecording>> _getRecordingConfigurations() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trc:GetRecordings xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
              username: _username!,
              password: _password!,
              action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trc:GetRecordings xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
              action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: soapRequest,
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final recordingItems = _findInResponse(parsed, 'RecordingItem') ?? [];

      final recordings = <OnvifRecording>[];
      if (recordingItems is List) {
        for (final recordingData in recordingItems) {
          if (recordingData is Map<String, dynamic>) {
            recordings.add(OnvifRecording.fromXml(recordingData));
          }
        }
      } else if (recordingItems is Map<String, dynamic>) {
        recordings.add(OnvifRecording.fromXml(recordingItems));
      }

      return recordings;
    } catch (e) {
      return [];
    }
  }

  bool get _hasCredentials => _username != null && _password != null;

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
}

/// ONVIF Recorded Video Model
class OnvifRecordedVideo {
  final String recordingToken;
  final String? profileToken;
  final DateTime startTime;
  final DateTime endTime;
  final List<OnvifTrack> tracks;
  final String? source;
  final String? streamUri;

  const OnvifRecordedVideo({
    required this.recordingToken,
    this.profileToken,
    required this.startTime,
    required this.endTime,
    this.tracks = const [],
    this.source,
    this.streamUri,
  });

  @override
  String toString() => 'OnvifRecordedVideo(token: $recordingToken, '
      'duration: ${endTime.difference(startTime)})';
}

// Import OnvifRecording và OnvifTrack từ recording_service.dart
class OnvifRecording {
  final String token;
  final String? configuration;
  final List<OnvifTrack> tracks;
  final Map<String, dynamic> extension;

  const OnvifRecording({
    required this.token,
    this.configuration,
    this.tracks = const [],
    this.extension = const {},
  });

  factory OnvifRecording.fromXml(Map<String, dynamic> xml) {
    final tracksData = xml['Tracks'];
    final tracks = <OnvifTrack>[];

    if (tracksData is Map<String, dynamic>) {
      final trackList = tracksData['Track'];
      if (trackList is List) {
        for (final trackData in trackList) {
          if (trackData is Map<String, dynamic>) {
            tracks.add(OnvifTrack.fromXml(trackData));
          }
        }
      } else if (trackList is Map<String, dynamic>) {
        tracks.add(OnvifTrack.fromXml(trackList));
      }
    }

    return OnvifRecording(
      token: xml['RecordingToken'] ?? xml['@token'] ?? xml['token'] ?? '',
      configuration: xml['Configuration']?.toString(),
      tracks: tracks,
      extension: xml['Extension'] ?? {},
    );
  }
}

class OnvifTrack {
  final String token;
  final String trackType;
  final String? description;
  final DateTime? dataFrom;
  final DateTime? dataTo;
  final Map<String, dynamic> extension;

  const OnvifTrack({
    required this.token,
    required this.trackType,
    this.description,
    this.dataFrom,
    this.dataTo,
    this.extension = const {},
  });

  factory OnvifTrack.fromXml(Map<String, dynamic> xml) {
    final config = xml['Configuration'] ?? {};
    return OnvifTrack(
      token: xml['TrackToken'] ?? xml['@token'] ?? xml['token'] ?? '',
      trackType:
          config['TrackType']?.toString() ?? xml['TrackType']?.toString() ?? '',
      description:
          config['Description']?.toString() ?? xml['Description']?.toString(),
      dataFrom: _parseDateTime(xml['DataFrom']),
      dataTo: _parseDateTime(xml['DataTo']),
      extension: xml['Extension'] ?? {},
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }
}
