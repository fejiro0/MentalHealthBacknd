import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emotional_state_model.dart';
import '../models/event_model.dart';
import '../utils/constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  DateTime? _lastNotificationTime;
  EmotionalState? _lastNotifiedState;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      debugPrint('Notification permission not granted');
    }
  }

  // Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Show notification for emotional state change
  Future<void> showEmotionalStateNotification(EmotionalStateResult result) async {
    // Check cooldown to avoid spamming notifications
    if (_lastNotificationTime != null) {
      final timeSinceLastNotification = DateTime.now().difference(_lastNotificationTime!);
      if (timeSinceLastNotification.inMinutes < AppConstants.notificationCooldownMinutes) {
        return;
      }
    }

    // Don't notify for normal state unless it's a change from a non-normal state
    if (result.state == EmotionalState.normal && _lastNotifiedState == EmotionalState.normal) {
      return;
    }

    // Only notify if confidence is above threshold
    if (result.confidence < AppConstants.defaultConfidenceThreshold) {
      return;
    }

    final title = _getNotificationTitle(result.state);
    final body = _getNotificationBody(result);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      result.detectedAt.millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );

    _lastNotificationTime = DateTime.now();
    _lastNotifiedState = result.state;
  }

  String _getNotificationTitle(EmotionalState state) {
    switch (state) {
      case EmotionalState.anxiety:
        return '⚠️ Anxiety Detected';
      case EmotionalState.stress:
        return '⚠️ Stress Detected';
      case EmotionalState.discomfort:
        return '⚠️ Discomfort Detected';
      case EmotionalState.normal:
        return '✅ State Normalized';
      case EmotionalState.unknown:
        return '❓ Unknown State';
    }
  }

  String _getNotificationBody(EmotionalStateResult result) {
    final baseMessage = result.state.description;
    final confidencePercent = (result.confidence * 100).toInt();
    return '$baseMessage\nConfidence: $confidencePercent%';
  }

  // Show notification for event (like fall detection) - CRITICAL: No cooldown for fall detection
  Future<void> showEventNotification({
    required EventModel event,
    bool playSound = false,
  }) async {
    // For critical events like fall detection, always show immediately (no cooldown check)
    final title = _getEventNotificationTitle(event.type);
    final body = _getEventNotificationBody(event);

    // Use maximum priority for critical events
    final importance = event.type == EventType.fall 
        ? Importance.max 
        : Importance.high;
    final priority = event.type == EventType.fall 
        ? Priority.max 
        : Priority.high;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: importance,
      priority: priority,
      showWhen: true,
      playSound: playSound || event.type == EventType.fall, // Always play sound for fall detection
      sound: (playSound || event.type == EventType.fall) 
          ? const RawResourceAndroidNotificationSound('default') // Use default system sound if custom not available
          : null,
      enableVibration: event.type == EventType.fall, // Vibrate for fall detection
      fullScreenIntent: event.type == EventType.fall, // Show full screen intent for fall
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound || event.type == EventType.fall,
      sound: (playSound || event.type == EventType.fall) 
          ? 'default' 
          : null,
      interruptionLevel: event.type == EventType.fall 
          ? InterruptionLevel.critical 
          : InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use unique ID based on timestamp to ensure notification is shown
    final notificationId = event.timestamp.millisecondsSinceEpoch % 1000000;
    
    await _notifications.show(
      notificationId,
      title,
      body,
      details,
    );

    debugPrint('🔔 Notification sent: $title - $body (Sound: ${playSound || event.type == EventType.fall}, Priority: $priority)');
  }

  String _getEventNotificationTitle(EventType type) {
    switch (type) {
      case EventType.fall:
        return '🚨 Fall Detected!';
      case EventType.feelingGood:
        return '😊 Feeling Good';
      case EventType.anxiety:
        return '⚠️ Anxiety Alert';
      case EventType.stress:
        return '⚠️ Stress Alert';
      case EventType.discomfort:
        return '⚠️ Discomfort Alert';
      case EventType.baselineThreshold:
        return '📊 Baseline Threshold Reached';
    }
  }

  String _getEventNotificationBody(EventModel event) {
    final confidencePercent = (event.confidence * 100).toInt();
    return '${event.type.description}\nConfidence: $confidencePercent%';
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

