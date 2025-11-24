import 'package:flutter/foundation.dart';

enum EmotionalState {
  normal,
  anxiety,
  stress,
  discomfort,
  unknown,
}

extension EmotionalStateExtension on EmotionalState {
  String get displayName {
    switch (this) {
      case EmotionalState.normal:
        return 'Normal';
      case EmotionalState.anxiety:
        return 'Anxiety';
      case EmotionalState.stress:
        return 'Stress';
      case EmotionalState.discomfort:
        return 'Discomfort';
      case EmotionalState.unknown:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case EmotionalState.normal:
        return 'All readings are within normal range';
      case EmotionalState.anxiety:
        return 'Signs of anxiety detected';
      case EmotionalState.stress:
        return 'Elevated stress levels detected';
      case EmotionalState.discomfort:
        return 'Discomfort indicators present';
      case EmotionalState.unknown:
        return 'Unable to determine state';
    }
  }
}

class EmotionalStateResult {
  final EmotionalState state;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> indicators;
  final DateTime detectedAt;

  EmotionalStateResult({
    required this.state,
    required this.confidence,
    required this.indicators,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'confidence': confidence,
      'indicators': indicators,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory EmotionalStateResult.fromJson(Map<String, dynamic> json) {
    try {
      // Debug logging
      debugPrint('📋 EmotionalStateResult.fromJson: Parsing data');
      debugPrint('   JSON keys: ${json.keys.toList()}');
      debugPrint('   State value: ${json['state']}');
      debugPrint('   Confidence value: ${json['confidence']}');
      
      final stateName = json['state']?.toString() ?? 'unknown';
      final state = EmotionalState.values.firstWhere(
        (e) => e.name == stateName,
        orElse: () => EmotionalState.unknown,
      );
      
      final confidence = (json['confidence'] ?? 0.0).toDouble();
      final indicators = json['indicators'] != null 
          ? Map<String, dynamic>.from(json['indicators'] is Map 
              ? json['indicators'] 
              : {})
          : <String, dynamic>{};
      
      DateTime detectedAt;
      try {
        final detectedAtStr = json['detectedAt']?.toString();
        detectedAt = detectedAtStr != null 
            ? DateTime.parse(detectedAtStr) 
            : DateTime.now();
      } catch (e) {
        debugPrint('⚠️ Error parsing detectedAt, using now: $e');
        detectedAt = DateTime.now();
      }
      
      debugPrint('✅ EmotionalStateResult.fromJson: Successfully created');
      debugPrint('   Final state: ${state.name}, confidence: $confidence');
      
      return EmotionalStateResult(
        state: state,
        confidence: confidence,
        indicators: indicators,
        detectedAt: detectedAt,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ EmotionalStateResult.fromJson: Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   JSON: $json');
      // Return a default unknown state instead of crashing
      return EmotionalStateResult(
        state: EmotionalState.unknown,
        confidence: 0.0,
        indicators: {},
        detectedAt: DateTime.now(),
      );
    }
  }
}

