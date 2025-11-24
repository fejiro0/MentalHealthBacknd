class BaselineModel {
  final String userId;
  final String deviceId; // NEW: Device this baseline is for
  final String condition; // 'anxiety', 'stress', 'discomfort'
  final Map<String, dynamic> sensorValues;
  final DateTime recordedAt;
  final String? notes;

  BaselineModel({
    required this.userId,
    required this.deviceId,
    required this.condition,
    required this.sensorValues,
    required this.recordedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'condition': condition,
      'sensorValues': sensorValues,
      'recordedAt': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory BaselineModel.fromJson(Map<String, dynamic> json) {
    return BaselineModel(
      userId: json['userId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      condition: json['condition'] ?? '',
      sensorValues: Map<String, dynamic>.from(json['sensorValues'] ?? {}),
      recordedAt: DateTime.parse(json['recordedAt'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }

  bool get isEmpty {
    return sensorValues.isEmpty || sensorValues.values.every((v) => v == 0 || v == null);
  }
}

