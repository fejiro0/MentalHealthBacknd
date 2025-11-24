import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data_model.dart';
import '../models/emotional_state_model.dart';
import '../utils/constants.dart';
import 'baseline_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Real-time processing service that continuously monitors sensor data,
/// compares against baselines, and detects emotional states
class RealtimeProcessingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final BaselineService _baselineService = BaselineService();
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _emotionalStateSubscription;
  
  String? _currentUserId;
  String? _currentDeviceId;
  EmotionalStateResult? _lastDetectedState;
  DateTime? _lastNotificationTime;
  
  final StreamController<EmotionalStateResult> _stateController = StreamController<EmotionalStateResult>.broadcast();
  final StreamController<SensorDataModel> _sensorController = StreamController<SensorDataModel>.broadcast();
  
  // Streams for UI to listen to
  Stream<EmotionalStateResult> get emotionalStateStream => _stateController.stream;
  Stream<SensorDataModel> get sensorDataStream => _sensorController.stream;
  
  /// Start monitoring for a user and device
  Future<void> startMonitoring({
    required String userId,
    required String deviceId,
  }) async {
    _currentUserId = userId;
    _currentDeviceId = deviceId;
    
    // Initialize notification service if not already done
    await _notificationService.initialize();
    
    // Start listening to sensor data
    _startSensorMonitoring(deviceId);
  }
  
  void _startSensorMonitoring(String deviceId) {
    // Cancel existing subscription if any
    _sensorSubscription?.cancel();
    
    // Listen to real-time sensor data
    _sensorSubscription = _database
        .ref()
        .child(AppConstants.devicesCollection)
        .child(deviceId)
        .child('current')
        .onValue
        .listen((event) {
      if (event.snapshot.value == null) return;
      
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final sensorData = SensorDataModel.fromJson(data);
        
        // Emit sensor data
        _sensorController.add(sensorData);
        
        // Process emotional state if user is set
        _processEmotionalState(sensorData);
      } catch (e) {
        debugPrint('Error processing sensor data: $e');
      }
    });
  }
  
  /// Process sensor data against baselines to detect emotional state
  Future<void> _processEmotionalState(SensorDataModel sensorData) async {
    if (_currentUserId == null || _currentDeviceId == null) return;
    
    EmotionalStateResult? bestResult;
    double bestConfidence = 0.0;
    
    // Check each baseline condition
    for (final condition in AppConstants.conditionsRequiringBaseline) {
      try {
        final hasBaseline = await _baselineService.hasBaseline(
          userId: _currentUserId!,
          deviceId: _currentDeviceId!,
          condition: condition,
        );
        
        if (!hasBaseline) continue;
        
        final baseline = await _baselineService.getBaseline(
          userId: _currentUserId!,
          deviceId: _currentDeviceId!,
          condition: condition,
        );
        
        if (baseline == null || baseline.isEmpty) continue;
        
        // Analyze against this baseline
        final result = _baselineService.analyzeEmotionalState(
          currentData: sensorData,
          baseline: baseline,
          targetCondition: condition,
        );
        
        // Keep the result with highest confidence for the target condition
        if (result.state != EmotionalState.normal && 
            result.confidence > bestConfidence &&
            result.state.name == condition) {
          bestResult = result;
          bestConfidence = result.confidence;
        }
      } catch (e) {
        debugPrint('Error processing baseline for $condition: $e');
      }
    }
    
    // If no specific condition detected, analyze generally
    bestResult ??= _analyzeGeneralState(sensorData);
    
    // Only update if confidence is above threshold
    if (bestResult.confidence >= AppConstants.defaultConfidenceThreshold) {
      // Check if state changed
      final stateChanged = _lastDetectedState == null ||
          _lastDetectedState!.state != bestResult.state;
      
      // Save to database
      await _firebaseService.saveEmotionalState(_currentUserId!, bestResult);
      
      // Emit state change
      _stateController.add(bestResult);
      
      // Send notification if state changed and is not normal
      if (stateChanged && bestResult.state != EmotionalState.normal) {
        await _sendNotificationIfNeeded(bestResult);
      }
      
      _lastDetectedState = bestResult;
    }
  }
  
  /// Analyze general emotional state without specific baseline
  EmotionalStateResult _analyzeGeneralState(SensorDataModel sensorData) {
    // This is a fallback when no baselines are set
    // Could use general thresholds or return unknown
    return EmotionalStateResult(
      state: EmotionalState.unknown,
      confidence: 0.0,
      indicators: {},
      detectedAt: DateTime.now(),
    );
  }
  
  /// Send notification with cooldown check
  Future<void> _sendNotificationIfNeeded(EmotionalStateResult result) async {
    // Check cooldown
    if (_lastNotificationTime != null) {
      final timeSinceLastNotification = DateTime.now().difference(_lastNotificationTime!);
      if (timeSinceLastNotification.inMinutes < AppConstants.notificationCooldownMinutes) {
        return;
      }
    }
    
    // Only notify for non-normal states
    if (result.state != EmotionalState.normal) {
      await _notificationService.showEmotionalStateNotification(result);
      _lastNotificationTime = DateTime.now();
    }
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _sensorSubscription?.cancel();
    _emotionalStateSubscription?.cancel();
    _sensorSubscription = null;
    _emotionalStateSubscription = null;
    _currentUserId = null;
    _currentDeviceId = null;
    _lastDetectedState = null;
  }
  
  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _stateController.close();
    _sensorController.close();
  }
}

