import 'package:onvif_flutter/onvif_flutter.dart';

/// Explore recording segments - tìm actual recorded video files
void main() async {
  print('=== Explore Recording Segments ===\n');

  final client = OnvifClient(
    host: 'fb000033.ddns.net',
    port: 8080,
    username: 'admin',
    password: 'FB000033',
  );

  try {
    await client.connect();
    print('✅ Connected successfully!\n');

    final transport = OnvifTransport(
      baseUrl: 'http://fb000033.ddns.net:8080',
      timeout: Duration(seconds: 30),
    );

    // ==================== 1. EXPLORE SEARCH SERVICE METHODS ====================
    print('🔍 Exploring Search Service Methods...\n');

    // Method A: FindEvents (có thể chứa recording events)
    await _testFindEvents(transport);

    // Method B: GetEventProperties
    await _testGetEventProperties(transport);

    // Method C: FindPTZPosition
    await _testFindPTZPosition(transport);

    // Method D: FindMetadata
    await _testFindMetadata(transport);

    // ==================== 2. EXPLORE RECORDING SERVICE ADVANCED ====================
    print('\n🎬 Exploring Recording Service Advanced Methods...\n');

    // Method E: GetRecordingJobs
    await _testGetRecordingJobs(transport);

    // Method F: GetRecordingJobConfiguration
    await _testGetRecordingJobConfiguration(transport);

    // Method G: GetRecordingJobState
    await _testGetRecordingJobState(transport);

    // ==================== 3. EXPLORE REPLAY SERVICE ====================
    print('\n▶️ Exploring Replay Service Methods...\n');

    // Method H: GetReplayUri với time ranges
    await _testGetReplayUriWithTime(transport);

    // Method I: SetReplayConfiguration
    await _testSetReplayConfiguration(transport);

    // ==================== 4. EXPLORE MEDIA2 SERVICE ====================
    print('\n📹 Exploring Media2 Service (newer ONVIF)...\n');

    // Method J: GetProfiles (Media2)
    await _testMedia2GetProfiles(transport);

    // ==================== 5. DAHUA PROPRIETARY METHODS ====================
    print('\n🏭 Exploring Dahua Proprietary Methods...\n');

    // Method K: Dahua GetRecordInfo
    await _testDahuaGetRecordInfo(transport);

    // Method L: Dahua QueryRecordFile
    await _testDahuaQueryRecordFile(transport);

    transport.dispose();
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

Future<void> _testFindEvents(OnvifTransport transport) async {
  try {
    print('Method A: FindEvents...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<tse:FindEvents xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
        <tse:StartPoint>${DateTime.now().subtract(Duration(hours: 2)).toIso8601String()}</tse:StartPoint>
        <tse:EndPoint>${DateTime.now().toIso8601String()}</tse:EndPoint>
        <tse:MaxMatches>50</tse:MaxMatches>
        <tse:IncludeStartState>true</tse:IncludeStartState>
      </tse:FindEvents>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/search/wsdl/FindEvents',
      headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/search_service',
      soapBody: request,
      soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindEvents',
    );

    print('✅ FindEvents successful');
    print('Response length: ${response.length}');
    if (response.length > 300) {
      print('First 300 chars: ${response.substring(0, 300)}...');
    } else {
      print('Response: $response');
    }
  } catch (e) {
    print('❌ FindEvents failed: $e');
  }
}

Future<void> _testGetEventProperties(OnvifTransport transport) async {
  try {
    print('\nMethod B: GetEventProperties...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<tse:GetEventSearchOptions xmlns:tse="http://www.onvif.org/ver10/search/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/search/wsdl/GetEventSearchOptions',
      headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/search_service',
      soapBody: request,
      soapAction:
          'http://www.onvif.org/ver10/search/wsdl/GetEventSearchOptions',
    );

    print('✅ GetEventSearchOptions successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ GetEventSearchOptions failed: $e');
  }
}

Future<void> _testFindPTZPosition(OnvifTransport transport) async {
  try {
    print('\nMethod C: FindPTZPosition...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<tse:FindPTZPosition xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
        <tse:StartPoint>${DateTime.now().subtract(Duration(hours: 1)).toIso8601String()}</tse:StartPoint>
        <tse:EndPoint>${DateTime.now().toIso8601String()}</tse:EndPoint>
        <tse:MaxMatches>10</tse:MaxMatches>
      </tse:FindPTZPosition>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/search/wsdl/FindPTZPosition',
      headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/search_service',
      soapBody: request,
      soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindPTZPosition',
    );

    print('✅ FindPTZPosition successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ FindPTZPosition failed: $e');
  }
}

Future<void> _testFindMetadata(OnvifTransport transport) async {
  try {
    print('\nMethod D: FindMetadata...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<tse:FindMetadata xmlns:tse="http://www.onvif.org/ver10/search/wsdl">
        <tse:StartPoint>${DateTime.now().subtract(Duration(hours: 1)).toIso8601String()}</tse:StartPoint>
        <tse:EndPoint>${DateTime.now().toIso8601String()}</tse:EndPoint>
        <tse:MaxMatches>10</tse:MaxMatches>
      </tse:FindMetadata>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/search/wsdl/FindMetadata',
      headers: {'tse': 'http://www.onvif.org/ver10/search/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/search_service',
      soapBody: request,
      soapAction: 'http://www.onvif.org/ver10/search/wsdl/FindMetadata',
    );

    print('✅ FindMetadata successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ FindMetadata failed: $e');
  }
}

Future<void> _testGetRecordingJobs(OnvifTransport transport) async {
  try {
    print('Method E: GetRecordingJobs...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trc:GetRecordingJobs xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: request,
      soapAction: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobs',
    );

    print('✅ GetRecordingJobs successful');
    print(
        'Response: ${response.substring(0, response.length > 500 ? 500 : response.length)}');
  } catch (e) {
    print('❌ GetRecordingJobs failed: $e');
  }
}

Future<void> _testGetRecordingJobConfiguration(OnvifTransport transport) async {
  try {
    print('\nMethod F: GetRecordingJobConfiguration...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trc:GetRecordingJobConfiguration xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action:
          'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobConfiguration',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: request,
      soapAction:
          'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobConfiguration',
    );

    print('✅ GetRecordingJobConfiguration successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ GetRecordingJobConfiguration failed: $e');
  }
}

Future<void> _testGetRecordingJobState(OnvifTransport transport) async {
  try {
    print('\nMethod G: GetRecordingJobState...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trc:GetRecordingJobState xmlns:trc="http://www.onvif.org/ver10/recording/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
      headers: {'trc': 'http://www.onvif.org/ver10/recording/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/recording_service',
      soapBody: request,
      soapAction:
          'http://www.onvif.org/ver10/recording/wsdl/GetRecordingJobState',
    );

    print('✅ GetRecordingJobState successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ GetRecordingJobState failed: $e');
  }
}

Future<void> _testGetReplayUriWithTime(OnvifTransport transport) async {
  try {
    print('Method H: GetReplayUri with specific time...');
    final startTime = DateTime.now().subtract(Duration(hours: 1));
    final endTime = DateTime.now().subtract(Duration(minutes: 58));

    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '''<trp:GetReplayUri xmlns:trp="http://www.onvif.org/ver10/replay/wsdl">
        <trp:StreamSetup>
          <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
          <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
            <tt:Protocol>RTSP</tt:Protocol>
          </tt:Transport>
        </trp:StreamSetup>
        <trp:RecordingToken>RecordMediaProfile00000</trp:RecordingToken>
        <trp:Time>
          <tt:From xmlns:tt="http://www.onvif.org/ver10/schema">${startTime.toIso8601String()}</tt:From>
          <tt:Until xmlns:tt="http://www.onvif.org/ver10/schema">${endTime.toIso8601String()}</tt:Until>
        </trp:Time>
      </trp:GetReplayUri>''',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
      headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/replay_service',
      soapBody: request,
      soapAction: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayUri',
    );

    print('✅ GetReplayUri with time successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ GetReplayUri with time failed: $e');
  }
}

Future<void> _testSetReplayConfiguration(OnvifTransport transport) async {
  try {
    print('\nMethod I: GetReplayConfiguration...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<trp:GetReplayConfiguration xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
      headers: {'trp': 'http://www.onvif.org/ver10/replay/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/replay_service',
      soapBody: request,
      soapAction:
          'http://www.onvif.org/ver10/replay/wsdl/GetReplayConfiguration',
    );

    print('✅ GetReplayConfiguration successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ GetReplayConfiguration failed: $e');
  }
}

Future<void> _testMedia2GetProfiles(OnvifTransport transport) async {
  try {
    print('Method J: Media2 GetProfiles...');
    final request = OnvifRequestBuilder.createSecureSoapEnvelope(
      body:
          '<tr2:GetProfiles xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"/>',
      username: 'admin',
      password: 'FB000033',
      action: 'http://www.onvif.org/ver20/media/wsdl/GetProfiles',
      headers: {'tr2': 'http://www.onvif.org/ver20/media/wsdl'},
    );

    final response = await transport.sendSoapRequest(
      path: '/onvif/media2_service',
      soapBody: request,
      soapAction: 'http://www.onvif.org/ver20/media/wsdl/GetProfiles',
    );

    print('✅ Media2 GetProfiles successful');
    print(
        'Response: ${response.substring(0, response.length > 300 ? 300 : response.length)}');
  } catch (e) {
    print('❌ Media2 GetProfiles failed: $e');
  }
}

Future<void> _testDahuaGetRecordInfo(OnvifTransport transport) async {
  try {
    print('Method K: Dahua GetRecordInfo...');

    // Try different Dahua proprietary endpoints
    final endpoints = [
      '/RPC2',
      '/cgi-bin/recordManager.cgi',
      '/cgi-bin/mediaFileFind.cgi',
      '/onvif/dahua_service',
    ];

    for (final endpoint in endpoints) {
      try {
        print('  Trying endpoint: $endpoint');

        final request = OnvifRequestBuilder.createSecureSoapEnvelope(
          body:
              '''<dh:GetRecordInfo xmlns:dh="http://www.dahua.com/ver10/recording/wsdl">
            <dh:StartTime>${DateTime.now().subtract(Duration(hours: 2)).toIso8601String()}</dh:StartTime>
            <dh:EndTime>${DateTime.now().toIso8601String()}</dh:EndTime>
          </dh:GetRecordInfo>''',
          username: 'admin',
          password: 'FB000033',
          action: 'GetRecordInfo',
          headers: {'dh': 'http://www.dahua.com/ver10/recording/wsdl'},
        );

        final response = await transport.sendSoapRequest(
          path: endpoint,
          soapBody: request,
          soapAction: 'GetRecordInfo',
        );

        print('    ✅ Success at $endpoint');
        print(
            '    Response: ${response.substring(0, response.length > 200 ? 200 : response.length)}');
        break;
      } catch (e) {
        print('    ❌ Failed at $endpoint: $e');
      }
    }
  } catch (e) {
    print('❌ Dahua GetRecordInfo completely failed: $e');
  }
}

Future<void> _testDahuaQueryRecordFile(OnvifTransport transport) async {
  try {
    print('\nMethod L: Dahua QueryRecordFile...');

    // CGI-based approach
    final cgiRequest =
        'action=getRecordFileList&channel=0&startTime=${DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000}&endTime=${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    print('  Trying CGI approach...');
    print('  URL: /cgi-bin/mediaFileFind.cgi?$cgiRequest');
  } catch (e) {
    print('❌ Dahua QueryRecordFile failed: $e');
  }
}
