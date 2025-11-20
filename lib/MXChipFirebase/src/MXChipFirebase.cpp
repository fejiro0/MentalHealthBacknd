#include "MXChipFirebase.h"
// WiFi class is available from AZ3166WiFi.h included in MXChipFirebase.h

MXChipFirebase::MXChipFirebase() {
    connected = false;
    debugMode = false;
    host = "192.168.1.100";  // Default proxy server IP (update to your computer's IP)
    port = 3000;              // Default proxy server port
    path = "/sensor-data";
    deviceId = "MXCHIP_001";
    lastSendTime = 0;
    updateInterval = 5000;  // Default: send every 5 seconds
    strcpy(lastError, "");
}

bool MXChipFirebase::begin(const char* host, int port) {
    this->host = host;
    this->port = port;
    connected = (WiFi.status() == WL_CONNECTED);  // Check if WiFi is connected
    if (debugMode) {
        Serial.print("MXChipFirebase initialized: ");
        Serial.print(host);
        Serial.print(":");
        Serial.println(port);
    }
    return connected;
}

bool MXChipFirebase::sendData(float temperature, float humidity) {
    if (!connected) return false;

    if (client.connect(host, port)) {
        // Create the JSON payload
        char payload[128];
        snprintf(payload, sizeof(payload), 
                "{\"temperature\":%.2f,\"humidity\":%.1f,\"timestamp\":%lu}",
                temperature, humidity, millis());

        // Send HTTP POST request
        char request[256];
        snprintf(request, sizeof(request),
                "POST %s HTTP/1.1\r\n"
                "Host: %s\r\n"
                "Content-Type: application/json\r\n"
                "Connection: close\r\n"
                "Content-Length: %d\r\n"
                "\r\n"
                "%s",
                path, host, strlen(payload), payload);
        
        if (debugMode) {
            Serial.println("Sending request:");
            Serial.println(request);
        }
        
        client.print(request);

        // Wait for response with timeout
        unsigned long timeout = millis();
        while (client.available() == 0) {
            if (millis() - timeout > 5000) {
                strcpy(lastError, "Client Timeout!");
                if (debugMode) Serial.println(">>> Client Timeout!");
                client.stop();
                return false;
            }
            delay(10);
        }

        // Read and print the response
        if (debugMode) {
            while (client.available()) {
                char c = client.read();
                Serial.write(c);
            }
        }
        
        client.stop();
        return true;
    }
    
    strcpy(lastError, "Failed to connect to server");
    return false;
}

bool MXChipFirebase::sendJSON(const char* jsonData) {
    if (!connected || WiFi.status() != WL_CONNECTED) {
        strcpy(lastError, "WiFi not connected");
        return false;
    }

    if (client.connect(host, port)) {
        // Send HTTP POST request
        char request[1200];
        int contentLength = strlen(jsonData);
        
        snprintf(request, sizeof(request),
                "POST %s HTTP/1.1\r\n"
                "Host: %s:%d\r\n"
                "Content-Type: application/json\r\n"
                "Connection: close\r\n"
                "Content-Length: %d\r\n"
                "\r\n"
                "%s",
                path, host, port, contentLength, jsonData);
        
        if (debugMode) {
            Serial.print("Connecting to proxy server... ");
            Serial.print(host);
            Serial.print(":");
            Serial.println(port);
            Serial.println("Sending JSON request:");
            Serial.println(request);
        }
        
        client.print(request);

        // Wait for response with timeout
        unsigned long timeout = millis();
        while (client.available() == 0) {
            if (millis() - timeout > 5000) {
                strcpy(lastError, "Client Timeout!");
                if (debugMode) Serial.println(">>> Client Timeout!");
                client.stop();
                return false;
            }
            delay(10);
        }

        // Read response and check for success
        bool success = false;
        String response = "";
        while (client.available()) {
            char c = client.read();
            response += c;
            if (debugMode) {
                Serial.write(c);
            }
        }
        
        // Check if response indicates success
        if (response.indexOf("200 OK") >= 0 || response.indexOf("200") >= 0 || response.indexOf("success") >= 0) {
            success = true;
        }
        
        if (debugMode) {
            if (success) {
                Serial.println("Proxy: Data sent successfully to Firebase");
            } else {
                Serial.println("Proxy: Request sent but no success confirmation");
            }
        }
        
        client.stop();
        
        if (!success) {
            strcpy(lastError, "No success confirmation from server");
        }
        
        return success;
    }
    
    strcpy(lastError, "Failed to connect to server");
    if (debugMode) {
        Serial.print("Failed to connect to: ");
        Serial.print(host);
        Serial.print(":");
        Serial.println(port);
    }
    return false;
}

bool MXChipFirebase::isConnected() {
    return connected;
}

void MXChipFirebase::setDebugMode(bool debug) {
    debugMode = debug;
}

void MXChipFirebase::setPath(const char* path) {
    this->path = path;
}

bool MXChipFirebase::sendSensorData(const char* deviceId, float temp, float hum, float motionMag, int sound,
                                    float accelX, float accelY, float accelZ,
                                    float gyroX, float gyroY, float gyroZ,
                                    float xAngle, float yAngle, float zAngle) {
    if (!connected || WiFi.status() != WL_CONNECTED) {
        strcpy(lastError, "WiFi not connected");
        return false;
    }

    // Check if enough time has passed
    unsigned long now = millis();
    if (now - lastSendTime < updateInterval) {
        return true; // Too soon to send
    }
    lastSendTime = now;

    // Create JSON payload matching proxy server format
    char jsonPayload[800];
    unsigned long timestamp = now / 1000; // Convert to seconds
    
    snprintf(jsonPayload, sizeof(jsonPayload),
        "{"
        "\"device_id\":\"%s\","
        "\"timestamp\":%lu,"
        "\"temperature\":%.2f,"
        "\"humidity\":%.2f,"
        "\"motion_magnitude\":%.3f,"
        "\"motion_x\":%.3f,"
        "\"motion_y\":%.3f,"
        "\"motion_z\":%.3f,"
        "\"gyro_x\":%.3f,"
        "\"gyro_y\":%.3f,"
        "\"gyro_z\":%.3f,"
        "\"angle_x\":%.2f,"
        "\"angle_y\":%.2f,"
        "\"angle_z\":%.2f,"
        "\"sound\":%d"
        "}",
        deviceId ? deviceId : this->deviceId, timestamp,
        temp, hum,
        motionMag, accelX, accelY, accelZ,
        gyroX, gyroY, gyroZ,
        xAngle, yAngle, zAngle,
        sound
    );

    return sendJSON(jsonPayload);
}

void MXChipFirebase::setDeviceId(const char* deviceId) {
    this->deviceId = deviceId;
}

void MXChipFirebase::setUpdateInterval(unsigned long interval) {
    this->updateInterval = interval;
}

const char* MXChipFirebase::getLastError() {
    return lastError;
} 