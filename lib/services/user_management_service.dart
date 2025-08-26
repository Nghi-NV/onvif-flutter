import '../client/transport.dart';
import '../models/user_management.dart';
import '../parsers/response_parser.dart';
import '../utils/constants.dart';
import '../utils/onvif_request.dart';
import '../exceptions/onvif_exceptions.dart';

/// ONVIF User Management Service
/// Quản lý tài khoản users, groups và access policies
class OnvifUserManagementService {
  final OnvifTransport _transport;
  final String? _username;
  final String? _password;
  String _serviceEndpoint = OnvifConstants.defaultDeviceServicePath;

  OnvifUserManagementService(this._transport, this._username, this._password);

  /// Cập nhật service endpoint
  void updateEndpoint(String newEndpoint) {
    if (newEndpoint.isNotEmpty) {
      _serviceEndpoint = newEndpoint;
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Lấy danh sách tất cả users
  Future<List<OnvifUser>> getUsers() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetUsers xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.deviceManagementNamespace}/GetUsers',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetUsers xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action: '${OnvifConstants.deviceManagementNamespace}/GetUsers',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/GetUsers',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final usersData = _findInResponse(parsed, 'User') ?? [];

      final users = <OnvifUser>[];
      if (usersData is List) {
        for (final userData in usersData) {
          if (userData is Map<String, dynamic>) {
            users.add(OnvifUser.fromXml(userData));
          }
        }
      } else if (usersData is Map<String, dynamic>) {
        users.add(OnvifUser.fromXml(usersData));
      }

      return users;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get users: $e',
        originalError: e,
      );
    }
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
    try {
      final user = OnvifUser(
        username: username,
        password: password,
        userLevel: userLevel,
        accessRights: accessRights ?? _getDefaultAccessRights(userLevel),
        userInformation: userInformation,
        groups: groups ?? [],
      );

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:CreateUsers xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${user.toXml()}</tds:CreateUsers>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.deviceManagementNamespace}/CreateUsers',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:CreateUsers xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${user.toXml()}</tds:CreateUsers>',
              action: '${OnvifConstants.deviceManagementNamespace}/CreateUsers',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/CreateUsers',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to create user: $e',
        originalError: e,
      );
    }
  }

  /// Xóa user
  Future<void> deleteUser(String username) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:DeleteUsers xmlns:tds="${OnvifConstants.deviceManagementNamespace}"><tds:Username>$username</tds:Username></tds:DeleteUsers>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.deviceManagementNamespace}/DeleteUsers',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:DeleteUsers xmlns:tds="${OnvifConstants.deviceManagementNamespace}"><tds:Username>$username</tds:Username></tds:DeleteUsers>',
              action: '${OnvifConstants.deviceManagementNamespace}/DeleteUsers',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/DeleteUsers',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to delete user: $e',
        originalError: e,
      );
    }
  }

  /// Cập nhật user
  Future<void> updateUser({
    required String username,
    String? newPassword,
    UserLevel? userLevel,
    List<String>? accessRights,
    UserInformation? userInformation,
    List<String>? groups,
  }) async {
    try {
      // Lấy thông tin user hiện tại
      final currentUsers = await getUsers();
      final currentUser = currentUsers.firstWhere(
        (u) => u.username == username,
        orElse: () => throw const OnvifConnectionException('User not found'),
      );

      // Tạo user với thông tin mới
      final updatedUser = currentUser.copyWith(
        password: newPassword,
        userLevel: userLevel,
        accessRights: accessRights,
        userInformation: userInformation,
        groups: groups,
      );

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:SetUser xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${updatedUser.toXml()}</tds:SetUser>',
              username: _username!,
              password: _password!,
              action: '${OnvifConstants.deviceManagementNamespace}/SetUser',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:SetUser xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${updatedUser.toXml()}</tds:SetUser>',
              action: '${OnvifConstants.deviceManagementNamespace}/SetUser',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/SetUser',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to update user: $e',
        originalError: e,
      );
    }
  }

  /// Đổi mật khẩu user
  Future<void> changePassword({
    required String username,
    required String newPassword,
  }) async {
    await updateUser(username: username, newPassword: newPassword);
  }

  // ==================== GROUP MANAGEMENT ====================

  /// Lấy danh sách tất cả groups
  Future<List<OnvifGroup>> getGroups() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/GetAccessPolicy',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final groupsData = _findInResponse(parsed, 'Group') ?? [];

      final groups = <OnvifGroup>[];
      if (groupsData is List) {
        for (final groupData in groupsData) {
          if (groupData is Map<String, dynamic>) {
            groups.add(OnvifGroup.fromXml(groupData));
          }
        }
      } else if (groupsData is Map<String, dynamic>) {
        groups.add(OnvifGroup.fromXml(groupsData));
      }

      return groups;
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get groups: $e',
        originalError: e,
      );
    }
  }

  /// Tạo group mới
  Future<void> createGroup({
    required String groupName,
    String? description,
    List<String>? accessRights,
    List<String>? members,
  }) async {
    try {
      final group = OnvifGroup(
        groupName: groupName,
        description: description,
        accessRights: accessRights ?? [],
        members: members ?? [],
      );

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:SetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${group.toXml()}</tds:SetAccessPolicy>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:SetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${group.toXml()}</tds:SetAccessPolicy>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to create group: $e',
        originalError: e,
      );
    }
  }

  /// Xóa group
  Future<void> deleteGroup(String groupName) async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:DeleteAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}"><tds:GroupName>$groupName</tds:GroupName></tds:DeleteAccessPolicy>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/DeleteAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:DeleteAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}"><tds:GroupName>$groupName</tds:GroupName></tds:DeleteAccessPolicy>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/DeleteAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/DeleteAccessPolicy',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to delete group: $e',
        originalError: e,
      );
    }
  }

  /// Thêm user vào group
  Future<void> addUserToGroup({
    required String username,
    required String groupName,
  }) async {
    try {
      // Lấy thông tin group hiện tại
      final groups = await getGroups();
      final group = groups.firstWhere(
        (g) => g.groupName == groupName,
        orElse: () => throw const OnvifConnectionException('Group not found'),
      );

      // Thêm user vào danh sách members
      if (!group.members.contains(username)) {
        final updatedMembers = [...group.members, username];
        final updatedGroup = OnvifGroup(
          groupName: group.groupName,
          description: group.description,
          accessRights: group.accessRights,
          members: updatedMembers,
          extension: group.extension,
        );

        final soapRequest = _hasCredentials
            ? OnvifRequestBuilder.createSecureSoapEnvelope(
                body:
                    '<tds:SetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${updatedGroup.toXml()}</tds:SetAccessPolicy>',
                username: _username!,
                password: _password!,
                action:
                    '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
                headers: {'tds': OnvifConstants.deviceManagementNamespace},
              )
            : OnvifRequestBuilder.createSoapEnvelope(
                body:
                    '<tds:SetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${updatedGroup.toXml()}</tds:SetAccessPolicy>',
                action:
                    '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
                headers: {'tds': OnvifConstants.deviceManagementNamespace},
              );

        await _transport.sendSoapRequest(
          path: _serviceEndpoint,
          soapBody: soapRequest,
          soapAction:
              '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
        );
      }
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to add user to group: $e',
        originalError: e,
      );
    }
  }

  /// Xóa user khỏi group
  Future<void> removeUserFromGroup({
    required String username,
    required String groupName,
  }) async {
    try {
      // Lấy thông tin group hiện tại
      final groups = await getGroups();
      final group = groups.firstWhere(
        (g) => g.groupName == groupName,
        orElse: () => throw const OnvifConnectionException('Group not found'),
      );

      // Xóa user khỏi danh sách members
      final updatedMembers = group.members.where((m) => m != username).toList();
      final updatedGroup = OnvifGroup(
        groupName: group.groupName,
        description: group.description,
        accessRights: group.accessRights,
        members: updatedMembers,
        extension: group.extension,
      );

      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:SetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${updatedGroup.toXml()}</tds:SetAccessPolicy>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:SetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}">${updatedGroup.toXml()}</tds:SetAccessPolicy>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/SetAccessPolicy',
      );
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to remove user from group: $e',
        originalError: e,
      );
    }
  }

  // ==================== ACCESS POLICY ====================

  /// Lấy access policy
  Future<AccessPolicy> getAccessPolicy() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetAccessPolicy xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetAccessPolicy',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction:
            '${OnvifConstants.deviceManagementNamespace}/GetAccessPolicy',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final policyData = _findInResponse(parsed, 'AccessPolicy') ?? {};

      return AccessPolicy.fromXml(policyData);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get access policy: $e',
        originalError: e,
      );
    }
  }

  // ==================== USER OPTIONS ====================

  /// Lấy user options (limits và capabilities)
  Future<UserOptions> getUserOptions() async {
    try {
      final soapRequest = _hasCredentials
          ? OnvifRequestBuilder.createSecureSoapEnvelope(
              body:
                  '<tds:GetSystemUris xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              username: _username!,
              password: _password!,
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetSystemUris',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            )
          : OnvifRequestBuilder.createSoapEnvelope(
              body:
                  '<tds:GetSystemUris xmlns:tds="${OnvifConstants.deviceManagementNamespace}"/>',
              action:
                  '${OnvifConstants.deviceManagementNamespace}/GetSystemUris',
              headers: {'tds': OnvifConstants.deviceManagementNamespace},
            );

      final response = await _transport.sendSoapRequest(
        path: _serviceEndpoint,
        soapBody: soapRequest,
        soapAction: '${OnvifConstants.deviceManagementNamespace}/GetSystemUris',
      );

      final parsed = OnvifResponseParser.parseXmlResponse(response);
      final optionsData = _findInResponse(parsed, 'UserOptions') ?? {};

      // Nếu không có UserOptions trong response, tạo default
      if (optionsData.isEmpty) {
        return const UserOptions(
          maxUsers: 10,
          maxGroups: 5,
          maxUserNameLength: 32,
          maxPasswordLength: 32,
          maxGroupNameLength: 32,
          supportedUserLevels: [
            UserLevel.administrator,
            UserLevel.operator,
            UserLevel.user,
          ],
        );
      }

      return UserOptions.fromXml(optionsData);
    } catch (e) {
      if (e is OnvifException) rethrow;
      throw OnvifConnectionException(
        'Failed to get user options: $e',
        originalError: e,
      );
    }
  }

  // ==================== HELPER METHODS ====================

  bool get _hasCredentials => _username != null && _password != null;

  List<String> _getDefaultAccessRights(UserLevel userLevel) {
    switch (userLevel) {
      case UserLevel.administrator:
        return AccessRights.administratorRights;
      case UserLevel.operator:
        return AccessRights.operatorRights;
      case UserLevel.user:
        return AccessRights.userRights;
      case UserLevel.anonymous:
        return [];
      case UserLevel.extended:
        return AccessRights.userRights;
    }
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
