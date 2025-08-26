import '../client/transport.dart';
import '../models/device_information.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Device Management Service
/// Quản lý các operations liên quan đến device
class OnvifDeviceService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = OnvifConstants.defaultDeviceServicePath;

  OnvifDeviceService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  /// Lấy thông tin thiết bị
  Future<OnvifDeviceInformation> getDeviceInformation() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetDeviceInformation xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetDeviceInformation',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createGetDeviceInformationRequest();

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/GetDeviceInformation',
      );

      final parsed =
          OnvifResponseParser.parseGetDeviceInformationResponse(response);
      return OnvifDeviceInformation.fromXml(parsed);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get device information: $e',
        originalError: e,
      );
    }
  }

  /// Lấy capabilities của thiết bị
  Future<OnvifDeviceCapabilities> getCapabilities(
      {List<String>? categories}) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildGetCapabilitiesBody(categories),
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetCapabilities',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createGetCapabilitiesRequest(
              categories: categories);

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/GetCapabilities',
      );

      final parsed = OnvifResponseParser.parseGetCapabilitiesResponse(response);
      return OnvifDeviceCapabilities.fromXml(parsed['Capabilities'] ?? {});
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get device capabilities: $e',
        originalError: e,
      );
    }
  }

  /// Lấy system date and time
  Future<DateTime> getSystemDateTime() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetSystemDateAndTime xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetSystemDateAndTime',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetSystemDateAndTime xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetSystemDateAndTime',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/GetSystemDateAndTime',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _parseSystemDateTime(parsed);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get system date time: $e',
        originalError: e,
      );
    }
  }

  /// Set system date and time
  Future<void> setSystemDateTime(DateTime dateTime) async {
    try {
      final body = _buildSetSystemDateTimeBody(dateTime);

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: body,
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SetSystemDateAndTime',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body: body,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SetSystemDateAndTime',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/SetSystemDateAndTime',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to set system date time: $e',
        originalError: e,
      );
    }
  }

  /// Reboot hệ thống
  Future<void> systemReboot() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:SystemReboot xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SystemReboot',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:SystemReboot xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SystemReboot',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/SystemReboot',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to reboot system: $e',
        originalError: e,
      );
    }
  }

  /// Lấy network interfaces
  Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetNetworkInterfaces xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetNetworkInterfaces',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetNetworkInterfaces xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetNetworkInterfaces',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/GetNetworkInterfaces',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _parseNetworkInterfaces(parsed);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get network interfaces: $e',
        originalError: e,
      );
    }
  }

  /// Lấy services từ device
  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetServices xmlns:tds="${OnvifConstants.deviceManagementNamespace}"><tds:IncludeCapability>false</tds:IncludeCapability></tds:GetServices>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.deviceManagementNamespace}/GetServices',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetServices xmlns:tds="${OnvifConstants.deviceManagementNamespace}"><tds:IncludeCapability>false</tds:IncludeCapability></tds:GetServices>',
              action: '${OnvifConstants.deviceManagementNamespace}/GetServices',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/GetServices',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _parseServices(parsed);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get services: $e',
        originalError: e,
      );
    }
  }

  /// Helper methods
  bool get _hasCredentials => _username != null && _password != null;

  String _buildGetCapabilitiesBody(List<String>? categories) {
    final buffer = StringBuffer();
    buffer.write(
        '<tds:GetCapabilities xmlns:tds="${OnvifConstants.deviceManagementNamespace}">');

    if (categories != null && categories.isNotEmpty) {
      for (final category in categories) {
        buffer.write('<tds:Category>$category</tds:Category>');
      }
    }

    buffer.write('</tds:GetCapabilities>');
    return buffer.toString();
  }

  String _buildSetSystemDateTimeBody(DateTime dateTime) {
    final utcDateTime = dateTime.toUtc();

    return '''
<tds:SetSystemDateAndTime xmlns:tds="${OnvifConstants.deviceManagementNamespace}">
  <tds:DateTimeType>Manual</tds:DateTimeType>
  <tds:DaylightSavings>false</tds:DaylightSavings>
  <tds:TimeZone>
    <tt:TZ xmlns:tt="http://www.onvif.org/ver10/schema">UTC</tt:TZ>
  </tds:TimeZone>
  <tds:UTCDateTime>
    <tt:Time xmlns:tt="http://www.onvif.org/ver10/schema">
      <tt:Hour>${utcDateTime.hour}</tt:Hour>
      <tt:Minute>${utcDateTime.minute}</tt:Minute>
      <tt:Second>${utcDateTime.second}</tt:Second>
    </tt:Time>
    <tt:Date xmlns:tt="http://www.onvif.org/ver10/schema">
      <tt:Year>${utcDateTime.year}</tt:Year>
      <tt:Month>${utcDateTime.month}</tt:Month>
      <tt:Day>${utcDateTime.day}</tt:Day>
    </tt:Date>
  </tds:UTCDateTime>
</tds:SetSystemDateAndTime>''';
  }

  DateTime _parseSystemDateTime(Map<String, dynamic> parsed) {
    // Tìm SystemDateAndTime trong response
    final systemDateTime = _findInResponse(parsed, 'SystemDateAndTime');
    if (systemDateTime == null) {
      throw const OnvifParsingException(
          'SystemDateAndTime not found in response');
    }

    // Parse UTC DateTime
    final utcDateTime = systemDateTime['UTCDateTime'];
    if (utcDateTime == null) {
      throw const OnvifParsingException('UTCDateTime not found in response');
    }

    final date = utcDateTime['Date'] ?? {};
    final time = utcDateTime['Time'] ?? {};

    final year =
        int.tryParse(date['Year']?.toString() ?? '') ?? DateTime.now().year;
    final month =
        int.tryParse(date['Month']?.toString() ?? '') ?? DateTime.now().month;
    final day =
        int.tryParse(date['Day']?.toString() ?? '') ?? DateTime.now().day;
    final hour = int.tryParse(time['Hour']?.toString() ?? '') ?? 0;
    final minute = int.tryParse(time['Minute']?.toString() ?? '') ?? 0;
    final second = int.tryParse(time['Second']?.toString() ?? '') ?? 0;

    return DateTime.utc(year, month, day, hour, minute, second);
  }

  List<Map<String, dynamic>> _parseNetworkInterfaces(
      Map<String, dynamic> parsed) {
    final interfaces = <Map<String, dynamic>>[];

    final networkInterfaces = _findInResponse(parsed, 'NetworkInterfaces');
    if (networkInterfaces != null) {
      if (networkInterfaces is List) {
        interfaces.addAll(networkInterfaces.cast<Map<String, dynamic>>());
      } else if (networkInterfaces is Map<String, dynamic>) {
        interfaces.add(networkInterfaces);
      }
    }

    return interfaces;
  }

  List<Map<String, dynamic>> _parseServices(Map<String, dynamic> parsed) {
    final services = <Map<String, dynamic>>[];

    final serviceList = _findInResponse(parsed, 'Service');
    if (serviceList != null) {
      if (serviceList is List) {
        services.addAll(serviceList.cast<Map<String, dynamic>>());
      } else if (serviceList is Map<String, dynamic>) {
        services.add(serviceList);
      }
    }

    return services;
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
