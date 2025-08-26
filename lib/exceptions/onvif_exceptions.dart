/// ONVIF Exception Classes
/// Định nghĩa các exception chuyên biệt cho ONVIF operations

/// Base exception cho tất cả ONVIF errors
abstract class OnvifException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const OnvifException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'OnvifException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception khi kết nối với thiết bị thất bại
class OnvifConnectionException extends OnvifException {
  const OnvifConnectionException(super.message,
      {super.code, super.originalError});

  @override
  String toString() => 'OnvifConnectionException: $message';
}

/// Exception khi xác thực thất bại
class OnvifAuthenticationException extends OnvifException {
  const OnvifAuthenticationException(super.message,
      {super.code, super.originalError});

  @override
  String toString() => 'OnvifAuthenticationException: $message';
}

/// Exception khi timeout
class OnvifTimeoutException extends OnvifException {
  final Duration timeout;

  const OnvifTimeoutException(super.message, this.timeout,
      {super.code, super.originalError});

  @override
  String toString() =>
      'OnvifTimeoutException: $message (Timeout: ${timeout.inSeconds}s)';
}

/// Exception khi parsing response thất bại
class OnvifParsingException extends OnvifException {
  final String? rawResponse;

  const OnvifParsingException(super.message,
      {this.rawResponse, super.code, super.originalError});

  @override
  String toString() => 'OnvifParsingException: $message';
}

/// Exception khi service không được hỗ trợ
class OnvifServiceNotSupportedException extends OnvifException {
  final String serviceName;

  const OnvifServiceNotSupportedException(this.serviceName)
      : super('Service $serviceName is not supported by this device');

  @override
  String toString() =>
      'OnvifServiceNotSupportedException: Service $serviceName is not supported';
}

/// Exception khi thiết bị không được tìm thấy
class OnvifDeviceNotFoundException extends OnvifException {
  final String? deviceAddress;

  const OnvifDeviceNotFoundException([this.deviceAddress])
      : super(
            'Device not found${deviceAddress != null ? ' at $deviceAddress' : ''}');

  @override
  String toString() => 'OnvifDeviceNotFoundException: ${message}';
}

/// Exception khi SOAP response có lỗi
class OnvifSoapException extends OnvifException {
  final String? faultCode;
  final String? faultString;
  final String? detail;

  const OnvifSoapException(super.message,
      {this.faultCode,
      this.faultString,
      this.detail,
      super.code,
      super.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('OnvifSoapException: $message');
    if (faultCode != null) buffer.write('\nFault Code: $faultCode');
    if (faultString != null) buffer.write('\nFault String: $faultString');
    if (detail != null) buffer.write('\nDetail: $detail');
    return buffer.toString();
  }
}

/// Exception khi cấu hình không hợp lệ
class OnvifConfigurationException extends OnvifException {
  const OnvifConfigurationException(super.message,
      {super.code, super.originalError});

  @override
  String toString() => 'OnvifConfigurationException: $message';
}

/// Exception khi stream không khả dụng
class OnvifStreamException extends OnvifException {
  final String? streamUri;

  const OnvifStreamException(super.message,
      {this.streamUri, super.code, super.originalError});

  @override
  String toString() =>
      'OnvifStreamException: $message${streamUri != null ? ' (URI: $streamUri)' : ''}';
}

/// Exception khi PTZ operation thất bại
class OnvifPtzException extends OnvifException {
  const OnvifPtzException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'OnvifPtzException: $message';
}

/// Exception khi recording operation thất bại
class OnvifRecordingException extends OnvifException {
  const OnvifRecordingException(super.message,
      {super.code, super.originalError});

  @override
  String toString() => 'OnvifRecordingException: $message';
}

/// Exception khi event handling thất bại
class OnvifEventException extends OnvifException {
  const OnvifEventException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'OnvifEventException: $message';
}

/// Exception khi discovery thất bại
class OnvifDiscoveryException extends OnvifException {
  const OnvifDiscoveryException(super.message,
      {super.code, super.originalError});

  @override
  String toString() => 'OnvifDiscoveryException: $message';
}
