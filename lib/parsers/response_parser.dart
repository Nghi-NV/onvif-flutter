import 'package:xml/xml.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Response Parser
/// Parse XML responses từ ONVIF SOAP calls
class OnvifResponseParser {
  /// Parse XML response thành Map
  static Map<String, dynamic> parseXmlResponse(String xmlResponse) {
    try {
      final document = XmlDocument.parse(xmlResponse);

      // Kiểm tra SOAP Fault trước - support multiple namespace prefixes
      final faultNode = document.findAllElements('soap:Fault').firstOrNull ??
          document.findAllElements('SOAP-ENV:Fault').firstOrNull ??
          document.findAllElements('s:Fault').firstOrNull ??
          document.findAllElements('env:Fault').firstOrNull ??
          document.findAllElements('Fault').firstOrNull;

      if (faultNode != null) {
        throw _parseSoapFault(faultNode);
      }

      // Parse SOAP Body - support multiple namespace prefixes
      final bodyNode = document.findAllElements('soap:Body').firstOrNull ??
          document.findAllElements('SOAP-ENV:Body').firstOrNull ??
          document.findAllElements('s:Body').firstOrNull ??
          document.findAllElements('env:Body').firstOrNull ??
          document.findAllElements('Body').firstOrNull;

      if (bodyNode == null) {
        throw const OnvifParsingException('No SOAP Body found in response');
      }

      return _parseXmlNode(bodyNode);
    } on XmlException catch (e) {
      throw OnvifParsingException(
        'Failed to parse XML response: ${e.message}',
        rawResponse: xmlResponse,
        originalError: e,
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifParsingException(
        'Unexpected error parsing XML response: $e',
        rawResponse: xmlResponse,
        originalError: e,
      );
    }
  }

  /// Parse một XML node thành Map
  static Map<String, dynamic> _parseXmlNode(XmlNode node) {
    if (node is XmlElement) {
      final result = <String, dynamic>{};

      // Parse attributes
      for (final attribute in node.attributes) {
        result['@${attribute.name.local}'] = attribute.value;
      }

      // Get direct child elements
      final childElements = node.children.whereType<XmlElement>().toList();

      // If no child elements, this is a leaf node with text content
      if (childElements.isEmpty) {
        final textContent = node.innerText.trim();
        if (textContent.isNotEmpty) {
          return {node.name.local: textContent};
        } else {
          return {node.name.local: null};
        }
      }

      // Parse each child element
      for (final child in childElements) {
        final childName = child.name.local;
        final childResult = _parseXmlNode(child);
        final childValue = childResult[childName];

        if (result.containsKey(childName)) {
          // Handle multiple elements with same name
          if (result[childName] is List) {
            (result[childName] as List).add(childValue);
          } else {
            result[childName] = [result[childName], childValue];
          }
        } else {
          result[childName] = childValue;
        }
      }

      return {node.name.local: result};
    }

    return {};
  }

  /// Parse SOAP Fault
  static OnvifSoapException _parseSoapFault(XmlElement faultNode) {
    String? faultCode;
    String? faultString;
    String? detail;

    try {
      final faultCodeNode = faultNode.findElements('faultcode').firstOrNull ??
          faultNode.findElements('soap:Code').firstOrNull;
      faultCode = faultCodeNode?.innerText;

      final faultStringNode =
          faultNode.findElements('faultstring').firstOrNull ??
              faultNode.findElements('soap:Reason').firstOrNull;
      faultString = faultStringNode?.innerText;

      final detailNode = faultNode.findElements('detail').firstOrNull ??
          faultNode.findElements('soap:Detail').firstOrNull;
      detail = detailNode?.innerText;
    } catch (e) {
      // Nếu parsing detail thất bại, chỉ cần basic fault info
    }

    return OnvifSoapException(
      'SOAP Fault received',
      faultCode: faultCode,
      faultString: faultString,
      detail: detail,
    );
  }

  /// Parse GetDeviceInformation response
  static Map<String, dynamic> parseGetDeviceInformationResponse(
      String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm GetDeviceInformationResponse trong parsed data
    final response = _findResponseData(parsed, 'GetDeviceInformationResponse');

    // Nếu không tìm thấy response wrapper, có thể dữ liệu nằm trực tiếp trong parsed
    if (response == null || response.isEmpty) {
      // Try to find device info directly in parsed data
      final deviceKeys = [
        'Manufacturer',
        'Model',
        'FirmwareVersion',
        'SerialNumber',
        'HardwareId'
      ];
      final directData = <String, dynamic>{};

      for (final key in deviceKeys) {
        final value = _findInResponse(parsed, key);
        if (value != null) {
          directData[key] = value;
        }
      }

      if (directData.isNotEmpty) {
        return directData;
      }
    }

    return response ?? {};
  }

  /// Parse GetCapabilities response
  static Map<String, dynamic> parseGetCapabilitiesResponse(String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm GetCapabilitiesResponse trong parsed data
    final response = _findResponseData(parsed, 'GetCapabilitiesResponse');

    return response ?? {};
  }

  /// Parse GetProfiles response
  static List<Map<String, dynamic>> parseGetProfilesResponse(
      String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm GetProfilesResponse trong parsed data
    final response = _findResponseData(parsed, 'GetProfilesResponse');

    if (response == null) return [];

    final profiles = response['Profiles'];
    if (profiles == null) return [];

    if (profiles is List) {
      return profiles.cast<Map<String, dynamic>>();
    } else if (profiles is Map<String, dynamic>) {
      return [profiles];
    }

    return [];
  }

  /// Parse GetStreamUri response
  static Map<String, dynamic> parseGetStreamUriResponse(String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm GetStreamUriResponse trong parsed data
    final response = _findResponseData(parsed, 'GetStreamUriResponse');

    return response?['MediaUri'] ?? {};
  }

  /// Parse GetSnapshotUri response
  static Map<String, dynamic> parseGetSnapshotUriResponse(String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm GetSnapshotUriResponse trong parsed data
    final response = _findResponseData(parsed, 'GetSnapshotUriResponse');

    return response?['MediaUri'] ?? {};
  }

  /// Parse PTZ operation responses
  static Map<String, dynamic> parsePtzResponse(
      String xmlResponse, String operationName) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm response data cho PTZ operation
    final response = _findResponseData(parsed, '${operationName}Response');

    return response ?? {};
  }

  /// Parse Discovery response
  static List<Map<String, dynamic>> parseDiscoveryResponse(String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Discovery response có thể có nhiều ProbeMatch
    final probeMatches = <Map<String, dynamic>>[];

    // Tìm ProbeMatches
    _findProbeMatches(parsed, probeMatches);

    return probeMatches;
  }

  /// Parse Events response
  static Map<String, dynamic> parseEventsResponse(
      String xmlResponse, String operationName) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm response data cho Events operation
    final response = _findResponseData(parsed, '${operationName}Response');

    return response ?? {};
  }

  /// Parse Recording Search response
  static List<Map<String, dynamic>> parseSearchResponse(String xmlResponse) {
    final parsed = parseXmlResponse(xmlResponse);

    // Tìm SearchResult hoặc tương tự
    final results = <Map<String, dynamic>>[];
    _findSearchResults(parsed, results);

    return results;
  }

  /// Tìm response data trong parsed XML
  static Map<String, dynamic>? _findResponseData(
      Map<String, dynamic> data, String responseName) {
    // Đệ quy tìm kiếm response node
    for (final key in data.keys) {
      final value = data[key];

      if (key == responseName && value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map<String, dynamic>) {
        final found = _findResponseData(value, responseName);
        if (found != null) return found;
      }

      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final found = _findResponseData(item, responseName);
            if (found != null) return found;
          }
        }
      }
    }

    return null;
  }

  /// Tìm ProbeMatch entries trong discovery response
  static void _findProbeMatches(
      Map<String, dynamic> data, List<Map<String, dynamic>> results) {
    for (final key in data.keys) {
      final value = data[key];

      if (key == 'ProbeMatch' || key == 'ProbeMatches') {
        if (value is Map<String, dynamic>) {
          results.add(value);
        } else if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              results.add(item);
            }
          }
        }
      }

      if (value is Map<String, dynamic>) {
        _findProbeMatches(value, results);
      }

      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            _findProbeMatches(item, results);
          }
        }
      }
    }
  }

  /// Tìm search results trong recording search response
  static void _findSearchResults(
      Map<String, dynamic> data, List<Map<String, dynamic>> results) {
    for (final key in data.keys) {
      final value = data[key];

      if (key == 'SearchResult' ||
          key == 'RecordingInformation' ||
          key == 'Recording') {
        if (value is Map<String, dynamic>) {
          results.add(value);
        } else if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              results.add(item);
            }
          }
        }
      }

      if (value is Map<String, dynamic>) {
        _findSearchResults(value, results);
      }

      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            _findSearchResults(item, results);
          }
        }
      }
    }
  }

  /// Helper để normalize XML namespace prefixes
  static String normalizeNamespace(String elementName) {
    // Loại bỏ namespace prefixes để dễ dàng parsing
    final parts = elementName.split(':');
    return parts.length > 1 ? parts.last : elementName;
  }

  /// Helper để extract text content từ mixed content node
  static String extractTextContent(XmlNode node) {
    if (node is XmlElement) {
      final textNodes = node.children.whereType<XmlText>();
      return textNodes.map((e) => e.text).join('').trim();
    }
    return '';
  }

  /// Validate parsed response có required fields không
  static void validateRequiredFields(
      Map<String, dynamic> data, List<String> requiredFields,
      {String? context}) {
    final missing = <String>[];

    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        missing.add(field);
      }
    }

    if (missing.isNotEmpty) {
      throw OnvifParsingException(
        'Missing required fields: ${missing.join(', ')}'
        '${context != null ? ' in $context' : ''}',
      );
    }
  }

  /// Tìm kiếm đệ quy một key trong response data
  static dynamic _findInResponse(Map<String, dynamic> data, String key) {
    // Tìm trực tiếp
    if (data.containsKey(key)) {
      return data[key];
    }

    // Tìm đệ quy trong các nested maps
    for (final value in data.values) {
      if (value is Map<String, dynamic>) {
        final found = _findInResponse(value, key);
        if (found != null) return found;
      } else if (value is List) {
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
