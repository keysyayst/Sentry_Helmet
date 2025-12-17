/*
 * ESP32 BLE GATT Server - SENTRY HELMET
 * 
 * Peran: BLE Peripheral / GATT Server
 * - Mengiklankan (advertising) dengan nama "HELM-VICTOR"
 * - Memiliki 1 Service utama dengan custom UUID
 * - Memiliki 2 Characteristic (RX: Write, TX: Notify)
 * - Komunikasi berbentuk String (UTF-8)
 * 
 * UUID Custom:
 * Service UUID  : 12345678-1234-5678-1234-56789abcdef0
 * RX Char UUID  : 12345678-1234-5678-1234-56789abcdef1 (Write)
 * TX Char UUID  : 12345678-1234-5678-1234-56789abcdef2 (Notify)
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ============================================
// KONFIGURASI UUID CUSTOM
// ============================================
#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_RX   "12345678-1234-5678-1234-56789abcdef1"  // Write
#define CHARACTERISTIC_TX   "12345678-1234-5678-1234-56789abcdef2"  // Notify

// ============================================
// VARIABEL GLOBAL
// ============================================
BLECharacteristic *pCharacteristicTX;
BLECharacteristic *pCharacteristicRX;
bool deviceConnected = false;
String lastReceivedData = "";

// ============================================
// SERVER CALLBACK - Untuk tracking koneksi
// ============================================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("[BLE] Device connected!");
  }

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("[BLE] Device disconnected!");
    
    // Restart advertising
    pServer->getAdvertising()->start();
    Serial.println("[BLE] Advertising restarted");
  }
};

// ============================================
// RX CHARACTERISTIC CALLBACK - Menerima data dari Android
// ============================================
class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String receivedData = pCharacteristic->getValue();
    
    if (receivedData.length() > 0) {
      lastReceivedData = receivedData;
      Serial.print("[RX] Data diterima: ");
      Serial.println(receivedData);
      
      // ============================================
      // LOGIC RESPONS BERDASARKAN DATA YANG DITERIMA
      // ============================================
      String response = "";
      
      if (receivedData == "PING") {
        response = "PONG";
      }
      else if (receivedData == "STATUS") {
        response = "OK|ESP32|RUNNING";
      }
      else if (receivedData == "HELLO") {
        response = "HI_FROM_ESP32";
      }
      else if (receivedData.startsWith("LED_")) {
        // Contoh: LED_ON atau LED_OFF
        String command = receivedData.substring(4);
        if (command == "ON") {
          digitalWrite(2, HIGH);
          response = "LED_ON_OK";
        } else if (command == "OFF") {
          digitalWrite(2, LOW);
          response = "LED_OFF_OK";
        }
      }
      else {
        response = "UNKNOWN_COMMAND";
      }
      
      // Kirim respons kembali lewat TX (Notify)
      if (deviceConnected && response.length() > 0) {
        pCharacteristicTX->setValue(response);
        pCharacteristicTX->notify();
        Serial.print("[TX] Data dikirim: ");
        Serial.println(response);
      }
    }
  }
};

// ============================================
// SETUP - Inisialisasi BLE
// ============================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n[SETUP] Starting ESP32 BLE GATT Server...");
  
  // Setup GPIO untuk LED testing
  pinMode(2, OUTPUT);
  digitalWrite(2, LOW);
  
  // Inisialisasi BLE Device
  BLEDevice::init("HELM-VICTOR");
  
  // Buat BLE Server
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  // Buat BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Buat TX Characteristic (Notify - ESP32 -> Android)
  pCharacteristicTX = pService->createCharacteristic(
    CHARACTERISTIC_TX,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristicTX->addDescriptor(new BLE2902());
  
  // Buat RX Characteristic (Write - Android -> ESP32)
  pCharacteristicRX = pService->createCharacteristic(
    CHARACTERISTIC_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
  pCharacteristicRX->setCallbacks(new MyCharacteristicCallbacks());
  
  // Start service
  pService->start();
  
  // Setup Advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  pServer->getAdvertising()->start();
  
  Serial.println("[SETUP] BLE GATT Server started successfully!");
  Serial.println("[INFO] Waiting for Android connection...");
  Serial.println("");
  Serial.println("=== UUID INFORMATION ===");
  Serial.println("Service UUID  : " SERVICE_UUID);
  Serial.println("RX Char UUID  : " CHARACTERISTIC_RX " (Write)");
  Serial.println("TX Char UUID  : " CHARACTERISTIC_TX " (Notify)");
  Serial.println("Device Name   : HELM-VICTOR");
  Serial.println("========================\n");
}

// ============================================
// LOOP - Monitoring & Debugging
// ============================================
void loop() {
  if (deviceConnected) {
    Serial.print(".");
    delay(1000);
  } else {
    delay(2000);
  }
}
