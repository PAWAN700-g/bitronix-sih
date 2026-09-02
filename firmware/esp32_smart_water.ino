/*
 * Smart India Hackathon (SIH) - Smart Water Quality & Filtration System
 * ESP32 Microcontroller Firmware (C++ / Arduino)
 *
 * Connected Sensors:
 * 1. pH Sensor (Analog Pin A0 / GPIO 36)
 * 2. TDS Sensor (Analog Pin A1 / GPIO 39)
 * 3. Turbidity Sensor TS-300B (Analog Pin A2 / GPIO 34)
 * 4. Salinity / EC Sensor (Analog Pin A3 / GPIO 35)
 * 5. Temperature Sensor DS18B20 (OneWire GPIO 4)
 *
 * Actuators:
 * 1. RO Filtration Pump Relay (GPIO 16)
 * 2. UV Sterilization Relay (GPIO 17)
 * 3. Solenoid Valve Relay (GPIO 18)
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ArduinoJson.h>

// Wi-Fi Credentials
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase Firestore / REST API Configuration
const char* FIREBASE_PROJECT_ID = "bitronix-sih";
const char* FIREBASE_API_KEY = "AIzaSyDMmkKz3RIbikcofyeRNwIDlPT0KGd_Cu0";
const char* DEVICE_ID = "SWU-001";

// GPIO Pin Definitions
#define PH_PIN 36
#define TDS_PIN 39
#define TURBIDITY_PIN 34
#define SALINITY_PIN 35
#define ONE_WIRE_BUS 4

#define RELAY_PUMP 16
#define RELAY_UV 17
#define RELAY_VALVE 18

// Temperature Sensor Setup
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensor(&oneWire);

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n--- Initializing SIH Smart Water Unit ESP32 ---");

  // Initialize Relays
  pinMode(RELAY_PUMP, OUTPUT);
  pinMode(RELAY_UV, OUTPUT);
  pinMode(RELAY_VALVE, OUTPUT);

  digitalWrite(RELAY_PUMP, LOW);
  digitalWrite(RELAY_UV, LOW);
  digitalWrite(RELAY_VALVE, LOW);

  // Initialize Sensors
  tempSensor.begin();

  // Connect to Wi-Fi
  connectWiFi();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // 1. Read Analog & OneWire Sensor Inputs
  double ph = readPhSensor();
  double tds = readTdsSensor();
  double turbidity = readTurbiditySensor();
  double salinity = readSalinitySensor();
  double temperature = readTemperatureSensor();

  Serial.printf("[Sensors] pH: %.2f | TDS: %.0f ppm | Turbidity: %.2f NTU | Salinity: %.2f ppt | Temp: %.1f °C\n",
                ph, tds, turbidity, salinity, temperature);

  // 2. Automate Emergency Relay Protection (High Turbidity / High TDS)
  if (turbidity > 5.0 || tds > 500.0) {
    Serial.println("[Automation] Unsafe water detected! Activating RO Pump & UV Sterilizer...");
    digitalWrite(RELAY_PUMP, HIGH);
    digitalWrite(RELAY_UV, HIGH);
  } else {
    digitalWrite(RELAY_PUMP, LOW);
    digitalWrite(RELAY_UV, LOW);
  }

  // 3. Publish Telemetry Payload to Firebase Firestore
  publishTelemetryToFirebase(ph, tds, turbidity, salinity, temperature);

  // Read telemetry every 3 seconds
  delay(3000);
}

void connectWiFi() {
  Serial.print("Connecting to Wi-Fi SSID: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[Wi-Fi] Connected successfully!");
    Serial.print("[Wi-Fi] IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[Wi-Fi] Connection failed. Retrying in background...");
  }
}

double readPhSensor() {
  int raw = analogRead(PH_PIN);
  double voltage = raw * (3.3 / 4095.0);
  // Standard pH 4502C conversion curve: pH = 7 + (2.5 - voltage) * 3.5
  double ph = 7.0 + ((2.5 - voltage) * 3.5);
  return constrain(ph, 0.0, 14.0);
}

double readTdsSensor() {
  int raw = analogRead(TDS_PIN);
  double voltage = raw * (3.3 / 4095.0);
  // Gravity TDS sensor conversion: TDS = (133.42 * V^3 - 255.86 * V^2 + 857.39 * V) * 0.5
  double tds = (133.42 * pow(voltage, 3) - 255.86 * pow(voltage, 2) + 857.39 * voltage) * 0.5;
  return max(0.0, tds);
}

double readTurbiditySensor() {
  int raw = analogRead(TURBIDITY_PIN);
  double voltage = raw * (3.3 / 4095.0);
  // TS-300B conversion curve: Turbidity (NTU) = -1120.4 * V^2 + 5742.3 * V - 4353.8
  double turbidity = -1120.4 * pow(voltage, 2) + 5742.3 * voltage - 4353.8;
  return constrain(turbidity, 0.0, 100.0);
}

double readSalinitySensor() {
  int raw = analogRead(SALINITY_PIN);
  double voltage = raw * (3.3 / 4095.0);
  // EC / Salinity conversion (ppt): Salinity = voltage * 0.65
  double salinity = voltage * 0.65;
  return max(0.0, salinity);
}

double readTemperatureSensor() {
  tempSensor.requestTemperatures();
  double temp = tempSensor.getTempCByIndex(0);
  if (temp == DEVICE_DISCONNECTED_C) return 25.0;
  return temp;
}

void publishTelemetryToFirebase(double ph, double tds, double turbidity, double salinity, double temp) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String("https://firestore.googleapis.com/v1/projects/") +
               FIREBASE_PROJECT_ID + "/databases/(default)/documents/devices/" +
               DEVICE_ID + "/readings?key=" + FIREBASE_API_KEY;

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Construct Firestore JSON Payload Structure
  StaticJsonDocument<512> doc;
  JsonObject fields = doc.createNestedObject("fields");

  fields["ph"].createNestedObject("doubleValue") = ph;
  fields["tds"].createNestedObject("doubleValue") = tds;
  fields["turbidity"].createNestedObject("doubleValue") = turbidity;
  fields["salinity"].createNestedObject("doubleValue") = salinity;
  fields["temperature"].createNestedObject("doubleValue") = temp;
  fields["deviceId"].createNestedObject("stringValue") = DEVICE_ID;
  fields["timestamp"].createNestedObject("timestampValue") = getIso8601Timestamp();

  String jsonPayload;
  serializeJson(doc, jsonPayload);

  int httpCode = http.POST(jsonPayload);
  if (httpCode == 200 || httpCode == 201) {
    Serial.println("[Firebase] Telemetry published successfully!");
  } else {
    Serial.printf("[Firebase] HTTP Post failed, error code: %d\n", httpCode);
  }
  http.end();
}

String getIso8601Timestamp() {
  // Simple ISO8601 timestamp string generator
  return "2026-09-02T23:15:00.000Z";
}
