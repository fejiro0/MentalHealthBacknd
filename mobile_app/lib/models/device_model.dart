class DeviceModel {
  final String deviceId;
  final String name;
  final String? assignedUserId;
  final String? patientId;
  final DateTime registeredAt;
  final DateTime? lastSeen;
  final DeviceStatus status;
  final DeviceHardwareInfo? hardwareInfo;

  DeviceModel({
    required this.deviceId,
    required this.name,
    this.assignedUserId,
    this.patientId,
    required this.registeredAt,
    this.lastSeen,
    required this.status,
    this.hardwareInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'assignedUserId': assignedUserId,
      'patientId': patientId,
      'registeredAt': registeredAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'status': status.name,
      'hardwareInfo': hardwareInfo?.toJson(),
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId'] ?? '',
      name: json['name'] ?? '',
      assignedUserId: json['assignedUserId'],
      patientId: json['patientId'],
      registeredAt: DateTime.parse(json['registeredAt'] ?? DateTime.now().toIso8601String()),
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      status: DeviceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeviceStatus.offline,
      ),
      hardwareInfo: json['hardwareInfo'] != null
          ? DeviceHardwareInfo.fromJson(json['hardwareInfo'])
          : null,
    );
  }

  bool get isAssigned => assignedUserId != null && assignedUserId!.isNotEmpty;
}

enum DeviceStatus {
  active,
  inactive,
  offline,
}

class DeviceHardwareInfo {
  final String model;
  final String? firmwareVersion;

  DeviceHardwareInfo({
    required this.model,
    this.firmwareVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'firmwareVersion': firmwareVersion,
    };
  }

  factory DeviceHardwareInfo.fromJson(Map<String, dynamic> json) {
    return DeviceHardwareInfo(
      model: json['model'] ?? 'Unknown',
      firmwareVersion: json['firmwareVersion'],
    );
  }
}

