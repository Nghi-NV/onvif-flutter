/// ONVIF Constants and Endpoints
/// Định nghĩa các hằng số và endpoint cho ONVIF protocol
class OnvifConstants {
  // ONVIF Namespaces
  static const String deviceManagementNamespace =
      'http://www.onvif.org/ver10/device/wsdl';
  static const String mediaNamespace = 'http://www.onvif.org/ver10/media/wsdl';
  static const String ptzNamespace = 'http://www.onvif.org/ver20/ptz/wsdl';
  static const String eventNamespace = 'http://www.onvif.org/ver10/events/wsdl';
  static const String imagingNamespace =
      'http://www.onvif.org/ver20/imaging/wsdl';
  static const String recordingNamespace =
      'http://www.onvif.org/ver10/recording/wsdl';
  static const String searchNamespace =
      'http://www.onvif.org/ver10/search/wsdl';
  static const String replayNamespace =
      'http://www.onvif.org/ver10/replay/wsdl';

  // SOAP Namespaces
  static const String soapEnvNamespace =
      'http://www.w3.org/2003/05/soap-envelope';
  static const String wsAddressingNamespace =
      'http://www.w3.org/2005/08/addressing';
  static const String wsSecurityNamespace =
      'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd';
  static const String wsUsernameTokenNamespace =
      'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest';

  // Default ONVIF Endpoints
  static const String defaultDeviceServicePath = '/onvif/device_service';
  static const String defaultMediaServicePath = '/onvif/Media';
  static const String defaultPtzServicePath = '/onvif/PTZ';
  static const String defaultEventServicePath = '/onvif/Events';
  static const String defaultImagingServicePath = '/onvif/Imaging';
  static const String defaultRecordingServicePath = '/onvif/Recording';
  static const String defaultSearchServicePath = '/onvif/Search';
  static const String defaultReplayServicePath = '/onvif/Replay';

  // WS-Discovery
  static const String wsDiscoveryMulticastAddress = '239.255.255.250';
  static const int wsDiscoveryPort = 3702;
  static const String wsDiscoveryNamespace =
      'http://schemas.xmlsoap.org/ws/2005/04/discovery';

  // Default ports
  static const int defaultHttpPort = 80;
  static const int defaultHttpsPort = 443;
  static const int defaultOnvifPort = 8080;

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration discoveryTimeout = Duration(seconds: 10);
  static const Duration streamTimeout = Duration(seconds: 60);

  // Stream types
  static const String rtspStreamType = 'RTP-Unicast';
  static const String httpStreamType = 'HTTP';

  // PTZ Speeds
  static const double defaultPtzSpeed = 0.5;
  static const double maxPtzSpeed = 1.0;
  static const double minPtzSpeed = 0.1;

  // Video encodings
  static const String h264Encoding = 'H264';
  static const String h265Encoding = 'H265';
  static const String mjpegEncoding = 'MJPEG';

  // Audio encodings
  static const String aacAudioEncoding = 'AAC';
  static const String g726AudioEncoding = 'G726';
  static const String pcmAudioEncoding = 'PCM';

  // Common resolutions
  static const String resolution1080p = '1920x1080';
  static const String resolution720p = '1280x720';
  static const String resolution480p = '720x480';
  static const String resolutionVga = '640x480';

  // Frame rates
  static const int frameRate30 = 30;
  static const int frameRate25 = 25;
  static const int frameRate15 = 15;
  static const int frameRate10 = 10;

  // Profile types
  static const String profileS = 'S'; // Video streaming
  static const String profileT = 'T'; // Advanced video streaming
  static const String profileG = 'G'; // Video recording and storage
  static const String profileM = 'M'; // Metadata and analytics

  // Error messages
  static const String authenticationError = 'Authentication failed';
  static const String connectionError = 'Connection failed';
  static const String timeoutError = 'Request timeout';
  static const String invalidResponseError = 'Invalid response received';
  static const String serviceNotSupportedError = 'Service not supported';
  static const String deviceNotFoundError = 'Device not found';
}

/// ONVIF Device Capabilities
class OnvifCapabilities {
  static const String deviceCapability = 'Device';
  static const String mediaCapability = 'Media';
  static const String ptzCapability = 'PTZ';
  static const String eventCapability = 'Events';
  static const String imagingCapability = 'Imaging';
  static const String recordingCapability = 'Recording';
  static const String searchCapability = 'Search';
  static const String replayCapability = 'Replay';
  static const String analyticsCapability = 'Analytics';
}

/// ONVIF Security Modes
enum OnvifSecurityMode { none, digest, wsse }

/// Stream Protocol Types
enum StreamProtocol { rtsp, http, https, tcp, udp }

/// PTZ Movement Types
enum PtzMovementType { continuous, relative, absolute }

/// Recording Status
enum RecordingStatus { recording, stopped, unknown }

/// Event Types
enum OnvifEventType {
  motion,
  tampering,
  lineDetection,
  fieldDetection,
  faceDetection,
  audioDetection,
  custom
}
