class AppConstants {
  // App Info
  static const String appName = 'Sentry Helmet';
  static const String appVersion = '1.0.0';
  
  // ESP32 Hardware Configuration
  static const Map<String, int> esp32Pins = {
    // RFID RC522 (SPI - VSPI)
    'rfid_ss': 5,
    'rfid_sck': 18,
    'rfid_mosi': 23,
    'rfid_miso': 19,
    'rfid_rst': 27,
    
    // GPS NEO-6M (UART2)
    'gps_tx': 16,
    'gps_rx': 17,
    
    // DHT11
    'dht11_data': 4,
    
    // MPU6050 (I2C)
    'mpu_sda': 21,
    'mpu_scl': 22,
    
    // Buzzer
    'buzzer': 25,
    
    // Relay (Active LOW)
    'relay': 26,
  };
  
  // Bluetooth Configuration
  static const String btDevicePrefix = 'SENTRY_HELMET_';
  static const String btServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String btCharacteristicUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  
  // Commands to ESP32
  static const String cmdLock = 'LOCK';
  static const String cmdUnlock = 'UNLOCK';
  static const String cmdGetStatus = 'STATUS';
  static const String cmdGetSensor = 'SENSOR';
  static const String cmdAlarmOn = 'ALARM_ON';
  static const String cmdAlarmOff = 'ALARM_OFF';
  
  // Sensor Thresholds
  static const double maxTemperature = 45.0; // Celsius
  static const double minTemperature = 0.0;
  static const double maxHumidity = 90.0;
  static const double minHumidity = 20.0;
  static const double crashThreshold = 3.0; // G-force
  
  // Emergency Configuration
  static const int emergencyTimeout = 30; // seconds
  static const double emergencyRadius = 5.0; // km
  
  // Storage Keys
  static const String keyFirstTime = 'first_time';
  static const String keyUserName = 'user_name';
  static const String keyUserPhone = 'user_phone';
  static const String keyEmergencyContacts = 'emergency_contacts';
  static const String keyBtDeviceId = 'bt_device_id';
  static const String keyBtDeviceName = 'bt_device_name';
  static const String keyAutoLock = 'auto_lock';
  static const String keyNotificationEnabled = 'notification_enabled';
  
  // API Configuration (untuk future Firebase/Backend)
  static const String apiBaseUrl = 'https://your-api.com/api/v1';
  static const int apiTimeout = 30; // seconds
  
  // Map Configuration
  static const double defaultLatitude = -7.9666; // Malang
  static const double defaultLongitude = 112.6326;
  static const double defaultZoom = 15.0;
}
