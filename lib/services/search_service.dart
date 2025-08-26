import '../client/transport.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF Search Service
/// Quản lý các operations liên quan đến tìm kiếm recordings và events
class OnvifSearchService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = OnvifConstants.defaultSearchServicePath;

  OnvifSearchService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  /// Tìm kiếm recordings theo thời gian
  /// NOTE: Fallback implementation dùng GetRecordings vì FindRecordings không support trên Dahua
  Future<List<Map<String, dynamic>>> searchRecordings({
    required DateTime startTime,
    required DateTime endTime,
    String? profileToken,
    int maxResults = 100,
    String? searchScope,
  }) async {
    try {
      // Try FindRecordings first (standard ONVIF)
      final findResults = await _tryFindRecordings(
          startTime, endTime, profileToken, maxResults, searchScope);

      // Kiểm tra xem có results không - nếu không có, fallback
      if (findResults.isEmpty) {
        return await _fallbackGetRecordings(startTime, endTime, maxResults);
      }

      return findResults;
    } catch (e) {
      // Fallback: Dùng GetRecordings từ recording service
      try {
        return await _fallbackGetRecordings(startTime, endTime, maxResults);
      } catch (fallbackError) {
        throw OnvifConnectionException(
          'Both FindRecordings and GetRecordings failed. Device may not support recording search.',
          originalError: fallbackError,
        );
      }
    }
  }

  /// Try standard ONVIF FindRecordings
  Future<List<Map<String, dynamic>>> _tryFindRecordings(
    DateTime startTime,
    DateTime endTime,
    String? profileToken,
    int maxResults,
    String? searchScope,
  ) async {
    final soapRequest = _hasCredentials
        ? OnvifRequestBuilder.createSecureSoapEnvelope(
            body: _buildSearchRecordingsBody(
              startTime,
              endTime,
              profileToken,
              maxResults,
              searchScope,
            ),
            username: _username!,
            password: _password!,
            action: '${OnvifConstants.searchNamespace}/FindRecordings',
            headers: {
              'tse': OnvifConstants.searchNamespace,
              'tt': 'http://www.onvif.org/ver10/schema',
            },
          )
        : OnvifRequestBuilder.createSoapEnvelope(
            body: _buildSearchRecordingsBody(
              startTime,
              endTime,
              profileToken,
              maxResults,
              searchScope,
            ),
            action: '${OnvifConstants.searchNamespace}/FindRecordings',
            headers: {
              'tse': OnvifConstants.searchNamespace,
              'tt': 'http://www.onvif.org/ver10/schema',
            },
          );

    final response = await _transport.sendSoapRequest(
      path: _serviceEndpoint,
      soapBody: soapRequest,
      soapAction: '${OnvifConstants.searchNamespace}/FindRecordings',
    );

    // Check nếu response chứa SOAP Fault, throw exception để trigger fallback
    if (response.contains('<s:Fault>') || response.contains('Unknown Error')) {
      throw OnvifSoapException('FindRecordings not supported by device');
    }

    return OnvifResponseParser.parseSearchResponse(response);
  }

  /// Fallback: GetRecordings từ recording service
  Future<List<Map<String, dynamic>>> _fallbackGetRecordings(
    DateTime startTime,
    DateTime endTime,
    int maxResults,
  ) async {
    final recordingRequest = _hasCredentials
        ? OnvifRequestBuilder.createSecureSoapEnvelope(
            body:
                '<trc:GetRecordings xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
            username: _username!,
            password: _password!,
            action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
            headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
          )
        : OnvifRequestBuilder.createSoapEnvelope(
            body:
                '<trc:GetRecordings xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
            action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
            headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
          );

    final response = await _transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: recordingRequest,
      soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordings',
    );

    return _parseGetRecordingsAsFallback(
        response, startTime, endTime, maxResults);
  }

  /// Parse GetRecordings response cho fallback search
  List<Map<String, dynamic>> _parseGetRecordingsAsFallback(
    String response,
    DateTime startTime,
    DateTime endTime,
    int maxResults,
  ) {
    try {
      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final recordingItems = _findInResponse(parsed, 'RecordingItem') ?? [];

      final results = <Map<String, dynamic>>[];

      if (recordingItems is List) {
        for (final item in recordingItems) {
          if (item is Map<String, dynamic>) {
            results
                .add(_convertRecordingToSearchResult(item, startTime, endTime));
          }
        }
      } else if (recordingItems is Map<String, dynamic>) {
        results.add(_convertRecordingToSearchResult(
            recordingItems, startTime, endTime));
      }

      // Limit results
      return results.take(maxResults).toList();
    } catch (e) {
      throw OnvifParsingException('Failed to parse GetRecordings response: $e');
    }
  }

  /// Convert recording item to search result format
  Map<String, dynamic> _convertRecordingToSearchResult(
    Map<String, dynamic> recordingItem,
    DateTime startTime,
    DateTime endTime,
  ) {
    final token = recordingItem['RecordingToken'] ?? '';
    final config = recordingItem['Configuration'] ?? {};
    final source = config['Source'] ?? {};
    final tracks = recordingItem['Tracks'] ?? {};

    return {
      'RecordingToken': token,
      'StartTime': startTime.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
      'Source': source['Name'] ?? 'Unknown',
      'Description': source['Description'] ?? 'Recording from camera',
      'Tracks': tracks,
      'IsEstimated': true, // Flag để biết đây là estimated time
    };
  }

  /// Tìm kiếm events theo thời gian
  Future<List<Map<String, dynamic>>> searchEvents({
    required DateTime startTime,
    required DateTime endTime,
    String? searchScope,
    int maxResults = 100,
    List<String>? eventTypes,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildSearchEventsBody(
                startTime,
                endTime,
                searchScope,
                maxResults,
                eventTypes,
              ),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.searchNamespace}/FindEvents',
              headers: {
                'tse': OnvifConstants.searchNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body: _buildSearchEventsBody(
                startTime,
                endTime,
                searchScope,
                maxResults,
                eventTypes,
              ),
              action: '${OnvifConstants.searchNamespace}/FindEvents',
              headers: {
                'tse': OnvifConstants.searchNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.searchNamespace}/FindEvents',
      );

      return OnvifResponseParser.parseSearchResponse(response);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifEventException(
        'Failed to search events: $e',
        originalError: e,
      );
    }
  }

  /// Lấy search results với pagination
  Future<Map<String, dynamic>> getSearchResults({
    required String searchToken,
    int? minResults,
    int? maxResults,
    Duration? waitTime,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildGetSearchResultsBody(
                searchToken,
                minResults,
                maxResults,
                waitTime,
              ),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.searchNamespace}/GetSearchResults',
              headers: {'tse': OnvifConstants.searchNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body: _buildGetSearchResultsBody(
                searchToken,
                minResults,
                maxResults,
                waitTime,
              ),
              action: '${OnvifConstants.searchNamespace}/GetSearchResults',
              headers: {'tse': OnvifConstants.searchNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.searchNamespace}/GetSearchResults',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _findInResponse(parsed, 'GetSearchResultsResponse') ?? {};
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifRecordingException(
        'Failed to get search results: $e',
        originalError: e,
      );
    }
  }

  /// Kết thúc search session
  Future<void> endSearch(String searchToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tse:EndSearch xmlns:tse="${OnvifConstants.searchNamespace}"><tse:SearchToken>$searchToken</tse:SearchToken></tse:EndSearch>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.searchNamespace}/EndSearch',
              headers: {'tse': OnvifConstants.searchNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tse:EndSearch xmlns:tse="${OnvifConstants.searchNamespace}"><tse:SearchToken>$searchToken</tse:SearchToken></tse:EndSearch>',
              action: '${OnvifConstants.searchNamespace}/EndSearch',
              headers: {'tse': OnvifConstants.searchNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.searchNamespace}/EndSearch',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifRecordingException(
        'Failed to end search: $e',
        originalError: e,
      );
    }
  }

  /// Lấy search state
  Future<Map<String, dynamic>> getSearchState(String searchToken) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tse:GetSearchState xmlns:tse="${OnvifConstants.searchNamespace}"><tse:SearchToken>$searchToken</tse:SearchToken></tse:GetSearchState>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.searchNamespace}/GetSearchState',
              headers: {'tse': OnvifConstants.searchNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tse:GetSearchState xmlns:tse="${OnvifConstants.searchNamespace}"><tse:SearchToken>$searchToken</tse:SearchToken></tse:GetSearchState>',
              action: '${OnvifConstants.searchNamespace}/GetSearchState',
              headers: {'tse': OnvifConstants.searchNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.searchNamespace}/GetSearchState',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      return _findInResponse(parsed, 'SearchState') ?? {};
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifRecordingException(
        'Failed to get search state: $e',
        originalError: e,
      );
    }
  }

  /// Tìm kiếm metadata theo thời gian
  Future<List<Map<String, dynamic>>> searchMetadata({
    required DateTime startTime,
    required DateTime endTime,
    String? searchScope,
    int maxResults = 100,
    List<String>? metadataTypes,
  }) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body: _buildSearchMetadataBody(
                startTime,
                endTime,
                searchScope,
                maxResults,
                metadataTypes,
              ),
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.searchNamespace}/FindMetadata',
              headers: {
                'tse': OnvifConstants.searchNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body: _buildSearchMetadataBody(
                startTime,
                endTime,
                searchScope,
                maxResults,
                metadataTypes,
              ),
              action: '${OnvifConstants.searchNamespace}/FindMetadata',
              headers: {
                'tse': OnvifConstants.searchNamespace,
                'tt': 'http://www.onvif.org/ver10/schema',
              },
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.searchNamespace}/FindMetadata',
      );

      return OnvifResponseParser.parseSearchResponse(response);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifRecordingException(
        'Failed to search metadata: $e',
        originalError: e,
      );
    }
  }

  /// Helper methods
  bool get _hasCredentials => _username != null && _password != null;

  dynamic _findInResponse(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) {
      return data[key];
    }

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

  String _buildSearchRecordingsBody(
    DateTime startTime,
    DateTime endTime,
    String? profileToken,
    int maxResults,
    String? searchScope,
  ) {
    final startTimeStr = _formatDateTime(startTime);
    final endTimeStr = _formatDateTime(endTime);

    final buffer = StringBuffer();
    buffer.write(
        '<tse:FindRecordings xmlns:tse="${OnvifConstants.searchNamespace}">');

    if (searchScope != null) {
      buffer.write(
          '<tse:Scope><tse:IncludedSources><tt:Token xmlns:tt="http://www.onvif.org/ver10/schema">$searchScope</tt:Token></tse:IncludedSources></tse:Scope>');
    }

    buffer.write('<tse:SearchCriteria>');
    buffer.write('<tse:RecordingInformationFilter>');

    if (profileToken != null) {
      buffer.write('<tse:RecordingToken>$profileToken</tse:RecordingToken>');
    }

    buffer.write('</tse:RecordingInformationFilter>');
    buffer.write('</tse:SearchCriteria>');

    buffer.write('<tse:StartPoint>$startTimeStr</tse:StartPoint>');
    buffer.write('<tse:EndPoint>$endTimeStr</tse:EndPoint>');
    buffer.write('<tse:MaxMatches>$maxResults</tse:MaxMatches>');
    buffer.write('<tse:KeepAliveTime>PT60S</tse:KeepAliveTime>');

    buffer.write('</tse:FindRecordings>');
    return buffer.toString();
  }

  String _buildSearchEventsBody(
    DateTime startTime,
    DateTime endTime,
    String? searchScope,
    int maxResults,
    List<String>? eventTypes,
  ) {
    final startTimeStr = _formatDateTime(startTime);
    final endTimeStr = _formatDateTime(endTime);

    final buffer = StringBuffer();
    buffer.write(
        '<tse:FindEvents xmlns:tse="${OnvifConstants.searchNamespace}">');

    if (searchScope != null) {
      buffer.write(
          '<tse:Scope><tse:IncludedSources><tt:Token xmlns:tt="http://www.onvif.org/ver10/schema">$searchScope</tt:Token></tse:IncludedSources></tse:Scope>');
    }

    buffer.write('<tse:SearchCriteria>');

    if (eventTypes != null && eventTypes.isNotEmpty) {
      for (final eventType in eventTypes) {
        buffer.write(
            '<tse:EventFilter><wsnt:TopicExpression xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2">$eventType</wsnt:TopicExpression></tse:EventFilter>');
      }
    }

    buffer.write('</tse:SearchCriteria>');

    buffer.write('<tse:StartPoint>$startTimeStr</tse:StartPoint>');
    buffer.write('<tse:EndPoint>$endTimeStr</tse:EndPoint>');
    buffer.write('<tse:MaxMatches>$maxResults</tse:MaxMatches>');
    buffer.write('<tse:KeepAliveTime>PT60S</tse:KeepAliveTime>');

    buffer.write('</tse:FindEvents>');
    return buffer.toString();
  }

  String _buildSearchMetadataBody(
    DateTime startTime,
    DateTime endTime,
    String? searchScope,
    int maxResults,
    List<String>? metadataTypes,
  ) {
    final startTimeStr = _formatDateTime(startTime);
    final endTimeStr = _formatDateTime(endTime);

    final buffer = StringBuffer();
    buffer.write(
        '<tse:FindMetadata xmlns:tse="${OnvifConstants.searchNamespace}">');

    if (searchScope != null) {
      buffer.write(
          '<tse:Scope><tse:IncludedSources><tt:Token xmlns:tt="http://www.onvif.org/ver10/schema">$searchScope</tt:Token></tse:IncludedSources></tse:Scope>');
    }

    buffer.write('<tse:SearchCriteria>');

    if (metadataTypes != null && metadataTypes.isNotEmpty) {
      for (final metadataType in metadataTypes) {
        buffer.write(
            '<tse:MetadataFilter><tse:MetadataStreamFilter><tt:MetadataTypes xmlns:tt="http://www.onvif.org/ver10/schema">$metadataType</tt:MetadataTypes></tse:MetadataStreamFilter></tse:MetadataFilter>');
      }
    }

    buffer.write('</tse:SearchCriteria>');

    buffer.write('<tse:StartPoint>$startTimeStr</tse:StartPoint>');
    buffer.write('<tse:EndPoint>$endTimeStr</tse:EndPoint>');
    buffer.write('<tse:MaxMatches>$maxResults</tse:MaxMatches>');
    buffer.write('<tse:KeepAliveTime>PT60S</tse:KeepAliveTime>');

    buffer.write('</tse:FindMetadata>');
    return buffer.toString();
  }

  String _buildGetSearchResultsBody(
    String searchToken,
    int? minResults,
    int? maxResults,
    Duration? waitTime,
  ) {
    final buffer = StringBuffer();
    buffer.write(
        '<tse:GetSearchResults xmlns:tse="${OnvifConstants.searchNamespace}">');
    buffer.write('<tse:SearchToken>$searchToken</tse:SearchToken>');

    if (minResults != null) {
      buffer.write('<tse:MinResults>$minResults</tse:MinResults>');
    }

    if (maxResults != null) {
      buffer.write('<tse:MaxResults>$maxResults</tse:MaxResults>');
    }

    if (waitTime != null) {
      buffer.write('<tse:WaitTime>PT${waitTime.inSeconds}S</tse:WaitTime>');
    }

    buffer.write('</tse:GetSearchResults>');
    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.toIso8601String();
  }

  // Duplicate method removed - using the one above
}
