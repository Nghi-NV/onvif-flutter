/// Video Source Model
/// Đại diện cho video source trong ONVIF device
class OnvifVideoSource {
  final String token;
  final String name;
  final int useCount;
  final String sourceToken;
  final double frameRate;
  final VideoResolution resolution;
  final ImagingSettings? imaging;
  final Extension? extension;

  const OnvifVideoSource({
    required this.token,
    required this.name,
    required this.useCount,
    required this.sourceToken,
    required this.frameRate,
    required this.resolution,
    this.imaging,
    this.extension,
  });

  factory OnvifVideoSource.fromXml(Map<String, dynamic> xml) {
    return OnvifVideoSource(
      token: xml['token'] ?? xml['Token'] ?? '',
      name: xml['Name']?.toString() ?? '',
      useCount: int.tryParse(xml['UseCount']?.toString() ?? '0') ?? 0,
      sourceToken: xml['SourceToken']?.toString() ?? '',
      frameRate: double.tryParse(xml['Framerate']?.toString() ?? '0') ?? 0.0,
      resolution: VideoResolution.fromXml(xml['Resolution'] ?? {}),
      imaging: xml['Imaging'] != null
          ? ImagingSettings.fromXml(xml['Imaging'])
          : null,
      extension:
          xml['Extension'] != null ? Extension.fromXml(xml['Extension']) : null,
    );
  }

  @override
  String toString() {
    return 'OnvifVideoSource(token: $token, name: $name, resolution: $resolution, frameRate: $frameRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifVideoSource && other.token == token;
  }

  @override
  int get hashCode => token.hashCode;
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

/// Imaging Settings
class ImagingSettings {
  final double? brightness;
  final double? contrast;
  final double? saturation;
  final double? sharpness;
  final FocusConfiguration? focus;
  final ExposureConfiguration? exposure;
  final WhiteBalanceConfiguration? whiteBalance;
  final WideDynamicRange? wideDynamicRange;
  final Extension? extension;

  const ImagingSettings({
    this.brightness,
    this.contrast,
    this.saturation,
    this.sharpness,
    this.focus,
    this.exposure,
    this.whiteBalance,
    this.wideDynamicRange,
    this.extension,
  });

  factory ImagingSettings.fromXml(Map<String, dynamic> xml) {
    return ImagingSettings(
      brightness: double.tryParse(xml['Brightness']?.toString() ?? ''),
      contrast: double.tryParse(xml['Contrast']?.toString() ?? ''),
      saturation: double.tryParse(xml['ColorSaturation']?.toString() ?? ''),
      sharpness: double.tryParse(xml['Sharpness']?.toString() ?? ''),
      focus: xml['Focus'] != null
          ? FocusConfiguration.fromXml(xml['Focus'])
          : null,
      exposure: xml['Exposure'] != null
          ? ExposureConfiguration.fromXml(xml['Exposure'])
          : null,
      whiteBalance: xml['WhiteBalance'] != null
          ? WhiteBalanceConfiguration.fromXml(xml['WhiteBalance'])
          : null,
      wideDynamicRange: xml['WideDynamicRange'] != null
          ? WideDynamicRange.fromXml(xml['WideDynamicRange'])
          : null,
      extension:
          xml['Extension'] != null ? Extension.fromXml(xml['Extension']) : null,
    );
  }

  @override
  String toString() {
    return 'ImagingSettings(brightness: $brightness, contrast: $contrast, saturation: $saturation)';
  }
}

/// Focus Configuration
class FocusConfiguration {
  final String autoFocusMode;
  final double? defaultSpeed;
  final double? nearLimit;
  final double? farLimit;

  const FocusConfiguration({
    required this.autoFocusMode,
    this.defaultSpeed,
    this.nearLimit,
    this.farLimit,
  });

  factory FocusConfiguration.fromXml(Map<String, dynamic> xml) {
    return FocusConfiguration(
      autoFocusMode: xml['AutoFocusMode']?.toString() ?? 'AUTO',
      defaultSpeed: double.tryParse(xml['DefaultSpeed']?.toString() ?? ''),
      nearLimit: double.tryParse(xml['NearLimit']?.toString() ?? ''),
      farLimit: double.tryParse(xml['FarLimit']?.toString() ?? ''),
    );
  }

  @override
  String toString() => 'FocusConfiguration(mode: $autoFocusMode)';
}

/// Exposure Configuration
class ExposureConfiguration {
  final String mode;
  final double? priority;
  final ExposureWindow? window;
  final double? minExposureTime;
  final double? maxExposureTime;
  final double? minGain;
  final double? maxGain;
  final double? minIris;
  final double? maxIris;
  final double? exposureTime;
  final double? gain;
  final double? iris;

  const ExposureConfiguration({
    required this.mode,
    this.priority,
    this.window,
    this.minExposureTime,
    this.maxExposureTime,
    this.minGain,
    this.maxGain,
    this.minIris,
    this.maxIris,
    this.exposureTime,
    this.gain,
    this.iris,
  });

  factory ExposureConfiguration.fromXml(Map<String, dynamic> xml) {
    return ExposureConfiguration(
      mode: xml['Mode']?.toString() ?? 'AUTO',
      priority: double.tryParse(xml['Priority']?.toString() ?? ''),
      window:
          xml['Window'] != null ? ExposureWindow.fromXml(xml['Window']) : null,
      minExposureTime:
          double.tryParse(xml['MinExposureTime']?.toString() ?? ''),
      maxExposureTime:
          double.tryParse(xml['MaxExposureTime']?.toString() ?? ''),
      minGain: double.tryParse(xml['MinGain']?.toString() ?? ''),
      maxGain: double.tryParse(xml['MaxGain']?.toString() ?? ''),
      minIris: double.tryParse(xml['MinIris']?.toString() ?? ''),
      maxIris: double.tryParse(xml['MaxIris']?.toString() ?? ''),
      exposureTime: double.tryParse(xml['ExposureTime']?.toString() ?? ''),
      gain: double.tryParse(xml['Gain']?.toString() ?? ''),
      iris: double.tryParse(xml['Iris']?.toString() ?? ''),
    );
  }

  @override
  String toString() => 'ExposureConfiguration(mode: $mode)';
}

/// Exposure Window
class ExposureWindow {
  final double bottom;
  final double top;
  final double right;
  final double left;

  const ExposureWindow({
    required this.bottom,
    required this.top,
    required this.right,
    required this.left,
  });

  factory ExposureWindow.fromXml(Map<String, dynamic> xml) {
    return ExposureWindow(
      bottom: double.tryParse(xml['bottom']?.toString() ?? '0') ?? 0.0,
      top: double.tryParse(xml['top']?.toString() ?? '0') ?? 0.0,
      right: double.tryParse(xml['right']?.toString() ?? '0') ?? 0.0,
      left: double.tryParse(xml['left']?.toString() ?? '0') ?? 0.0,
    );
  }

  @override
  String toString() =>
      'ExposureWindow(left: $left, top: $top, right: $right, bottom: $bottom)';
}

/// White Balance Configuration
class WhiteBalanceConfiguration {
  final String mode;
  final double? crGain;
  final double? cbGain;

  const WhiteBalanceConfiguration({
    required this.mode,
    this.crGain,
    this.cbGain,
  });

  factory WhiteBalanceConfiguration.fromXml(Map<String, dynamic> xml) {
    return WhiteBalanceConfiguration(
      mode: xml['Mode']?.toString() ?? 'AUTO',
      crGain: double.tryParse(xml['CrGain']?.toString() ?? ''),
      cbGain: double.tryParse(xml['CbGain']?.toString() ?? ''),
    );
  }

  @override
  String toString() => 'WhiteBalanceConfiguration(mode: $mode)';
}

/// Wide Dynamic Range
class WideDynamicRange {
  final String mode;
  final double? level;

  const WideDynamicRange({
    required this.mode,
    this.level,
  });

  factory WideDynamicRange.fromXml(Map<String, dynamic> xml) {
    return WideDynamicRange(
      mode: xml['Mode']?.toString() ?? 'OFF',
      level: double.tryParse(xml['Level']?.toString() ?? ''),
    );
  }

  @override
  String toString() => 'WideDynamicRange(mode: $mode, level: $level)';
}

/// Extension for additional video source configurations
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
