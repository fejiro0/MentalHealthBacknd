#include <Arduino.h>
#include "AZ3166WiFi.h"
#include "Wire.h"
#include "MXChipFirebase.h"

// ============================================================================
// DIRECT HARDWARE SENSOR IMPLEMENTATION
// ============================================================================

// I2C Addresses for Built-in Sensors
#define HTS221_ADDR        0x5F    // Temperature & Humidity
#define LSM6DS3_ADDR       0x6A    // Accelerometer & Gyroscope  
#define LPS22HB_ADDR       0x5C    // Barometric Pressure
#define LIS2MDL_ADDR       0x1E    // Magnetometer

// HTS221 Register Map (Temperature & Humidity)
#define HTS221_WHO_AM_I        0x0F
#define HTS221_CTRL_REG1       0x20
#define HTS221_CTRL_REG2       0x21
#define HTS221_CTRL_REG3       0x22
#define HTS221_STATUS_REG      0x27
#define HTS221_TEMP_OUT_L      0x2A
#define HTS221_TEMP_OUT_H      0x2B
#define HTS221_HUMIDITY_OUT_L  0x28
#define HTS221_HUMIDITY_OUT_H  0x29
#define HTS221_CALIB_T0_DEGC_X8    0x32
#define HTS221_CALIB_T1_DEGC_X8    0x33
#define HTS221_CALIB_T0_T1_MSB     0x35
#define HTS221_CALIB_T0_OUT_L      0x3C
#define HTS221_CALIB_T0_OUT_H      0x3D
#define HTS221_CALIB_T1_OUT_L      0x3E
#define HTS221_CALIB_T1_OUT_H      0x3F
#define HTS221_CALIB_H0_RH_X2      0x30
#define HTS221_CALIB_H1_RH_X2      0x31
#define HTS221_CALIB_H0_T0_OUT_L   0x36
#define HTS221_CALIB_H0_T0_OUT_H   0x37
#define HTS221_CALIB_H1_T0_OUT_L   0x3A
#define HTS221_CALIB_H1_T0_OUT_H   0x3B

// LSM6DS3 Register Map (Accelerometer & Gyroscope)
#define LSM6DS3_WHO_AM_I       0x0F
#define LSM6DS3_CTRL1_XL       0x10
#define LSM6DS3_CTRL2_G        0x11
#define LSM6DS3_CTRL3_C        0x12
#define LSM6DS3_CTRL4_C        0x13
#define LSM6DS3_CTRL5_C        0x14
#define LSM6DS3_CTRL6_C        0x15
#define LSM6DS3_CTRL7_G        0x16
#define LSM6DS3_CTRL8_XL       0x17
#define LSM6DS3_CTRL9_XL       0x18
#define LSM6DS3_CTRL10_C       0x19
#define LSM6DS3_OUTX_L_XL      0x28
#define LSM6DS3_OUTX_H_XL      0x29
#define LSM6DS3_OUTY_L_XL      0x2A
#define LSM6DS3_OUTY_H_XL      0x2B
#define LSM6DS3_OUTZ_L_XL      0x2C
#define LSM6DS3_OUTZ_H_XL      0x2D
#define LSM6DS3_OUTX_L_G       0x22
#define LSM6DS3_OUTX_H_G       0x23
#define LSM6DS3_OUTY_L_G       0x24
#define LSM6DS3_OUTY_H_G       0x25
#define LSM6DS3_OUTZ_L_G       0x26
#define LSM6DS3_OUTZ_H_G       0x27

// LPS22HB Register Map (Pressure)
#define LPS22HB_WHO_AM_I       0x0F
#define LPS22HB_CTRL_REG1      0x10
#define LPS22HB_CTRL_REG2      0x11
#define LPS22HB_CTRL_REG3      0x12
#define LPS22HB_STATUS_REG     0x27
#define LPS22HB_PRESS_OUT_XL   0x28
#define LPS22HB_PRESS_OUT_L    0x29
#define LPS22HB_PRESS_OUT_H    0x2A
#define LPS22HB_TEMP_OUT_L     0x2B
#define LPS22HB_TEMP_OUT_H     0x2C

// LIS2MDL Register Map (Magnetometer)
#define LIS2MDL_WHO_AM_I       0x4F
#define LIS2MDL_CFG_REG_A      0x60
#define LIS2MD3_CFG_REG_C      0x62
#define LIS2MDL_STATUS_REG     0x67
#define LIS2MDL_OUTX_L_REG     0x68
#define LIS2MDL_OUTX_H_REG     0x69
#define LIS2MDL_OUTY_L_REG     0x6A
#define LIS2MDL_OUTY_H_REG     0x6B
#define LIS2MDL_OUTZ_L_REG     0x6C
#define LIS2MDL_OUTZ_H_REG     0x6D

// Microphone Pin (Analog)
#define MIC_PIN A3

// Sound Calibration Parameters
#define SOUND_BASELINE_SAMPLES 50    // Samples to take for baseline calibration
#define SOUND_BASELINE_THRESHOLD 5   // Minimum change from baseline to register as sound

// Configuration - prefer project `src/config.h` but provide safe defaults
// Copy `src/config.h.example` -> `src/config.h` and fill your values.
#include "config.h"

// Ensure defaults exist if `config.h` didn't define them
#ifndef WIFI_SSID
#define WIFI_SSID "AZUSPROG 0814"
#endif
#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD "12345679"
#endif
#ifndef PROXY_SERVER_HOST
#define PROXY_SERVER_HOST "192.168.1.100"
#endif
#ifndef PROXY_SERVER_PORT
#define PROXY_SERVER_PORT 3000
#endif
#ifndef PROXY_ENDPOINT
#define PROXY_ENDPOINT "/sensor-data"
#endif
#ifndef FIREBASE_HOST
#define FIREBASE_HOST "your-project-default-rtdb.firebaseio.com"
#endif
#ifndef FIREBASE_PROJECT_ID
#define FIREBASE_PROJECT_ID "your-project-id"
#endif
#ifndef DEVICE_ID
#define DEVICE_ID "MXCHIP_001"
#endif
#ifndef FIREBASE_UPDATE_INTERVAL_MS
#define FIREBASE_UPDATE_INTERVAL_MS 2000
#endif

// ============================================================================
// DIRECT I2C COMMUNICATION FUNCTIONS
// ============================================================================

// Direct I2C Write - Single Register
void i2cWriteRegister(uint8_t deviceAddr, uint8_t reg, uint8_t value) {
    Wire.beginTransmission(deviceAddr);
    Wire.write(reg);
    Wire.write(value);
    Wire.endTransmission();
}

// Direct I2C Read - Single Register
uint8_t i2cReadRegister(uint8_t deviceAddr, uint8_t reg) {
    Wire.beginTransmission(deviceAddr);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom(deviceAddr, (uint8_t)1);
    return Wire.read();
  }

// Direct I2C Read - Multiple Registers
void i2cReadRegisters(uint8_t deviceAddr, uint8_t reg, uint8_t* data, uint8_t length) {
    Wire.beginTransmission(deviceAddr);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom(deviceAddr, length);
    for (uint8_t i = 0; i < length; i++) {
        data[i] = Wire.read();
    }
}

// Direct I2C Read - 16-bit Value
int16_t i2cRead16Bit(uint8_t deviceAddr, uint8_t regL, uint8_t regH) {
    uint8_t low = i2cReadRegister(deviceAddr, regL);
    uint8_t high = i2cReadRegister(deviceAddr, regH);
    return (int16_t)((high << 8) | low);
  }

// ============================================================================
// SOUND SENSOR CALIBRATION SYSTEM
// ============================================================================

class SoundCalibrator {
private:
    int baselineValue;
    int baselinePeakToPeak;  // Natural variation in quiet room
    bool isCalibrated;
    float smoothedValue;
    
    // Sensitivity settings
    const float SMOOTHING = 0.80f;  // 80% old, 20% new (stable but responsive)
    const float SENSITIVITY = 2.0f;  // Amplify variations for distant sounds
    
public:
    SoundCalibrator() {
        baselineValue = 0;
        baselinePeakToPeak = 0;
        isCalibrated = false;
        smoothedValue = 0.0f;
    }
    
    // Calibrate baseline during quiet period
    void calibrate() {
        Serial.println("🎤 Sound Sensor: Starting baseline calibration...");
        Serial.println("🎤 Please keep quiet for 3 seconds...");
        
        long sumAvg = 0;
        long sumPeak = 0;
        int samples = 30;
        
        for (int i = 0; i < samples; i++) {
            // Measure average
            int val = analogRead(MIC_PIN);
            sumAvg += val;
            
            // Measure peak-to-peak variation
            int minVal = 1023, maxVal = 0;
            for (int j = 0; j < 10; j++) {
                int reading = analogRead(MIC_PIN);
                if (reading < minVal) minVal = reading;
                if (reading > maxVal) maxVal = reading;
                delayMicroseconds(100);
            }
            sumPeak += (maxVal - minVal);
            
            delay(100);
            
            if (i % 10 == 0) {
                Serial.print("🎤 Calibrating... ");
                Serial.print((i * 100) / samples);
                Serial.println("%");
            }
        }
        
        baselineValue = sumAvg / samples;
        baselinePeakToPeak = sumPeak / samples;
        smoothedValue = 0.0f;
        isCalibrated = true;
        
        Serial.print("🎤 Baseline (average): ");
        Serial.print(baselineValue);
        Serial.print(" | Natural variation: ");
        Serial.println(baselinePeakToPeak);
        Serial.println("🎤 Sound sensor ready! (Quiet room should read 0-10)");
    }
    
    // Get calibrated sound level - sensitive to distant sounds
    int getCalibratedSoundLevel() {
        if (!isCalibrated) {
            return analogRead(MIC_PIN);
        }
        
        // Method 1: Average reading (for loud sounds)
        int rawAvg = analogRead(MIC_PIN);
        int avgDiff = abs(rawAvg - baselineValue);
        
        // Method 2: Peak-to-peak (for distant sounds - more sensitive)
        int minVal = 1023, maxVal = 0;
        for (int i = 0; i < 15; i++) {
            int reading = analogRead(MIC_PIN);
            if (reading < minVal) minVal = reading;
            if (reading > maxVal) maxVal = reading;
            delayMicroseconds(100);
        }
        int peakToPeak = maxVal - minVal;
        
        // Subtract natural variation
        int relativePeak = peakToPeak - baselinePeakToPeak;
        if (relativePeak < 0) relativePeak = 0;
        
        // Amplify variations for sensitivity to distant sounds
        int amplifiedPeak = (int)(relativePeak * SENSITIVITY);
        
        // Combine: use larger of the two methods
        int combined = (avgDiff > amplifiedPeak) ? avgDiff : amplifiedPeak;
        
        // Apply smoothing for stability
        smoothedValue = SMOOTHING * smoothedValue + (1.0f - SMOOTHING) * combined;
        
        return (int)smoothedValue;
    }
    
    bool isReady() {
        return isCalibrated;
    }
    
    int getBaseline() {
        return baselineValue;
    }
};

// Global sound calibrator
SoundCalibrator soundCalibrator;

// ============================================================================
// HTS221 TEMPERATURE & HUMIDITY SENSOR
// ============================================================================

struct HTS221_Calibration {
    float T0_degC, T1_degC;
    int16_t T0_out, T1_out;
    float H0_rh, H1_rh;
    int16_t H0_T0_out, H1_T0_out;
};

class HTS221_Direct {
private:
    uint8_t address;
    HTS221_Calibration calib;
    float tempBuffer[5] = {0};
    float humBuffer[5] = {0};
    uint8_t bufferIndex = 0;

    float smoothData(float* buffer, float newValue) {
        buffer[bufferIndex] = newValue;
        bufferIndex = (bufferIndex + 1) % 5;
    
    float sum = 0;
        for (uint8_t i = 0; i < 5; i++) {
      sum += buffer[i];
    }
        return sum / 5.0f;
  }

public:
    HTS221_Direct(uint8_t addr = HTS221_ADDR) : address(addr) {}

  bool begin() {
    Wire.begin();
    
        // Check device ID
        if (i2cReadRegister(address, HTS221_WHO_AM_I) != 0xBC) {
            Serial.println("HTS221: Device not found!");
      return false;
    }

        // Power on and set data rate
        i2cWriteRegister(address, HTS221_CTRL_REG1, 0x85); // 12.5Hz, BDU=1, ODR=01
        
        // Wait for sensor to stabilize
        delay(100);

    // Read calibration data
        uint8_t T0_degC_x8 = i2cReadRegister(address, HTS221_CALIB_T0_DEGC_X8);
        uint8_t T1_degC_x8 = i2cReadRegister(address, HTS221_CALIB_T1_DEGC_X8);
        uint8_t T0_T1_msb = i2cReadRegister(address, HTS221_CALIB_T0_T1_MSB);

    calib.T0_degC = ((T0_T1_msb & 0x03) << 8 | T0_degC_x8) / 8.0f;
    calib.T1_degC = ((T0_T1_msb & 0x0C) << 6 | T1_degC_x8) / 8.0f;
        calib.T0_out = i2cRead16Bit(address, HTS221_CALIB_T0_OUT_L, HTS221_CALIB_T0_OUT_H);
        calib.T1_out = i2cRead16Bit(address, HTS221_CALIB_T1_OUT_L, HTS221_CALIB_T1_OUT_H);
        calib.H0_rh = i2cReadRegister(address, HTS221_CALIB_H0_RH_X2) / 2.0f;
        calib.H1_rh = i2cReadRegister(address, HTS221_CALIB_H1_RH_X2) / 2.0f;
        calib.H0_T0_out = i2cRead16Bit(address, HTS221_CALIB_H0_T0_OUT_L, HTS221_CALIB_H0_T0_OUT_H);
        calib.H1_T0_out = i2cRead16Bit(address, HTS221_CALIB_H1_T0_OUT_L, HTS221_CALIB_H1_T0_OUT_H);

        // Initialize buffers
        for (uint8_t i = 0; i < 5; i++) {
      tempBuffer[i] = calib.T0_degC;
      humBuffer[i] = calib.H0_rh;
    }

        Serial.println("HTS221: Direct hardware initialization successful!");
    return true;
  }

  void readData(float &temperature, float &humidity) {
        // Check if data is ready
        uint8_t status = i2cReadRegister(address, HTS221_STATUS_REG);
        if (!(status & 0x03)) return; // No new data

        // Read temperature
        int16_t temp_raw = i2cRead16Bit(address, HTS221_TEMP_OUT_L, HTS221_TEMP_OUT_H);
    temperature = calib.T0_degC + (float)(temp_raw - calib.T0_out) * 
                 (calib.T1_degC - calib.T0_degC) / (float)(calib.T1_out - calib.T0_out);

        // Read humidity
        int16_t hum_raw = i2cRead16Bit(address, HTS221_HUMIDITY_OUT_L, HTS221_HUMIDITY_OUT_H);
    humidity = calib.H0_rh + (float)(hum_raw - calib.H0_T0_out) * 
              (calib.H1_rh - calib.H0_rh) / (float)(calib.H1_T0_out - calib.H0_T0_out);
    humidity = constrain(humidity, 0.0f, 100.0f);

    // Apply smoothing
        temperature = smoothData(tempBuffer, temperature);
        humidity = smoothData(humBuffer, humidity);
    }
};

// ============================================================================
// LSM6DS3 ACCELEROMETER & GYROSCOPE SENSOR
// ============================================================================

struct MotionData {
    float accelX, accelY, accelZ;    // m/s²
    float gyroX, gyroY, gyroZ;       // degrees/s
    float motionMagnitude;            // Overall motion level
    float xAngle, yAngle, zAngle;    // Orientation angles (degrees) - matches phone display
    bool isMoving;                    // Motion detection flag
    bool sensorWorking;               // Sensor status flag
};

class LSM6DS3_Direct {
private:
    uint8_t address;
    
    // Orientation angles (complementary filter state)
    float pitch = 0.0f;   // Y-axis rotation (yAngle)
    float roll = 0.0f;    // X-axis rotation (xAngle)
    float yaw = 0.0f;     // Z-axis rotation (zAngle)
    unsigned long lastAngleUpdate = 0;
    const float ALPHA = 0.98f;  // Complementary filter coefficient (98% gyro, 2% accel)
    
public:
    LSM6DS3_Direct(uint8_t addr = 0x6A) : address(addr) {}
    
    bool begin() {
        Serial.println("LSM6DS3: Starting ROBUST initialization...");
        
        // 1. Check device ID with multiple attempts
        Serial.println("LSM6DS3: Checking device ID...");
        uint8_t deviceId = 0;
        bool deviceFound = false;
        
        for (int attempt = 0; attempt < 3; attempt++) {
            deviceId = i2cReadRegister(address, LSM6DS3_WHO_AM_I);
            Serial.print("LSM6DS3: Attempt ");
            Serial.print(attempt + 1);
            Serial.print(" - Device ID = 0x");
            Serial.println(deviceId, 16);
            
            if (deviceId == 0x69 || deviceId == 0x6A) {
                deviceFound = true;
                Serial.println("LSM6DS3: ✅ Device found with ID 0x" + String(deviceId, 16));
                break;
            }
            delay(100);
        }
        
        if (!deviceFound) {
            Serial.println("LSM6DS3: Device not found! Expected 0x69 or 0x6A, got 0x" + String(deviceId, 16));
            Serial.println("LSM6DS3: This could be:");
            Serial.println("  - Wrong I2C address (trying 0x6B as alternative)");
            Serial.println("  - Hardware connection issue");
            Serial.println("  - Sensor not powered");
            
            // Try alternative address 0x6B
            Serial.println("LSM6DS3: Trying alternative address 0x6B...");
            address = 0x6B;
            deviceId = i2cReadRegister(address, LSM6DS3_WHO_AM_I);
            Serial.print("LSM6DS3: Alternative address Device ID = 0x");
            Serial.println(deviceId, 16);
            
            if (deviceId != 0x69 && deviceId != 0x6A) {
                Serial.println("LSM6DS3: Alternative address also failed!");
                return false;
            } else {
                Serial.println("LSM6DS3: Found device at alternative address 0x6B!");
            }
        }
        
        // 2. Reset device completely
        Serial.println("LSM6DS3: Performing complete reset...");
        i2cWriteRegister(address, LSM6DS3_CTRL3_C, 0x01);
        delay(200);
        
        // 3. Wait for reset to complete
        uint8_t resetStatus = i2cReadRegister(address, LSM6DS3_CTRL3_C);
        Serial.print("LSM6DS3: Reset status = 0x");
        Serial.println(resetStatus, 16);
        
        // 4. Configure accelerometer: 100Hz, ±2g, BDU enabled
        Serial.println("LSM6DS3: Configuring accelerometer...");
        i2cWriteRegister(address, LSM6DS3_CTRL1_XL, 0x50); // 100Hz, ±2g
        delay(100);
        
        // 5. Configure gyroscope: 100Hz, ±245dps, BDU enabled
        Serial.println("LSM6DS3: Configuring gyroscope...");
        i2cWriteRegister(address, LSM6DS3_CTRL2_G, 0x50); // 100Hz, ±245dps
        delay(100);
        
        // 6. Configure control register: BDU=1, IF_INC=1
        Serial.println("LSM6DS3: Configuring control register...");
        i2cWriteRegister(address, LSM6DS3_CTRL3_C, 0x04); // BDU=1, IF_INC=1
        delay(100);
        
        // 7. Verify configuration
        uint8_t ctrl1 = i2cReadRegister(address, LSM6DS3_CTRL1_XL);
        uint8_t ctrl2 = i2cReadRegister(address, LSM6DS3_CTRL2_G);
        uint8_t ctrl3 = i2cReadRegister(address, LSM6DS3_CTRL3_C);
        
        Serial.print("LSM6DS3: CTRL1_XL = 0x");
        Serial.println(ctrl1, 16);
        Serial.print("LSM6DS3: CTRL2_G = 0x");
        Serial.println(ctrl2, 16);
        Serial.print("LSM6DS3: CTRL3_C = 0x");
        Serial.println(ctrl3, 16);
        
        // 8. Wait for sensor to stabilize
        Serial.println("LSM6DS3: Waiting for stabilization...");
        delay(1000);
        
        // 9. Test data production with multiple attempts
        Serial.println("LSM6DS3: Testing data production...");
        bool hasData = false;
        
        for (int attempt = 0; attempt < 5; attempt++) {
            uint8_t testData[6];
            i2cReadRegisters(address, LSM6DS3_OUTX_L_XL, testData, 6);
            
            Serial.print("LSM6DS3: Attempt ");
            Serial.print(attempt + 1);
            Serial.print(" - Test read: ");
            for (int i = 0; i < 6; i++) {
                Serial.print("0x");
                Serial.print(testData[i], 16);
                Serial.print(" ");
            }
            Serial.println();
            
            // Check if any data is non-zero
            for (int i = 0; i < 6; i++) {
                if (testData[i] != 0x00) {
                    hasData = true;
                    break;
                }
            }
            
            if (hasData) {
                Serial.println("LSM6DS3: ✅ Data is being produced!");
                break;
            }
            
            delay(500);
        }
        
        if (!hasData) {
            Serial.println("LSM6DS3: ❌ No data after multiple attempts - trying alternative config...");
            
            // Try alternative configuration
            i2cWriteRegister(address, LSM6DS3_CTRL1_XL, 0x60); // 833Hz, ±2g
            delay(100);
            i2cWriteRegister(address, LSM6DS3_CTRL2_G, 0x60); // 833Hz, ±245dps
            delay(100);
            i2cWriteRegister(address, LSM6DS3_CTRL3_C, 0x04); // BDU=1
            delay(100);
            
            delay(1000);
            
            // Test again
            uint8_t testData[6];
            i2cReadRegisters(address, LSM6DS3_OUTX_L_XL, testData, 6);
            Serial.print("LSM6DS3: Alternative test: ");
            for (int i = 0; i < 6; i++) {
                Serial.print("0x");
                Serial.print(testData[i], 16);
                Serial.print(" ");
            }
            Serial.println();
            
            hasData = false;
            for (int i = 0; i < 6; i++) {
                if (testData[i] != 0x00) {
                    hasData = true;
                    break;
                }
            }
            
            if (!hasData) {
                Serial.println("LSM6DS3: ❌ Still no data - hardware issue!");
                return false;
            }
        }
        
        Serial.println("LSM6DS3: ✅ Initialization successful!");
        return true;
    }
    
    void readData(MotionData &motion) {
        uint8_t data[12];
        
        // Read accelerometer data
        i2cReadRegisters(address, LSM6DS3_OUTX_L_XL, data, 6);
        
        // Convert to signed 16-bit values
        int16_t accelX_raw = (int16_t)(data[1] << 8 | data[0]);
        int16_t accelY_raw = (int16_t)(data[3] << 8 | data[2]);
        int16_t accelZ_raw = (int16_t)(data[5] << 8 | data[4]);
        
        // Convert to m/s² (scale factor for ±2g range: 0.061 mg/LSB)
        motion.accelX = accelX_raw * 0.061f * 0.001f * 9.81f;
        motion.accelY = accelY_raw * 0.061f * 0.001f * 9.81f;
        motion.accelZ = accelZ_raw * 0.061f * 0.001f * 9.81f;
        
        // Read gyroscope data
        i2cReadRegisters(address, LSM6DS3_OUTX_L_G, data, 6);
        
        // Convert to signed 16-bit values
        int16_t gyroX_raw = (int16_t)(data[1] << 8 | data[0]);
        int16_t gyroY_raw = (int16_t)(data[3] << 8 | data[2]);
        int16_t gyroZ_raw = (int16_t)(data[5] << 8 | data[4]);
        
        // Convert to degrees/s (scale factor for ±245dps range: 8.75 mdps/LSB)
        motion.gyroX = gyroX_raw * 8.75f * 0.001f;
        motion.gyroY = gyroY_raw * 8.75f * 0.001f;
        motion.gyroZ = gyroZ_raw * 8.75f * 0.001f;
        
        // Calculate motion magnitude (excluding gravity)
        // Remove gravity component (assuming Z-axis is vertical)
        float accelX_noGravity = motion.accelX;
        float accelY_noGravity = motion.accelY;
        float accelZ_noGravity = motion.accelZ - 9.81f; // Remove gravity
        
        motion.motionMagnitude = sqrt(accelX_noGravity * accelX_noGravity + 
                                    accelY_noGravity * accelY_noGravity + 
                                    accelZ_noGravity * accelZ_noGravity);
        
        // Motion detection (now properly calibrated)
        motion.isMoving = (motion.motionMagnitude > 0.1f);
        
        // Calculate orientation angles (matching phone display format)
        // Using complementary filter: accelerometer for long-term accuracy, gyro for responsiveness
        unsigned long currentAngleTime = millis();
        float dt = 0.0f;
        
        if (lastAngleUpdate > 0) {
            dt = (currentAngleTime - lastAngleUpdate) / 1000.0f;  // Convert to seconds
        } else {
            dt = 0.01f;  // Default 10ms for first reading
        }
        lastAngleUpdate = currentAngleTime;
        
        // Calculate angles from accelerometer (when device is relatively still)
        // Convert accelerometer from m/s² to g
        float ax_g = motion.accelX / 9.81f;
        float ay_g = motion.accelY / 9.81f;
        float az_g = motion.accelZ / 9.81f;
        
        // Calculate accelerometer-based angles (in degrees)
        // Roll (rotation around X-axis) = xAngle
        float accelRoll = atan2(ay_g, az_g) * 180.0f / 3.14159265f;
        
        // Pitch (rotation around Y-axis) = yAngle
        float accelPitch = atan2(-ax_g, sqrt(ay_g * ay_g + az_g * az_g)) * 180.0f / 3.14159265f;
        
        // Yaw (rotation around Z-axis) = zAngle (approximate from accelerometer)
        float accelYaw = atan2(ay_g, ax_g) * 180.0f / 3.14159265f;
        
        // Integrate gyroscope to get angle change
        if (dt > 0 && dt < 1.0f) {  // Valid time delta (avoid huge jumps)
            // Update angles using complementary filter
            // ALPHA = 0.98 means 98% gyro (responsive), 2% accelerometer (stable)
            pitch = ALPHA * (pitch + motion.gyroY * dt) + (1.0f - ALPHA) * accelPitch;
            roll = ALPHA * (roll + motion.gyroX * dt) + (1.0f - ALPHA) * accelRoll;
            yaw = ALPHA * (yaw + motion.gyroZ * dt) + (1.0f - ALPHA) * accelYaw;
        } else {
            // First reading or invalid dt - use accelerometer directly
            pitch = accelPitch;
            roll = accelRoll;
            yaw = accelYaw;
        }
        
        // Store angles in motion structure (matching phone display: x-angle, y-angle, z-angle)
        motion.xAngle = roll;   // X-axis rotation
        motion.yAngle = pitch;  // Y-axis rotation
        motion.zAngle = yaw;    // Z-axis rotation
        
        // Set sensor working flag
        motion.sensorWorking = true;
    }
};

// ============================================================================
// PROFESSIONAL SENSOR MONITORING SYSTEM
// ============================================================================

// Data Collection Parameters
#define SAMPLE_FREQUENCY_MS 1000        // Sample every 1 second
#define ANALYSIS_WINDOW_MS 10000        // Analyze over 10 seconds
#define SMOOTHING_SAMPLES 10            // Average over 10 samples
#define ALERT_THRESHOLD_COUNT 3         // Alert after 3 consecutive violations

// Sound Level Thresholds (Calibrated Scale - above baseline)
#define SOUND_SILENCE_MAX 5             // 0-5: Silence (near baseline)
#define SOUND_LOW_MAX 20                // 6-20: Low sound
#define SOUND_MEDIUM_MAX 50             // 21-50: Medium sound  
#define SOUND_HIGH_MAX 100              // 51-100: High sound
#define SOUND_DANGEROUS_MIN 100         // 100+: Dangerous/very loud

// Motion Intensity Thresholds (Gravity-Corrected Scale)
#define MOTION_CALM_MAX 0.5             // 0-0.5 m/s²: Calm (gravity-corrected)
#define MOTION_NORMAL_MAX 1.5           // 0.5-1.5 m/s²: Normal movement
#define MOTION_ACTIVE_MAX 3.0           // 1.5-3.0 m/s²: Active movement
#define MOTION_VIOLENT_MIN 3.0          // 3.0+ m/s²: Violent/shaking

// Environmental Thresholds
#define TEMP_COMFORTABLE_MIN 18.0       // 18-26°C: Comfortable
#define TEMP_COMFORTABLE_MAX 26.0
#define TEMP_UNCOMFORTABLE_MIN 26.0     // 26-30°C: Uncomfortable
#define TEMP_UNCOMFORTABLE_MAX 30.0
#define TEMP_DANGEROUS_MIN 30.0         // 30+°C: Dangerous

#define HUMIDITY_COMFORTABLE_MIN 30.0   // 30-70%: Comfortable
#define HUMIDITY_COMFORTABLE_MAX 70.0
#define HUMIDITY_UNCOMFORTABLE_MIN 70.0 // 70-85%: Uncomfortable
#define HUMIDITY_UNCOMFORTABLE_MAX 85.0
#define HUMIDITY_DANGEROUS_MIN 85.0     // 85+%: Dangerous

// ============================================================================
// INTELLIGENT DATA STRUCTURES
// ============================================================================

struct SensorData {
    float temperature;
    float humidity;
    float motionMagnitude;
    float soundLevel;
    unsigned long timestamp;
};

struct AnalysisResult {
    // Sound Analysis
    String soundStatus;
    bool soundAlert;
    int soundViolationCount;
    
    // Motion Analysis
    String motionStatus;
    bool motionAlert;
    int motionViolationCount;
    
    // Environmental Analysis
    String tempStatus;
    String humidityStatus;
    bool environmentalAlert;
    
    // Overall Health Status
    String overallStatus;
    int alertLevel; // 0=Normal, 1=Warning, 2=Alert, 3=Critical
};

class IntelligentSensorMonitor {
private:
    SensorData dataBuffer[SMOOTHING_SAMPLES];
    int bufferIndex;
    unsigned long lastAnalysis;
    unsigned long lastSample;
    
    // Alert Counters
    int soundAlertCount;
    int motionAlertCount;
    int environmentalAlertCount;
    
    // Trend Analysis
    float tempTrend;
    float humidityTrend;
    float motionTrend;
    float soundTrend;
    
public:
    IntelligentSensorMonitor() {
        bufferIndex = 0;
        lastAnalysis = 0;
        lastSample = 0;
        soundAlertCount = 0;
        motionAlertCount = 0;
        environmentalAlertCount = 0;
        tempTrend = 0;
        humidityTrend = 0;
        motionTrend = 0;
        soundTrend = 0;
        
        // Initialize buffer
        for (int i = 0; i < SMOOTHING_SAMPLES; i++) {
            dataBuffer[i] = {0, 0, 0, 0, 0};
        }
    }
    
    // Add new sensor data with timestamp
    void addData(float temp, float hum, float motion, float sound) {
        unsigned long now = millis();
        
        // Only sample at specified frequency
        if (now - lastSample >= SAMPLE_FREQUENCY_MS) {
            dataBuffer[bufferIndex] = {temp, hum, motion, sound, now};
            bufferIndex = (bufferIndex + 1) % SMOOTHING_SAMPLES;
            lastSample = now;
        }
    }
    
    // Get smoothed data (averaged over multiple samples)
    SensorData getSmoothedData() {
        float tempSum = 0, humSum = 0, motionSum = 0, soundSum = 0;
        int validSamples = 0;
        
        for (int i = 0; i < SMOOTHING_SAMPLES; i++) {
            if (dataBuffer[i].timestamp > 0) {
                tempSum += dataBuffer[i].temperature;
                humSum += dataBuffer[i].humidity;
                motionSum += dataBuffer[i].motionMagnitude;
                soundSum += dataBuffer[i].soundLevel;
                validSamples++;
            }
        }
        
        if (validSamples > 0) {
            return {
                tempSum / validSamples,
                humSum / validSamples,
                motionSum / validSamples,
                soundSum / validSamples,
                millis()
            };
        }
        
        return {0, 0, 0, 0, 0};
    }
    
    // Analyze sound levels intelligently
    String analyzeSound(float soundLevel) {
        if (soundLevel <= SOUND_SILENCE_MAX) return "SILENCE";
        if (soundLevel <= SOUND_LOW_MAX) return "LOW";
        if (soundLevel <= SOUND_MEDIUM_MAX) return "MEDIUM";
        if (soundLevel <= SOUND_HIGH_MAX) return "HIGH";
        return "DANGEROUS";
    }
    
    // Analyze motion intensity intelligently
    String analyzeMotion(float motionMagnitude) {
        if (motionMagnitude <= MOTION_CALM_MAX) return "CALM";
        if (motionMagnitude <= MOTION_NORMAL_MAX) return "NORMAL";
        if (motionMagnitude <= MOTION_ACTIVE_MAX) return "ACTIVE";
        return "VIOLENT";
    }
    
    // Analyze environmental conditions
    String analyzeTemperature(float temp) {
        if (temp >= TEMP_COMFORTABLE_MIN && temp <= TEMP_COMFORTABLE_MAX) return "COMFORTABLE";
        if (temp >= TEMP_UNCOMFORTABLE_MIN && temp <= TEMP_UNCOMFORTABLE_MAX) return "UNCOMFORTABLE";
        return "DANGEROUS";
    }
    
    String analyzeHumidity(float humidity) {
        if (humidity >= HUMIDITY_COMFORTABLE_MIN && humidity <= HUMIDITY_COMFORTABLE_MAX) return "COMFORTABLE";
        if (humidity >= HUMIDITY_UNCOMFORTABLE_MIN && humidity <= HUMIDITY_UNCOMFORTABLE_MAX) return "UNCOMFORTABLE";
        return "DANGEROUS";
    }
    
    // Calculate trends (rate of change)
    void calculateTrends() {
        if (bufferIndex >= 2) {
            int prevIndex = (bufferIndex - 2 + SMOOTHING_SAMPLES) % SMOOTHING_SAMPLES;
            int currIndex = (bufferIndex - 1 + SMOOTHING_SAMPLES) % SMOOTHING_SAMPLES;
            
            if (dataBuffer[prevIndex].timestamp > 0 && dataBuffer[currIndex].timestamp > 0) {
                unsigned long timeDiff = dataBuffer[currIndex].timestamp - dataBuffer[prevIndex].timestamp;
                if (timeDiff > 0) {
                    tempTrend = (dataBuffer[currIndex].temperature - dataBuffer[prevIndex].temperature) / (timeDiff / 1000.0f);
                    humidityTrend = (dataBuffer[currIndex].humidity - dataBuffer[prevIndex].humidity) / (timeDiff / 1000.0f);
                    motionTrend = (dataBuffer[currIndex].motionMagnitude - dataBuffer[prevIndex].motionMagnitude) / (timeDiff / 1000.0f);
                    soundTrend = (dataBuffer[currIndex].soundLevel - dataBuffer[prevIndex].soundLevel) / (timeDiff / 1000.0f);
                }
            }
        }
    }
    
    // Perform comprehensive analysis
    AnalysisResult analyze() {
        AnalysisResult result = {"", false, 0, "", false, 0, "", "", false, "", 0};
        
        unsigned long now = millis();
        
        // Only analyze at specified intervals
        if (now - lastAnalysis >= ANALYSIS_WINDOW_MS) {
            SensorData smoothed = getSmoothedData();
            calculateTrends();
            
            // Sound Analysis
            result.soundStatus = analyzeSound(smoothed.soundLevel);
            if (smoothed.soundLevel > SOUND_HIGH_MAX) {
                soundAlertCount++;
                result.soundAlert = (soundAlertCount >= ALERT_THRESHOLD_COUNT);
                result.soundViolationCount = soundAlertCount;
            } else {
                soundAlertCount = 0;
                result.soundAlert = false;
                result.soundViolationCount = 0;
            }
            
            // Motion Analysis
            result.motionStatus = analyzeMotion(smoothed.motionMagnitude);
            if (smoothed.motionMagnitude > MOTION_ACTIVE_MAX) {
                motionAlertCount++;
                result.motionAlert = (motionAlertCount >= ALERT_THRESHOLD_COUNT);
                result.motionViolationCount = motionAlertCount;
            } else {
                motionAlertCount = 0;
                result.motionAlert = false;
                result.motionViolationCount = 0;
            }
            
            // Environmental Analysis
            result.tempStatus = analyzeTemperature(smoothed.temperature);
            result.humidityStatus = analyzeHumidity(smoothed.humidity);
            result.environmentalAlert = (result.tempStatus == "DANGEROUS" || result.humidityStatus == "DANGEROUS");
            
            // Overall Status Assessment
            int alertScore = 0;
            if (result.soundAlert) alertScore += 1;
            if (result.motionAlert) alertScore += 1;
            if (result.environmentalAlert) alertScore += 2;
            
            if (alertScore == 0) {
                result.overallStatus = "NORMAL";
                result.alertLevel = 0;
            } else if (alertScore == 1) {
                result.overallStatus = "WARNING";
                result.alertLevel = 1;
            } else if (alertScore == 2) {
                result.overallStatus = "ALERT";
                result.alertLevel = 2;
  } else {
                result.overallStatus = "CRITICAL";
                result.alertLevel = 3;
            }
            
            lastAnalysis = now;
        }
        
        return result;
    }
    
    // Get current sensor readings (smoothed)
    SensorData getCurrentReadings() {
        return getSmoothedData();
    }
};

// Global instance
IntelligentSensorMonitor sensorMonitor;

// ============================================================================
// FIREBASE CLIENT (Using MXChipFirebase Library)
// ============================================================================

// Global Firebase client instance
MXChipFirebase firebaseClient;

// Runtime configuration variables (change without recompiling)
char currentProxyHost[128] = PROXY_SERVER_HOST;
int currentProxyPort = PROXY_SERVER_PORT;
String wifiSsidStr = String(WIFI_SSID);
String wifiPasswordStr = String(WIFI_PASSWORD);

// Process serial commands (SET PROXY host[:port], SET WIFI ssid password)
void processSerialCommands() {
    if (!Serial || Serial.available() == 0) return;
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd.length() == 0) return;
    Serial.print("Received command: "); Serial.println(cmd);

    if (cmd.startsWith("SET PROXY ")) {
        String payload = cmd.substring(10);
        payload.trim();
        int colonIndex = payload.indexOf(':');
        String hostPart = payload;
        String portPart = "";
        if (colonIndex > 0) {
            hostPart = payload.substring(0, colonIndex);
            portPart = payload.substring(colonIndex + 1);
        }
        hostPart.trim(); portPart.trim();
            if (hostPart.length() > 0) {
            strncpy(currentProxyHost, hostPart.c_str(), sizeof(currentProxyHost) - 1);
            currentProxyHost[sizeof(currentProxyHost) - 1] = '\0';
            if (portPart.length() > 0) {
                currentProxyPort = portPart.toInt();
            }
            Serial.print("Proxy set to: "); Serial.print(currentProxyHost); Serial.print(":"); Serial.println(currentProxyPort);
            // Try re-initializing the firebase client with the new host/port
            if (WiFi.status() == WL_CONNECTED) {
                if (firebaseClient.begin(currentProxyHost, currentProxyPort)) {
                    Serial.println("Firebase client reinitialized with new proxy");
                } else {
                    Serial.println("Firebase client reinitialization FAILED");
                }
            }
        }
    } else if (cmd.startsWith("SET WIFI ")) {
        String payload = cmd.substring(9);
        payload.trim();
        int firstSpace = payload.indexOf(' ');
        if (firstSpace > 0) {
            String ssid = payload.substring(0, firstSpace);
            String pass = payload.substring(firstSpace + 1);
            ssid.trim(); pass.trim();
            if (ssid.length() > 0) {
                wifiSsidStr = ssid;
                wifiPasswordStr = pass;
                Serial.print("WiFi set to SSID: "); Serial.print(wifiSsidStr); Serial.print(" (password length: "); Serial.print(wifiPasswordStr.length()); Serial.println(")");
                // Reconnect using new WiFi credentials
                Serial.println("Reconnecting WiFi with new credentials...");
                WiFi.disconnect();
                delay(200);
                const char* ssid_ptr2 = wifiSsidStr.c_str();
                const char* pwd_ptr2 = wifiPasswordStr.c_str();
                if (WiFi.begin((char*)ssid_ptr2, (char*)pwd_ptr2) == WL_CONNECTED) {
                    Serial.println("✅ WiFi Connected with new credentials!");
                    if (firebaseClient.begin(currentProxyHost, currentProxyPort)) {
                        Serial.println("✅ Firebase client initialized after WiFi reconnect");
                    }
                } else {
                    Serial.println("❌ WiFi connect (runtime) failed - verify credentials and try again");
                }
            }
        }
    } else if (cmd.equalsIgnoreCase("GET CONFIG")) {
        Serial.println("Current configuration:");
        Serial.print("  WiFi SSID: "); Serial.println(wifiSsidStr);
        Serial.print("  Proxy Host: "); Serial.print(currentProxyHost); Serial.print(":"); Serial.println(currentProxyPort);
    } else {
        Serial.println("Unknown command. Use 'SET PROXY host[:port]', 'SET WIFI ssid password', or 'GET CONFIG'.");
    }
}

// ============================================================================
// CLEAN, HUMAN-READABLE DISPLAY SYSTEM
// ============================================================================

// Display Settings
#define DISPLAY_INTERVAL_MS 1000        // Update values every 1 second
#define AVERAGE_WINDOW_MS 2000           // Average over 2 seconds for display
#define SIGNIFICANT_CHANGE_TEMP 0.1     // 0.1°C change (very sensitive)
#define SIGNIFICANT_CHANGE_HUM 0.5      // 0.5% change (very sensitive)
#define SIGNIFICANT_CHANGE_MOTION 0.05  // 0.05 m/s² change (very sensitive)
#define SIGNIFICANT_CHANGE_SOUND 1      // 1 unit change (very sensitive)

class CleanDisplay {
private:
    unsigned long lastDisplay;
    unsigned long lastDataCollection;
    bool headerPrinted;
    
    // Running averages
    float tempSum, humSum, motionSum, soundSum;
    int sampleCount;
    
    // Previous values for change detection
    float lastTemp, lastHum, lastMotion, lastSound;
    
public:
    CleanDisplay() {
        lastDisplay = 0;
        lastDataCollection = 0;
        headerPrinted = false;
        tempSum = humSum = motionSum = soundSum = 0;
        sampleCount = 0;
        lastTemp = lastHum = lastMotion = lastSound = -999;
    }
    
    void addData(float temp, float hum, float motion, float sound) {
        unsigned long now = millis();
        
        // Collect data every 500ms for better real-time accuracy
        if (now - lastDataCollection >= 500) {
            tempSum += temp;
            humSum += hum;
            motionSum += motion;
            soundSum += sound;
            sampleCount++;
            lastDataCollection = now;
        }
    }
    
    void display() {
        unsigned long now = millis();
        
        // Update values every second
        if (now - lastDisplay >= DISPLAY_INTERVAL_MS) {
            
            // Calculate averages
            float avgTemp = (sampleCount > 0) ? tempSum / sampleCount : 0;
            float avgHum = (sampleCount > 0) ? humSum / sampleCount : 0;
            float avgMotion = (sampleCount > 0) ? motionSum / sampleCount : 0;
            float avgSound = (sampleCount > 0) ? soundSum / sampleCount : 0;
            
            // Print header only once
            if (!headerPrinted) {
                Serial.println();
                Serial.println("═══════════════════════════════════════════════════════════════");
                Serial.println("          MENTAL HEALTH MONITOR - REAL-TIME SENSOR DATA");
                Serial.println("═══════════════════════════════════════════════════════════════");
                Serial.println();
                Serial.println("CURRENT READINGS:");
                Serial.println("───────────────────────────────────────────────────────────────");
                headerPrinted = true;
            }
            
            // Update each line in place using carriage return (static labels, dynamic values)
            // Temperature - overwrite the line
            Serial.print("\rTemperature: ");
            Serial.print(avgTemp, 2);
            Serial.print("°C                    ");  // Pad to clear old text
            
            // Humidity - move to next line and overwrite
            Serial.print("\nHumidity:    ");
            Serial.print(avgHum, 2);
            Serial.print("%                    ");
            
            // Motion
            Serial.print("\nMotion:      ");
            Serial.print(avgMotion, 3);
            Serial.print(" m/s²                  ");
            
            // Angles (if motion sensor is working)
            extern MotionData motion;
            if (motion.sensorWorking) {
                Serial.print("\nAngles:      X=");
                Serial.print(motion.xAngle, 1);
                Serial.print("° Y=");
                Serial.print(motion.yAngle, 1);
                Serial.print("° Z=");
                Serial.print(motion.zAngle, 1);
                Serial.print("°                    ");
            }
            
            // Sound
            Serial.print("\nSound:       ");
            Serial.print(avgSound, 1);
            Serial.print(" units                  ");
            
            // Update last values
            lastTemp = avgTemp;
            lastHum = avgHum;
            lastMotion = avgMotion;
            lastSound = avgSound;
            
            // Reset for next cycle
            tempSum = humSum = motionSum = soundSum = 0;
            sampleCount = 0;
            lastDisplay = now;
        }
    }
};

// Global clean display instance
CleanDisplay cleanDisplay;

// ============================================================================
// SENSOR INSTANCES
// ============================================================================

HTS221_Direct hts221;
LSM6DS3_Direct lsm6ds3;

// ============================================================================
// MAIN SETUP & LOOP
// ============================================================================

void setup() {
    Serial.begin(115200);
    // Allow a brief window for runtime configuration commands via Serial
    Serial.println("Type 'SET PROXY host[:port]' or 'SET WIFI ssid password' within 10 seconds to change runtime config");
    unsigned long configStart = millis();
    while (millis() - configStart < 10000) {
        processSerialCommands();
        delay(50);
    }
    while (!Serial);

    Serial.println("=== MXChip AZ3166 - Direct Hardware Sensor Implementation ===");
    Serial.println("Final Year Project: Mental Health Monitoring System");
    Serial.println("============================================================");
    
    // Initialize sensors with direct hardware access
    Serial.println("Initializing sensors with direct hardware control...");
    
    // First, scan I2C bus to see what devices are present
    Serial.println("Scanning I2C bus...");
    Wire.begin();
    int deviceCount = 0;
    for (uint8_t addr = 0x08; addr < 0x78; addr++) {
        Wire.beginTransmission(addr);
        if (Wire.endTransmission() == 0) {
            Serial.print("I2C device found at address 0x");
            Serial.println(addr, 16);
            deviceCount++;
        }
    }
    Serial.print("I2C scan complete. Found ");
    Serial.print(deviceCount);
    Serial.println(" devices.");
    
    // Test specific addresses
    Serial.println("Testing specific sensor addresses:");
    Wire.beginTransmission(0x5F); // HTS221
    if (Wire.endTransmission() == 0) {
        Serial.println("✅ HTS221 (0x5F) - RESPONDING");
    } else {
        Serial.println("❌ HTS221 (0x5F) - NOT RESPONDING");
    }
    
    Wire.beginTransmission(0x6A); // LSM6DS3
    if (Wire.endTransmission() == 0) {
        Serial.println("✅ LSM6DS3 (0x6A) - RESPONDING");
    } else {
        Serial.println("❌ LSM6DS3 (0x6A) - NOT RESPONDING");
    }
    
    Wire.beginTransmission(0x6B); // LSM6DS3 alternative
    if (Wire.endTransmission() == 0) {
        Serial.println("✅ LSM6DS3 (0x6B) - RESPONDING");
    } else {
        Serial.println("❌ LSM6DS3 (0x6B) - NOT RESPONDING");
    }
    Serial.println();
    
    bool hts221_ok = hts221.begin();
    bool lsm6ds3_ok = lsm6ds3.begin();
    
    // Calibrate sound sensor
    soundCalibrator.calibrate();
    
    Serial.println("============================================================");
    Serial.println("SENSOR INITIALIZATION SUMMARY:");
    Serial.print("HTS221 (Temperature & Humidity): ");
    Serial.println(hts221_ok ? "✅ OK" : "❌ FAILED");
    Serial.print("LSM6DS3 (Accelerometer & Gyroscope): ");
    Serial.println(lsm6ds3_ok ? "✅ OK" : "❌ FAILED");
    Serial.print("Microphone (Sound Sensor): ");
    Serial.println(soundCalibrator.isReady() ? "✅ CALIBRATED" : "❌ FAILED");
    Serial.println("============================================================");
    
    // Initialize WiFi using AZ3166 WiFi libraries
    Serial.println();
    Serial.println("============================================================");
    Serial.println("INITIALIZING WiFi CONNECTION...");
    Serial.println("============================================================");
    Serial.print("Connecting to WiFi: ");
    Serial.println(wifiSsidStr);
    
    // Initialize WiFi using standard WiFi class (from AZ3166WiFi.h)
    const char* ssid_ptr = wifiSsidStr.c_str();
    const char* pwd_ptr = wifiPasswordStr.c_str();
    if (WiFi.begin((char*)ssid_ptr, (char*)pwd_ptr) != WL_CONNECTED) {
        Serial.println("Connecting to WiFi...");
        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 20) {
            delay(500);
            Serial.print(".");
            attempts++;
        }
        Serial.println();
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi Connected!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        Serial.print("Signal Strength (RSSI): ");
        Serial.print(WiFi.RSSI());
        Serial.println(" dBm");
        
        // Initialize Firebase client
        Serial.println();
        Serial.println("============================================================");
        Serial.println("INITIALIZING FIREBASE CONNECTION...");
        Serial.println("============================================================");
        firebaseClient.setDebugMode(true);
        firebaseClient.setPath(PROXY_ENDPOINT);
        firebaseClient.setDeviceId(DEVICE_ID);
        firebaseClient.setUpdateInterval(FIREBASE_UPDATE_INTERVAL_MS);
        
        // Try to initialize client using runtime host & port
        if (firebaseClient.begin(currentProxyHost, currentProxyPort)) {
            Serial.println("✅ Firebase client initialized");
            Serial.print("Proxy Server: ");
            Serial.print(currentProxyHost);
            Serial.print(":");
            Serial.println(currentProxyPort);
        } else {
            Serial.println("❌ Firebase client initialization failed");
            Serial.print("Error: ");
            Serial.println(firebaseClient.getLastError());
        }
    } else {
        Serial.println("❌ WiFi Connection Failed!");
        Serial.println("System will continue but data won't be sent to Firebase.");
    }
    Serial.println("============================================================");
    
    if (!hts221_ok && !lsm6ds3_ok) {
        Serial.println("ERROR: No sensors working! Check hardware connections.");
    while(1);
  }

    Serial.println("System ready - Reading available sensor data...");
    Serial.println("============================================================");
}

// Global motion data for angle display
MotionData motion;

void loop() {
    // Evaluate runtime serial commands frequently
    processSerialCommands();
    // Read sensor data
    float temperature = 0.0f, humidity = 0.0f;
    motion.sensorWorking = false; // Default to false
    
    // Read HTS221 (temperature & humidity)
  hts221.readData(temperature, humidity);

    // Read LSM6DS3 (motion) - with fallback
    static bool lsm6ds3_working = true;
    if (lsm6ds3_working) {
        lsm6ds3.readData(motion);
        if (!motion.sensorWorking) {
            lsm6ds3_working = false;
            Serial.println("LSM6DS3: Sensor failed during operation - using fallback");
        }
    } else {
        // Fallback: simulate minimal motion data (gravity-corrected)
        motion.accelX = 0.0f;
        motion.accelY = 0.0f;
        motion.accelZ = 9.81f; // Gravity only
        motion.gyroX = 0.0f;
        motion.gyroY = 0.0f;
        motion.gyroZ = 0.0f;
        motion.motionMagnitude = 0.0f; // No motion (gravity-corrected)
        motion.xAngle = 0.0f;
        motion.yAngle = 0.0f;
        motion.zAngle = 0.0f;
        motion.isMoving = false;
        motion.sensorWorking = false;
    }
    
    // Read microphone (calibrated)
    int micValue = soundCalibrator.getCalibratedSoundLevel();
    
    // Add data to clean display system
    cleanDisplay.addData(temperature, humidity, motion.motionMagnitude, micValue);
    
    // Display clean report every 5 seconds
    cleanDisplay.display();
    
    // Send data to Firebase if WiFi is connected
    if (WiFi.status() == WL_CONNECTED && firebaseClient.isConnected()) {
        firebaseClient.sendSensorData(
            DEVICE_ID,
            temperature, 
            humidity, 
            motion.motionMagnitude,
            micValue,
            motion.accelX,
            motion.accelY,
            motion.accelZ,
            motion.gyroX,
            motion.gyroY,
            motion.gyroZ,
            motion.xAngle,
            motion.yAngle,
            motion.zAngle
        );
    }
    
    // Simple delay
    delay(1000);
}
