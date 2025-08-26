import '../utils/constants.dart';

/// Media Profile Model
/// Đại diện cho một ONVIF media profile với các cấu hình video/audio
class OnvifMediaProfile {
  final String token;
  final String name;
  final bool fixed;
  final VideoSourceConfiguration? videoSourceConfiguration;
  final AudioSourceConfiguration? audioSourceConfiguration;
  final VideoEncoderConfiguration? videoEncoderConfiguration;
  final AudioEncoderConfiguration? audioEncoderConfiguration;
  final PtzConfiguration? ptzConfiguration;
  final VideoAnalyticsConfiguration? videoAnalyticsConfiguration;
  final MetadataConfiguration? metadataConfiguration;
  final List<Extension> extensions;

  const OnvifMediaProfile({
    required this.token,
    required this.name,
    this.fixed = false,
    this.videoSourceConfiguration,
    this.audioSourceConfiguration,
    this.videoEncoderConfiguration,
    this.audioEncoderConfiguration,
    this.ptzConfiguration,
    this.videoAnalyticsConfiguration,
    this.metadataConfiguration,
    this.extensions = const [],
  });

  factory OnvifMediaProfile.fromXml(Map<String, dynamic> xml) {
    return OnvifMediaProfile(
      token: xml['@token'] ?? xml['token'] ?? xml['Token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      fixed: _parseBool(xml['@fixed'] ?? xml['fixed']),
      videoSourceConfiguration: xml['VideoSourceConfiguration'] != null
          ? VideoSourceConfiguration.fromXml(xml['VideoSourceConfiguration'])
          : null,
      audioSourceConfiguration: xml['AudioSourceConfiguration'] != null
          ? AudioSourceConfiguration.fromXml(xml['AudioSourceConfiguration'])
          : null,
      videoEncoderConfiguration: xml['VideoEncoderConfiguration'] != null
          ? VideoEncoderConfiguration.fromXml(xml['VideoEncoderConfiguration'])
          : null,
      audioEncoderConfiguration: xml['AudioEncoderConfiguration'] != null
          ? AudioEncoderConfiguration.fromXml(xml['AudioEncoderConfiguration'])
          : null,
      ptzConfiguration: xml['PTZConfiguration'] != null
          ? PtzConfiguration.fromXml(xml['PTZConfiguration'])
          : null,
      videoAnalyticsConfiguration: xml['VideoAnalyticsConfiguration'] != null
          ? VideoAnalyticsConfiguration.fromXml(
              xml['VideoAnalyticsConfiguration'])
          : null,
      metadataConfiguration: xml['MetadataConfiguration'] != null
          ? MetadataConfiguration.fromXml(xml['MetadataConfiguration'])
          : null,
      extensions: _parseExtensions(xml['Extension']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  static List<Extension> _parseExtensions(dynamic extensionData) {
    if (extensionData == null) return [];

    final extensions = <Extension>[];
    if (extensionData is List) {
      for (final ext in extensionData) {
        if (ext is Map<String, dynamic>) {
          extensions.add(Extension.fromXml(ext));
        }
      }
    } else if (extensionData is Map<String, dynamic>) {
      extensions.add(Extension.fromXml(extensionData));
    }

    return extensions;
  }

  /// Kiểm tra xem profile có hỗ trợ video không
  bool get hasVideo =>
      videoSourceConfiguration != null || videoEncoderConfiguration != null;

  /// Kiểm tra xem profile có hỗ trợ audio không
  bool get hasAudio =>
      audioSourceConfiguration != null || audioEncoderConfiguration != null;

  /// Kiểm tra xem profile có hỗ trợ PTZ không
  bool get hasPtz => ptzConfiguration != null;

  /// Lấy resolution từ video encoder configuration
  VideoResolution? get videoResolution => videoEncoderConfiguration?.resolution;

  /// Lấy frame rate từ video encoder configuration
  double? get frameRate =>
      videoEncoderConfiguration?.rateControl?.frameRateLimit;

  /// Lấy bitrate từ video encoder configuration
  int? get bitRate => videoEncoderConfiguration?.rateControl?.bitrateLimit;

  @override
  String toString() {
    return 'OnvifMediaProfile(token: $token, name: $name, fixed: $fixed, '
        'hasVideo: $hasVideo, hasAudio: $hasAudio, hasPtz: $hasPtz)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifMediaProfile && other.token == token;
  }

  @override
  int get hashCode => token.hashCode;
}

/// Video Source Configuration
class VideoSourceConfiguration {
  final String token;
  final String name;
  final int useCount;
  final String sourceToken;
  final IntRectangle bounds;

  const VideoSourceConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    required this.sourceToken,
    required this.bounds,
  });

  factory VideoSourceConfiguration.fromXml(Map<String, dynamic> xml) {
    return VideoSourceConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      sourceToken: xml['SourceToken']?.toString() ?? '',
      bounds: IntRectangle.fromXml(xml['Bounds'] ?? {}),
    );
  }

  @override
  String toString() => 'VideoSourceConfiguration(token: $token, name: $name)';
}

/// Audio Source Configuration
class AudioSourceConfiguration {
  final String token;
  final String name;
  final int useCount;
  final String sourceToken;

  const AudioSourceConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    required this.sourceToken,
  });

  factory AudioSourceConfiguration.fromXml(Map<String, dynamic> xml) {
    return AudioSourceConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      sourceToken: xml['SourceToken']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'AudioSourceConfiguration(token: $token, name: $name)';
}

/// Video Encoder Configuration
class VideoEncoderConfiguration {
  final String token;
  final String name;
  final int useCount;
  final String encoding;
  final VideoResolution resolution;
  final VideoRateControl? rateControl;
  final H264Configuration? h264;
  final Multicast? multicast;
  final int sessionTimeout;

  const VideoEncoderConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    required this.encoding,
    required this.resolution,
    this.rateControl,
    this.h264,
    this.multicast,
    required this.sessionTimeout,
  });

  factory VideoEncoderConfiguration.fromXml(Map<String, dynamic> xml) {
    return VideoEncoderConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      encoding: xml['Encoding']?.toString() ?? OnvifConstants.h264Encoding,
      resolution: VideoResolution.fromXml(xml['Resolution'] ?? {}),
      rateControl: xml['RateControl'] != null
          ? VideoRateControl.fromXml(xml['RateControl'])
          : null,
      h264: xml['H264'] != null ? H264Configuration.fromXml(xml['H264']) : null,
      multicast:
          xml['Multicast'] != null ? Multicast.fromXml(xml['Multicast']) : null,
      sessionTimeout:
          int.tryParse(xml['SessionTimeout']?.toString() ?? '60') ?? 60,
    );
  }

  @override
  String toString() =>
      'VideoEncoderConfiguration(token: $token, encoding: $encoding, '
      'resolution: $resolution)';
}

/// Audio Encoder Configuration
class AudioEncoderConfiguration {
  final String token;
  final String name;
  final int useCount;
  final String encoding;
  final int bitrate;
  final int sampleRate;
  final Multicast? multicast;
  final int sessionTimeout;

  const AudioEncoderConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    required this.encoding,
    required this.bitrate,
    required this.sampleRate,
    this.multicast,
    required this.sessionTimeout,
  });

  factory AudioEncoderConfiguration.fromXml(Map<String, dynamic> xml) {
    return AudioEncoderConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      encoding: xml['Encoding']?.toString() ?? OnvifConstants.aacAudioEncoding,
      bitrate: int.tryParse(xml['Bitrate']?.toString() ?? '0') ?? 0,
      sampleRate: int.tryParse(xml['SampleRate']?.toString() ?? '0') ?? 0,
      multicast:
          xml['Multicast'] != null ? Multicast.fromXml(xml['Multicast']) : null,
      sessionTimeout:
          int.tryParse(xml['SessionTimeout']?.toString() ?? '60') ?? 60,
    );
  }

  @override
  String toString() =>
      'AudioEncoderConfiguration(token: $token, encoding: $encoding)';
}

/// PTZ Configuration (simplified version, full implementation in ptz_configuration.dart)
class PtzConfiguration {
  final String token;
  final String name;
  final int useCount;
  final String nodeToken;

  const PtzConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    required this.nodeToken,
  });

  factory PtzConfiguration.fromXml(Map<String, dynamic> xml) {
    return PtzConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      nodeToken: xml['NodeToken']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'PtzConfiguration(token: $token, nodeToken: $nodeToken)';
}

/// Video Analytics Configuration
class VideoAnalyticsConfiguration {
  final String token;
  final String name;
  final int useCount;

  const VideoAnalyticsConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
  });

  factory VideoAnalyticsConfiguration.fromXml(Map<String, dynamic> xml) {
    return VideoAnalyticsConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  String toString() =>
      'VideoAnalyticsConfiguration(token: $token, name: $name)';
}

/// Metadata Configuration
class MetadataConfiguration {
  final String token;
  final String name;
  final int useCount;

  const MetadataConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
  });

  factory MetadataConfiguration.fromXml(Map<String, dynamic> xml) {
    return MetadataConfiguration(
      token: xml['token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  String toString() => 'MetadataConfiguration(token: $token, name: $name)';
}

/// Video Resolution
class VideoResolution {
  final int width;
  final int height;

  const VideoResolution({
    required this.width,
    required this.height,
  });

  factory VideoResolution.fromXml(Map<String, dynamic> xml) {
    return VideoResolution(
      width: int.tryParse(xml['Width']?.toString() ?? '0') ?? 0,
      height: int.tryParse(xml['Height']?.toString() ?? '0') ?? 0,
    );
  }

  /// Tạo resolution từ string (e.g., "1920x1080")
  factory VideoResolution.fromString(String resolution) {
    final parts = resolution.split('x');
    if (parts.length != 2) {
      throw ArgumentError('Invalid resolution format: $resolution');
    }

    return VideoResolution(
      width: int.parse(parts[0]),
      height: int.parse(parts[1]),
    );
  }

  /// Chuyển đổi thành string
  @override
  String toString() => '${width}x$height';

  /// Kiểm tra xem có phải là resolution 1080p không
  bool get is1080p => width == 1920 && height == 1080;

  /// Kiểm tra xem có phải là resolution 720p không
  bool get is720p => width == 1280 && height == 720;

  /// Kiểm tra xem có phải là resolution 4K không
  bool get is4K => width >= 3840 && height >= 2160;

  /// Tính aspect ratio
  double get aspectRatio => width / height;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoResolution &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

/// Video Rate Control
class VideoRateControl {
  final double? frameRateLimit;
  final String? encodingInterval;
  final int? bitrateLimit;

  const VideoRateControl({
    this.frameRateLimit,
    this.encodingInterval,
    this.bitrateLimit,
  });

  factory VideoRateControl.fromXml(Map<String, dynamic> xml) {
    return VideoRateControl(
      frameRateLimit: double.tryParse(xml['FrameRateLimit']?.toString() ?? ''),
      encodingInterval: xml['EncodingInterval']?.toString(),
      bitrateLimit: int.tryParse(xml['BitrateLimit']?.toString() ?? ''),
    );
  }

  @override
  String toString() =>
      'VideoRateControl(frameRate: $frameRateLimit, bitrate: $bitrateLimit)';
}

/// H264 Configuration
class H264Configuration {
  final String? govLength;
  final String? h264Profile;

  const H264Configuration({
    this.govLength,
    this.h264Profile,
  });

  factory H264Configuration.fromXml(Map<String, dynamic> xml) {
    return H264Configuration(
      govLength: xml['GovLength']?.toString(),
      h264Profile: xml['H264Profile']?.toString(),
    );
  }

  @override
  String toString() => 'H264Configuration(profile: $h264Profile)';
}

/// Multicast Configuration
class Multicast {
  final String? address;
  final int? port;
  final int? ttl;
  final bool? autoStart;

  const Multicast({
    this.address,
    this.port,
    this.ttl,
    this.autoStart,
  });

  factory Multicast.fromXml(Map<String, dynamic> xml) {
    return Multicast(
      address: xml['Address']?.toString(),
      port: int.tryParse(xml['Port']?.toString() ?? ''),
      ttl: int.tryParse(xml['TTL']?.toString() ?? ''),
      autoStart: OnvifMediaProfile._parseBool(xml['AutoStart']),
    );
  }

  @override
  String toString() => 'Multicast(address: $address:$port)';
}

/// Integer Rectangle
class IntRectangle {
  final int x;
  final int y;
  final int width;
  final int height;

  const IntRectangle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory IntRectangle.fromXml(Map<String, dynamic> xml) {
    return IntRectangle(
      x: int.tryParse(xml['x']?.toString() ?? '0') ?? 0,
      y: int.tryParse(xml['y']?.toString() ?? '0') ?? 0,
      width: int.tryParse(xml['width']?.toString() ?? '0') ?? 0,
      height: int.tryParse(xml['height']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  String toString() => 'IntRectangle(x: $x, y: $y, w: $width, h: $height)';
}

/// Extension for additional profile configurations
class Extension {
  final String name;
  final Map<String, dynamic> properties;

  const Extension({
    required this.name,
    this.properties = const {},
  });

  factory Extension.fromXml(Map<String, dynamic> xml) {
    return Extension(
      name: xml['name'] ?? 'Unknown',
      properties: Map<String, dynamic>.from(xml),
    );
  }

  @override
  String toString() => 'Extension(name: $name)';
}
