/// User Management Models
/// Các models cho quản lý tài khoản user, admin, group trong ONVIF

/// ONVIF User Model
/// Đại diện cho một user trong hệ thống ONVIF
class OnvifUser {
  final String username;
  final String? password;
  final UserLevel userLevel;
  final List<String> accessRights;
  final UserInformation? userInformation;
  final List<String> groups;
  final Map<String, dynamic> extension;

  const OnvifUser({
    required this.username,
    this.password,
    required this.userLevel,
    this.accessRights = const [],
    this.userInformation,
    this.groups = const [],
    this.extension = const {},
  });

  factory OnvifUser.fromXml(Map<String, dynamic> xml) {
    return OnvifUser(
      username: xml['Username']?.toString() ?? '',
      password: xml['Password']?.toString(),
      userLevel: UserLevel.fromString(xml['UserLevel']?.toString() ?? 'User'),
      accessRights: _parseAccessRights(xml['AccessRights']),
      userInformation: xml['UserInformation'] != null
          ? UserInformation.fromXml(xml['UserInformation'])
          : null,
      groups: _parseStringList(xml['Groups']),
      extension: xml['Extension'] ?? {},
    );
  }

  static List<String> _parseAccessRights(dynamic data) {
    if (data == null) return [];
    if (data is String) return [data];
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is Map) {
      final rights = <String>[];
      data.forEach((key, value) {
        if (value == true || value == 'true') {
          rights.add(key.toString());
        }
      });
      return rights;
    }
    return [];
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is String) return [data];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  /// Kiểm tra xem user có quyền cụ thể không
  bool hasAccessRight(String right) => accessRights.contains(right);

  /// Kiểm tra xem có phải là administrator không
  bool get isAdministrator => userLevel == UserLevel.administrator;

  /// Kiểm tra xem có phải là operator không
  bool get isOperator => userLevel == UserLevel.operator;

  /// Kiểm tra xem có phải là user thường không
  bool get isUser => userLevel == UserLevel.user;

  /// Kiểm tra xem có phải là anonymous không
  bool get isAnonymous => userLevel == UserLevel.anonymous;

  /// Tạo bản copy với thông tin mới
  OnvifUser copyWith({
    String? username,
    String? password,
    UserLevel? userLevel,
    List<String>? accessRights,
    UserInformation? userInformation,
    List<String>? groups,
    Map<String, dynamic>? extension,
  }) {
    return OnvifUser(
      username: username ?? this.username,
      password: password ?? this.password,
      userLevel: userLevel ?? this.userLevel,
      accessRights: accessRights ?? this.accessRights,
      userInformation: userInformation ?? this.userInformation,
      groups: groups ?? this.groups,
      extension: extension ?? this.extension,
    );
  }

  /// Chuyển đổi thành XML cho SOAP request
  String toXml() {
    final buffer = StringBuffer();
    buffer
        .write('<tds:User xmlns:tds="http://www.onvif.org/ver10/device/wsdl">');
    buffer.write('<tds:Username>$username</tds:Username>');

    if (password != null) {
      buffer.write('<tds:Password>$password</tds:Password>');
    }

    buffer.write('<tds:UserLevel>${userLevel.value}</tds:UserLevel>');

    if (accessRights.isNotEmpty) {
      buffer.write('<tds:AccessRights>');
      for (final right in accessRights) {
        buffer.write('<tds:AccessRight>$right</tds:AccessRight>');
      }
      buffer.write('</tds:AccessRights>');
    }

    if (userInformation != null) {
      buffer.write(userInformation!.toXml());
    }

    if (groups.isNotEmpty) {
      for (final group in groups) {
        buffer.write('<tds:Group>$group</tds:Group>');
      }
    }

    buffer.write('</tds:User>');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'OnvifUser(username: $username, userLevel: $userLevel, '
        'accessRights: ${accessRights.length}, groups: ${groups.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifUser && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}

/// User Level Enum
enum UserLevel {
  administrator('Administrator'),
  operator('Operator'),
  user('User'),
  anonymous('Anonymous'),
  extended('Extended');

  const UserLevel(this.value);
  final String value;

  static UserLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'administrator':
        return UserLevel.administrator;
      case 'operator':
        return UserLevel.operator;
      case 'user':
        return UserLevel.user;
      case 'anonymous':
        return UserLevel.anonymous;
      case 'extended':
        return UserLevel.extended;
      default:
        return UserLevel.user;
    }
  }

  @override
  String toString() => value;
}

/// User Information
class UserInformation {
  final String? firstName;
  final String? lastName;
  final String? emailAddress;
  final String? phoneNumber;
  final String? description;
  final Map<String, dynamic> extension;

  const UserInformation({
    this.firstName,
    this.lastName,
    this.emailAddress,
    this.phoneNumber,
    this.description,
    this.extension = const {},
  });

  factory UserInformation.fromXml(Map<String, dynamic> xml) {
    return UserInformation(
      firstName: xml['FirstName']?.toString(),
      lastName: xml['LastName']?.toString(),
      emailAddress: xml['EmailAddress']?.toString(),
      phoneNumber: xml['PhoneNumber']?.toString(),
      description: xml['Description']?.toString(),
      extension: xml['Extension'] ?? {},
    );
  }

  /// Tên đầy đủ
  String get fullName {
    final parts = <String>[];
    if (firstName != null) parts.add(firstName!);
    if (lastName != null) parts.add(lastName!);
    return parts.join(' ');
  }

  /// Chuyển đổi thành XML
  String toXml() {
    final buffer = StringBuffer();
    buffer.write('<tds:UserInformation>');

    if (firstName != null) {
      buffer.write('<tds:FirstName>$firstName</tds:FirstName>');
    }
    if (lastName != null) {
      buffer.write('<tds:LastName>$lastName</tds:LastName>');
    }
    if (emailAddress != null) {
      buffer.write('<tds:EmailAddress>$emailAddress</tds:EmailAddress>');
    }
    if (phoneNumber != null) {
      buffer.write('<tds:PhoneNumber>$phoneNumber</tds:PhoneNumber>');
    }
    if (description != null) {
      buffer.write('<tds:Description>$description</tds:Description>');
    }

    buffer.write('</tds:UserInformation>');
    return buffer.toString();
  }

  @override
  String toString() => 'UserInformation(name: $fullName, email: $emailAddress)';
}

/// ONVIF Group Model
class OnvifGroup {
  final String groupName;
  final String? description;
  final List<String> accessRights;
  final List<String> members;
  final Map<String, dynamic> extension;

  const OnvifGroup({
    required this.groupName,
    this.description,
    this.accessRights = const [],
    this.members = const [],
    this.extension = const {},
  });

  factory OnvifGroup.fromXml(Map<String, dynamic> xml) {
    return OnvifGroup(
      groupName: xml['GroupName']?.toString() ?? '',
      description: xml['Description']?.toString(),
      accessRights: OnvifUser._parseAccessRights(xml['AccessRights']),
      members: OnvifUser._parseStringList(xml['Members']),
      extension: xml['Extension'] ?? {},
    );
  }

  /// Kiểm tra xem group có quyền cụ thể không
  bool hasAccessRight(String right) => accessRights.contains(right);

  /// Kiểm tra xem user có trong group không
  bool containsMember(String username) => members.contains(username);

  /// Chuyển đổi thành XML cho SOAP request
  String toXml() {
    final buffer = StringBuffer();
    buffer.write(
        '<tds:Group xmlns:tds="http://www.onvif.org/ver10/device/wsdl">');
    buffer.write('<tds:GroupName>$groupName</tds:GroupName>');

    if (description != null) {
      buffer.write('<tds:Description>$description</tds:Description>');
    }

    if (accessRights.isNotEmpty) {
      buffer.write('<tds:AccessRights>');
      for (final right in accessRights) {
        buffer.write('<tds:AccessRight>$right</tds:AccessRight>');
      }
      buffer.write('</tds:AccessRights>');
    }

    if (members.isNotEmpty) {
      for (final member in members) {
        buffer.write('<tds:Member>$member</tds:Member>');
      }
    }

    buffer.write('</tds:Group>');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'OnvifGroup(name: $groupName, members: ${members.length}, '
        'accessRights: ${accessRights.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnvifGroup && other.groupName == groupName;
  }

  @override
  int get hashCode => groupName.hashCode;
}

/// Access Policy Model
class AccessPolicy {
  final String policyFile;
  final List<AccessPolicyRule> rules;
  final Map<String, dynamic> extension;

  const AccessPolicy({
    required this.policyFile,
    this.rules = const [],
    this.extension = const {},
  });

  factory AccessPolicy.fromXml(Map<String, dynamic> xml) {
    final rulesData = xml['Rules'];
    final rules = <AccessPolicyRule>[];

    if (rulesData is List) {
      for (final rule in rulesData) {
        if (rule is Map<String, dynamic>) {
          rules.add(AccessPolicyRule.fromXml(rule));
        }
      }
    } else if (rulesData is Map<String, dynamic>) {
      rules.add(AccessPolicyRule.fromXml(rulesData));
    }

    return AccessPolicy(
      policyFile: xml['PolicyFile']?.toString() ?? '',
      rules: rules,
      extension: xml['Extension'] ?? {},
    );
  }

  @override
  String toString() =>
      'AccessPolicy(policyFile: $policyFile, rules: ${rules.length})';
}

/// Access Policy Rule
class AccessPolicyRule {
  final String entity;
  final String entityType;
  final List<String> accessRights;
  final Map<String, dynamic> extension;

  const AccessPolicyRule({
    required this.entity,
    required this.entityType,
    this.accessRights = const [],
    this.extension = const {},
  });

  factory AccessPolicyRule.fromXml(Map<String, dynamic> xml) {
    return AccessPolicyRule(
      entity: xml['Entity']?.toString() ?? '',
      entityType: xml['EntityType']?.toString() ?? '',
      accessRights: OnvifUser._parseAccessRights(xml['AccessRights']),
      extension: xml['Extension'] ?? {},
    );
  }

  @override
  String toString() => 'AccessPolicyRule(entity: $entity, type: $entityType)';
}

/// User Options - Configuration cho user management
class UserOptions {
  final int maxUsers;
  final int maxGroups;
  final int maxUserNameLength;
  final int maxPasswordLength;
  final int maxGroupNameLength;
  final List<UserLevel> supportedUserLevels;
  final List<String> supportedAccessRights;
  final bool passwordComplexitySupport;
  final bool userLockoutSupport;
  final Map<String, dynamic> extension;

  const UserOptions({
    required this.maxUsers,
    required this.maxGroups,
    required this.maxUserNameLength,
    required this.maxPasswordLength,
    required this.maxGroupNameLength,
    this.supportedUserLevels = const [],
    this.supportedAccessRights = const [],
    this.passwordComplexitySupport = false,
    this.userLockoutSupport = false,
    this.extension = const {},
  });

  factory UserOptions.fromXml(Map<String, dynamic> xml) {
    final supportedLevels = <UserLevel>[];
    final levelsData = xml['SupportedUserLevels'];
    if (levelsData is List) {
      for (final level in levelsData) {
        supportedLevels.add(UserLevel.fromString(level.toString()));
      }
    } else if (levelsData is String) {
      supportedLevels.add(UserLevel.fromString(levelsData));
    }

    return UserOptions(
      maxUsers: int.tryParse(xml['MaxUsers']?.toString() ?? '0') ?? 0,
      maxGroups: int.tryParse(xml['MaxGroups']?.toString() ?? '0') ?? 0,
      maxUserNameLength:
          int.tryParse(xml['MaxUserNameLength']?.toString() ?? '0') ?? 0,
      maxPasswordLength:
          int.tryParse(xml['MaxPasswordLength']?.toString() ?? '0') ?? 0,
      maxGroupNameLength:
          int.tryParse(xml['MaxGroupNameLength']?.toString() ?? '0') ?? 0,
      supportedUserLevels: supportedLevels,
      supportedAccessRights:
          OnvifUser._parseAccessRights(xml['SupportedAccessRights']),
      passwordComplexitySupport: _parseBool(xml['PasswordComplexitySupport']),
      userLockoutSupport: _parseBool(xml['UserLockoutSupport']),
      extension: xml['Extension'] ?? {},
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  @override
  String toString() {
    return 'UserOptions(maxUsers: $maxUsers, maxGroups: $maxGroups, '
        'supportedLevels: ${supportedUserLevels.length})';
  }
}

/// Predefined Access Rights Constants
class AccessRights {
  // Device Access Rights
  static const String deviceGetInformation = 'DeviceIO:GetInformation';
  static const String deviceSetInformation = 'DeviceIO:SetInformation';
  static const String deviceGetConfiguration = 'DeviceIO:GetConfiguration';
  static const String deviceSetConfiguration = 'DeviceIO:SetConfiguration';
  static const String deviceReboot = 'Device:Reboot';
  static const String deviceFactoryReset = 'Device:FactoryReset';

  // Media Access Rights
  static const String mediaGetProfiles = 'Media:GetProfiles';
  static const String mediaGetStreamUri = 'Media:GetStreamUri';
  static const String mediaGetSnapshot = 'Media:GetSnapshot';
  static const String mediaCreateProfile = 'Media:CreateProfile';
  static const String mediaDeleteProfile = 'Media:DeleteProfile';

  // PTZ Access Rights
  static const String ptzControl = 'PTZ:Control';
  static const String ptzGetStatus = 'PTZ:GetStatus';
  static const String ptzGetConfiguration = 'PTZ:GetConfiguration';
  static const String ptzSetConfiguration = 'PTZ:SetConfiguration';

  // Event Access Rights
  static const String eventGetEvents = 'Event:GetEvents';
  static const String eventSetEvents = 'Event:SetEvents';
  static const String eventSubscribe = 'Event:Subscribe';

  // Recording Access Rights
  static const String recordingSearch = 'Recording:Search';
  static const String recordingPlayback = 'Recording:Playback';
  static const String recordingControl = 'Recording:Control';

  // User Management Access Rights
  static const String userGetUsers = 'User:GetUsers';
  static const String userCreateUser = 'User:CreateUser';
  static const String userDeleteUser = 'User:DeleteUser';
  static const String userModifyUser = 'User:ModifyUser';

  // Group Management Access Rights
  static const String groupGetGroups = 'Group:GetGroups';
  static const String groupCreateGroup = 'Group:CreateGroup';
  static const String groupDeleteGroup = 'Group:DeleteGroup';
  static const String groupModifyGroup = 'Group:ModifyGroup';

  /// Tất cả quyền dành cho Administrator
  static const List<String> administratorRights = [
    deviceGetInformation,
    deviceSetInformation,
    deviceGetConfiguration,
    deviceSetConfiguration,
    deviceReboot,
    deviceFactoryReset,
    mediaGetProfiles,
    mediaGetStreamUri,
    mediaGetSnapshot,
    mediaCreateProfile,
    mediaDeleteProfile,
    ptzControl,
    ptzGetStatus,
    ptzGetConfiguration,
    ptzSetConfiguration,
    eventGetEvents,
    eventSetEvents,
    eventSubscribe,
    recordingSearch,
    recordingPlayback,
    recordingControl,
    userGetUsers,
    userCreateUser,
    userDeleteUser,
    userModifyUser,
    groupGetGroups,
    groupCreateGroup,
    groupDeleteGroup,
    groupModifyGroup,
  ];

  /// Quyền cơ bản dành cho Operator
  static const List<String> operatorRights = [
    deviceGetInformation,
    deviceGetConfiguration,
    mediaGetProfiles,
    mediaGetStreamUri,
    mediaGetSnapshot,
    ptzControl,
    ptzGetStatus,
    ptzGetConfiguration,
    eventGetEvents,
    recordingSearch,
    recordingPlayback,
  ];

  /// Quyền cơ bản dành cho User
  static const List<String> userRights = [
    deviceGetInformation,
    mediaGetProfiles,
    mediaGetStreamUri,
    mediaGetSnapshot,
    ptzGetStatus,
    eventGetEvents,
    recordingSearch,
  ];
}
