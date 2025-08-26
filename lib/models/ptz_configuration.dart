import '../utils/constants.dart';

/// PTZ Configuration Model
/// Đại diện cho cấu hình PTZ trong ONVIF device
class OnvifPtzConfiguration {
  final String token;
  final String name;
  final int useCount;
  final String nodeToken;
  final String? defaultAbsolutePantTiltPositionSpace;
  final String? defaultAbsoluteZoomPositionSpace;
  final String? defaultRelativePanTiltTranslationSpace;
  final String? defaultRelativeZoomTranslationSpace;
  final String? defaultContinuousPanTiltVelocitySpace;
  final String? defaultContinuousZoomVelocitySpace;
  final PtzSpeed? defaultPtzSpeed;
  final Duration? defaultPtzTimeout;
  final PtzLimits? panTiltLimits;
  final PtzLimits? zoomLimits;
  final Extension? extension;

  const OnvifPtzConfiguration({
    required this.token,
    required this.name,
    required this.useCount,
    required this.nodeToken,
    this.defaultAbsolutePantTiltPositionSpace,
    this.defaultAbsoluteZoomPositionSpace,
    this.defaultRelativePanTiltTranslationSpace,
    this.defaultRelativeZoomTranslationSpace,
    this.defaultContinuousPanTiltVelocitySpace,
    this.defaultContinuousZoomVelocitySpace,
    this.defaultPtzSpeed,
    this.defaultPtzTimeout,
    this.panTiltLimits,
    this.zoomLimits,
    this.extension,
  });

  factory OnvifPtzConfiguration.fromXml(Map<String, dynamic> xml) {
    return OnvifPtzConfiguration(
      token: xml['token'] ?? xml['Token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      nodeToken: xml['NodeToken']?.toString() ?? '',
      defaultAbsolutePantTiltPositionSpace:
          xml['DefaultAbsolutePantTiltPositionSpace']?.toString(),
      defaultAbsoluteZoomPositionSpace:
          xml['DefaultAbsoluteZoomPositionSpace']?.toString(),
      defaultRelativePanTiltTranslationSpace:
          xml['DefaultRelativePanTiltTranslationSpace']?.toString(),
      defaultRelativeZoomTranslationSpace:
          xml['DefaultRelativeZoomTranslationSpace']?.toString(),
      defaultContinuousPanTiltVelocitySpace:
          xml['DefaultContinuousPanTiltVelocitySpace']?.toString(),
      defaultContinuousZoomVelocitySpace:
          xml['DefaultContinuousZoomVelocitySpace']?.toString(),
      defaultPtzSpeed: xml['DefaultPTZSpeed'] != null
          ? PtzSpeed.fromXml(xml['DefaultPTZSpeed'])
          : null,
      defaultPtzTimeout: _parseDuration(xml['DefaultPTZTimeout']),
      panTiltLimits: xml['PanTiltLimits'] != null
          ? PtzLimits.fromXml(xml['PanTiltLimits'])
          : null,
      zoomLimits: xml['ZoomLimits'] != null
          ? PtzLimits.fromXml(xml['ZoomLimits'])
          : null,
      extension:
          xml['Extension'] != null ? Extension.fromXml(xml['Extension']) : null,
    );
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

  @override
  String toString() {
    return 'OnvifPtzConfiguration(token: $token, name: $name, nodeToken: $nodeToken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifPtzConfiguration && other.token == token;
  }

  @override
  int get hashCode => token.hashCode;
}

/// PTZ Speed
class PtzSpeed {
  final PtzVector2D? panTilt;
  final PtzVector1D? zoom;

  const PtzSpeed({
    this.panTilt,
    this.zoom,
  });

  factory PtzSpeed.fromXml(Map<String, dynamic> xml) {
    return PtzSpeed(
      panTilt:
          xml['PanTilt'] != null ? PtzVector2D.fromXml(xml['PanTilt']) : null,
      zoom: xml['Zoom'] != null ? PtzVector1D.fromXml(xml['Zoom']) : null,
    );
  }

  factory PtzSpeed.create({
    double panSpeed = OnvifConstants.defaultPtzSpeed,
    double tiltSpeed = OnvifConstants.defaultPtzSpeed,
    double zoomSpeed = OnvifConstants.defaultPtzSpeed,
  }) {
    return PtzSpeed(
      panTilt: PtzVector2D(x: panSpeed, y: tiltSpeed),
      zoom: PtzVector1D(x: zoomSpeed),
    );
  }

  @override
  String toString() => 'PtzSpeed(panTilt: $panTilt, zoom: $zoom)';
}

/// PTZ Vector 2D (Pan/Tilt)
class PtzVector2D {
  final double x; // Pan
  final double y; // Tilt
  final String? space;

  const PtzVector2D({
    required this.x,
    required this.y,
    this.space,
  });

  factory PtzVector2D.fromXml(Map<String, dynamic> xml) {
    return PtzVector2D(
      x: double.tryParse(xml['x']?.toString() ?? '0') ?? 0.0,
      y: double.tryParse(xml['y']?.toString() ?? '0') ?? 0.0,
      space: xml['space']?.toString(),
    );
  }

  /// Tạo vector với các giá trị clamped trong range [-1, 1]
  factory PtzVector2D.clamped({
    required double x,
    required double y,
    String? space,
  }) {
    return PtzVector2D(
      x: x.clamp(-1.0, 1.0),
      y: y.clamp(-1.0, 1.0),
      space: space,
    );
  }

  /// Pan velocity
  double get pan => x;

  /// Tilt velocity
  double get tilt => y;

  /// Kiểm tra xem có đang di chuyển không
  bool get isMoving => x != 0.0 || y != 0.0;

  /// Tạo vector stop (0, 0)
  static const PtzVector2D stop = PtzVector2D(x: 0.0, y: 0.0);

  @override
  String toString() => 'PtzVector2D(x: $x, y: $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PtzVector2D && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// PTZ Vector 1D (Zoom)
class PtzVector1D {
  final double x; // Zoom
  final String? space;

  const PtzVector1D({
    required this.x,
    this.space,
  });

  factory PtzVector1D.fromXml(Map<String, dynamic> xml) {
    return PtzVector1D(
      x: double.tryParse(xml['x']?.toString() ?? '0') ?? 0.0,
      space: xml['space']?.toString(),
    );
  }

  /// Tạo vector với giá trị clamped trong range [-1, 1]
  factory PtzVector1D.clamped({
    required double x,
    String? space,
  }) {
    return PtzVector1D(
      x: x.clamp(-1.0, 1.0),
      space: space,
    );
  }

  /// Zoom velocity
  double get zoom => x;

  /// Kiểm tra xem có đang zoom không
  bool get isZooming => x != 0.0;

  /// Tạo vector stop (0)
  static const PtzVector1D stop = PtzVector1D(x: 0.0);

  @override
  String toString() => 'PtzVector1D(x: $x)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PtzVector1D && other.x == x;
  }

  @override
  int get hashCode => x.hashCode;
}

/// PTZ Limits
class PtzLimits {
  final PtzRange? range;

  const PtzLimits({this.range});

  factory PtzLimits.fromXml(Map<String, dynamic> xml) {
    return PtzLimits(
      range: xml['Range'] != null ? PtzRange.fromXml(xml['Range']) : null,
    );
  }

  @override
  String toString() => 'PtzLimits(range: $range)';
}

/// PTZ Range
class PtzRange {
  final String uri;
  final PtzRectangle xRange;
  final PtzRectangle yRange;

  const PtzRange({
    required this.uri,
    required this.xRange,
    required this.yRange,
  });

  factory PtzRange.fromXml(Map<String, dynamic> xml) {
    return PtzRange(
      uri: xml['URI']?.toString() ?? '',
      xRange: PtzRectangle.fromXml(xml['XRange'] ?? {}),
      yRange: PtzRectangle.fromXml(xml['YRange'] ?? {}),
    );
  }

  @override
  String toString() => 'PtzRange(uri: $uri, xRange: $xRange, yRange: $yRange)';
}

/// PTZ Rectangle
class PtzRectangle {
  final double min;
  final double max;

  const PtzRectangle({
    required this.min,
    required this.max,
  });

  factory PtzRectangle.fromXml(Map<String, dynamic> xml) {
    return PtzRectangle(
      min: double.tryParse(xml['Min']?.toString() ?? '0') ?? 0.0,
      max: double.tryParse(xml['Max']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Kiểm tra xem giá trị có nằm trong range không
  bool contains(double value) => value >= min && value <= max;

  /// Clamp giá trị vào range
  double clamp(double value) => value.clamp(min, max);

  /// Range size
  double get size => max - min;

  @override
  String toString() => 'PtzRectangle(min: $min, max: $max)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PtzRectangle && other.min == min && other.max == max;
  }

  @override
  int get hashCode => min.hashCode ^ max.hashCode;
}

/// PTZ Status
class PtzStatus {
  final PtzVector2D? position;
  final PtzVector2D? velocity;
  final PtzMoveStatus? moveStatus;
  final String? error;
  final DateTime? utcTime;

  const PtzStatus({
    this.position,
    this.velocity,
    this.moveStatus,
    this.error,
    this.utcTime,
  });

  factory PtzStatus.fromXml(Map<String, dynamic> xml) {
    return PtzStatus(
      position:
          xml['Position'] != null ? PtzVector2D.fromXml(xml['Position']) : null,
      velocity:
          xml['Velocity'] != null ? PtzVector2D.fromXml(xml['Velocity']) : null,
      moveStatus: xml['MoveStatus'] != null
          ? PtzMoveStatus.fromXml(xml['MoveStatus'])
          : null,
      error: xml['Error']?.toString(),
      utcTime: _parseDateTime(xml['UtcTime']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra xem có đang di chuyển không
  bool get isMoving => velocity?.isMoving ?? false;

  /// Kiểm tra xem có error không
  bool get hasError => error != null && error!.isNotEmpty;

  @override
  String toString() =>
      'PtzStatus(position: $position, velocity: $velocity, isMoving: $isMoving)';
}

/// PTZ Move Status
class PtzMoveStatus {
  final String? panTilt;
  final String? zoom;

  const PtzMoveStatus({
    this.panTilt,
    this.zoom,
  });

  factory PtzMoveStatus.fromXml(Map<String, dynamic> xml) {
    return PtzMoveStatus(
      panTilt: xml['PanTilt']?.toString(),
      zoom: xml['Zoom']?.toString(),
    );
  }

  /// Kiểm tra xem pan/tilt có đang di chuyển không
  bool get isPanTiltMoving => panTilt == 'MOVING';

  /// Kiểm tra xem zoom có đang di chuyển không
  bool get isZoomMoving => zoom == 'MOVING';

  /// Kiểm tra xem có movement nào đang diễn ra không
  bool get isMoving => isPanTiltMoving || isZoomMoving;

  @override
  String toString() => 'PtzMoveStatus(panTilt: $panTilt, zoom: $zoom)';
}

/// PTZ Preset
class PtzPreset {
  final String token;
  final String name;
  final PtzVector2D? ptzPosition;

  const PtzPreset({
    required this.token,
    required this.name,
    this.ptzPosition,
  });

  factory PtzPreset.fromXml(Map<String, dynamic> xml) {
    return PtzPreset(
      token: xml['token'] ?? xml['Token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      ptzPosition: xml['PTZPosition'] != null
          ? PtzVector2D.fromXml(xml['PTZPosition'])
          : null,
    );
  }

  @override
  String toString() => 'PtzPreset(token: $token, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PtzPreset && other.token == token;
  }

  @override
  int get hashCode => token.hashCode;
}

/// Extension for additional PTZ configurations
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
