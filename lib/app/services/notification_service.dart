import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../data/models/alert_model.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<NotificationService> init() async {
    await _initializeNotifications();
    return this;
  }

  // Initialize local notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (GetPlatform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    // Navigate based on payload
    if (response.payload != null) {
      // Handle navigation
      Get.toNamed('/alerts');
    }
  }

  // Show notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'sentry_helmet_channel',
          'Sentry Helmet Notifications',
          channelDescription: 'Notifications from Sentry Helmet app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Show alert notification
  Future<void> showAlertNotification(AlertModel alert) async {
    await showNotification(
      id: alert.id.hashCode,
      title: '${alert.icon} ${alert.title}',
      body: alert.message,
      payload: alert.id,
    );
  }

  // Show crash alert with high priority
  Future<void> showCrashAlert({
    required String message,
    required String location,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Alerts',
          channelDescription: 'Critical emergency notifications',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Emergency ID
      '🚨 KECELAKAAN TERDETEKSI',
      '$message\nLokasi: $location',
      details,
      payload: 'emergency',
    );
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
