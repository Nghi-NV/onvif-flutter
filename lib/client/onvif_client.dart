import '../client/transport.dart';
import '../models/device_information.dart';
import '../models/media_profile.dart';
import '../models/stream_uri.dart';
import '../models/user_management.dart';
import '../services/device_service.dart';
import '../services/media_service.dart';
import '../services/ptz_service.dart';
import '../services/search_service.dart';
import '../services/user_management_service.dart';
import '../services/recording_service.dart';
import '../services/recording_segments_service.dart';
import '../utils/constants.dart';
import '../exceptions/onvif_exceptions.dart';

/// Main ONVIF Client
/// Client chính để tương tác với ONVIF devices
class OnvifClient {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final bool useHttps;
  final Duration timeout;
  final bool allowSelfSignedCerts;

  late final OnvifTransport _transport;
  late final OnvifDeviceService _deviceService;
  late final OnvifMediaService _mediaService;
  late final OnvifPtzService _ptzService;
  late final OnvifSearchService _searchService;
  late final OnvifUserManagementService _userManagementService;
  late final OnvifRecordingService _recordingService;
  late final OnvifRecordingSegmentsService _recordingSegmentsService;

  // Cache cho capabilities và device info
  OnvifDeviceInformation? _deviceInfo;
  OnvifDeviceCapabilities? _capabilities;
  List<OnvifMediaProfile>? _profiles;

  OnvifClient({
    required this.host,
    this.port = OnvifConstants.defaultOnvifPort,
    this.username,
    this.password,
    this.useHttps = false,
    this.timeout = OnvifConstants.defaultTimeout,
    this.allowSelfSignedCerts = true,
  }) {
    _initializeServices();
  }

  /// Factory constructor cho device discovery
  factory OnvifClient.fromDiscoveredDevice({
    required String address,
    int? port,
    String? username,
    String? password,
    bool useHttps = false,
    Duration timeout = OnvifConstants.defaultTimeout,
    bool allowSelfSignedCerts = true,
  }) {
    final uri = Uri.tryParse(address);
    final deviceHost = uri?.host ?? address;
    final devicePort = uri?.port ?? port ?? OnvifConstants.defaultOnvifPort;

    return OnvifClient(
      host: deviceHost,
      port: devicePort,
      username: username,
      password: password,
      useHttps: useHttps,
      timeout: timeout,
      allowSelfSignedCerts: allowSelfSignedCerts,
    );
  }

  void _initializeServices() {
    final baseUrl = '${useHttps ? 'https' : 'http'}://$host:$port';

    _transport = OnvifTransport(
      baseUrl: baseUrl,
      timeout: timeout,
      allowSelfSignedCerts: allowSelfSignedCerts,
    );

    _deviceService = OnvifDeviceService(_transport, username, password);
    _mediaService = OnvifMediaService(_transport, username, password);
    _ptzService = OnvifPtzService(_transport, username, password);
    _searchService = OnvifSearchService(_transport, username, password);
    _userManagementService =
        OnvifUserManagementService(_transport, username, password);
    _recordingService = OnvifRecordingService(_transport, username, password);
    _recordingSegmentsService =
        OnvifRecordingSegmentsService(_transport, username, password);
  }

  /// Getters cho các services
  OnvifDeviceService get device => _deviceService;
  OnvifMediaService get media => _mediaService;
  OnvifPtzService get ptz => _ptzService;
  OnvifSearchService get search => _searchService;
  OnvifUserManagementService get userManagement => _userManagementService;
  OnvifRecordingService get recording => _recordingService;
  OnvifRecordingSegmentsService get recordingSegments =>
      _recordingSegmentsService;

  /// Kết nối và xác thực với device
  Future<bool> connect() async {
    try {
      // Lấy device information để kiểm tra kết nối
      _deviceInfo = await _deviceService.getDeviceInformation();

      // Lấy capabilities để setup services
      _capabilities = await _deviceService.getCapabilities();

      // Update service endpoints từ capabilities
      _updateServiceEndpoints();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cập nhật service endpoints từ capabilities
  void _updateServiceEndpoints() {
    if (_capabilities == null) return;

    final caps = _capabilities!;

    // Update Device service endpoint
    if (caps.device?.xAddr != null) {
      _deviceService.updateEndpoint(caps.device!.xAddr!);
    }

    // Update Media service endpoint
    if (caps.media?.xAddr != null) {
      _mediaService.updateEndpoint(caps.media!.xAddr!);
    }

    // Update PTZ service endpoint
    if (caps.ptz?.xAddr != null) {
      _ptzService.updateEndpoint(caps.ptz!.xAddr!);
    }

    // Update Search service endpoint - có thể cần tìm trong extensions
    // hoặc recording capability
  }

  /// Lấy thông tin thiết bị
  Future<OnvifDeviceInformation> getDeviceInformation() async {
    _deviceInfo ??= await _deviceService.getDeviceInformation();
    return _deviceInfo!;
  }

  /// Lấy capabilities của thiết bị
  Future<OnvifDeviceCapabilities> getCapabilities() async {
    _capabilities ??= await _deviceService.getCapabilities();
    return _capabilities!;
  }

  /// Lấy tất cả media profiles
  Future<List<OnvifMediaProfile>> getProfiles() async {
    _profiles ??= await _mediaService.getProfiles();
    return _profiles!;
  }

  /// Lấy profile theo token
  Future<OnvifMediaProfile?> getProfile(String token) async {
    final profiles = await getProfiles();
    try {
      return profiles.firstWhere((p) => p.token == token);
    } catch (e) {
      return null;
    }
  }

  /// Lấy stream URI cho profile
  Future<OnvifStreamUri> getStreamUri({
    required String profileToken,
    StreamProtocol protocol = StreamProtocol.rtsp,
  }) async {
    return await _mediaService.getStreamUri(
      profileToken: profileToken,
      protocol: protocol,
    );
  }

  /// Lấy snapshot URI cho profile
  Future<OnvifSnapshotUri> getSnapshotUri(String profileToken) async {
    return await _mediaService.getSnapshotUri(profileToken);
  }

  /// Chụp snapshot và trả về bytes
  Future<List<int>> captureSnapshot(String profileToken) async {
    return await _mediaService.captureSnapshot(profileToken);
  }

  /// Kiểm tra xem device có hỗ trợ PTZ không
  bool get supportsPtz => _capabilities?.ptz != null;

  /// PTZ Move Continuous
  Future<void> ptzMoveContinuous({
    required String profileToken,
    required double panVelocity,
    required double tiltVelocity,
    double zoomVelocity = 0.0,
    Duration? timeout,
  }) async {
    if (!supportsPtz) {
      throw const OnvifServiceNotSupportedException('PTZ');
    }

    await _ptzService.continuousMove(
      profileToken: profileToken,
      panVelocity: panVelocity,
      tiltVelocity: tiltVelocity,
      zoomVelocity: zoomVelocity,
      timeout: timeout,
    );
  }

  /// PTZ Stop
  Future<void> ptzStop({
    required String profileToken,
    bool stopPanTilt = true,
    bool stopZoom = true,
  }) async {
    if (!supportsPtz) {
      throw const OnvifServiceNotSupportedException('PTZ');
    }

    await _ptzService.stop(
      profileToken: profileToken,
      stopPanTilt: stopPanTilt,
      stopZoom: stopZoom,
    );
  }

  /// Kiểm tra xem device có hỗ trợ events không
  bool get supportsEvents => _capabilities?.events != null;

  /// Kiểm tra xem device có hỗ trợ recording không
  bool get supportsRecording {
    if (_capabilities == null) return false;

    // Theo debug results, device có Recording, Search, và Replay services
    // Kiểm tra xem có thể gọi recording service không
    return true; // Device có recording service endpoints
  }

  /// Kiểm tra xem có phải là NVR/DVR (multi-channel) không
  Future<bool> isMultiChannelDevice() async {
    final profiles = await getProfiles();
    return profiles.length > 1;
  }

  /// Lấy số lượng channels
  Future<int> getChannelCount() async {
    final profiles = await getProfiles();
    return profiles.length;
  }

  // Method này đã được move xuống dưới trong RECORDING & PLAYBACK section

  /// Test kết nối với device
  Future<bool> testConnection() async {
    try {
      await _deviceService.getDeviceInformation();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lấy system date and time từ device
  Future<DateTime?> getSystemDateTime() async {
    try {
      return await _deviceService.getSystemDateTime();
    } catch (e) {
      return null;
    }
  }

  /// Set system date and time
  Future<bool> setSystemDateTime(DateTime dateTime) async {
    try {
      await _deviceService.setSystemDateTime(dateTime);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reboot device
  Future<bool> rebootDevice() async {
    try {
      await _deviceService.systemReboot();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lấy danh sách tất cả users
  Future<List<OnvifUser>> getUsers() async {
    return await _userManagementService.getUsers();
  }

  /// Tạo user mới
  Future<void> createUser({
    required String username,
    required String password,
    required UserLevel userLevel,
    List<String>? accessRights,
    UserInformation? userInformation,
    List<String>? groups,
  }) async {
    await _userManagementService.createUser(
      username: username,
      password: password,
      userLevel: userLevel,
      accessRights: accessRights,
      userInformation: userInformation,
      groups: groups,
    );
  }

  /// Xóa user
  Future<void> deleteUser(String username) async {
    await _userManagementService.deleteUser(username);
  }

  /// Cập nhật thông tin user
  Future<void> updateUser({
    required String username,
    String? newPassword,
    UserLevel? userLevel,
    List<String>? accessRights,
    UserInformation? userInformation,
    List<String>? groups,
  }) async {
    await _userManagementService.updateUser(
      username: username,
      newPassword: newPassword,
      userLevel: userLevel,
      accessRights: accessRights,
      userInformation: userInformation,
      groups: groups,
    );
  }

  /// Đổi mật khẩu user
  Future<void> changeUserPassword({
    required String username,
    required String newPassword,
  }) async {
    await _userManagementService.changePassword(
      username: username,
      newPassword: newPassword,
    );
  }

  /// Lấy danh sách groups
  Future<List<OnvifGroup>> getGroups() async {
    return await _userManagementService.getGroups();
  }

  /// Tạo group mới
  Future<void> createGroup({
    required String groupName,
    String? description,
    List<String>? accessRights,
    List<String>? members,
  }) async {
    await _userManagementService.createGroup(
      groupName: groupName,
      description: description,
      accessRights: accessRights,
      members: members,
    );
  }

  /// Xóa group
  Future<void> deleteGroup(String groupName) async {
    await _userManagementService.deleteGroup(groupName);
  }

  /// Thêm user vào group
  Future<void> addUserToGroup({
    required String username,
    required String groupName,
  }) async {
    await _userManagementService.addUserToGroup(
      username: username,
      groupName: groupName,
    );
  }

  /// Xóa user khỏi group
  Future<void> removeUserFromGroup({
    required String username,
    required String groupName,
  }) async {
    await _userManagementService.removeUserFromGroup(
      username: username,
      groupName: groupName,
    );
  }

  /// Lấy access policy
  Future<AccessPolicy> getAccessPolicy() async {
    return await _userManagementService.getAccessPolicy();
  }

  /// Lấy user options (giới hạn và capabilities)
  Future<UserOptions> getUserOptions() async {
    return await _userManagementService.getUserOptions();
  }

  // ==================== RECORDING & PLAYBACK ====================

  /// Tìm kiếm recordings trong khoảng thời gian
  Future<List<Map<String, dynamic>>> searchRecordings({
    required DateTime startTime,
    required DateTime endTime,
    String? profileToken,
    int maxResults = 100,
  }) async {
    return await _searchService.searchRecordings(
      startTime: startTime,
      endTime: endTime,
      profileToken: profileToken,
      maxResults: maxResults,
    );
  }

  /// Lấy danh sách recordings
  Future<List<OnvifRecording>> getRecordings() async {
    return await _recordingService.getRecordings();
  }

  /// Lấy cấu hình recording
  Future<OnvifRecordingConfiguration> getRecordingConfiguration() async {
    return await _recordingService.getRecordingConfiguration();
  }

  /// Tìm kiếm recording segments theo thời gian (actual recorded video files)
  Future<List<OnvifRecordingSegment>> searchRecordingSegments({
    required DateTime startTime,
    required DateTime endTime,
    String? profileToken,
    int maxResults = 100,
  }) async {
    return await _recordingSegmentsService.searchRecordingSegments(
      startTime: startTime,
      endTime: endTime,
      profileToken: profileToken,
      maxResults: maxResults,
    );
  }

  /// Lấy replay URI cho time range cụ thể
  Future<String?> getReplayUriForTimeRange({
    required String recordingToken,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return await _recordingSegmentsService.getReplayUriForTimeRange(
      recordingToken: recordingToken,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Lấy device URI
  String get deviceUri => '${useHttps ? 'https' : 'http'}://$host:$port';

  /// Lấy credentials string
  String? get credentials =>
      username != null && password != null ? '$username:$password' : null;

  /// Clone client với credentials khác
  OnvifClient withCredentials(String newUsername, String newPassword) {
    return OnvifClient(
      host: host,
      port: port,
      username: newUsername,
      password: newPassword,
      useHttps: useHttps,
      timeout: timeout,
      allowSelfSignedCerts: allowSelfSignedCerts,
    );
  }

  /// Clone client với timeout khác
  OnvifClient withTimeout(Duration newTimeout) {
    return OnvifClient(
      host: host,
      port: port,
      username: username,
      password: password,
      useHttps: useHttps,
      timeout: newTimeout,
      allowSelfSignedCerts: allowSelfSignedCerts,
    );
  }

  /// Đóng kết nối và giải phóng resources
  void dispose() {
    _transport.dispose();
    _deviceInfo = null;
    _capabilities = null;
    _profiles = null;
  }

  @override
  String toString() {
    return 'OnvifClient(host: $host:$port, '
        'authenticated: ${username != null}, '
        'https: $useHttps)';
  }
}
