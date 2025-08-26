import '../client/transport.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Recording Service
/// Quản lý recordings và tìm kiếm recordings
class OnvifRecordingService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = '/onvif/recording_service';

  OnvifRecordingService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  /// Lấy danh sách tất cả recordings
  Future<List<OnvifRecording>> getRecordings() async {
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
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final recordingsData = _findInResponse(parsed, 'RecordingItem') ?? [];

      final recordings = <OnvifRecording>[];
      if (recordingsData is List) {
        for (final recordingData in recordingsData) {
          if (recordingData is Map<String, dynamic>) {
            recordings.add(OnvifRecording.fromXml(recordingData));
          }
        }
      } else if (recordingsData is Map<String, dynamic>) {
        recordings.add(OnvifRecording.fromXml(recordingsData));
      }

      return recordings;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get recordings: $e',
        originalError: e,
      );
    }
  }

  /// Tạo recording mới
  Future<OnvifRecording> createRecording({
    required String recordingToken,
    required List<OnvifTrack> tracks,
  }) async {
    try {
      final tracksXml = tracks.map((track) => track.toXml()).join('');

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '''<trc:CreateRecording xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
                <trc:RecordingToken>$recordingToken</trc:RecordingToken>
                $tracksXml
              </trc:CreateRecording>''',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/CreateRecording',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '''<trc:CreateRecording xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
                <trc:RecordingToken>$recordingToken</trc:RecordingToken>
                $tracksXml
              </trc:CreateRecording>''',
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/CreateRecording',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/CreateRecording',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final recordingData = _findInResponse(parsed, 'Recording') ?? {};

      return OnvifRecording.fromXml(recordingData);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to create recording: $e',
        originalError: e,
      );
    }
  }

  /// Xóa recording
  Future<void> deleteRecording(String recordingToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '''<trc:DeleteRecording xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
                <trc:RecordingToken>$recordingToken</trc:RecordingToken>
              </trc:DeleteRecording>''',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/DeleteRecording',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '''<trc:DeleteRecording xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
                <trc:RecordingToken>$recordingToken</trc:RecordingToken>
              </trc:DeleteRecording>''',
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/DeleteRecording',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: 'http://www.onvif.org/ver10/recording/wsdl/DeleteRecording',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to delete recording: $e',
        originalError: e,
      );
    }
  }

  /// Lấy cấu hình recording
  Future<OnvifRecordingConfiguration> getRecordingConfiguration() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trc:GetRecordingConfiguration xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/GetRecordingConfiguration',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trc:GetRecordingConfiguration xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/GetRecordingConfiguration',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            'http://www.onvif.org/ver10/recording/wsdl/GetRecordingConfiguration',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final configData =
          _findInResponse(parsed, 'RecordingConfiguration') ?? {};

      return OnvifRecordingConfiguration.fromXml(configData);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get recording configuration: $e',
        originalError: e,
      );
    }
  }

  // ==================== HELPER METHODS ====================

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

/// ONVIF Recording Model
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

  @override
  String toString() =>
      'OnvifRecording(token: $token, tracks: ${tracks.length})';
}

/// ONVIF Track Model
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

  String toXml() {
    final buffer = StringBuffer();
    buffer.write('<trc:Track token="$token">');
    buffer.write('<trc:TrackType>$trackType</trc:TrackType>');
    if (description != null) {
      buffer.write('<trc:Description>$description</trc:Description>');
    }
    if (dataFrom != null) {
      buffer
          .write('<trc:DataFrom>${dataFrom!.toIso8601String()}</trc:DataFrom>');
    }
    if (dataTo != null) {
      buffer.write('<trc:DataTo>${dataTo!.toIso8601String()}</trc:DataTo>');
    }
    buffer.write('</trc:Track>');
    return buffer.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => 'OnvifTrack(token: $token, type: $trackType)';
}

/// ONVIF Recording Configuration Model
class OnvifRecordingConfiguration {
  final String source;
  final String content;
  final int? maximumRetentionTime;
  final Map<String, dynamic> extension;

  const OnvifRecordingConfiguration({
    required this.source,
    required this.content,
    this.maximumRetentionTime,
    this.extension = const {},
  });

  factory OnvifRecordingConfiguration.fromXml(Map<String, dynamic> xml) {
    return OnvifRecordingConfiguration(
      source: xml['Source']?.toString() ?? '',
      content: xml['Content']?.toString() ?? '',
      maximumRetentionTime:
          int.tryParse(xml['MaximumRetentionTime']?.toString() ?? ''),
      extension: xml['Extension'] ?? {},
    );
  }

  @override
  String toString() =>
      'OnvifRecordingConfiguration(source: $source, content: $content)';
}
