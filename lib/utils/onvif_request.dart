import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'constants.dart';

/// ONVIF Request Builder
/// Xây dựng SOAP requests cho ONVIF services
class OnvifRequestBuilder {
  static const Uuid _uuid = Uuid();

  /// Tạo SOAP envelope cơ bản
  static String createSoapEnvelope({
    required String body,
    String? action,
    Map<String, String>? headers,
    bool includeAddressing = true,
  }) {
    final messageId = _uuid.v4();
    final replyTo = 'http://www.w3.org/2005/08/addressing/anonymous';

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.write('<soap:Envelope');
    buffer.write(' xmlns:soap="${OnvifConstants.soapEnvNamespace}"');

    if (includeAddressing) {
      buffer.write(' xmlns:wsa="${OnvifConstants.wsAddressingNamespace}"');
    }

    // Thêm các namespace khác nếu cần
    if (headers != null) {
      headers.forEach((key, value) {
        buffer.write(' xmlns:$key="$value"');
      });
    }

    buffer.writeln('>');

    // SOAP Header
    if (includeAddressing || action != null) {
      buffer.writeln('<soap:Header>');

      if (includeAddressing) {
        buffer.writeln('<wsa:MessageID>urn:uuid:$messageId</wsa:MessageID>');
        buffer.writeln(
            '<wsa:ReplyTo><wsa:Address>$replyTo</wsa:Address></wsa:ReplyTo>');
        buffer.writeln(
            '<wsa:To>http://www.w3.org/2005/08/addressing/anonymous</wsa:To>');
      }

      if (action != null) {
        buffer.writeln('<wsa:Action>$action</wsa:Action>');
      }

      buffer.writeln('</soap:Header>');
    }

    // SOAP Body
    buffer.writeln('<soap:Body>');
    buffer.writeln(body);
    buffer.writeln('</soap:Body>');
    buffer.writeln('</soap:Envelope>');

    return buffer.toString();
  }

  /// Tạo SOAP envelope với WS-Security authentication
  static String createSecureSoapEnvelope({
    required String body,
    required String username,
    required String password,
    String? action,
    Map<String, String>? headers,
    bool includeAddressing = true,
  }) {
    final messageId = _uuid.v4();
    final replyTo = 'http://www.w3.org/2005/08/addressing/anonymous';
    final securityHeader = _createWsSecurityHeader(username, password);

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.write('<soap:Envelope');
    buffer.write(' xmlns:soap="${OnvifConstants.soapEnvNamespace}"');
    buffer.write(' xmlns:wsse="${OnvifConstants.wsSecurityNamespace}"');

    if (includeAddressing) {
      buffer.write(' xmlns:wsa="${OnvifConstants.wsAddressingNamespace}"');
    }

    // Thêm các namespace khác nếu cần
    if (headers != null) {
      headers.forEach((key, value) {
        buffer.write(' xmlns:$key="$value"');
      });
    }

    buffer.writeln('>');

    // SOAP Header với Security
    buffer.writeln('<soap:Header>');
    buffer.writeln(securityHeader);

    if (includeAddressing) {
      buffer.writeln('<wsa:MessageID>urn:uuid:$messageId</wsa:MessageID>');
      buffer.writeln(
          '<wsa:ReplyTo><wsa:Address>$replyTo</wsa:Address></wsa:ReplyTo>');
      buffer.writeln(
          '<wsa:To>http://www.w3.org/2005/08/addressing/anonymous</wsa:To>');
    }

    if (action != null) {
      buffer.writeln('<wsa:Action>$action</wsa:Action>');
    }

    buffer.writeln('</soap:Header>');

    // SOAP Body
    buffer.writeln('<soap:Body>');
    buffer.writeln(body);
    buffer.writeln('</soap:Body>');
    buffer.writeln('</soap:Envelope>');

    return buffer.toString();
  }

  /// Tạo WS-Security header với Username Token Profile
  static String _createWsSecurityHeader(String username, String password) {
    final nonce = _generateNonce();
    final created = _getCurrentUtcTime();
    final passwordDigest = _calculatePasswordDigest(password, nonce, created);

    return '''
<wsse:Security soap:mustUnderstand="1">
  <wsse:UsernameToken>
    <wsse:Username>$username</wsse:Username>
    <wsse:Password Type="${OnvifConstants.wsUsernameTokenNamespace}">$passwordDigest</wsse:Password>
    <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">$nonce</wsse:Nonce>
    <wsu:Created xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">$created</wsu:Created>
  </wsse:UsernameToken>
</wsse:Security>''';
  }

  /// Sinh nonce ngẫu nhiên
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Lấy thời gian UTC hiện tại theo định dạng ISO8601
  static String _getCurrentUtcTime() {
    final now = DateTime.now().toUtc();
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(now);
  }

  /// Tính toán password digest theo WS-Security spec
  static String _calculatePasswordDigest(
      String password, String nonce, String created) {
    final nonceBytes = base64Decode(nonce);
    final createdBytes = utf8.encode(created);
    final passwordBytes = utf8.encode(password);

    final combined = <int>[]
      ..addAll(nonceBytes)
      ..addAll(createdBytes)
      ..addAll(passwordBytes);

    final digest = sha1.convert(combined);
    return base64Encode(digest.bytes);
  }

  /// Tạo GetDeviceInformation request
  static String createGetDeviceInformationRequest() {
    const body =
        '<tds:GetDeviceInformation xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>';
    return createSoapEnvelope(
      body: body,
      action:
          '${OnvifConstants.deviceManagementNamespace}/GetDeviceInformation',
      headers: {'tds': OnvifConstants.deviceManagementNamespace},
    );
  }

  /// Tạo GetCapabilities request
  static String createGetCapabilitiesRequest({List<String>? categories}) {
    final buffer = StringBuffer();
    buffer.write(
        '<tds:GetCapabilities xmlns:tds="${OnvifConstants.deviceManagementNamespace}">');

    if (categories != null && categories.isNotEmpty) {
      for (final category in categories) {
        buffer.write('<tds:Category>$category</tds:Category>');
      }
    }

    buffer.write('</tds:GetCapabilities>');

    return createSoapEnvelope(
      body: buffer.toString(),
      action: '${OnvifConstants.deviceManagementNamespace}/GetCapabilities',
      headers: {'tds': OnvifConstants.deviceManagementNamespace},
    );
  }

  /// Tạo GetProfiles request
  static String createGetProfilesRequest() {
    const body =
        '<trt:GetProfiles xmlns:trt="${OnvifConstants.mediaNamespace}"/>';
    return createSoapEnvelope(
      body: body,
      action: '${OnvifConstants.mediaNamespace}/GetProfiles',
      headers: {'trt': OnvifConstants.mediaNamespace},
    );
  }

  /// Tạo GetStreamUri request
  static String createGetStreamUriRequest({
    required String profileToken,
    String protocol = 'RTSP',
  }) {
    final body = '''
<trt:GetStreamUri xmlns:trt="${OnvifConstants.mediaNamespace}">
  <trt:StreamSetup>
    <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
    <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
      <tt:Protocol>$protocol</tt:Protocol>
    </tt:Transport>
  </trt:StreamSetup>
  <trt:ProfileToken>$profileToken</trt:ProfileToken>
</trt:GetStreamUri>''';

    return createSoapEnvelope(
      body: body,
      action: '${OnvifConstants.mediaNamespace}/GetStreamUri',
      headers: {
        'trt': OnvifConstants.mediaNamespace,
        'tt': 'http://www.onvif.org/ver10/schema',
      },
    );
  }

  /// Tạo GetSnapshotUri request
  static String createGetSnapshotUriRequest(String profileToken) {
    final body = '''
<trt:GetSnapshotUri xmlns:trt="${OnvifConstants.mediaNamespace}">
  <trt:ProfileToken>$profileToken</trt:ProfileToken>
</trt:GetSnapshotUri>''';

    return createSoapEnvelope(
      body: body,
      action: '${OnvifConstants.mediaNamespace}/GetSnapshotUri',
      headers: {'trt': OnvifConstants.mediaNamespace},
    );
  }

  /// Tạo PTZ ContinuousMove request
  static String createPtzContinuousMoveRequest({
    required String profileToken,
    required double panVelocity,
    required double tiltVelocity,
    required double zoomVelocity,
    Duration? timeout,
  }) {
    final timeoutValue = timeout?.inSeconds ?? 10;

    final body = '''
<tptz:ContinuousMove xmlns:tptz="${OnvifConstants.ptzNamespace}">
  <tptz:ProfileToken>$profileToken</tptz:ProfileToken>
  <tptz:Velocity>
    <tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="$panVelocity" y="$tiltVelocity"/>
    <tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomVelocity"/>
  </tptz:Velocity>
  <tptz:Timeout>PT${timeoutValue}S</tptz:Timeout>
</tptz:ContinuousMove>''';

    return createSoapEnvelope(
      body: body,
      action: '${OnvifConstants.ptzNamespace}/ContinuousMove',
      headers: {
        'tptz': OnvifConstants.ptzNamespace,
        'tt': 'http://www.onvif.org/ver10/schema',
      },
    );
  }

  /// Tạo PTZ Stop request
  static String createPtzStopRequest({
    required String profileToken,
    bool stopPanTilt = true,
    bool stopZoom = true,
  }) {
    final body = '''
<tptz:Stop xmlns:tptz="${OnvifConstants.ptzNamespace}">
  <tptz:ProfileToken>$profileToken</tptz:ProfileToken>
  <tptz:PanTilt>$stopPanTilt</tptz:PanTilt>
  <tptz:Zoom>$stopZoom</tptz:Zoom>
</tptz:Stop>''';

    return createSoapEnvelope(
      body: body,
      action: '${OnvifConstants.ptzNamespace}/Stop',
      headers: {'tptz': OnvifConstants.ptzNamespace},
    );
  }
}
