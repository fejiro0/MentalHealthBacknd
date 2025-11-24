class SensorDataModel {
  final String deviceId;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final MotionData motion;
  final int sound;
  final DateTime receivedAt;

  SensorDataModel({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.motion,
    required this.sound,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'temperature': temperature,
      'humidity': humidity,
      'sensors': {
        'motion': motion.toJson(),
        'sound': {'raw': sound},
      },
      'received_at': receivedAt.toIso8601String(),
    };
  }

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    // Backend sends: { device_id, timestamp (seconds), sensors: { motion: {...}, sound: {raw: ...}, temperature, humidity }, received_at }
    // Helper to safely convert Map<Object?, Object?> to Map<String, dynamic>
    Map<String, dynamic> safeConvertMap(dynamic value) {
      if (value == null) return <String, dynamic>{};
      if (value is Map) {
        return value.map((k, v) {
          if (v is Map) {
            return MapEntry(k.toString(), safeConvertMap(v));
          }
          return MapEntry(k.toString(), v);
        });
      }
      return <String, dynamic>{};
    }
    
    final safeJson = safeConvertMap(json);
    final sensors = safeConvertMap(safeJson['sensors']);
    final motionData = safeConvertMap(sensors['motion']);

    // Parse timestamp - backend sends in SECONDS, convert to milliseconds
    int timestampMs;
    final timestamp = safeJson['timestamp'];
    if (timestamp != null) {
      if (timestamp is int) {
        // If less than year 2001 in milliseconds, assume seconds and convert
        timestampMs = timestamp < 1000000000 ? timestamp * 1000 : timestamp;
      } else if (timestamp is num) {
        timestampMs = (timestamp < 1000000000 ? timestamp * 1000 : timestamp).toInt();
      } else {
        timestampMs = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      timestampMs = DateTime.now().millisecondsSinceEpoch;
    }

    // Parse received_at - ISO string from backend
    DateTime receivedAt;
    final receivedAtStr = safeJson['received_at'];
    if (receivedAtStr != null) {
      try {
        receivedAt = DateTime.parse(receivedAtStr.toString());
      } catch (e) {
        receivedAt = DateTime.now();
      }
    } else {
      receivedAt = DateTime.now();
    }

    // Get temperature and humidity from sensors object or root
    final temp = sensors['temperature'] ?? safeJson['temperature'] ?? 0.0;
    final hum = sensors['humidity'] ?? safeJson['humidity'] ?? 0.0;

    // Get sound value
    final soundVal =
        sensors['sound']?['raw'] ?? sensors['sound'] ?? safeJson['sound'] ?? 0;
    final soundInt =
        soundVal is int ? soundVal : (soundVal is num ? soundVal.toInt() : 0);

    // Get device_id
    final deviceId = safeJson['device_id']?.toString() ?? '';

    return SensorDataModel(
      deviceId: deviceId,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      temperature:
          (temp is num ? temp : double.tryParse(temp.toString()) ?? 0.0)
              .toDouble(),
      humidity: (hum is num ? hum : double.tryParse(hum.toString()) ?? 0.0)
          .toDouble(),
      motion: MotionData.fromJson(motionData),
      sound: soundInt,
      receivedAt: receivedAt,
    );
  }
}

class MotionData {
  final double magnitude;
  final double x;
  final double y;
  final double z;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double angleX;
  final double angleY;
  final double angleZ;

  MotionData({
    required this.magnitude,
    required this.x,
    required this.y,
    required this.z,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.angleX,
    required this.angleY,
    required this.angleZ,
  });

  Map<String, dynamic> toJson() {
    return {
      'magnitude': magnitude,
      'x': x,
      'y': y,
      'z': z,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'angle_x': angleX,
      'angle_y': angleY,
      'angle_z': angleZ,
    };
  }

  factory MotionData.fromJson(Map<String, dynamic> json) {
    // Handle Map<Object?, Object?> type from Firebase
    final safeJson = json.map((key, value) => MapEntry(key.toString(), value));
    
    return MotionData(
      magnitude: ((safeJson['magnitude'] ?? 0.0) as num).toDouble(),
      x: ((safeJson['x'] ?? 0.0) as num).toDouble(),
      y: ((safeJson['y'] ?? 0.0) as num).toDouble(),
      z: ((safeJson['z'] ?? 0.0) as num).toDouble(),
      gyroX: ((safeJson['gyro_x'] ?? 0.0) as num).toDouble(),
      gyroY: ((safeJson['gyro_y'] ?? 0.0) as num).toDouble(),
      gyroZ: ((safeJson['gyro_z'] ?? 0.0) as num).toDouble(),
      angleX: ((safeJson['angle_x'] ?? 0.0) as num).toDouble(),
      angleY: ((safeJson['angle_y'] ?? 0.0) as num).toDouble(),
      angleZ: ((safeJson['angle_z'] ?? 0.0) as num).toDouble(),
    );
  }
}
