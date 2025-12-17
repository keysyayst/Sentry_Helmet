import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../core/utils/helpers.dart';
import '../data/models/helmet_data_model.dart';
import '../data/models/alert_model.dart';
import '../data/models/ride_history_model.dart';

class FirebaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _userId;
  String? _fcmToken;

  Future<FirebaseService> init() async {
    // Initialize FCM
    await initializeMessaging();
    return this;
  }

  // Set user ID
  void setUserId(String userId) {
    _userId = userId;
  }

  // Initialize Firebase Cloud Messaging
  Future<void> initializeMessaging() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        print('FCM Token: $_fcmToken');

        // Listen to token refresh
        _messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          _saveFCMToken(token);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      } else {
        print('User declined or has not accepted permission');
      }

    } catch (e) {
      print('Error initializing messaging: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      Helpers.showInfo(
        '${message.notification!.title}\n${message.notification!.body}',
      );
    }
  }

  // Save helmet data to Firestore
  Future<void> saveHelmetData(HelmetDataModel data) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('helmet_data')
          .doc(data.id)
          .set(data.toJson());
    } catch (e) {
      print('Error saving helmet data: $e');
    }
  }

  // Get helmet data stream
  Stream<HelmetDataModel?> getHelmetDataStream() {
    if (_userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('helmet_data')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return HelmetDataModel.fromJson(
          snapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    });
  }

  // Save alert to Firestore
  Future<void> saveAlert(AlertModel alert) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('alerts')
          .doc(alert.id)
          .set(alert.toJson());

      // Send notification to emergency contacts
      await _sendEmergencyNotification(alert);

    } catch (e) {
      print('Error saving alert: $e');
    }
  }

  // Get alerts stream
  Stream<List<AlertModel>> getAlertsStream({int limit = 50}) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Save ride history
  Future<void> saveRideHistory(RideHistoryModel ride) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ride_history')
          .doc(ride.id)
          .set(ride.toJson());
    } catch (e) {
      print('Error saving ride history: $e');
    }
  }

  // Get ride history stream
  Stream<List<RideHistoryModel>> getRideHistoryStream({int limit = 20}) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('ride_history')
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideHistoryModel.fromJson(doc.data()))
          .toList();
    });
  }

  // Send emergency notification
  Future<void> _sendEmergencyNotification(AlertModel alert) async {
    // This would typically call a Cloud Function to send notifications
    // to emergency contacts via SMS or push notifications
    
    try {
      await _firestore.collection('emergency_notifications').add({
        'userId': _userId,
        'alertId': alert.id,
        'type': alert.type.toString(),
        'message': alert.message,
        'location': alert.location?.toJson(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending emergency notification: $e');
    }
  }

  // Update alert status
  Future<void> updateAlertStatus(String alertId, {
    bool? isRead,
    bool? isResolved,
  }) async {
    if (_userId == null) return;

    try {
      Map<String, dynamic> updates = {};
      if (isRead != null) updates['isRead'] = isRead;
      if (isResolved != null) updates['isResolved'] = isResolved;

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('alerts')
          .doc(alertId)
          .update(updates);
    } catch (e) {
      print('Error updating alert status: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
