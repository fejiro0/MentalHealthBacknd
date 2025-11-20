#include <Arduino.h>

// ============================================================================
// SOUND SENSOR - HIGHLY SENSITIVE TO BACKGROUND NOISE
// ============================================================================

#define MIC_PIN A3

class AdvancedSoundSensor {
private:
    // Baseline and smoothing
    int quietBaseline = 0;
    float smoothedValue = 0.0f;
    bool isCalibrated = false;
    
    // Sampling parameters
    static const int FAST_SAMPLES = 30;      // Samples for peak-to-peak detection
    static const int CALIBRATION_SAMPLES = 100; // Samples for baseline
    
    // Sensitivity controls
    float sensitivity = 8.0f;                // Amplification for variations (higher = more sensitive)
    float smoothing = 0.70f;                 // Smoothing (0.7 = 70% old, 30% new)
    
    // Read baseline in quiet conditions
    int measureQuietBaseline() {
        long sum = 0;
        for (int i = 0; i < CALIBRATION_SAMPLES; i++) {
            sum += analogRead(MIC_PIN);
            delay(10);
        }
        return sum / CALIBRATION_SAMPLES;
    }
    
    // Detect sound variations (this catches distant sounds)
    int detectSoundVariations() {
        int minVal = 1023;
        int maxVal = 0;
        
        // Fast sampling to catch sound wave variations
        for (int i = 0; i < FAST_SAMPLES; i++) {
            int reading = analogRead(MIC_PIN);
            if (reading < minVal) minVal = reading;
            if (reading > maxVal) maxVal = reading;
            delayMicroseconds(100);
        }
        
        // Peak-to-peak: the amplitude of the sound wave
        int peakToPeak = maxVal - minVal;
        
        // Amplify for sensitivity (this makes distant sounds detectable)
        int amplified = (int)(peakToPeak * sensitivity);
        
        return amplified;
    }
    
public:
    AdvancedSoundSensor() {
        quietBaseline = 0;
        smoothedValue = 0.0f;
        isCalibrated = false;
    }
    
    // Calibrate by measuring the quiet room baseline
    void calibrate() {
        Serial.println("========================================");
        Serial.println("SOUND SENSOR CALIBRATION");
        Serial.println("========================================");
        Serial.println("Keep the room QUIET for 2 seconds...");
        delay(1000);
        
        Serial.print("Calibrating");
        for (int i = 0; i < 5; i++) {
            Serial.print(".");
            delay(200);
        }
        Serial.println();
        
        quietBaseline = measureQuietBaseline();
        smoothedValue = 0.0f;  // Start from 0 after calibration
        isCalibrated = true;
        
        Serial.print("Baseline (quiet room): ");
        Serial.println(quietBaseline);
        Serial.print("Sensitivity level: ");
        Serial.println(sensitivity);
        Serial.println("Calibration complete!");
        Serial.println("========================================");
        Serial.println();
    }
    
    // Get the current sound level
    int getSoundLevel() {
        if (!isCalibrated) {
            calibrate();
        }
        
        // Detect variations (this catches sound waves from distant sources)
        int variations = detectSoundVariations();
        
        // Apply smoothing for stable readings
        smoothedValue = smoothing * smoothedValue + (1.0f - smoothing) * variations;
        
        return (int)smoothedValue;
    }
    
    // Get sound level with descriptive status
    String getSoundStatus(int level) {
        if (level < 5) return "SILENT";
        if (level < 15) return "VERY QUIET";
        if (level < 30) return "QUIET";
        if (level < 50) return "NORMAL";
        if (level < 80) return "MODERATE";
        if (level < 120) return "LOUD";
        return "VERY LOUD";
    }
    
    // Adjust sensitivity (1.0 - 20.0)
    void setSensitivity(float newSensitivity) {
        sensitivity = newSensitivity;
        Serial.print("Sensitivity adjusted to: ");
        Serial.println(sensitivity);
    }
    
    // Get the baseline value
    int getBaseline() {
        return quietBaseline;
    }
};

// ============================================================================
// MAIN PROGRAM
// ============================================================================

AdvancedSoundSensor soundSensor;

void setup() {
    Serial.begin(115200);
    while (!Serial);
    
    Serial.println();
    Serial.println("============================================");
    Serial.println("  ADVANCED SOUND SENSOR TEST");
    Serial.println("  MXChip AZ3166 - Mental Health Monitor");
    Serial.println("============================================");
    Serial.println();
    
    // Calibrate the sensor
    soundSensor.calibrate();
    
    Serial.println("Starting continuous monitoring...");
    Serial.println("Legend: [Value] Status (higher = louder)");
    Serial.println();
}

void loop() {
    // Get sound level
    int soundLevel = soundSensor.getSoundLevel();
    String status = soundSensor.getSoundStatus(soundLevel);
    
    // Display with visual bar
    Serial.print("Sound: ");
    Serial.print(soundLevel);
    Serial.print(" | ");
    Serial.print(status);
    Serial.print(" | ");
    
    // Visual bar graph
    Serial.print("[");
    int bars = soundLevel / 5;  // Scale for display
    if (bars > 50) bars = 50;   // Max 50 bars
    for (int i = 0; i < bars; i++) {
        Serial.print("=");
    }
    Serial.println("]");
    
    delay(100);  // Update 10 times per second
}

