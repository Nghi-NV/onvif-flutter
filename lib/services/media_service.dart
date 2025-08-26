import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../client/transport.dart';
import '../models/media_profile.dart';
import '../models/stream_uri.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Media Service
/// Quản lý các operations liên quan đến media (video/audio streams, profiles, snapshots)
class OnvifMediaService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = OnvifConstants.defaultMediaServicePath;

  OnvifMediaService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  /// Lấy tất cả media profiles
  Future<List<OnvifMediaProfile>> getProfiles() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trt:GetProfiles xmlns:trt="${OnvifConstants.mediaNamespace}"/>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/GetProfiles',
              headers: {'trt': OnvifConstants.mediaNamespace},
            )
          : OnvifRequestBuilder.createGetProfilesRequest();

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/GetProfiles',
      );

      final profilesData =
          OnvifResponseParser.parseGetProfilesResponse(response);

      return profilesData
          .map((data) => OnvifMediaProfile.fromXml(data))
          .toList();
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get profiles: $e',
        originalError: e,
      );
    }
  }

  /// Lấy stream URI cho profile
  Future<OnvifStreamUri> getStreamUri({
    required String profileToken,
    StreamProtocol protocol = StreamProtocol.rtsp,
  }) async {
    try {
      final protocolString = _getProtocolString(protocol);

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildGetStreamUriBody(profileToken, protocolString),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/GetStreamUri',
              headers: {
                'trt': OnvifConstants.mediaNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            )
          : OnvifRequestBuilder.createGetStreamUriRequest(
              profileToken: profileToken,
              protocol: protocolString,
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/GetStreamUri',
      );

      final streamData =
          OnvifResponseParser.parseGetStreamUriResponse(response);

      return OnvifStreamUri.fromXml(streamData);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifStreamException(
        'Failed to get stream URI: $e',
        originalError: e,
      );
    }
  }

  /// Lấy snapshot URI cho profile
  Future<OnvifSnapshotUri> getSnapshotUri(String profileToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trt:GetSnapshotUri xmlns:trt="${OnvifConstants.mediaNamespace}"><trt:ProfileToken>$profileToken</trt:ProfileToken></trt:GetSnapshotUri>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/GetSnapshotUri',
              headers: {'trt': OnvifConstants.mediaNamespace},
            )
          : OnvifRequestBuilder.createGetSnapshotUriRequest(profileToken);

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/GetSnapshotUri',
      );

      final snapshotData =
          OnvifResponseParser.parseGetSnapshotUriResponse(response);

      return OnvifSnapshotUri.fromXml(snapshotData);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifStreamException(
        'Failed to get snapshot URI: $e',
        originalError: e,
      );
    }
  }

  /// Chụp snapshot và trả về bytes
  Future<Uint8List> captureSnapshot(String profileToken) async {
    try {
      final snapshotUri = await getSnapshotUri(profileToken);

      if (!snapshotUri.isValid) {
        throw OnvifStreamException('Invalid snapshot URI: ${snapshotUri.uri}');
      }

      // Tạo URI với credentials nếu có
      String finalUri = snapshotUri.uri;
      if (_hasCredentials) {
        finalUri = snapshotUri.withCredentials(_username!, _password!);
      }

      final response = await _transport.sendGetRequest(
        path: finalUri,
        responseType: ResponseType.bytes,
      );

      if (response.statusCode != 200) {
        throw OnvifStreamException(
          'Failed to capture snapshot: HTTP ${response.statusCode}',
          streamUri: finalUri,
        );
      }

      return Uint8List.fromList(response.data);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifStreamException(
        'Failed to capture snapshot: $e',
        originalError: e,
      );
    }
  }

  /// Lấy video sources
  Future<List<Map<String, dynamic>>> getVideoSources() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trt:GetVideoSources xmlns:trt="${OnvifConstants.mediaNamespace}"/>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/GetVideoSources',
              headers: {'trt': OnvifConstants.mediaNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trt:GetVideoSources xmlns:trt="${OnvifConstants.mediaNamespace}"/>',
              action: '${OnvifConstants.mediaNamespace}/GetVideoSources',
              headers: {'trt': OnvifConstants.mediaNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/GetVideoSources',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _parseVideoSources(parsed);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get video sources: $e',
        originalError: e,
      );
    }
  }

  /// Lấy audio sources
  Future<List<Map<String, dynamic>>> getAudioSources() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trt:GetAudioSources xmlns:trt="${OnvifConstants.mediaNamespace}"/>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/GetAudioSources',
              headers: {'trt': OnvifConstants.mediaNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trt:GetAudioSources xmlns:trt="${OnvifConstants.mediaNamespace}"/>',
              action: '${OnvifConstants.mediaNamespace}/GetAudioSources',
              headers: {'trt': OnvifConstants.mediaNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/GetAudioSources',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _parseAudioSources(parsed);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get audio sources: $e',
        originalError: e,
      );
    }
  }

  /// Tạo profile mới
  Future<String> createProfile({
    required String name,
    String? token,
  }) async {
    try {
      final profileToken =
          token ?? 'Profile_${DateTime.now().millisecondsSinceEpoch}';

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trt:CreateProfile xmlns:trt="${OnvifConstants.mediaNamespace}"><trt:Name>$name</trt:Name><trt:Token>$profileToken</trt:Token></trt:CreateProfile>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/CreateProfile',
              headers: {'trt': OnvifConstants.mediaNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trt:CreateProfile xmlns:trt="${OnvifConstants.mediaNamespace}"><trt:Name>$name</trt:Name><trt:Token>$profileToken</trt:Token></trt:CreateProfile>',
              action: '${OnvifConstants.mediaNamespace}/CreateProfile',
              headers: {'trt': OnvifConstants.mediaNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/CreateProfile',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final profileData = _findInResponse(parsed, 'Profile');

      return profileData?['token'] ?? profileToken;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to create profile: $e',
        originalError: e,
      );
    }
  }

  /// Xóa profile
  Future<void> deleteProfile(String profileToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<trt:DeleteProfile xmlns:trt="${OnvifConstants.mediaNamespace}"><trt:ProfileToken>$profileToken</trt:ProfileToken></trt:DeleteProfile>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.mediaNamespace}/DeleteProfile',
              headers: {'trt': OnvifConstants.mediaNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<trt:DeleteProfile xmlns:trt="${OnvifConstants.mediaNamespace}"><trt:ProfileToken>$profileToken</trt:ProfileToken></trt:DeleteProfile>',
              action: '${OnvifConstants.mediaNamespace}/DeleteProfile',
              headers: {'trt': OnvifConstants.mediaNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.mediaNamespace}/DeleteProfile',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to delete profile: $e',
        originalError: e,
      );
    }
  }

  /// Helper methods
  bool get _hasCredentials => _username != null && _password != null;

  String _getProtocolString(StreamProtocol protocol) {
    switch (protocol) {
      case StreamProtocol.rtsp:
        return 'RTSP';
      case StreamProtocol.http:
        return 'HTTP';
      case StreamProtocol.https:
        return 'HTTPS';
      case StreamProtocol.tcp:
        return 'TCP';
      case StreamProtocol.udp:
        return 'UDP';
    }
  }

  String _buildGetStreamUriBody(String profileToken, String protocol) {
    return '''
<trt:GetStreamUri xmlns:trt="${OnvifConstants.mediaNamespace}">
  <trt:StreamSetup>
    <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
    <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
      <tt:Protocol>$protocol</tt:Protocol>
    </tt:Transport>
  </trt:StreamSetup>
  <trt:ProfileToken>$profileToken</trt:ProfileToken>
</trt:GetStreamUri>''';
  }

  List<Map<String, dynamic>> _parseVideoSources(Map<String, dynamic> parsed) {
    final sources = <Map<String, dynamic>>[];

    final videoSources = _findInResponse(parsed, 'VideoSources');
    if (videoSources != null) {
      if (videoSources is List) {
        sources.addAll(videoSources.cast<Map<String, dynamic>>());
      } else if (videoSources is Map<String, dynamic>) {
        sources.add(videoSources);
      }
    }

    return sources;
  }

  List<Map<String, dynamic>> _parseAudioSources(Map<String, dynamic> parsed) {
    final sources = <Map<String, dynamic>>[];

    final audioSources = _findInResponse(parsed, 'AudioSources');
    if (audioSources != null) {
      if (audioSources is List) {
        sources.addAll(audioSources.cast<Map<String, dynamic>>());
      } else if (audioSources is Map<String, dynamic>) {
        sources.add(audioSources);
      }
    }

    return sources;
  }

  dynamic _findInResponse(Map<String, dynamic> data, String key) {
    // Đệ quy tìm kiếm key trong response
    for (final k in data.keys) {
      final value = data[k];

      if (k == key) return value;

      if (value is Map<String, dynamic>) {
        final found = _findInResponse(value, key);
        if (found != null) return found;
      }

      if (value is List) {
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
