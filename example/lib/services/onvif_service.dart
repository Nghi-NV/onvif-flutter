import 'package:onvif_flutter/onvif_flutter.dart';
import '../models/device_model.dart';

class OnvifService {
  OnvifClient? _client;
  DeviceModel? _currentDevice;

  OnvifClient? get client => _client;
  DeviceModel? get currentDevice => _currentDevice;

  Future<bool> connectToDevice(DeviceModel device) async {
    try {
      _client = OnvifClient(
        host: device.host,
        port: device.port,
        username: device.username,
        password: device.password,
      );

      _client!.connect();
      _currentDevice = device;
      return true;
    } catch (e) {
      print('❌ Lỗi kết nối ONVIF: $e');
      _client = null;
      _currentDevice = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_client != null) {
      _client!.dispose();
      _client = null;
      _currentDevice = null;
    }
  }

  Future<OnvifDeviceInformation?> getDeviceInformation() async {
    if (_client == null) return null;

    try {
      return await _client!.device.getDeviceInformation();
    } catch (e) {
      print('❌ Lỗi lấy thông tin thiết bị: $e');
      return null;
    }
  }

  Future<List<OnvifMediaProfile>> getMediaProfiles() async {
    if (_client == null) return [];

    try {
      return await _client!.media.getProfiles();
    } catch (e) {
      print('❌ Lỗi lấy media profiles: $e');
      return [];
    }
  }

  Future<String?> getStreamUri(String profileToken) async {
    if (_client == null) return null;

    try {
      final streamUri =
          await _client!.media.getStreamUri(profileToken: profileToken);
      return streamUri.uri;
    } catch (e) {
      print('❌ Lỗi lấy stream URI: $e');
      return null;
    }
  }

  Future<String?> getSnapshotUri(String profileToken) async {
    if (_client == null) return null;

    try {
      final snapshotUri = await _client!.media.getSnapshotUri(profileToken);
      return snapshotUri.uri;
    } catch (e) {
      print('❌ Lỗi lấy snapshot URI: $e');
      return null;
    }
  }

  Future<List<OnvifUser>> getUsers() async {
    if (_client == null) return [];

    try {
      return await _client!.userManagement.getUsers();
    } catch (e) {
      print('❌ Lỗi lấy danh sách users: $e');
      return [];
    }
  }

  Future<List<OnvifGroup>> getGroups() async {
    if (_client == null) return [];

    try {
      return await _client!.userManagement.getGroups();
    } catch (e) {
      print('❌ Lỗi lấy danh sách groups: $e');
      return [];
    }
  }

  Future<List<OnvifRecording>> getRecordings() async {
    if (_client == null) return [];

    try {
      return await _client!.recording.getRecordings();
    } catch (e) {
      print('❌ Lỗi lấy recordings: $e');
      return [];
    }
  }

  Future<void> movePTZ({
    required String profileToken,
    required double pan,
    required double tilt,
    required double zoom,
  }) async {
    if (_client == null) return;

    try {
      await _client!.ptz.continuousMove(
        profileToken: profileToken,
        panVelocity: pan,
        tiltVelocity: tilt,
        zoomVelocity: zoom,
      );
    } catch (e) {
      print('❌ Lỗi điều khiển PTZ: $e');
    }
  }

  Future<void> stopPTZ({required String profileToken}) async {
    if (_client == null) return;

    try {
      await _client!.ptz.stop(profileToken: profileToken);
    } catch (e) {
      print('❌ Lỗi dừng PTZ: $e');
    }
  }
}
