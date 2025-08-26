import '../client/transport.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF PTZ Service
/// Quản lý các operations liên quan đến PTZ (Pan/Tilt/Zoom)
class OnvifPtzService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = OnvifConstants.defaultPtzServicePath;

  OnvifPtzService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  /// PTZ Continuous Move
  Future<void> continuousMove({
    required String profileToken,
    required double panVelocity,
    required double tiltVelocity,
    double zoomVelocity = 0.0,
    Duration? timeout,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildContinuousMoveBody(
                profileToken,
                panVelocity,
                tiltVelocity,
                zoomVelocity,
                timeout,
              ),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.ptzNamespace}/ContinuousMove',
              headers: {
                'tptz': OnvifConstants.ptzNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            )
          : OnvifRequestBuilder.createPtzContinuousMoveRequest(
              profileToken: profileToken,
              panVelocity: panVelocity,
              tiltVelocity: tiltVelocity,
              zoomVelocity: zoomVelocity,
              timeout: timeout,
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.ptzNamespace}/ContinuousMove',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifPtzException(
        'Failed to execute continuous move: $e',
        originalError: e,
      );
    }
  }

  /// PTZ Stop
  Future<void> stop({
    required String profileToken,
    bool stopPanTilt = true,
    bool stopZoom = true,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildStopBody(profileToken, stopPanTilt, stopZoom),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.ptzNamespace}/Stop',
              headers: {'tptz': OnvifConstants.ptzNamespace},
            )
          : OnvifRequestBuilder.createPtzStopRequest(
              profileToken: profileToken,
              stopPanTilt: stopPanTilt,
              stopZoom: stopZoom,
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.ptzNamespace}/Stop',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifPtzException(
        'Failed to stop PTZ: $e',
        originalError: e,
      );
    }
  }

  /// PTZ Relative Move
  Future<void> relativeMove({
    required String profileToken,
    required double panTranslation,
    required double tiltTranslation,
    double zoomTranslation = 0.0,
    double? panSpeed,
    double? tiltSpeed,
    double? zoomSpeed,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildRelativeMoveBody(
                profileToken,
                panTranslation,
                tiltTranslation,
                zoomTranslation,
                panSpeed,
                tiltSpeed,
                zoomSpeed,
              ),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.ptzNamespace}/RelativeMove',
              headers: {
                'tptz': OnvifConstants.ptzNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body: _buildRelativeMoveBody(
                profileToken,
                panTranslation,
                tiltTranslation,
                zoomTranslation,
                panSpeed,
                tiltSpeed,
                zoomSpeed,
              ),
              action: '${OnvifConstants.ptzNamespace}/RelativeMove',
              headers: {
                'tptz': OnvifConstants.ptzNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.ptzNamespace}/RelativeMove',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifPtzException(
        'Failed to execute relative move: $e',
        originalError: e,
      );
    }
  }

  /// PTZ Absolute Move
  Future<void> absoluteMove({
    required String profileToken,
    required double panPosition,
    required double tiltPosition,
    double zoomPosition = 0.0,
    double? panSpeed,
    double? tiltSpeed,
    double? zoomSpeed,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildAbsoluteMoveBody(
                profileToken,
                panPosition,
                tiltPosition,
                zoomPosition,
                panSpeed,
                tiltSpeed,
                zoomSpeed,
              ),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.ptzNamespace}/AbsoluteMove',
              headers: {
                'tptz': OnvifConstants.ptzNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body: _buildAbsoluteMoveBody(
                profileToken,
                panPosition,
                tiltPosition,
                zoomPosition,
                panSpeed,
                tiltSpeed,
                zoomSpeed,
              ),
              action: '${OnvifConstants.ptzNamespace}/AbsoluteMove',
              headers: {
                'tptz': OnvifConstants.ptzNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.ptzNamespace}/AbsoluteMove',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifPtzException(
        'Failed to execute absolute move: $e',
        originalError: e,
      );
    }
  }

  /// Lấy PTZ Status
  Future<Map<String, dynamic>> getStatus(String profileToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tptz:GetStatus xmlns:tptz="${OnvifConstants.ptzNamespace}"><tptz:ProfileToken>$profileToken</tptz:ProfileToken></tptz:GetStatus>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.ptzNamespace}/GetStatus',
              headers: {'tptz': OnvifConstants.ptzNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tptz:GetStatus xmlns:tptz="${OnvifConstants.ptzNamespace}"><tptz:ProfileToken>$profileToken</tptz:ProfileToken></tptz:GetStatus>',
              action: '${OnvifConstants.ptzNamespace}/GetStatus',
              headers: {'tptz': OnvifConstants.ptzNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.ptzNamespace}/GetStatus',
      );

      final parsed =
          OnvifResponseParser.parsePtzResponse(response, 'GetStatus');
      return parsed['PTZStatus'] ?? {};
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifPtzException(
        'Failed to get PTZ status: $e',
        originalError: e,
      );
    }
  }

  /// Lấy PTZ Configuration Options
  Future<Map<String, dynamic>> getConfigurationOptions(
      String configurationToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tptz:GetConfigurationOptions xmlns:tptz="${OnvifConstants.ptzNamespace}"><tptz:ConfigurationToken>$configurationToken</tptz:ConfigurationToken></tptz:GetConfigurationOptions>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.ptzNamespace}/GetConfigurationOptions',
              headers: {'tptz': OnvifConstants.ptzNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tptz:GetConfigurationOptions xmlns:tptz="${OnvifConstants.ptzNamespace}"><tptz:ConfigurationToken>$configurationToken</tptz:ConfigurationToken></tptz:GetConfigurationOptions>',
              action: '${OnvifConstants.ptzNamespace}/GetConfigurationOptions',
              headers: {'tptz': OnvifConstants.ptzNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.ptzNamespace}/GetConfigurationOptions',
      );

      final parsed = OnvifResponseParser.parsePtzResponse(
          response, 'GetConfigurationOptions');
      return parsed['PTZConfigurationOptions'] ?? {};
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifPtzException(
        'Failed to get PTZ configuration options: $e',
        originalError: e,
      );
    }
  }

  /// Helper methods
  bool get _hasCredentials => _username != null && _password != null;

  String _buildContinuousMoveBody(
    String profileToken,
    double panVelocity,
    double tiltVelocity,
    double zoomVelocity,
    Duration? timeout,
  ) {
    final timeoutValue = timeout?.inSeconds ?? 10;

    return '''
<tptz:ContinuousMove xmlns:tptz="${OnvifConstants.ptzNamespace}">
  <tptz:ProfileToken>$profileToken</tptz:ProfileToken>
  <tptz:Velocity>
    <tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="$panVelocity" y="$tiltVelocity"/>
    <tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomVelocity"/>
  </tptz:Velocity>
  <tptz:Timeout>PT${timeoutValue}S</tptz:Timeout>
</tptz:ContinuousMove>''';
  }

  String _buildStopBody(String profileToken, bool stopPanTilt, bool stopZoom) {
    return '''
<tptz:Stop xmlns:tptz="${OnvifConstants.ptzNamespace}">
  <tptz:ProfileToken>$profileToken</tptz:ProfileToken>
  <tptz:PanTilt>$stopPanTilt</tptz:PanTilt>
  <tptz:Zoom>$stopZoom</tptz:Zoom>
</tptz:Stop>''';
  }

  String _buildRelativeMoveBody(
    String profileToken,
    double panTranslation,
    double tiltTranslation,
    double zoomTranslation,
    double? panSpeed,
    double? tiltSpeed,
    double? zoomSpeed,
  ) {
    final buffer = StringBuffer();
    buffer.write(
        '<tptz:RelativeMove xmlns:tptz="${OnvifConstants.ptzNamespace}">');
    buffer.write('<tptz:ProfileToken>$profileToken</tptz:ProfileToken>');
    buffer.write('<tptz:Translation>');
    buffer.write(
        '<tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="$panTranslation" y="$tiltTranslation"/>');
    buffer.write(
        '<tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomTranslation"/>');
    buffer.write('</tptz:Translation>');

    if (panSpeed != null || tiltSpeed != null || zoomSpeed != null) {
      buffer.write('<tptz:Speed>');
      if (panSpeed != null || tiltSpeed != null) {
        buffer.write(
            '<tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="${panSpeed ?? 0}" y="${tiltSpeed ?? 0}"/>');
      }
      if (zoomSpeed != null) {
        buffer.write(
            '<tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomSpeed"/>');
      }
      buffer.write('</tptz:Speed>');
    }

    buffer.write('</tptz:RelativeMove>');
    return buffer.toString();
  }

  String _buildAbsoluteMoveBody(
    String profileToken,
    double panPosition,
    double tiltPosition,
    double zoomPosition,
    double? panSpeed,
    double? tiltSpeed,
    double? zoomSpeed,
  ) {
    final buffer = StringBuffer();
    buffer.write(
        '<tptz:AbsoluteMove xmlns:tptz="${OnvifConstants.ptzNamespace}">');
    buffer.write('<tptz:ProfileToken>$profileToken</tptz:ProfileToken>');
    buffer.write('<tptz:Position>');
    buffer.write(
        '<tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="$panPosition" y="$tiltPosition"/>');
    buffer.write(
        '<tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomPosition"/>');
    buffer.write('</tptz:Position>');

    if (panSpeed != null || tiltSpeed != null || zoomSpeed != null) {
      buffer.write('<tptz:Speed>');
      if (panSpeed != null || tiltSpeed != null) {
        buffer.write(
            '<tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="${panSpeed ?? 0}" y="${tiltSpeed ?? 0}"/>');
      }
      if (zoomSpeed != null) {
        buffer.write(
            '<tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomSpeed"/>');
      }
      buffer.write('</tptz:Speed>');
    }

    buffer.write('</tptz:AbsoluteMove>');
    return buffer.toString();
  }
}
