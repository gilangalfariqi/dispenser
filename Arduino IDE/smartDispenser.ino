/*
 * SMART WATER DISPENSER - FIREBASE INTEGRASI + MANUAL CONTROL
 * Board: ESP32 DevKit V1
 * Firebase Structure:
 *   /sensors - Sensor data (read by app)
 *   /control - Manual pump control (written by app)
 */

#include <WiFi.h>
#include <FirebaseESP32.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <OneWire.h>
#include <DallasTemperature.h>

/* ========== WIFI & FIREBASE ========== */
const char* WIFI_SSID = "nteik";
const char* WIFI_PASS = "Satu2345";

#define FIREBASE_HOST "dispenser-56c3f-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "AIzaSyA0J4L9ZrDx1QmSZHfvEGIPU6vdQC-73t0"

FirebaseData fbdo;
FirebaseData streamData;
FirebaseConfig cfg;
FirebaseAuth auth;
/* ===================================== */

/* ========== HARDWARE PIN ========== */
#define TRIG_GELAS  26
#define ECHO_GELAS  25
#define TRIG_GALON  32
#define ECHO_GALON  35
#define IR_SENSOR   34
#define FLOW_PIN    33
#define RELAY_PIN   14
#define LED_READY   2
#define LED_PUMP    27
#define BUTTON_PIN  13
#define DS18B20_PIN 4
/* ================================== */

/* ========== KONSTANTA ========== */
const float TINGGI_GELAS_CM       = 8.0;
const float JARAK_SENSOR_KE_DASAR = 24.0;
const float TINGGI_GALON_CM       = 12.0;
const float WATER_FULL_THRESHOLD  = 7.5;
const float WATER_EMPTY_THRESHOLD = 1.0;
const float PULSES_PER_LITER      = 350.0;
/* ================================ */

/* ========== LCD 20x4 ========== */
LiquidCrystal_I2C lcd(0x27, 20, 4);

/* ========== DS18B20 ========== */
OneWire oneWire(DS18B20_PIN);
DallasTemperature sensors(&oneWire);

/* ========== VARIABLES ========== */
volatile unsigned long pulseCount = 0;
bool filling = false;
bool manualMode = false;
bool pumpManualState = false;
unsigned long lastUpload = 0;
unsigned long lastButtonCheck = 0;
bool lastButtonState = HIGH;

/* ========== INTERRUPT FLOW ========== */
void IRAM_ATTR countPulse() {
    pulseCount++;
}

/* ========== ULTRASONIC ========== */
float readDistanceCM(int trig, int echo) {
    digitalWrite(trig, LOW);
    delayMicroseconds(2);
    digitalWrite(trig, HIGH);
    delayMicroseconds(10);
    digitalWrite(trig, LOW);

    long duration = pulseIn(echo, HIGH, 30000);
    if (duration == 0) return -1;
    return (duration / 2.0) * 0.0343;
}

float getWaterHeight(float d) {
    if (d < 0) return 0;
    float h = JARAK_SENSOR_KE_DASAR - d;
    if (h < 0) h = 0;
    if (h > TINGGI_GELAS_CM) h = TINGGI_GELAS_CM;
    return h;
}

int getGalonPercent(float d) {
    if (d < 0) return 0;
    float h = TINGGI_GALON_CM - d;
    if (h < 0) h = 0;
    if (h > TINGGI_GALON_CM) h = TINGGI_GALON_CM;
    return (int)((h / TINGGI_GALON_CM) * 100);
}

/* ========== FLOW ========== */
float getVolumeL() {
    noInterrupts();
    unsigned long p = pulseCount;
    interrupts();
    return p / PULSES_PER_LITER;
}

/* ========== POMPA ========== */
void startPump() {
    digitalWrite(RELAY_PIN, HIGH);
    digitalWrite(LED_PUMP, HIGH);
    digitalWrite(LED_READY, LOW);
    filling = true;

    noInterrupts();
    pulseCount = 0;
    interrupts();

    Serial.println("✓ Pump STARTED");
}

void stopPump() {
    digitalWrite(RELAY_PIN, LOW);
    digitalWrite(LED_PUMP, LOW);
    digitalWrite(LED_READY, HIGH);
    filling = false;

    Serial.println("✓ Pump STOPPED");
}

/* ========== FIREBASE ========== */
void pushFirebase(float wh, int gal, float temp, float vol, String stat) {
    if (WiFi.status() != WL_CONNECTED) {
        WiFi.reconnect();
        return;
    }

    FirebaseJson json;
    json.add("waterHeight", wh);
    json.add("galonLevel", gal);
    json.add("temperature", temp);
    json.add("volume", (int)(vol * 1000));
    json.add("glassStatus", stat);
    json.add("timestamp", millis());

    if (Firebase.setJSON(fbdo, "/sensors", json)) {
        Serial.println("✔ Firebase uploaded");
    } else {
        Serial.println("✖ Firebase error: " + fbdo.errorReason());
    }
}

/* ========== STREAM CALLBACK ========== */
void streamCallback(StreamData data) {
    if (data.dataPath() == "/pumpManual") {
        pumpManualState = data.boolData();
        manualMode = true;

        Serial.print("📱 Manual control: ");
        Serial.println(pumpManualState ? "START" : "STOP");

        if (pumpManualState && !filling) {
            startPump();
        } else if (!pumpManualState && filling) {
            stopPump();
        }
    }
}

void streamTimeoutCallback(bool timeout) {
    if (timeout) {
        Serial.println("⚠ Stream timeout, reconnecting...");
    }
}

/* ========== LCD ========== */
void updateLCD(float wh, int gal, float temp, float vol, bool glass) {
    lcd.clear();

    lcd.setCursor(0, 0);
    lcd.print("Mode:");
    lcd.print(manualMode ? "MANUAL" : "AUTO  ");
    lcd.print(" G:");
    lcd.print(glass ? "Yes" : "No ");

    lcd.setCursor(0, 1);
    lcd.print("Water:");
    lcd.print(wh, 1);
    lcd.print("cm ");
    if (wh >= WATER_FULL_THRESHOLD) lcd.print("FULL ");
    else if (wh < WATER_EMPTY_THRESHOLD) lcd.print("EMPTY");
    else lcd.print("OK   ");

    lcd.setCursor(0, 2);
    lcd.print("Galon:");
    lcd.print(gal);
    lcd.print("% T:");
    lcd.print(temp, 1);
    lcd.print("C");

    lcd.setCursor(0, 3);
    lcd.print("Pump:");
    lcd.print(filling ? "ON " : "OFF");
    lcd.print(" Vol:");
    lcd.print((int)(vol * 1000));
    lcd.print("mL");
}

/* ========== SETUP ========== */
void setup() {
    Serial.begin(115200);

    // Pin Setup
    pinMode(TRIG_GELAS, OUTPUT);
    pinMode(ECHO_GELAS, INPUT);
    pinMode(TRIG_GALON, OUTPUT);
    pinMode(ECHO_GALON, INPUT);
    pinMode(IR_SENSOR, INPUT);
    pinMode(RELAY_PIN, OUTPUT);
    pinMode(LED_READY, OUTPUT);
    pinMode(LED_PUMP, OUTPUT);
    pinMode(BUTTON_PIN, INPUT_PULLUP);

    digitalWrite(RELAY_PIN, LOW);
    digitalWrite(LED_READY, HIGH);
    digitalWrite(LED_PUMP, LOW);

    attachInterrupt(digitalPinToInterrupt(FLOW_PIN), countPulse, RISING);
    sensors.begin();

    // LCD Init
    lcd.init();
    lcd.backlight();
    lcd.print("SMART DISPENSER");
    lcd.setCursor(0, 1);
    lcd.print("Initializing...");
    delay(1000);

    // WiFi Connection
    lcd.clear();
    lcd.print("Connecting WiFi");
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    byte tries = 0;
    while (WiFi.status() != WL_CONNECTED && tries < 20) {
        delay(500);
        lcd.print(".");
        tries++;
    }

    lcd.clear();
    if (WiFi.status() == WL_CONNECTED) {
        lcd.print("WiFi: Connected");
        Serial.println("✓ WiFi connected");
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
    } else {
        lcd.print("WiFi: Failed");
        Serial.println("✖ WiFi failed");
    }
    delay(1000);

    // Firebase Init
    cfg.host = FIREBASE_HOST;
    cfg.signer.tokens.legacy_token = FIREBASE_AUTH;
    Firebase.begin(&cfg, &auth);
    Firebase.reconnectWiFi(true);

    // Start Firebase Stream for Manual Control
    if (!Firebase.beginStream(streamData, "/control")) {
        Serial.println("✖ Stream begin failed");
        Serial.println(streamData.errorReason());
    } else {
        Firebase.setStreamCallback(streamData, streamCallback, streamTimeoutCallback);
        Serial.println("✓ Stream started for /control");
    }

    lcd.clear();
    lcd.print("System Ready!");
    delay(1000);
}

/* ========== LOOP ========== */
void loop() {
    static unsigned long lastCheck = 0;
    unsigned long now = millis();

    if (now - lastCheck < 300) return;
    lastCheck = now;

    // Read Sensors
    float distGelas = readDistanceCM(TRIG_GELAS, ECHO_GELAS);
    float distGalon = readDistanceCM(TRIG_GALON, ECHO_GALON);
    sensors.requestTemperatures();
    float tempC = sensors.getTempCByIndex(0);
    float volL = getVolumeL();
    bool glass = (digitalRead(IR_SENSOR) == HIGH);
    float waterH = getWaterHeight(distGelas);
    int galPct = getGalonPercent(distGalon);

    // Auto Mode Logic (if not manual)
    if (!manualMode) {
        if (glass && !filling && waterH < WATER_FULL_THRESHOLD) {
            startPump();
        } else if (filling && (waterH >= WATER_FULL_THRESHOLD || !glass)) {
            stopPump();
        }
    }

    // Physical Button Check (Toggle Manual Mode)
    if (now - lastButtonCheck > 200) {
        lastButtonCheck = now;
        bool currentButtonState = digitalRead(BUTTON_PIN);

        if (currentButtonState == HIGH && lastButtonState == LOW) {
            // Button pressed
            if (filling) {
                stopPump();
            } else {
                startPump();
            }
            manualMode = true;
            delay(300); // Debounce
        }
        lastButtonState = currentButtonState;
    }

    // Update LCD
    updateLCD(waterH, galPct, tempC, volL, glass);

    // Upload to Firebase every 5 seconds
    if (now - lastUpload > 5000) {
        lastUpload = now;

        String stat = filling ? "filling" :
                      (waterH >= WATER_FULL_THRESHOLD ? "full" : "empty");

        pushFirebase(waterH, galPct, tempC, volL, stat);

        // Reset manual mode after some time of inactivity
        if (manualMode && !pumpManualState && !filling) {
            static int autoModeCounter = 0;
            autoModeCounter++;
            if (autoModeCounter > 12) { // 60 seconds
                manualMode = false;
                autoModeCounter = 0;
                Serial.println("↻ Switched back to AUTO mode");
            }
        }
    }
}