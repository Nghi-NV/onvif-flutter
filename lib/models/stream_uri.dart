import '../utils/constants.dart';

/// Stream URI Model
/// Đại diện cho URI của stream từ ONVIF device
class OnvifStreamUri {
  final String uri;
  final StreamProtocol protocol;
  final bool invalidAfterConnect;
  final bool invalidAfterReboot;
  final Duration? timeout;
  final Map<String, String> headers;

  const OnvifStreamUri({
    required this.uri,
    this.protocol = StreamProtocol.rtsp,
    this.invalidAfterConnect = false,
    this.invalidAfterReboot = false,
    this.timeout,
    this.headers = const {},
  });

  factory OnvifStreamUri.fromXml(Map<String, dynamic> xml) {
    final uriString = xml['Uri']?.toString() ?? '';
    final protocol = _parseProtocol(uriString);

    return OnvifStreamUri(
      uri: uriString,
      protocol: protocol,
      invalidAfterConnect: _parseBool(xml['InvalidAfterConnect']),
      invalidAfterReboot: _parseBool(xml['InvalidAfterReboot']),
      timeout: _parseDuration(xml['Timeout']),
      headers: _parseHeaders(xml['Headers']),
    );
  }

  static StreamProtocol _parseProtocol(String uri) {
    if (uri.startsWith('rtsp://')) return StreamProtocol.rtsp;
    if (uri.startsWith('https://')) return StreamProtocol.https;
    if (uri.startsWith('http://')) return StreamProtocol.http;
    if (uri.contains('tcp')) return StreamProtocol.tcp;
    if (uri.contains('udp')) return StreamProtocol.udp;
    return StreamProtocol.rtsp; // default
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  static Duration? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is Duration) return value;

    final str = value.toString();
    if (str.startsWith('PT') && str.endsWith('S')) {
      final seconds = int.tryParse(str.substring(2, str.length - 1));
      return seconds != null ? Duration(seconds: seconds) : null;
    }

    final seconds = int.tryParse(str);
    return seconds != null ? Duration(seconds: seconds) : null;
  }

  static Map<String, String> _parseHeaders(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, String>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  /// Kiểm tra xem URI có hợp lệ không
  bool get isValid => uri.isNotEmpty && Uri.tryParse(uri) != null;

  /// Lấy scheme của URI (rtsp, http, https, etc.)
  String? get scheme => Uri.tryParse(uri)?.scheme;

  /// Lấy host từ URI
  String? get host => Uri.tryParse(uri)?.host;

  /// Lấy port từ URI
  int? get port => Uri.tryParse(uri)?.port;

  /// Lấy path từ URI
  String? get path => Uri.tryParse(uri)?.path;

  /// Lấy query parameters từ URI
  Map<String, String> get queryParameters =>
      Uri.tryParse(uri)?.queryParameters ?? {};

  /// Kiểm tra xem có phải là RTSP stream không
  bool get isRtsp => protocol == StreamProtocol.rtsp || scheme == 'rtsp';

  /// Kiểm tra xem có phải là HTTP stream không
  bool get isHttp => protocol == StreamProtocol.http || scheme == 'http';

  /// Kiểm tra xem có phải là HTTPS stream không
  bool get isHttps => protocol == StreamProtocol.https || scheme == 'https';

  /// Kiểm tra xem có phải là TCP transport không
  bool get isTcp => protocol == StreamProtocol.tcp;

  /// Kiểm tra xem có phải là UDP transport không
  bool get isUdp => protocol == StreamProtocol.udp;

  /// Tạo URI với credentials
  String withCredentials(String username, String password) {
    final parsedUri = Uri.tryParse(uri);
    if (parsedUri == null) return uri;

    final newUri = parsedUri.replace(
      userInfo: '$username:$password',
    );

    return newUri.toString();
  }

  /// Tạo URI với query parameters bổ sung
  String withQueryParameters(Map<String, String> additionalParams) {
    final parsedUri = Uri.tryParse(uri);
    if (parsedUri == null) return uri;

    final newQueryParams = <String, String>{
      ...parsedUri.queryParameters,
      ...additionalParams,
    };

    final newUri = parsedUri.replace(queryParameters: newQueryParams);
    return newUri.toString();
  }

  @override
  String toString() => 'OnvifStreamUri(uri: $uri, protocol: $protocol)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifStreamUri && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;
}

/// Snapshot URI Model
/// Đại diện cho URI để lấy snapshot từ ONVIF device
class OnvifSnapshotUri {
  final String uri;
  final bool invalidAfterConnect;
  final bool invalidAfterReboot;
  final Duration? timeout;
  final Map<String, String> headers;

  const OnvifSnapshotUri({
    required this.uri,
    this.invalidAfterConnect = false,
    this.invalidAfterReboot = false,
    this.timeout,
    this.headers = const {},
  });

  factory OnvifSnapshotUri.fromXml(Map<String, dynamic> xml) {
    return OnvifSnapshotUri(
      uri: xml['Uri']?.toString() ?? '',
      invalidAfterConnect:
          OnvifStreamUri._parseBool(xml['InvalidAfterConnect']),
      invalidAfterReboot: OnvifStreamUri._parseBool(xml['InvalidAfterReboot']),
      timeout: OnvifStreamUri._parseDuration(xml['Timeout']),
      headers: OnvifStreamUri._parseHeaders(xml['Headers']),
    );
  }

  /// Kiểm tra xem URI có hợp lệ không
  bool get isValid => uri.isNotEmpty && Uri.tryParse(uri) != null;

  /// Lấy scheme của URI
  String? get scheme => Uri.tryParse(uri)?.scheme;

  /// Lấy host từ URI
  String? get host => Uri.tryParse(uri)?.host;

  /// Lấy port từ URI
  int? get port => Uri.tryParse(uri)?.port;

  /// Lấy path từ URI
  String? get path => Uri.tryParse(uri)?.path;

  /// Kiểm tra xem có phải là HTTPS không
  bool get isHttps => scheme == 'https';

  /// Tạo URI với credentials
  String withCredentials(String username, String password) {
    final parsedUri = Uri.tryParse(uri);
    if (parsedUri == null) return uri;

    final newUri = parsedUri.replace(
      userInfo: '$username:$password',
    );

    return newUri.toString();
  }

  /// Tạo URI với query parameters bổ sung
  String withQueryParameters(Map<String, String> additionalParams) {
    final parsedUri = Uri.tryParse(uri);
    if (parsedUri == null) return uri;

    final newQueryParams = <String, String>{
      ...parsedUri.queryParameters,
      ...additionalParams,
    };

    final newUri = parsedUri.replace(queryParameters: newQueryParams);
    return newUri.toString();
  }

  @override
  String toString() => 'OnvifSnapshotUri(uri: $uri)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifSnapshotUri && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;
}

/// Stream Setup Model
/// Cấu hình cho stream setup request
class StreamSetup {
  final String stream;
  final String protocol;
  final String? unicastAddress;
  final int? multicastPort;
  final String? multicastAddress;
  final int? multicastTtl;
  final bool? autoStart;

  const StreamSetup({
    required this.stream,
    required this.protocol,
    this.unicastAddress,
    this.multicastPort,
    this.multicastAddress,
    this.multicastTtl,
    this.autoStart,
  });

  factory StreamSetup.rtspUnicast({String? unicastAddress}) {
    return StreamSetup(
      stream: OnvifConstants.rtspStreamType,
      protocol: 'RTSP',
      unicastAddress: unicastAddress,
    );
  }

  factory StreamSetup.httpUnicast({String? unicastAddress}) {
    return StreamSetup(
      stream: OnvifConstants.httpStreamType,
      protocol: 'HTTP',
      unicastAddress: unicastAddress,
    );
  }

  factory StreamSetup.multicast({
    required String address,
    required int port,
    int ttl = 64,
    bool autoStart = false,
  }) {
    return StreamSetup(
      stream: OnvifConstants.rtspStreamType,
      protocol: 'RTSP',
      multicastAddress: address,
      multicastPort: port,
      multicastTtl: ttl,
      autoStart: autoStart,
    );
  }

  /// Chuyển đổi thành XML cho SOAP request
  String toXml() {
    final buffer = StringBuffer();
    buffer.write(
        '<tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">$stream</tt:Stream>');
    buffer.write('<tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">');
    buffer.write('<tt:Protocol>$protocol</tt:Protocol>');

    if (unicastAddress != null) {
      buffer.write(
          '<tt:Tunnel><tt:IPv4Address>$unicastAddress</tt:IPv4Address></tt:Tunnel>');
    }

    if (multicastAddress != null && multicastPort != null) {
      buffer.write('<tt:Multicast>');
      buffer.write('<tt:IPv4Address>$multicastAddress</tt:IPv4Address>');
      buffer.write('<tt:Port>$multicastPort</tt:Port>');
      if (multicastTtl != null) {
        buffer.write('<tt:TTL>$multicastTtl</tt:TTL>');
      }
      if (autoStart != null) {
        buffer.write('<tt:AutoStart>$autoStart</tt:AutoStart>');
      }
      buffer.write('</tt:Multicast>');
    }

    buffer.write('</tt:Transport>');
    return buffer.toString();
  }

  @override
  String toString() => 'StreamSetup(stream: $stream, protocol: $protocol)';
}
