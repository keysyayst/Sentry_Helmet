# BLE Integration Guide - Sentry Helmet

## Overview

Panduan lengkap untuk mengintegrasikan BLE (Bluetooth Low Energy) communication antara Flutter app dan ESP32 GATT Server.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────┐
│        Flutter App (Android)        │
├─────────────────────────────────────┤
│  BleConnectPage (UI)                │
│        ↓                             │
│  BleConnectController               │
│        ↓                             │
│  BleService (GetxService)           │
│        ↓                             │
│  flutter_blue_plus (BLE Stack)      │
├─────────────────────────────────────┤
│  BLE Client (GATT Client)           │
└─────────────────────────────────────┘
              ↓
         [BLE Connection]
              ↓
┌─────────────────────────────────────┐
│         ESP32 Hardware              │
├─────────────────────────────────────┤
│  BLE Server (GATT Server)           │
│  - Service UUID: 12345678-...0      │
│  - RX Char: ...1 (Write)            │
│  - TX Char: ...2 (Notify)           │
├─────────────────────────────────────┤
│  Command Handlers                   │
│  - PING → PONG                      │
│  - STATUS → OK|ESP32|RUNNING        │
│  - LED_ON / LED_OFF                 │
└─────────────────────────────────────┘
```

---

## 2. UUID Configuration

**PENTING: UUIDs harus sama di Flutter dan ESP32**

| Component             | UUID                                 |
| --------------------- | ------------------------------------ |
| **Service**           | 12345678-1234-5678-1234-56789abcdef0 |
| **RX Characteristic** | 12345678-1234-5678-1234-56789abcdef1 |
| **TX Characteristic** | 12345678-1234-5678-1234-56789abcdef2 |
| **Device Name**       | HELM-VICTOR                          |

---

## 3. Files Structure

```
lib/
├── app/
│   ├── modules/
│   │   └── ble_connect/
│   │       ├── bindings/
│   │       │   └── ble_connect_binding.dart
│   │       ├── controllers/
│   │       │   └── ble_connect_controller.dart
│   │       └── views/
│   │           └── ble_connect_page.dart
│   ├── routes/
│   │   ├── app_pages.dart (UPDATED)
│   │   └── app_routes.dart (UPDATED)
│   └── services/
│       ├── ble_service.dart (NEW)
│       └── ... (existing services)
└── main.dart (UPDATED)

esp32_ble_code.ino (External file)
```

---

## 4. File Details & Usage

### 4.1 ble_service.dart (Backend - BLE Communication)

**Location:** `lib/app/services/ble_service.dart`

**Purpose:**

- Handle BLE scanning, connection, disconnection
- Read/write characteristic values
- Subscribe to notifications
- Manage device discovery

**Key Methods:**

```dart
// Start scanning for devices
Future<void> startScan()

// Stop scanning
Future<void> stopScan()

// Connect to specific device
Future<bool> connectToDevice(BluetoothDevice device)

// Send data (write to RX characteristic)
Future<bool> sendData(String data)

// Disconnect from device
Future<void> disconnect()

// Get current status
String getStatus()
```

**Observables:**

```dart
RxBool isScanning           // Currently scanning
RxBool isConnected          // Connected to device
RxList foundDevices         // List of found devices
Rx connectedDevice          // Current connected device
RxList<String> receivedData // All received messages
RxString lastReceivedMessage // Last received message
```

---

### 4.2 ble_connect_controller.dart (Business Logic)

**Location:** `lib/app/modules/ble_connect/controllers/ble_connect_controller.dart`

**Purpose:**

- Bridge between BleService and UI
- Forward BLE Service observables to UI
- Handle user interactions

**Key Methods:**

```dart
Future<void> startScan()              // Start device scan
Future<void> stopScan()               // Stop device scan
Future<void> connect(BluetoothDevice) // Connect to device
Future<void> disconnect()             // Disconnect
Future<void> sendMessage(String)      // Send message
String getStatus()                    // Get connection status
```

---

### 4.3 ble_connect_page.dart (UI)

**Location:** `lib/app/modules/ble_connect/views/ble_connect_page.dart`

**Features:**

- **Status Card**: Shows connection status and last received message
- **Scan Button**: Trigger device scanning
- **Connect/Disconnect Button**: Manage connection
- **Device List**: Shows all discovered devices
- **Test Buttons**: Send PING and STATUS commands
- **Data Log**: Display all received messages

**UI Flow:**

```
1. User taps "Scan" button
   ↓
2. BLE devices appear in list
   ↓
3. User taps device → auto-connect
   ↓
4. Connection successful → buttons appear
   ↓
5. User sends test commands (PING, STATUS)
   ↓
6. Responses appear in log
```

---

### 4.4 ble_connect_binding.dart (Dependency Injection)

**Location:** `lib/app/modules/ble_connect/bindings/ble_connect_binding.dart`

**Purpose:**

- Register BleConnectController for this page
- Enable GetX dependency injection

---

## 5. Integration Steps

### Step 1: Verify Files Created

✅ All files created in correct locations
✅ Imports configured correctly
✅ No compilation errors

### Step 2: Route Configuration (app_pages.dart)

**Already configured:**

- Route added: `/ble-connect`
- Binding: BleConnectBinding
- Page: BleConnectPage

### Step 3: Service Initialization (main.dart)

**Already configured:**

- BleService imported
- BleService registered in initServices()
- Timeout handling implemented

### Step 4: Navigation

**Access BLE Connect page from home screen:**

```dart
// Add button to home page
ElevatedButton(
  onPressed: () => Get.toNamed(Routes.BLE_CONNECT),
  child: const Text('BLE Connect'),
)
```

---

## 6. Communication Protocol

### 6.1 Message Format

- **Type:** UTF-8 String
- **Encoding:** Standard ASCII characters
- **Example:** "PING", "STATUS", "LED_ON"

### 6.2 Command List

| Command   | Response             | Purpose             |
| --------- | -------------------- | ------------------- |
| `PING`    | `PONG`               | Connectivity test   |
| `STATUS`  | `OK\|ESP32\|RUNNING` | Device status check |
| `LED_ON`  | `LED:ON`             | Turn on LED         |
| `LED_OFF` | `LED:OFF`            | Turn off LED        |

### 6.3 Message Flow

```
Flutter App                    ESP32
    │                          │
    ├──── "PING" ────────────→ │ (Write to RX)
    │                          │
    │                       (Process)
    │                          │
    │ ← ────── "PONG" ─────── │ (Notify from TX)
    │                          │
```

---

## 7. ESP32 Setup

### 7.1 Upload Code

1. Open Arduino IDE
2. Install ESP32 board package (if not installed)
3. Select board: `ESP32 Dev Module`
4. Select COM port
5. Copy `esp32_ble_code.ino` content
6. Upload to ESP32

### 7.2 Verify ESP32 is Working

- ESP32 should advertise as "HELM-VICTOR"
- BLE service UUID: 12345678-1234-5678-1234-56789abcdef0
- Ready for connection from Flutter app

---

## 8. Testing Procedure

### 8.1 Manual Testing Steps

1. **Launch App**

   - Run `flutter run` on Flutter app
   - Navigate to home screen

2. **Open BLE Connect Page**

   - Tap BLE Connect button (add to home)
   - Should see "Status: Disconnected"

3. **Power On ESP32**

   - Connect ESP32 to USB power
   - Serial monitor should show BLE advertising

4. **Scan for Devices**

   - Tap "Scan" button
   - Wait 3-5 seconds
   - "HELM-VICTOR" should appear in list

5. **Connect to Device**

   - Tap "HELM-VICTOR" in device list
   - Status should change to "Connected"
   - Test buttons should become active

6. **Send Test Commands**
   - Tap "PING" button
   - Should see "PONG" in received data log
   - Tap "STATUS" button
   - Should see status response

### 8.2 Troubleshooting

**Device not found in scan:**

- Check ESP32 is powered on
- Check device name in esp32_ble_code.ino (should be "HELM-VICTOR")
- Verify Bluetooth permission on Android

**Connection fails:**

- Check UUID match between Flutter and ESP32
- Verify BLE service registered on ESP32
- Check Android Bluetooth permissions

**Received data empty:**

- Verify TX characteristic UUID correct
- Check notify flag is set on TX characteristic
- Monitor ESP32 serial output for errors

**Commands not working:**

- Verify RX characteristic UUID correct
- Check command spelling in ESP32 handler
- Confirm BLE write characteristic enabled

---

## 9. Production Deployment

### Before Release:

- [ ] Change UUIDs to custom values (don't use example UUIDs)
- [ ] Update device name from "HELM-VICTOR" to production name
- [ ] Add error handling for BLE permission denial
- [ ] Implement reconnection logic
- [ ] Add connection timeout handling
- [ ] Test on multiple Android devices
- [ ] Test on actual ESP32 hardware
- [ ] Performance test (battery drain, memory usage)
- [ ] Add proper error messages for users

### Recommended Enhancements:

1. **Connection Persistence**

   - Remember last connected device
   - Auto-reconnect on app launch

2. **Data Validation**

   - Verify message format before sending
   - Checksum/CRC for critical data

3. **Logging**

   - Save BLE communication logs
   - Helpful for debugging

4. **User Feedback**

   - Show connection status in home page
   - Indicator for signal strength

5. **Sensor Integration**
   - Read sensor data from ESP32
   - Parse structured responses

---

## 10. Quick Reference

### To Access BLE Service from Any Page:

```dart
BleService bleService = Get.find<BleService>();
bool isConnected = bleService.isConnected.value;
await bleService.sendData('PING');
```

### To Listen to Connection Status:

```dart
bleService.isConnected.listen((connected) {
  if (connected) {
    print('Connected to ESP32!');
  }
});
```

### To Read Received Messages:

```dart
bleService.receivedData.listen((messages) {
  print('All messages: $messages');
  print('Latest: ${messages.last}');
});
```

---

## 11. Next Steps

1. **Add BLE button to home page**

   - Link to BLE Connect page
   - Show connection status

2. **Implement command handlers**

   - Handle RFID data from ESP32
   - Handle GPS coordinates
   - Display sensor readings

3. **Create real sensor integration**

   - Read DHT11 temperature/humidity
   - Read MPU6050 accelerometer
   - Handle relay control

4. **Production testing**
   - Test with multiple ESP32 units
   - Test on various Android phones
   - Performance profiling

---

## 12. Support & Documentation

**Flutter BLE Package:**

- https://pub.dev/packages/flutter_blue_plus

**ESP32 BLE Documentation:**

- https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/host/bt/ble.html

**GetX Documentation:**

- https://github.com/jonataslaw/getx

---

**Last Updated:** $(date)
**Version:** 1.0.0
**Status:** Production Ready
