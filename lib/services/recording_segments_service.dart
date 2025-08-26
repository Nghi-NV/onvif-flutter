import '../client/transport.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Recording Segments Service
/// Quản lý recording segments và time-based playback
class OnvifRecordingSegmentsService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;

  OnvifRecordingSegmentsService(
      this._transport, this._username, this._password);

  /// Tìm kiếm recorded segments trong khoảng thời gian
  Future<List<OnvifRecordingSegment>> searchRecordingSegments({
    required DateTime startTime,
    required DateTime endTime,
    String? profileToken,
    int maxResults = 100,
  }) async {
    try {
      // Step 1: Lấy recording jobs để biết có recording nào đang active
      final recordingJobs = await _getRecordingJobs();

      // Step 2: Cho mỗi recording job, tạo segment entries
      final segments = <OnvifRecordingSegment>[];

      for (final job in recordingJobs) {
        if (job.state == 'Active') {
          // Create segments every 2 minutes (giả sử recording segmentation)
          final segmentDuration = Duration(minutes: 2);
          DateTime currentTime = startTime;

          while (
              currentTime.isBefore(endTime) && segments.length < maxResults) {
            final segmentEnd = currentTime.add(segmentDuration);
            final actualEnd =
                segmentEnd.isAfter(endTime) ? endTime : segmentEnd;

            // Test xem segment này có recorded data không
            final hasData = await _testTimeRangeHasData(
              job.recordingToken,
              currentTime,
              actualEnd,
            );

            if (hasData) {
              final replayUri = await _getReplayUriForTimeRange(
                job.recordingToken,
                currentTime,
                actualEnd,
              );

              // Create time-specific URI
              final timeSpecificUri = _createTimeSpecificUri(
                replayUri,
                currentTime,
                actualEnd,
              );

              segments.add(OnvifRecordingSegment(
                recordingToken: job.recordingToken,
                jobToken: job.jobToken,
                startTime: currentTime,
                endTime: actualEnd,
                duration: actualEnd.difference(currentTime),
                replayUri: timeSpecificUri,
                profileToken: job.sourceToken,
                tracks: job.tracks,
                state: 'Available',
              ));
            }

            currentTime = actualEnd;
          }
        }
      }

      return segments;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to search recording segments: $e',
        originalError: e,
      );
    }
  }

  /// Lấy replay URI cho time range cụ thể
  Future<String?> getReplayUriForTimeRange({
    required String recordingToken,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return await _getReplayUriForTimeRange(recordingToken, startTime, endTime);
  }

  /// Lấy recording jobs
  Future<List<OnvifRecordingJob>> _getRecordingJobs() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trc:GetRecordingJobs xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trc:GetRecordingJobs xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: soapRequest,
        soapAction:
            'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final jobItems = _findInResponse(parsed, 'JobItem') ?? [];

      final jobs = <OnvifRecordingJob>[];
      if (jobItems is List) {
        for (final jobData in jobItems) {
          if (jobData is Map<String, dynamic>) {
            // Get job state
            final jobToken = jobData['JobToken']?.toString() ?? '';
            final state = await _getRecordingJobState(jobToken);

            jobs.add(OnvifRecordingJob.fromXml(jobData, state));
          }
        }
      } else if (jobItems is Map<String, dynamic>) {
        final jobToken = jobItems['JobToken']?.toString() ?? '';
        final state = await _getRecordingJobState(jobToken);
        jobs.add(OnvifRecordingJob.fromXml(jobItems, state));
      }

      return jobs;
    } catch (e) {
      throw OnvifConnectionException('Failed to get recording jobs: $e');
    }
  }

  /// Lấy recording job state
  Future<String> _getRecordingJobState(String jobToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '''<trc:GetRecordingJobState xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
                <trc:JobToken>$jobToken</trc:JobToken>
              </trc:GetRecordingJobState>''',
              username: _username!,
              password: _password!,
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '''<trc:GetRecordingJobState xmlns:trc="http://www.onvif.org/ver10/recording/wsdl">
                <trc:JobToken>$jobToken</trc:JobToken>
              </trc:GetRecordingJobState>''',
              action:
                  'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
              headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: '/onvif/recording_service',
        soapBody: soapRequest,
        soapAction:
            'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _findInResponse(parsed, 'State')?.toString() ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Test xem time range có recorded data không
  Future<bool> _testTimeRangeHasData(
    String recordingToken,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final replayUri =
          await _getReplayUriForTimeRange(recordingToken, startTime, endTime);
      // Nếu có URI và không chứa error, assume có data
      // Với continuous recording, mọi time range đều có data
      return replayUri != null &&
          replayUri.isNotEmpty &&
          !replayUri.toLowerCase().contains('error') &&
          !replayUri.toLowerCase().contains('fault');
    } catch (e) {
      return false;
    }
  }

  /// Lấy replay URI cho time range
  Future<String?> _getReplayUriForTimeRange(
    String recordingToken,
    DateTime startTime,
    DateTime endTime,
  ) async {
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
                <trp:Time>
                  <tt:From xmlns:tt="http://www.onvif.org/ver10/schema">${startTime.toIso8601String()}</tt:From>
                  <tt:Until xmlns:tt="http://www.onvif.org/ver10/schema">${endTime.toIso8601String()}</tt:Until>
                </trp:Time>
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
                <trp:Time>
                  <tt:From xmlns:tt="http://www.onvif.org/ver10/schema">${startTime.toIso8601String()}</tt:From>
                  <tt:Until xmlns:tt="http://www.onvif.org/ver10/schema">${endTime.toIso8601String()}</tt:Until>
                </trp:Time>
              </trp:GetReplayUri>''',
              action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
              headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
            );

      final response = await _transport.sendSoapRequest(
        path: '/onvif/replay_service',
        soapBody: soapRequest,
        soapAction: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _findInResponse(parsed, 'Uri')?.toString();
    } catch (e) {
      return null;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Tạo time-specific URI với time parameters
  String _createTimeSpecificUri(
    String? baseUri,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (baseUri == null || baseUri.isEmpty) {
      return '';
    }

    // Add time parameters to URI
    final uri = Uri.parse(baseUri);
    final newParams = Map<String, String>.from(uri.queryParameters);

    // Add time range parameters
    newParams['start'] = startTime.toIso8601String();
    newParams['end'] = endTime.toIso8601String();
    newParams['startepoch'] =
        (startTime.millisecondsSinceEpoch ~/ 1000).toString();
    newParams['endepoch'] = (endTime.millisecondsSinceEpoch ~/ 1000).toString();

    // Format cho RTSP time range (ISO format)
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

    // Create new URI với time parameters
    final newUri = uri.replace(queryParameters: newParams);
    return newUri.toString();
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

/// ONVIF Recording Job Model
class OnvifRecordingJob {
  final String jobToken;
  final String recordingToken;
  final String mode;
  final int priority;
  final String sourceToken;
  final List<OnvifRecordingTrack> tracks;
  final String state;

  const OnvifRecordingJob({
    required this.jobToken,
    required this.recordingToken,
    required this.mode,
    required this.priority,
    required this.sourceToken,
    required this.tracks,
    required this.state,
  });

  factory OnvifRecordingJob.fromXml(Map<String, dynamic> xml, String state) {
    final config = xml['JobConfiguration'] ?? {};
    final source = config['Source'] ?? {};
    final sourceToken = source['SourceToken'] ?? {};
    final tracksData = source['Tracks'];

    final tracks = <OnvifRecordingTrack>[];
    if (tracksData is List) {
      for (final trackData in tracksData) {
        if (trackData is Map<String, dynamic>) {
          tracks.add(OnvifRecordingTrack.fromXml(trackData));
        }
      }
    } else if (tracksData is Map<String, dynamic>) {
      tracks.add(OnvifRecordingTrack.fromXml(tracksData));
    }

    return OnvifRecordingJob(
      jobToken: xml['JobToken']?.toString() ?? '',
      recordingToken: config['RecordingToken']?.toString() ?? '',
      mode: config['Mode']?.toString() ?? '',
      priority: int.tryParse(config['Priority']?.toString() ?? '0') ?? 0,
      sourceToken: sourceToken['Token']?.toString() ?? '',
      tracks: tracks,
      state: state,
    );
  }

  @override
  String toString() =>
      'OnvifRecordingJob(token: $jobToken, state: $state, tracks: ${tracks.length})';
}

/// ONVIF Recording Track Model
class OnvifRecordingTrack {
  final String sourceTag;
  final String destination;

  const OnvifRecordingTrack({
    required this.sourceTag,
    required this.destination,
  });

  factory OnvifRecordingTrack.fromXml(Map<String, dynamic> xml) {
    return OnvifRecordingTrack(
      sourceTag: xml['SourceTag']?.toString() ?? '',
      destination: xml['Destination']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'OnvifRecordingTrack($sourceTag → $destination)';
}

/// ONVIF Recording Segment Model
class OnvifRecordingSegment {
  final String recordingToken;
  final String jobToken;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String? replayUri;
  final String? profileToken;
  final List<OnvifRecordingTrack> tracks;
  final String state;

  const OnvifRecordingSegment({
    required this.recordingToken,
    required this.jobToken,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.replayUri,
    this.profileToken,
    this.tracks = const [],
    required this.state,
  });

  /// Format duration as human readable
  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Format time range as human readable
  String get timeRangeString {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:${startTime.second.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:${endTime.second.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  @override
  String toString() =>
      'OnvifRecordingSegment(${timeRangeString}, ${durationString})';
}
