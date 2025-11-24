class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String baselinesCollection = 'baselines';
  static const String devicesCollection = 'devices';
  static const String emotionalStatesCollection = 'emotional_states';

  // Baseline Conditions
  static const List<String> baselineConditions = ['anxiety', 'stress', 'discomfort'];
  
  // Conditions that require baseline
  static const List<String> conditionsRequiringBaseline = ['anxiety', 'stress', 'discomfort'];
  
  // Conditions that don't require baseline
  static const List<String> conditionsNotRequiringBaseline = ['fall_detection', 'wellbeing', 'dashboard'];

  // Notification Channels
  static const String notificationChannelId = 'mental_health_monitoring';
  static const String notificationChannelName = 'Mental Health Alerts';
  static const String notificationChannelDescription = 'Notifications for emotional state changes';

  // Thresholds (can be adjusted)
  static const double defaultConfidenceThreshold = 0.7;
  static const int notificationCooldownMinutes = 5;

  // Device ID (can be configured per user)
  static const String defaultDeviceId = 'MXCHIP_001';

  // Baseline Recording
  static const int defaultBaselineRecordingDurationSeconds = 60; // 1 minute

  // Colors
  static const int primaryColor = 0xFF6366F1; // Indigo
  static const int secondaryColor = 0xFF8B5CF6; // Purple
  static const int errorColor = 0xFFEF4444; // Red
  static const int successColor = 0xFF10B981; // Green
  static const int warningColor = 0xFFF59E0B; // Amber
}

