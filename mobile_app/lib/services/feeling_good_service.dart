import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_data_model.dart';
import '../models/event_model.dart';
import '../models/baseline_model.dart';
import 'event_service.dart';

class FeelingGoodService {
  final EventService _eventService;

  List<SensorDataModel> _recentReadings = [];
  DateTime? _lastFeelingGoodEvent;
  
  static const int stableReadingsCount = 15; // Need 15 stable readings (increased for better accuracy)
  static const int feelingGoodCooldownMinutes = 60; // One event per hour max
  static const double stabilityThreshold = 8.0; // % variation allowed (relaxed for better detection)

  FeelingGoodService(this._eventService);

  /// Detect "feeling good" state using statistical analysis
  /// Criteria: Values have been normal and stable for a period
  Future<EventModel?> detectFeelingGood({
    required SensorDataModel currentData,
    required String userId,
    required String deviceId,
    BaselineModel? normalBaseline,
  }) async {
    // Add current reading
    _recentReadings.add(currentData);

    // Keep only recent readings (last 20)
    if (_recentReadings.length > 20) {
      _recentReadings.removeAt(0);
    }

    // Need enough readings to determine stability
    if (_recentReadings.length < stableReadingsCount) {
      return null;
    }

    // Check cooldown
    if (_lastFeelingGoodEvent != null) {
      final minutesSince = DateTime.now().difference(_lastFeelingGoodEvent!).inMinutes;
      if (minutesSince < feelingGoodCooldownMinutes) {
        return null;
      }
    }

    // Use the last stableReadingsCount readings
    final recent = _recentReadings.takeLast(stableReadingsCount).toList();
    
    // Calculate averages
    final avgTemp = recent.map((r) => r.temperature).reduce((a, b) => a + b) / recent.length;
    final avgHumidity = recent.map((r) => r.humidity).reduce((a, b) => a + b) / recent.length;
    final avgMotion = recent.map((r) => r.motion.magnitude).reduce((a, b) => a + b) / recent.length;
    final avgSound = recent.map((r) => r.sound.toDouble()).reduce((a, b) => a + b) / recent.length;

    // Calculate variance (mean squared deviation)
    double tempVariance = 0;
    double humidityVariance = 0;
    double motionVariance = 0;
    double soundVariance = 0;

    for (final reading in recent) {
      tempVariance += pow(reading.temperature - avgTemp, 2);
      humidityVariance += pow(reading.humidity - avgHumidity, 2);
      motionVariance += pow(reading.motion.magnitude - avgMotion, 2);
      soundVariance += pow(reading.sound - avgSound, 2);
    }

    // Calculate standard deviation (sqrt of variance)
    final tempStdDev = sqrt(tempVariance / recent.length);
    final humidityStdDev = sqrt(humidityVariance / recent.length);
    final motionStdDev = sqrt(motionVariance / recent.length);
    final soundStdDev = sqrt(soundVariance / recent.length);

    // Calculate coefficient of variation (%)
    final tempCV = avgTemp > 0 ? (tempStdDev / avgTemp) * 100 : 0;
    final humidityCV = avgHumidity > 0 ? (humidityStdDev / avgHumidity) * 100 : 0;
    final motionCV = avgMotion > 0 ? (motionStdDev / avgMotion) * 100 : 0;
    final soundCV = avgSound > 0 ? (soundStdDev / avgSound) * 100 : 0;

    // Check if all readings are stable (low coefficient of variation)
    final isStable = tempCV <= stabilityThreshold &&
        humidityCV <= stabilityThreshold &&
        motionCV <= (stabilityThreshold * 1.5) && // Motion can vary more
        soundCV <= (stabilityThreshold * 2); // Sound can vary much more

    // Check if values are in normal range (if baseline exists)
    bool isNormal = true;
    double normalConfidence = 1.0;
    
    if (normalBaseline != null && !normalBaseline.isEmpty) {
      final baselineTemp = (normalBaseline.sensorValues['temperature'] ?? 0.0) as num;
      final baselineHumidity = (normalBaseline.sensorValues['humidity'] ?? 0.0) as num;
      final baselineMotion = (normalBaseline.sensorValues['motion_magnitude'] ?? 0.0) as num;

      final tempDiff = ((avgTemp - baselineTemp.toDouble()) / (baselineTemp.toDouble() > 0 ? baselineTemp.toDouble() : 1)).abs() * 100;
      final humidityDiff = ((avgHumidity - baselineHumidity.toDouble()) / (baselineHumidity.toDouble() > 0 ? baselineHumidity.toDouble() : 1)).abs() * 100;
      final motionDiff = baselineMotion.toDouble() > 0
          ? ((avgMotion - baselineMotion.toDouble()) / baselineMotion.toDouble()).abs() * 100
          : 0;

      // Allow some deviation from baseline (within 20% for temp/humidity, 40% for motion)
      isNormal = tempDiff <= 20 && humidityDiff <= 20 && motionDiff <= 40;
      
      // Calculate confidence based on how close to baseline
      normalConfidence = 1.0 - min(
        (tempDiff / 20 + humidityDiff / 20 + motionDiff / 40) / 3,
        1.0
      );
    }

    if (isStable && isNormal) {
      // Calculate confidence based on stability and normality
      final stabilityScore = (
        (1.0 - min(tempCV / stabilityThreshold, 1.0)) * 0.25 +
        (1.0 - min(humidityCV / stabilityThreshold, 1.0)) * 0.25 +
        (1.0 - min(motionCV / (stabilityThreshold * 1.5), 1.0)) * 0.25 +
        (1.0 - min(soundCV / (stabilityThreshold * 2), 1.0)) * 0.25
      );
      
      // Combine stability and normality scores
      final confidence = (stabilityScore * 0.6 + normalConfidence * 0.4).clamp(0.6, 1.0);

      final event = EventModel(
        id: _eventService.generateEventId(),
        userId: userId,
        deviceId: deviceId,
        type: EventType.feelingGood,
        confidence: confidence,
        sensorData: {
          'temperature': avgTemp,
          'humidity': avgHumidity,
          'motionMagnitude': avgMotion,
          'sound': avgSound,
        },
        additionalData: {
          'algorithm': 'feeling_good_statistical',
          'stability': {
            'tempCV': tempCV,
            'humidityCV': humidityCV,
            'motionCV': motionCV,
            'soundCV': soundCV,
          },
          'stabilityScore': stabilityScore,
          'normalConfidence': normalConfidence,
          'readingsCount': recent.length,
        },
        timestamp: DateTime.now(),
      );

      await _eventService.saveEvent(event);
      _lastFeelingGoodEvent = DateTime.now();

      debugPrint('✅ Feeling good detected! Stability: ${(stabilityScore * 100).toStringAsFixed(1)}%, Normal: ${(normalConfidence * 100).toStringAsFixed(1)}%, Overall: ${(confidence * 100).toStringAsFixed(1)}%');
      return event;
    }

    return null;
  }

  void reset() {
    _recentReadings.clear();
    _lastFeelingGoodEvent = null;
  }
}

// Extension to get last N elements from a list
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}
