/*
  Hotel Tuperiri ESP32 Garage Controller

  Board: ESP32 NodeMCU-32S
  BLE library: NimBLE-Arduino 2.5.0

  BLE command format:
    <COMMAND_TOKEN>:OPEN
    <COMMAND_TOKEN>:PRESS
    <COMMAND_TOKEN>:STATUS
    <COMMAND_TOKEN>:PING

  Web routes:
    GET /                  Web control page
    GET /status            JSON status
    GET /press?token=...   Pulse relay when authenticated
*/

#include <Arduino.h>
#include <ArduinoOTA.h>
#include <NimBLEDevice.h>
#include <WebServer.h>
#include <WiFi.h>

// =========================
// Easy configuration
// =========================

const char* BLE_DEVICE_NAME = "HOTEL_TUPERIRI";

const char* AP_SSID = "GarageDoor";
const char* AP_PASSWORD = "garage123";  // Must be at least 8 chars for WPA2.
const IPAddress AP_IP(192, 168, 4, 1);
const IPAddress AP_GATEWAY(192, 168, 4, 1);
const IPAddress AP_SUBNET(255, 255, 255, 0);

const char* OTA_HOSTNAME = "hotel-tuperiri-esp32";
const char* OTA_PASSWORD = "ChangeMeOTA";

const char* COMMAND_TOKEN = "ChangeThisToken";
const bool REQUIRE_WEB_AUTH = true;

const uint8_t RELAY_PIN = 27;
const bool RELAY_ACTIVE_LOW = false;
const uint32_t RELAY_PULSE_MS = 600;
const uint32_t RELAY_COOLDOWN_MS = 5000;

const uint32_t BLE_ADVERTISE_WATCHDOG_MS = 10000;
const uint32_t STATUS_NOTIFY_INTERVAL_MS = 5000;
const uint32_t SERIAL_BAUD = 115200;

const char* SERVICE_UUID = "12345678-1234-1234-1234-123456789001";
const char* COMMAND_CHAR_UUID = "12345678-1234-1234-1234-123456789002";
const char* STATUS_CHAR_UUID = "12345678-1234-1234-1234-123456789003";

// =========================
// Runtime state
// =========================

WebServer server(80);
NimBLEServer* bleServer = nullptr;
NimBLECharacteristic* statusCharacteristic = nullptr;

bool bleClientConnected = false;
bool relayActive = false;
uint32_t relayStartedAt = 0;
uint32_t lastRelayPulseAt = 0;
uint32_t lastBleAdvertiseCheckAt = 0;
uint32_t lastStatusNotifyAt = 0;
String lastCommandSource = "boot";
String lastResult = "ready";

// =========================
// Utility helpers
// =========================

void logLine(const String& message) {
  Serial.printf("[%lu] %s\n", millis(), message.c_str());
}

void writeRelay(bool active) {
  const bool pinLevel = RELAY_ACTIVE_LOW ? !active : active;
  digitalWrite(RELAY_PIN, pinLevel ? HIGH : LOW);
}

String boolText(bool value) {
  return value ? "true" : "false";
}

String statusJson() {
  const uint32_t now = millis();
  const uint32_t cooldownRemaining =
      now - lastRelayPulseAt >= RELAY_COOLDOWN_MS
          ? 0
          : RELAY_COOLDOWN_MS - (now - lastRelayPulseAt);

  String json = "{";
  json += "\"device\":\"";
  json += BLE_DEVICE_NAME;
  json += "\",\"relayActive\":";
  json += boolText(relayActive);
  json += ",\"bleConnected\":";
  json += boolText(bleClientConnected);
  json += ",\"cooldownMs\":";
  json += cooldownRemaining;
  json += ",\"lastCommandSource\":\"";
  json += lastCommandSource;
  json += "\",\"lastResult\":\"";
  json += lastResult;
  json += "\",\"uptimeMs\":";
  json += now;
  json += "}";
  return json;
}

void publishStatus(const String& reason) {
  const String payload = statusJson();
  logLine("Status [" + reason + "]: " + payload);

  if (statusCharacteristic == nullptr) {
    return;
  }

  statusCharacteristic->setValue(payload.c_str());
  if (bleClientConnected) {
    statusCharacteristic->notify();
  }
}

bool isAuthenticated(const String& token) {
  return token == COMMAND_TOKEN;
}

bool canPulseRelay(String& failureReason) {
  if (relayActive) {
    failureReason = "relay_busy";
    return false;
  }

  const uint32_t now = millis();
  if (lastRelayPulseAt != 0 && now - lastRelayPulseAt < RELAY_COOLDOWN_MS) {
    failureReason = "cooldown_active";
    return false;
  }

  return true;
}

bool startRelayPulse(const String& source) {
  String failureReason;
  if (!canPulseRelay(failureReason)) {
    lastCommandSource = source;
    lastResult = failureReason;
    logLine("Relay rejected from " + source + ": " + failureReason);
    publishStatus("relay_rejected");
    return false;
  }

  relayActive = true;
  relayStartedAt = millis();
  lastRelayPulseAt = relayStartedAt;
  lastCommandSource = source;
  lastResult = "relay_pulse_started";

  writeRelay(true);
  logLine("Relay pulse started from " + source);
  publishStatus("relay_started");
  return true;
}

void serviceRelayPulse() {
  if (!relayActive) {
    return;
  }

  if (millis() - relayStartedAt < RELAY_PULSE_MS) {
    return;
  }

  relayActive = false;
  writeRelay(false);
  lastResult = "relay_pulse_complete";
  logLine("Relay pulse complete");
  publishStatus("relay_complete");
}

// =========================
// Command handling
// =========================

String trimCopy(String value) {
  value.trim();
  return value;
}

String upperCopy(String value) {
  value.trim();
  value.toUpperCase();
  return value;
}

bool handleCommandPayload(const String& payload, const String& source, String& response) {
  const int separator = payload.indexOf(':');
  if (separator <= 0) {
    response = "ERR missing_auth";
    lastCommandSource = source;
    lastResult = "missing_auth";
    publishStatus("auth_failed");
    return false;
  }

  const String token = payload.substring(0, separator);
  const String command = upperCopy(payload.substring(separator + 1));

  if (!isAuthenticated(token)) {
    response = "ERR auth_failed";
    lastCommandSource = source;
    lastResult = "auth_failed";
    logLine("Authentication failed from " + source);
    publishStatus("auth_failed");
    return false;
  }

  if (command == "PRESS" || command == "OPEN" || command == "TRIGGER") {
    const bool ok = startRelayPulse(source);
    response = ok ? "OK relay_started" : "ERR " + lastResult;
    return ok;
  }

  if (command == "STATUS") {
    lastCommandSource = source;
    lastResult = "status_requested";
    response = statusJson();
    publishStatus("status_requested");
    return true;
  }

  if (command == "PING") {
    lastCommandSource = source;
    lastResult = "pong";
    response = "OK pong";
    publishStatus("ping");
    return true;
  }

  response = "ERR unknown_command";
  lastCommandSource = source;
  lastResult = "unknown_command";
  publishStatus("unknown_command");
  return false;
}

// =========================
// BLE
// =========================

void startBleAdvertising(const String& reason) {
  NimBLEDevice::getAdvertising()->start();
  lastBleAdvertiseCheckAt = millis();
  logLine("BLE advertising started: " + reason);
}

class HotelBleServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* server, NimBLEConnInfo& connInfo) override {
    bleClientConnected = true;
    logLine("BLE connected: " + String(connInfo.getAddress().toString().c_str()));
    publishStatus("ble_connected");
  }

  void onDisconnect(NimBLEServer* server, NimBLEConnInfo& connInfo, int reason) override {
    bleClientConnected = false;
    logLine("BLE disconnected: reason " + String(reason));
    publishStatus("ble_disconnected");
    startBleAdvertising("disconnect");
  }
};

class CommandCharacteristicCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* characteristic, NimBLEConnInfo& connInfo) override {
    const std::string rawValue = characteristic->getValue();
    const String payload = trimCopy(String(rawValue.c_str()));
    String response;

    logLine("BLE command received: " + payload);
    handleCommandPayload(payload, "ble", response);

    if (statusCharacteristic != nullptr) {
      statusCharacteristic->setValue(response.c_str());
      if (bleClientConnected) {
        statusCharacteristic->notify();
      }
    }
  }
};

void setupBle() {
  NimBLEDevice::init(BLE_DEVICE_NAME);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);

  bleServer = NimBLEDevice::createServer();
  bleServer->setCallbacks(new HotelBleServerCallbacks());

  NimBLEService* service = bleServer->createService(SERVICE_UUID);

  NimBLECharacteristic* commandCharacteristic = service->createCharacteristic(
      COMMAND_CHAR_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  commandCharacteristic->setCallbacks(new CommandCharacteristicCallbacks());

  statusCharacteristic = service->createCharacteristic(
      STATUS_CHAR_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  statusCharacteristic->setValue(statusJson().c_str());

  service->start();

  NimBLEAdvertising* advertising = NimBLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setName(BLE_DEVICE_NAME);

  startBleAdvertising("setup");
  logLine("BLE ready as " + String(BLE_DEVICE_NAME));
}

void serviceBleAdvertising() {
  if (bleClientConnected) {
    return;
  }

  if (millis() - lastBleAdvertiseCheckAt >= BLE_ADVERTISE_WATCHDOG_MS) {
    NimBLEDevice::getAdvertising()->start();
    lastBleAdvertiseCheckAt = millis();
  }
}

// =========================
// Wi-Fi, web, OTA
// =========================

bool webRequestAuthenticated() {
  if (!REQUIRE_WEB_AUTH) {
    return true;
  }

  if (!server.hasArg("token")) {
    return false;
  }

  return isAuthenticated(server.arg("token"));
}

String webPage() {
  String html;
  html.reserve(3500);
  html += "<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>";
  html += "<title>Hotel Tuperiri</title>";
  html += "<style>";
  html += "body{font-family:Arial,sans-serif;background:#111827;color:#f9fafb;margin:0;display:grid;min-height:100vh;place-items:center}";
  html += "main{width:min(92vw,440px)}h1{font-size:28px;margin:0 0 10px}p{color:#cbd5e1}";
  html += "input,button{width:100%;box-sizing:border-box;border-radius:8px;border:0;padding:14px;font-size:16px;margin-top:12px}";
  html += "input{background:#1f2937;color:#fff;border:1px solid #374151}";
  html += "button{background:#22c55e;color:#052e16;font-weight:700;cursor:pointer}";
  html += "pre{white-space:pre-wrap;background:#030712;border:1px solid #374151;border-radius:8px;padding:12px;min-height:96px}";
  html += "</style></head><body><main>";
  html += "<h1>Hotel Tuperiri</h1>";
  html += "<p>ESP32 garage relay controller</p>";
  html += "<input id='token' placeholder='Command token' type='password'>";
  html += "<button onclick='pressRelay()'>Press Relay</button>";
  html += "<button onclick='loadStatus()'>Refresh Status</button>";
  html += "<pre id='status'>Loading...</pre>";
  html += "<script>";
  html += "const statusEl=document.getElementById('status');";
  html += "function token(){return encodeURIComponent(document.getElementById('token').value)}";
  html += "async function loadStatus(){const r=await fetch('/status');statusEl.textContent=await r.text()}";
  html += "async function pressRelay(){const r=await fetch('/press?token='+token());statusEl.textContent=await r.text();setTimeout(loadStatus,500)}";
  html += "loadStatus();setInterval(loadStatus,5000);";
  html += "</script></main></body></html>";
  return html;
}

void handleRoot() {
  server.send(200, "text/html", webPage());
}

void handleStatus() {
  server.send(200, "application/json", statusJson());
}

void handlePress() {
  if (!webRequestAuthenticated()) {
    lastCommandSource = "web";
    lastResult = "auth_failed";
    publishStatus("web_auth_failed");
    server.send(401, "text/plain", "ERR auth_failed");
    return;
  }

  const bool ok = startRelayPulse("web");
  server.send(ok ? 200 : 429, "text/plain", ok ? "OK relay_started" : "ERR " + lastResult);
}

void handleNotFound() {
  server.send(404, "text/plain", "Not found");
}

void setupWifiAp() {
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(AP_IP, AP_GATEWAY, AP_SUBNET);
  WiFi.softAP(AP_SSID, AP_PASSWORD);

  logLine("Wi-Fi AP started: " + String(AP_SSID));
  logLine("Wi-Fi AP IP: " + WiFi.softAPIP().toString());
}

void setupWebServer() {
  server.on("/", HTTP_GET, handleRoot);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/press", HTTP_GET, handlePress);
  server.onNotFound(handleNotFound);
  server.begin();
  logLine("Web server started");
}

void setupOta() {
  ArduinoOTA.setHostname(OTA_HOSTNAME);
  ArduinoOTA.setPassword(OTA_PASSWORD);

  ArduinoOTA.onStart([]() {
    writeRelay(false);
    relayActive = false;
    logLine("OTA update started");
  });
  ArduinoOTA.onEnd([]() {
    logLine("OTA update finished");
  });
  ArduinoOTA.onError([](ota_error_t error) {
    logLine("OTA error: " + String(static_cast<int>(error)));
  });

  ArduinoOTA.begin();
  logLine("OTA ready as " + String(OTA_HOSTNAME));
}

void servicePeriodicStatus() {
  if (millis() - lastStatusNotifyAt < STATUS_NOTIFY_INTERVAL_MS) {
    return;
  }

  lastStatusNotifyAt = millis();
  publishStatus("periodic");
}

// =========================
// Arduino lifecycle
// =========================

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(100);
  logLine("Booting Hotel Tuperiri controller");

  pinMode(RELAY_PIN, OUTPUT);
  writeRelay(false);

  setupWifiAp();
  setupWebServer();
  setupOta();
  setupBle();

  publishStatus("boot");
}

void loop() {
  server.handleClient();
  ArduinoOTA.handle();
  serviceRelayPulse();
  serviceBleAdvertising();
  servicePeriodicStatus();
}
