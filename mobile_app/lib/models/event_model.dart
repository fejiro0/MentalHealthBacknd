import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum EventType {
  fall,
  feelingGood,
  anxiety,
  stress,
  discomfort,
  baselineThreshold,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.fall:
        return 'Fall Detected';
      case EventType.feelingGood:
        return 'Feeling Good';
      case EventType.anxiety:
        return 'Anxiety Detected';
      case EventType.stress:
        return 'Stress Detected';
      case EventType.discomfort:
        return 'Discomfort Detected';
      case EventType.baselineThreshold:
        return 'Baseline Threshold Reached';
    }
  }

  String get description {
    switch (this) {
      case EventType.fall:
        return 'Possible fall detected based on sensor readings';
      case EventType.feelingGood:
        return 'Readings indicate normal, calm state';
      case EventType.anxiety:
        return 'Anxiety indicators detected above baseline';
      case EventType.stress:
        return 'Stress indicators detected above baseline';
      case EventType.discomfort:
        return 'Discomfort indicators detected above baseline';
      case EventType.baselineThreshold:
        return 'Sensor values reached baseline threshold';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.fall:
        return Icons.warning;
      case EventType.feelingGood:
        return Icons.sentiment_satisfied;
      case EventType.anxiety:
        return Icons.mood_bad;
      case EventType.stress:
        return Icons.emergency;
      case EventType.discomfort:
        return Icons.sick;
      case EventType.baselineThreshold:
        return Icons.notifications_active;
    }
  }
}

class EventModel {
  final String id;
  final String userId;
  final String deviceId;
  final EventType type;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> sensorData; // Sensor values at time of event
  final Map<String, dynamic>? additionalData; // Extra info like algorithm details
  final DateTime timestamp;
  final String? notes;

  EventModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.type,
    required this.confidence,
    required this.sensorData,
    this.additionalData,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'type': type.name,
      'confidence': confidence,
      'sensorData': sensorData,
      'additionalData': additionalData,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.baselineThreshold,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      sensorData: Map<String, dynamic>.from(json['sensorData'] ?? {}),
      additionalData: json['additionalData'] != null
          ? Map<String, dynamic>.from(json['additionalData'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }
}

