import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 Initializing notification service...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
      'urgent_notifications',
      'Urgent Notifications',
      description: 'High priority notifications for tour guides',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel tourChannel = AndroidNotificationChannel(
      'tour_notifications',
      'Tour Notifications',
      description: 'Tour-related notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel reviewChannel = AndroidNotificationChannel(
      'review_notifications',
      'Review Notifications',
      description: 'Review and rating notifications',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'reminder_notifications',
      'Reminder Notifications',
      description: 'Trip reminders and alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(urgentChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(tourChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reviewChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 Notification permission status: ${settings.authorizationStatus}');

    // Request additional permissions for Android
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
      } catch (e) {
        print('⚠️ Permission request failed: $e');
        // Continue without additional permissions - Firebase messaging should still work
      }
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('🔔 FCM Token: $_fcmToken');

    // Save token to shared preferences
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken!);
    }

    // Subscribe to general topics
    await _firebaseMessaging.subscribeToTopic('tour_guides');
    await _firebaseMessaging.subscribeToTopic('notifications');
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Received foreground message: ${message.messageId}');
    print('🔔 Message data: ${message.data}');
    print('🔔 Message notification: ${message.notification?.title}');

    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('🔔 Notification tapped: ${message.messageId}');
    await _processNotificationData(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      _processNotificationPayload(response.payload!);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tour_notifications',
      'Tour Notifications',
      channelDescription: 'Tour-related notifications',
      importance: Importance.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: message.data.toString(),
    );
  }

  /// Process notification data
  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    try {
      String? type = data['type'];
      String? tripId = data['tripId'];
      String? applicationId = data['applicationId'];

      print('🔔 Processing notification data - Type: $type, TripId: $tripId');

      switch (type) {
        case 'trip_application':
          // Navigate to trip applications
          break;
        case 'trip_accepted':
          // Navigate to accepted trips
          break;
        case 'trip_started':
          // Navigate to ongoing trips
          break;
        case 'trip_completed':
          // Navigate to completed trips
          break;
        case 'new_review':
          // Navigate to reviews
          break;
        case 'payment_processed':
          // Navigate to payments
          break;
        case 'trip_reminder':
          // Show trip reminder
          break;
        default:
          print('🔔 Unknown notification type: $type');
      }
    } catch (e) {
      print('❌ Error processing notification data: $e');
    }
  }

  /// Process notification payload
  void _processNotificationPayload(String payload) {
    try {
      // Parse payload and handle navigation
      print('🔔 Processing payload: $payload');
    } catch (e) {
      print('❌ Error processing notification payload: $e');
    }
  }

  /// Subscribe to user-specific topics
  Future<void> subscribeToUserTopics(String userId, String userRole) async {
    try {
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      await _firebaseMessaging.subscribeToTopic('role_$userRole');
      
      if (userRole == 'Tour Guide') {
        await _firebaseMessaging.subscribeToTopic('tour_guides');
        await _firebaseMessaging.subscribeToTopic('guide_notifications');
      } else if (userRole == 'Tourist') {
        await _firebaseMessaging.subscribeToTopic('tourists');
        await _firebaseMessaging.subscribeToTopic('tourist_notifications');
      }

      print('🔔 Subscribed to topics for user: $userId, role: $userRole');
    } catch (e) {
      print('❌ Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe from user-specific topics
  Future<void> unsubscribeFromUserTopics(String userId, String userRole) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
      await _firebaseMessaging.unsubscribeFromTopic('role_$userRole');
      
      if (userRole == 'Tour Guide') {
        await _firebaseMessaging.unsubscribeFromTopic('tour_guides');
        await _firebaseMessaging.unsubscribeFromTopic('guide_notifications');
      } else if (userRole == 'Tourist') {
        await _firebaseMessaging.unsubscribeFromTopic('tourists');
        await _firebaseMessaging.unsubscribeFromTopic('tourist_notifications');
      }

      print('🔔 Unsubscribed from topics for user: $userId, role: $userRole');
    } catch (e) {
      print('❌ Error unsubscribing from topics: $e');
    }
  }

  /// Show trip reminder notification
  Future<void> showTripReminder({
    required String tripId,
    required String tripTitle,
    required String touristName,
    required DateTime startTime,
    required String reminderType,
  }) async {
    try {
      String title;
      String body;
      String channelId;
      Importance importance;

      switch (reminderType) {
        case '1_day':
          title = 'Trip Tomorrow!';
          body = 'You have "$tripTitle" with $touristName starting tomorrow. Please prepare and confirm meeting details.';
          channelId = 'reminder_notifications';
          importance = Importance.high;
          break;
        case '2_hours':
          title = 'Trip Starting Soon!';
          body = 'Your trip "$tripTitle" with $touristName starts in 2 hours. Please contact the tourist to confirm.';
          channelId = 'urgent_notifications';
          importance = Importance.max;
          break;
        case '30_minutes':
          title = 'Trip Starting Very Soon!';
          body = 'Your trip "$tripTitle" with $touristName starts in 30 minutes. Please be ready!';
          channelId = 'urgent_notifications';
          importance = Importance.max;
          break;
        default:
          title = 'Trip Reminder';
          body = 'You have "$tripTitle" with $touristName coming up.';
          channelId = 'reminder_notifications';
          importance = Importance.high;
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        'Trip Reminders',
        channelDescription: 'Reminders for upcoming trips',
        importance: importance,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: const Color(0xFF667eea),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        tripId.hashCode,
        title,
        body,
        details,
        payload: 'trip_reminder:$tripId:$reminderType',
      );

      print('🔔 Trip reminder sent: $title');
    } catch (e) {
      print('❌ Error showing trip reminder: $e');
    }
  }

  /// Show new application notification
  Future<void> showNewApplicationNotification({
    required String tripId,
    required String tripTitle,
    required String touristName,
    required String applicationId,
  }) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'tour_notifications',
        'Tour Notifications',
        channelDescription: 'Tour-related notifications',
        importance: Importance.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: const Color(0xFF667eea),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        applicationId.hashCode,
        'New Trip Application!',
        '$touristName applied for your trip "$tripTitle"',
        details,
        payload: 'trip_application:$tripId:$applicationId',
      );

      print('🔔 New application notification sent');
    } catch (e) {
      print('❌ Error showing new application notification: $e');
    }
  }

  /// Show application status update notification
  Future<void> showApplicationStatusNotification({
    required String tripId,
    required String tripTitle,
    required String status,
    required String applicationId,
  }) async {
    try {
      String title;
      String body;
      String channelId;
      Color color;

      switch (status.toLowerCase()) {
        case 'accepted':
          title = 'Application Accepted!';
          body = 'Your application for "$tripTitle" has been accepted!';
          channelId = 'tour_notifications';
          color = const Color(0xFF4CAF50);
          break;
        case 'rejected':
          title = 'Application Update';
          body = 'Your application for "$tripTitle" was not selected this time.';
          channelId = 'tour_notifications';
          color = const Color(0xFFF44336);
          break;
        case 'started':
          title = 'Trip Started!';
          body = 'Your trip "$tripTitle" has started. Have a great tour!';
          channelId = 'tour_notifications';
          color = const Color(0xFF2196F3);
          break;
        case 'completed':
          title = 'Trip Completed!';
          body = 'Your trip "$tripTitle" has been completed. Thank you for your service!';
          channelId = 'tour_notifications';
          color = const Color(0xFF9C27B0);
          break;
        default:
          title = 'Application Update';
          body = 'Your application for "$tripTitle" has been updated.';
          channelId = 'tour_notifications';
          color = const Color(0xFF667eea);
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        'Tour Notifications',
        channelDescription: 'Tour-related notifications',
        importance: Importance.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: color,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        applicationId.hashCode,
        title,
        body,
        details,
        payload: 'application_status:$tripId:$status:$applicationId',
      );

      print('🔔 Application status notification sent: $status');
    } catch (e) {
      print('❌ Error showing application status notification: $e');
    }
  }

  /// Show new review notification
  Future<void> showNewReviewNotification({
    required String tripId,
    required String tripTitle,
    required String touristName,
    required int rating,
    required String reviewText,
  }) async {
    try {
      String title = 'New Review Received!';
      String body = '$touristName left a $rating-star review for "$tripTitle"';
      
      Color color = rating >= 4 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'review_notifications',
        'Review Notifications',
        channelDescription: 'Review and rating notifications',
        importance: Importance.defaultImportance,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: false,
        color: color,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        tripId.hashCode,
        title,
        body,
        details,
        payload: 'new_review:$tripId:$rating',
      );

      print('🔔 New review notification sent: $rating stars');
    } catch (e) {
      print('❌ Error showing new review notification: $e');
    }
  }

  /// Show payment notification
  Future<void> showPaymentNotification({
    required String tripId,
    required String tripTitle,
    required String amount,
    required String status,
  }) async {
    try {
      String title;
      String body;
      Color color;

      switch (status.toLowerCase()) {
        case 'processed':
          title = 'Payment Processed';
          body = 'Payment of $amount for "$tripTitle" has been processed and will be transferred within 3-5 business days.';
          color = const Color(0xFF4CAF50);
          break;
        case 'pending':
          title = 'Payment Pending';
          body = 'Payment of $amount for "$tripTitle" is being processed.';
          color = const Color(0xFFFF9800);
          break;
        case 'failed':
          title = 'Payment Failed';
          body = 'Payment of $amount for "$tripTitle" failed. Please contact support.';
          color = const Color(0xFFF44336);
          break;
        default:
          title = 'Payment Update';
          body = 'Payment update for "$tripTitle".';
          color = const Color(0xFF667eea);
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'payment_notifications',
        'Payment Notifications',
        channelDescription: 'Payment-related notifications',
        importance: Importance.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        color: color,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        tripId.hashCode,
        title,
        body,
        details,
        payload: 'payment:$tripId:$status',
      );

      print('🔔 Payment notification sent: $status');
    } catch (e) {
      print('❌ Error showing payment notification: $e');
    }
  }

  /// Schedule trip reminders
  Future<void> scheduleTripReminders({
    required String tripId,
    required String tripTitle,
    required String touristName,
    required DateTime startTime,
  }) async {
    try {
      // Schedule 1 day before reminder
      DateTime oneDayBefore = startTime.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(DateTime.now())) {
        await _localNotifications.zonedSchedule(
          tripId.hashCode + 1,
          'Trip Tomorrow!',
          'You have "$tripTitle" with $touristName starting tomorrow. Please prepare and confirm meeting details.',
          _convertToTZDateTime(oneDayBefore),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_notifications',
              'Trip Reminders',
              channelDescription: 'Reminders for upcoming trips',
              importance: Importance.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              color: Color(0xFF667eea),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'trip_reminder:$tripId:1_day',
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Schedule 2 hours before reminder
      DateTime twoHoursBefore = startTime.subtract(const Duration(hours: 2));
      if (twoHoursBefore.isAfter(DateTime.now())) {
        await _localNotifications.zonedSchedule(
          tripId.hashCode + 2,
          'Trip Starting Soon!',
          'Your trip "$tripTitle" with $touristName starts in 2 hours. Please contact the tourist to confirm.',
          _convertToTZDateTime(twoHoursBefore),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'urgent_notifications',
              'Urgent Notifications',
              channelDescription: 'High priority notifications for tour guides',
              importance: Importance.max,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              color: Color(0xFF667eea),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'trip_reminder:$tripId:2_hours',
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Schedule 30 minutes before reminder
      DateTime thirtyMinutesBefore = startTime.subtract(const Duration(minutes: 30));
      if (thirtyMinutesBefore.isAfter(DateTime.now())) {
        await _localNotifications.zonedSchedule(
          tripId.hashCode + 3,
          'Trip Starting Very Soon!',
          'Your trip "$tripTitle" with $touristName starts in 30 minutes. Please be ready!',
          _convertToTZDateTime(thirtyMinutesBefore),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'urgent_notifications',
              'Urgent Notifications',
              channelDescription: 'High priority notifications for tour guides',
              importance: Importance.max,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              color: Color(0xFF667eea),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'trip_reminder:$tripId:30_minutes',
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      print('🔔 Trip reminders scheduled for: $tripTitle');
    } catch (e) {
      print('❌ Error scheduling trip reminders: $e');
    }
  }

  /// Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.UTC);
  }

  /// Cancel scheduled notifications for a trip
  Future<void> cancelTripReminders(String tripId) async {
    try {
      await _localNotifications.cancel(tripId.hashCode + 1); // 1 day before
      await _localNotifications.cancel(tripId.hashCode + 2); // 2 hours before
      await _localNotifications.cancel(tripId.hashCode + 3); // 30 minutes before
      print('🔔 Cancelled reminders for trip: $tripId');
    } catch (e) {
      print('❌ Error cancelling trip reminders: $e');
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// Request notification permissions again
  Future<bool> requestPermissions() async {
    try {
      await _requestPermissions();
      return await areNotificationsEnabled();
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      // Return true if Firebase messaging is working, even if additional permissions fail
      try {
        NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      } catch (e2) {
        print('❌ Error checking Firebase messaging status: $e2');
        return false;
      }
    }
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Handling background message: ${message.messageId}');
  print('🔔 Message data: ${message.data}');
  
  // You can perform background tasks here
  // For example, updating local database, sending analytics, etc.
}

