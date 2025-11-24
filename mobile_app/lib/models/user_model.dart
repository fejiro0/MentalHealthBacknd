class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String role; // 'caregiver' or 'patient'
  final String? assignedDeviceId; // Device assigned to this user
  final String? patientId; // If caregiver, which patient they monitor
  final List<String>? deviceIds; // Multiple devices (for caregivers monitoring multiple patients)
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    required this.role,
    this.assignedDeviceId,
    this.patientId,
    this.deviceIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'assignedDeviceId': assignedDeviceId,
      'patientId': patientId,
      'deviceIds': deviceIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      role: json['role'] ?? 'patient',
      assignedDeviceId: json['assignedDeviceId'],
      patientId: json['patientId'],
      deviceIds: json['deviceIds'] != null 
          ? List<String>.from(json['deviceIds'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get hasDevice => assignedDeviceId != null && assignedDeviceId!.isNotEmpty;
}

