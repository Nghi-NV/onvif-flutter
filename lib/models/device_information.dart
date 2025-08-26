/// Device Information Model
/// Thông tin cơ bản về ONVIF device
class OnvifDeviceInformation {
  final String? manufacturer;
  final String? model;
  final String? firmwareVersion;
  final String? serialNumber;
  final String? hardwareId;

  const OnvifDeviceInformation({
    this.manufacturer,
    this.model,
    this.firmwareVersion,
    this.serialNumber,
    this.hardwareId,
  });

  factory OnvifDeviceInformation.fromXml(Map<String, dynamic> xml) {
    return OnvifDeviceInformation(
      manufacturer: xml['Manufacturer']?.toString(),
      model: xml['Model']?.toString(),
      firmwareVersion: xml['FirmwareVersion']?.toString(),
      serialNumber: xml['SerialNumber']?.toString(),
      hardwareId: xml['HardwareId']?.toString(),
    );
  }

  @override
  String toString() {
    return 'OnvifDeviceInformation(manufacturer: $manufacturer, model: $model, '
        'firmwareVersion: $firmwareVersion, serialNumber: $serialNumber, '
        'hardwareId: $hardwareId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifDeviceInformation &&
        other.manufacturer == manufacturer &&
        other.model == model &&
        other.firmwareVersion == firmwareVersion &&
        other.serialNumber == serialNumber &&
        other.hardwareId == hardwareId;
  }

  @override
  int get hashCode {
    return manufacturer.hashCode ^
        model.hashCode ^
        firmwareVersion.hashCode ^
        serialNumber.hashCode ^
        hardwareId.hashCode;
  }
}

/// Device Capabilities Model
/// Các capabilities mà ONVIF device hỗ trợ
class OnvifDeviceCapabilities {
  final DeviceCapability? device;
  final MediaCapability? media;
  final PtzCapability? ptz;
  final EventCapability? events;
  final ImagingCapability? imaging;
  final AnalyticsCapability? analytics;
  final List<ExtensionCapability> extensions;

  const OnvifDeviceCapabilities({
    this.device,
    this.media,
    this.ptz,
    this.events,
    this.imaging,
    this.analytics,
    this.extensions = const [],
  });

  factory OnvifDeviceCapabilities.fromXml(Map<String, dynamic> xml) {
    return OnvifDeviceCapabilities(
      device: xml['Device'] != null
          ? DeviceCapability.fromXml(xml['Device'])
          : null,
      media:
          xml['Media'] != null ? MediaCapability.fromXml(xml['Media']) : null,
      ptz: xml['PTZ'] != null ? PtzCapability.fromXml(xml['PTZ']) : null,
      events:
          xml['Events'] != null ? EventCapability.fromXml(xml['Events']) : null,
      imaging: xml['Imaging'] != null
          ? ImagingCapability.fromXml(xml['Imaging'])
          : null,
      analytics: xml['Analytics'] != null
          ? AnalyticsCapability.fromXml(xml['Analytics'])
          : null,
      extensions: _parseExtensions(xml['Extension']),
    );
  }

  static List<ExtensionCapability> _parseExtensions(dynamic extensionData) {
    if (extensionData == null) return [];

    final extensions = <ExtensionCapability>[];
    if (extensionData is List) {
      for (final ext in extensionData) {
        if (ext is Map<String, dynamic>) {
          extensions.add(ExtensionCapability.fromXml(ext));
        }
      }
    } else if (extensionData is Map<String, dynamic>) {
      extensions.add(ExtensionCapability.fromXml(extensionData));
    }

    return extensions;
  }

  @override
  String toString() {
    return 'OnvifDeviceCapabilities(device: $device, media: $media, ptz: $ptz, '
        'events: $events, imaging: $imaging, analytics: $analytics, '
        'extensions: ${extensions.length})';
  }
}

/// Device Capability
class DeviceCapability {
  final String? xAddr;
  final NetworkCapability? network;
  final SystemCapability? system;
  final IOCapability? io;
  final SecurityCapability? security;

  const DeviceCapability({
    this.xAddr,
    this.network,
    this.system,
    this.io,
    this.security,
  });

  factory DeviceCapability.fromXml(Map<String, dynamic> xml) {
    return DeviceCapability(
      xAddr: xml['XAddr']?.toString(),
      network: xml['Network'] != null
          ? NetworkCapability.fromXml(xml['Network'])
          : null,
      system: xml['System'] != null
          ? SystemCapability.fromXml(xml['System'])
          : null,
      io: xml['IO'] != null ? IOCapability.fromXml(xml['IO']) : null,
      security: xml['Security'] != null
          ? SecurityCapability.fromXml(xml['Security'])
          : null,
    );
  }

  @override
  String toString() => 'DeviceCapability(xAddr: $xAddr)';
}

/// Media Capability
class MediaCapability {
  final String? xAddr;
  final RtpMulticast? rtpMulticast;
  final RtpTcp? rtpTcp;
  final RtpRtspTcp? rtpRtspTcp;
  final List<String> supportedProfiles;

  const MediaCapability({
    this.xAddr,
    this.rtpMulticast,
    this.rtpTcp,
    this.rtpRtspTcp,
    this.supportedProfiles = const [],
  });

  factory MediaCapability.fromXml(Map<String, dynamic> xml) {
    return MediaCapability(
      xAddr: xml['XAddr']?.toString(),
      rtpMulticast: xml['RTPMulticast'] != null
          ? RtpMulticast.fromXml(xml['RTPMulticast'])
          : null,
      rtpTcp: xml['RTP_TCP'] != null ? RtpTcp.fromXml(xml['RTP_TCP']) : null,
      rtpRtspTcp: xml['RTP_RTSP_TCP'] != null
          ? RtpRtspTcp.fromXml(xml['RTP_RTSP_TCP'])
          : null,
      supportedProfiles: _parseStringList(xml['SupportedProfiles']),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is String) return [data];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  @override
  String toString() =>
      'MediaCapability(xAddr: $xAddr, profiles: $supportedProfiles)';
}

/// PTZ Capability
class PtzCapability {
  final String? xAddr;

  const PtzCapability({this.xAddr});

  factory PtzCapability.fromXml(Map<String, dynamic> xml) {
    return PtzCapability(xAddr: xml['XAddr']?.toString());
  }

  @override
  String toString() => 'PtzCapability(xAddr: $xAddr)';
}

/// Event Capability
class EventCapability {
  final String? xAddr;
  final bool wsSubscriptionPolicySupport;
  final bool wsPullPointSupport;
  final bool wsBasicNotificationSupport;

  const EventCapability({
    this.xAddr,
    this.wsSubscriptionPolicySupport = false,
    this.wsPullPointSupport = false,
    this.wsBasicNotificationSupport = false,
  });

  factory EventCapability.fromXml(Map<String, dynamic> xml) {
    return EventCapability(
      xAddr: xml['XAddr']?.toString(),
      wsSubscriptionPolicySupport:
          _parseBool(xml['WSSubscriptionPolicySupport']),
      wsPullPointSupport: _parseBool(xml['WSPullPointSupport']),
      wsBasicNotificationSupport:
          _parseBool(xml['WSPausableSubscriptionManagerInterfaceSupport']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  @override
  String toString() => 'EventCapability(xAddr: $xAddr)';
}

/// Imaging Capability
class ImagingCapability {
  final String? xAddr;

  const ImagingCapability({this.xAddr});

  factory ImagingCapability.fromXml(Map<String, dynamic> xml) {
    return ImagingCapability(xAddr: xml['XAddr']?.toString());
  }

  @override
  String toString() => 'ImagingCapability(xAddr: $xAddr)';
}

/// Analytics Capability
class AnalyticsCapability {
  final String? xAddr;
  final bool ruleSupport;
  final bool analyticsModuleSupport;

  const AnalyticsCapability({
    this.xAddr,
    this.ruleSupport = false,
    this.analyticsModuleSupport = false,
  });

  factory AnalyticsCapability.fromXml(Map<String, dynamic> xml) {
    return AnalyticsCapability(
      xAddr: xml['XAddr']?.toString(),
      ruleSupport: EventCapability._parseBool(xml['RuleSupport']),
      analyticsModuleSupport:
          EventCapability._parseBool(xml['AnalyticsModuleSupport']),
    );
  }

  @override
  String toString() => 'AnalyticsCapability(xAddr: $xAddr)';
}

/// Extension Capability
class ExtensionCapability {
  final String name;
  final String? xAddr;
  final Map<String, dynamic> properties;

  const ExtensionCapability({
    required this.name,
    this.xAddr,
    this.properties = const {},
  });

  factory ExtensionCapability.fromXml(Map<String, dynamic> xml) {
    return ExtensionCapability(
      name: xml['name'] ?? 'Unknown',
      xAddr: xml['XAddr']?.toString(),
      properties: Map<String, dynamic>.from(xml),
    );
  }

  @override
  String toString() => 'ExtensionCapability(name: $name, xAddr: $xAddr)';
}

// Helper capabilities
class NetworkCapability {
  final bool ipv6;
  final bool ipv4;
  final bool discoveryResolve;
  final bool discoveryBye;
  final bool remoteDiscovery;

  const NetworkCapability({
    this.ipv6 = false,
    this.ipv4 = true,
    this.discoveryResolve = false,
    this.discoveryBye = false,
    this.remoteDiscovery = false,
  });

  factory NetworkCapability.fromXml(Map<String, dynamic> xml) {
    return NetworkCapability(
      ipv6: EventCapability._parseBool(xml['IPV6']),
      ipv4: EventCapability._parseBool(xml['IPV4']),
      discoveryResolve: EventCapability._parseBool(xml['DiscoveryResolve']),
      discoveryBye: EventCapability._parseBool(xml['DiscoveryBye']),
      remoteDiscovery: EventCapability._parseBool(xml['RemoteDiscovery']),
    );
  }
}

class SystemCapability {
  final bool discoveryResolve;
  final bool discoveryBye;
  final bool remoteDiscovery;
  final bool systemBackup;
  final bool systemLogging;
  final bool firmwareUpgrade;

  const SystemCapability({
    this.discoveryResolve = false,
    this.discoveryBye = false,
    this.remoteDiscovery = false,
    this.systemBackup = false,
    this.systemLogging = false,
    this.firmwareUpgrade = false,
  });

  factory SystemCapability.fromXml(Map<String, dynamic> xml) {
    return SystemCapability(
      discoveryResolve: EventCapability._parseBool(xml['DiscoveryResolve']),
      discoveryBye: EventCapability._parseBool(xml['DiscoveryBye']),
      remoteDiscovery: EventCapability._parseBool(xml['RemoteDiscovery']),
      systemBackup: EventCapability._parseBool(xml['SystemBackup']),
      systemLogging: EventCapability._parseBool(xml['SystemLogging']),
      firmwareUpgrade: EventCapability._parseBool(xml['FirmwareUpgrade']),
    );
  }
}

class IOCapability {
  final int inputConnectors;
  final int relayOutputs;

  const IOCapability({
    this.inputConnectors = 0,
    this.relayOutputs = 0,
  });

  factory IOCapability.fromXml(Map<String, dynamic> xml) {
    return IOCapability(
      inputConnectors:
          int.tryParse(xml['InputConnectors']?.toString() ?? '0') ?? 0,
      relayOutputs: int.tryParse(xml['RelayOutputs']?.toString() ?? '0') ?? 0,
    );
  }
}

class SecurityCapability {
  final bool tls10;
  final bool tls11;
  final bool tls12;
  final bool onboardKeyGeneration;
  final bool accessPolicyConfig;
  final bool defaultAccessPolicy;

  const SecurityCapability({
    this.tls10 = false,
    this.tls11 = false,
    this.tls12 = false,
    this.onboardKeyGeneration = false,
    this.accessPolicyConfig = false,
    this.defaultAccessPolicy = false,
  });

  factory SecurityCapability.fromXml(Map<String, dynamic> xml) {
    return SecurityCapability(
      tls10: EventCapability._parseBool(xml['TLS1.0']),
      tls11: EventCapability._parseBool(xml['TLS1.1']),
      tls12: EventCapability._parseBool(xml['TLS1.2']),
      onboardKeyGeneration:
          EventCapability._parseBool(xml['OnboardKeyGeneration']),
      accessPolicyConfig: EventCapability._parseBool(xml['AccessPolicyConfig']),
      defaultAccessPolicy:
          EventCapability._parseBool(xml['DefaultAccessPolicy']),
    );
  }
}

class RtpMulticast {
  final bool supported;

  const RtpMulticast({this.supported = false});

  factory RtpMulticast.fromXml(Map<String, dynamic> xml) {
    return RtpMulticast(
        supported: EventCapability._parseBool(xml['Supported']));
  }
}

class RtpTcp {
  final bool supported;

  const RtpTcp({this.supported = false});

  factory RtpTcp.fromXml(Map<String, dynamic> xml) {
    return RtpTcp(supported: EventCapability._parseBool(xml['Supported']));
  }
}

class RtpRtspTcp {
  final bool supported;

  const RtpRtspTcp({this.supported = false});

  factory RtpRtspTcp.fromXml(Map<String, dynamic> xml) {
    return RtpRtspTcp(supported: EventCapability._parseBool(xml['Supported']));
  }
}
