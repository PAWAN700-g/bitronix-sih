/*
 * Bitronix Smart Water Quality Monitoring System
 * ESP32 Reference Firmware
 * 
 * Adaptive Sampling Algorithm:
 * - The system samples sensors at a Base Interval (2000ms) when water quality is stable.
 * - If a change beyond defined thresholds is detected (e.g., pH ±0.1), the system 
 *   switches to a Fast Interval (500ms) to closely monitor the fluctuation.
 * - Once the readings remain stable (change within thresholds) for 10 consecutive 
 *   readings, the system reverts back to the Base Interval.
 * - To reduce bandwidth and cloud costs, delta updates are used: data is only pushed 
 *   to Firebase when values change beyond the defined thresholds.
 */

#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <time.h>

// ---------------------------------------------------------
// WiFi & Firebase Configuration (Placeholders)
// ---------------------------------------------------------
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

#define API_KEY "YOUR_FIREBASE_WEB_API_KEY"
#define DATABASE_URL "https://bitronix-sih-default-rtdb.asia-southeast1.firebasedatabase.app"
#define USER_EMAIL "YOUR_USER_EMAIL"
#define USER_PASSWORD "YOUR_USER_PASSWORD"

// ---------------------------------------------------------
// Hardware Configuration
// ---------------------------------------------------------
#define PIN_PH        36 // A0 (VP)
#define PIN_TURBIDITY 39 // A1 (VN)
#define PIN_TDS       34 // A2
#define PIN_SALINITY  35 // A3
#define PIN_TEMP      32 // A4

// ---------------------------------------------------------
// Adaptive Sampling & Thresholds
// ---------------------------------------------------------
#define BASE_INTERVAL 2000 // 2 seconds
#define FAST_INTERVAL 500  // 0.5 seconds
#define STABLE_READINGS_THRESHOLD 10

#define THRESHOLD_PH 0.1
#define THRESHOLD_TURBIDITY 0.2
#define THRESHOLD_TDS 5.0

// ---------------------------------------------------------
// Global Variables
// ---------------------------------------------------------
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastReadTime = 0;
int currentInterval = BASE_INTERVAL;
int stableCount = 0;
bool isFastSampling = false;

// Last pushed readings for delta comparison
float lastPushedPh = -999.0;
float lastPushedTurbidity = -999.0;
float lastPushedTds = -999.0;

// NTP configuration
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 19800; // IST (UTC +5:30)
const int   daylightOffset_sec = 0;

// ---------------------------------------------------------
// Helper: Median Filter
// ---------------------------------------------------------
// Read 5 rapid samples, sort them, and return the median to avoid noise
float readMedian(int pin) {
    float samples[5];
    for (int i = 0; i < 5; i++) {
        // Read analog value and convert to voltage/unit placeholder
        samples[i] = analogRead(pin) * (3.3 / 4095.0); 
        delay(10);
    }
    
    // Bubble sort
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4 - i; j++) {
            if (samples[j] > samples[j + 1]) {
                float temp = samples[j];
                samples[j] = samples[j + 1];
                samples[j + 1] = temp;
            }
        }
    }
    return samples[2]; // Return median
}

// ---------------------------------------------------------
// Helper: NTP Time
// ---------------------------------------------------------
unsigned long getTime() {
    time_t now;
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return 0;
    }
    time(&now);
    return (unsigned long)now * 1000; // Convert to epoch ms
}

void setup() {
    Serial.begin(115200);
    analogReadResolution(12);
    
    // Connect to WiFi
    Serial.print("Connecting to WiFi");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(300);
    }
    Serial.println("\nWiFi Connected.");

    // Init NTP
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

    // Init Firebase
    Serial.printf("Firebase Client v%s\n", FIREBASE_CLIENT_VERSION);
    config.api_key = API_KEY;
    config.database_url = DATABASE_URL;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    config.token_status_callback = tokenStatusCallback;
    
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void loop() {
    // Check if it's time for the next reading
    if (millis() - lastReadTime >= currentInterval) {
        lastReadTime = millis();
        
        // 1. Sensor Reading with Median Filtering
        // Note: Calibration equations should be applied to the raw median voltage
        float ph = readMedian(PIN_PH) * 3.5;          
        float turbidity = readMedian(PIN_TURBIDITY) * 10.0; 
        float tds = readMedian(PIN_TDS) * 100.0;      
        float salinity = readMedian(PIN_SALINITY) * 50.0; 
        float temp = readMedian(PIN_TEMP) * 20.0;     

        // 2. Change Detection (Delta)
        bool significantChange = false;
        if (abs(ph - lastPushedPh) >= THRESHOLD_PH ||
            abs(turbidity - lastPushedTurbidity) >= THRESHOLD_TURBIDITY ||
            abs(tds - lastPushedTds) >= THRESHOLD_TDS) {
            significantChange = true;
        }

        // 3. Adaptive Sampling Logic
        if (significantChange) {
            currentInterval = FAST_INTERVAL;
            stableCount = 0;
            isFastSampling = true;
            Serial.println("Change detected: Switching to FAST sampling.");
        } else {
            stableCount++;
            if (stableCount >= STABLE_READINGS_THRESHOLD && isFastSampling) {
                currentInterval = BASE_INTERVAL;
                isFastSampling = false;
                Serial.println("Readings stable: Reverting to BASE sampling.");
            }
        }

        // 4. Delta Updates to Firebase
        if (significantChange || lastPushedPh == -999.0) {
            // Get T1 Timestamps
            unsigned long currentEpochMs = getTime();
            unsigned long sensorTimestamp = millis(); // T1: Device uptime in ms

            // Prepare JSON payload
            FirebaseJson json;
            json.set("ph", ph);
            json.set("turbidity", turbidity);
            json.set("tds", tds);
            json.set("salinity", salinity);
            json.set("temperature", temp);
            json.set("timestamp", currentEpochMs);
            json.set("sensor_timestamp", sensorTimestamp);
            
            Serial.println("Pushing update to Firebase...");
            
            // Write to live_reading node
            String liveNode = "/devices/ESP001/live_reading";
            if (Firebase.RTDB.setJSON(&fbdo, liveNode.c_str(), &json)) {
                Serial.println("Live reading updated successfully.");
                
                // Also push to history node
                String historyNode = "/devices/ESP001/history";
                if (Firebase.RTDB.pushJSON(&fbdo, historyNode.c_str(), &json)) {
                    Serial.println("History logged successfully.");
                } else {
                    Serial.println("Failed to push history: " + fbdo.errorReason());
                }
                
                // Update last pushed values
                lastPushedPh = ph;
                lastPushedTurbidity = turbidity;
                lastPushedTds = tds;
            } else {
                Serial.println("Failed to update live reading: " + fbdo.errorReason());
            }
        }
    }
}
