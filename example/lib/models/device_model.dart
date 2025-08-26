class DeviceModel {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String manufacturer;
  final String model;
  final bool isOnline;
  final DateTime lastSeen;

  DeviceModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.manufacturer,
    required this.model,
    required this.isOnline,
    required this.lastSeen,
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? manufacturer,
    String? model,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'manufacturer': manufacturer,
      'model': model,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      isOnline: json['isOnline'],
      lastSeen: DateTime.parse(json['lastSeen']),
    );
  }
}
