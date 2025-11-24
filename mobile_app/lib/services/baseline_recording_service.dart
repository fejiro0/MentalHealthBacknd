import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data_model.dart';
import 'baseline_service.dart';
import 'firebase_service.dart';

/// Service for recording baselines over a duration (e.g., 1 minute)
/// Each condition is recorded independently
class BaselineRecordingService {
  final BaselineService _baselineService = BaselineService();
  final FirebaseService _firebaseService = FirebaseService();
  
  // Track active recordings per condition
  final Map<String, Timer> _recordingTimers = {};
  final Map<String, List<SensorDataModel>> _recordingData = {};
  final Map<String, StreamSubscription<SensorDataModel?>> _subscriptions = {};
  
  // Callbacks for UI updates
  Function(String condition, Duration remaining)? onRecordingProgress;
  Function(String condition)? onRecordingComplete;
  Function(String condition, String error)? onRecordingError;

  /// Start recording baseline for a specific condition
  /// Duration in seconds (default 60 seconds = 1 minute)
  Future<void> startRecording({
    required String userId,
    required String deviceId,
    required String condition,
    required int durationSeconds,
    Function(String condition, Duration remaining)? onProgress,
    Function(String condition)? onComplete,
    Function(String condition, String error)? onError,
  }) async {
    // Stop any existing recording for this condition
    await stopRecording(condition);
    
    // Set callbacks
    onRecordingProgress = onProgress;
    onRecordingComplete = onComplete;
    onRecordingError = onError;

    // Initialize data list for this condition
    _recordingData[condition] = [];

    // Subscribe to sensor data
    final subscription = _firebaseService.getCurrentSensorData(deviceId).listen(
      (sensorData) {
        if (sensorData != null && _recordingData.containsKey(condition)) {
          _recordingData[condition]!.add(sensorData);
        }
      },
      onError: (error) {
        debugPrint('Error receiving sensor data during recording: $error');
        if (onRecordingError != null) {
          onRecordingError!(condition, error.toString());
        }
      },
    );

    _subscriptions[condition] = subscription;

    // Start timer
    final startTime = DateTime.now();
    final duration = Duration(seconds: durationSeconds);
    
    _recordingTimers[condition] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final remaining = duration - elapsed;

      if (onRecordingProgress != null) {
        onRecordingProgress!(condition, remaining);
      }

      if (remaining.isNegative || remaining.inSeconds <= 0) {
        // Recording complete
        timer.cancel();
        _completeRecording(userId: userId, deviceId: deviceId, condition: condition);
      }
    });
  }

  /// Complete recording and save baseline (averaged values)
  Future<void> _completeRecording({
    required String userId,
    required String deviceId,
    required String condition,
  }) async {
    try {
      final recordings = _recordingData[condition];
      
      if (recordings == null || recordings.isEmpty) {
        throw 'No sensor data collected during recording period';
      }

      // Calculate average values
      final avgTemp = recordings.map((r) => r.temperature).reduce((a, b) => a + b) / recordings.length;
      final avgHumidity = recordings.map((r) => r.humidity).reduce((a, b) => a + b) / recordings.length;
      final avgMotionMag = recordings.map((r) => r.motion.magnitude).reduce((a, b) => a + b) / recordings.length;
      final avgMotionX = recordings.map((r) => r.motion.x).reduce((a, b) => a + b) / recordings.length;
      final avgMotionY = recordings.map((r) => r.motion.y).reduce((a, b) => a + b) / recordings.length;
      final avgMotionZ = recordings.map((r) => r.motion.z).reduce((a, b) => a + b) / recordings.length;
      final avgSound = recordings.map((r) => r.sound.toDouble()).reduce((a, b) => a + b) / recordings.length;

      // Create averaged sensor data
      final averagedData = SensorDataModel(
        deviceId: deviceId,
        timestamp: DateTime.now(),
        temperature: avgTemp,
        humidity: avgHumidity,
        motion: MotionData(
          magnitude: avgMotionMag,
          x: avgMotionX,
          y: avgMotionY,
          z: avgMotionZ,
          gyroX: 0, // Not critical for baseline
          gyroY: 0,
          gyroZ: 0,
          angleX: 0,
          angleY: 0,
          angleZ: 0,
        ),
        sound: avgSound.toInt(),
        receivedAt: DateTime.now(),
      );

      // Save baseline
      await _baselineService.recordBaseline(
        userId: userId,
        deviceId: deviceId,
        condition: condition,
        sensorData: averagedData,
        notes: 'Recorded over ${recordings.length} readings',
      );

      // Cleanup
      await stopRecording(condition);

      if (onRecordingComplete != null) {
        onRecordingComplete!(condition);
      }

      debugPrint('✅ Baseline recorded for $condition: ${recordings.length} readings averaged');
    } catch (e) {
      debugPrint('❌ Error completing baseline recording: $e');
      if (onRecordingError != null) {
        onRecordingError!(condition, e.toString());
      }
    }
  }

  /// Stop recording for a condition
  Future<void> stopRecording(String condition) async {
    _recordingTimers[condition]?.cancel();
    _recordingTimers.remove(condition);
    
    await _subscriptions[condition]?.cancel();
    _subscriptions.remove(condition);
    
    _recordingData.remove(condition);
  }

  /// Stop all recordings
  Future<void> stopAllRecordings() async {
    final conditions = _recordingTimers.keys.toList();
    for (final condition in conditions) {
      await stopRecording(condition);
    }
  }

  /// Check if a condition is currently being recorded
  bool isRecording(String condition) {
    return _recordingTimers.containsKey(condition);
  }

  /// Get recording progress
  int getRecordingCount(String condition) {
    return _recordingData[condition]?.length ?? 0;
  }
}

