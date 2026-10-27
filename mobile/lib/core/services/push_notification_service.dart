// ignore_for_file: avoid_print
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/services/pending_notification_manager.dart';
import 'package:mobile/main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  void Function(String)? _onNavigate;

  Future<void> initialize({void Function(String)? onNavigate}) async {
    _onNavigate = onNavigate;
    // 1. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined notification permission');
      return;
    }

    // 2. Set foreground presentation options natively using Firebase Messaging
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Local Notifications for Android Foreground
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);
    
    await localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          if (_onNavigate != null) {
            _onNavigate!(response.payload!);
          }
        }
      },
    );

    // Request Android 13+ permissions explicitly for local notifications
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    // Create the channel on the device (if a channel with an id already exists, it will be updated)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );
    await androidImplementation?.createNotificationChannel(channel);

    const AndroidNotificationChannel adminChannel = AndroidNotificationChannel(
      'admin_community_requests', // id
      'Admin Community Requests', // title
      description: 'Notifications for new database community requests.', // description
      importance: Importance.max,
    );
    await androidImplementation?.createNotificationChannel(adminChannel);
    
    await androidImplementation?.requestNotificationsPermission();

    // 4. Handle foreground messages natively and locally
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.messageId}');
      
      final String title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
      final String body = message.notification?.body ?? message.data['body'] ?? '';
      final String? route = message.data['route'];
      
      final String? notificationType = message.data['notificationType'];
      final bool isAdminReq = notificationType == 'COMMUNITY_REQUEST';

      // Try showing native local notification
      try {
        localNotifications.show(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              isAdminReq ? 'admin_community_requests' : 'high_importance_channel', // id
              isAdminReq ? 'Admin Community Requests' : 'High Importance Notifications', // title
              channelDescription: isAdminReq ? 'Notifications for new database community requests.' : 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: route, // Pass route as payload
        );
      } catch (e) {
        print('Local notification failed: $e');
      }

      // Guaranteed Fallback: Show an in-app SnackBar notification via scaffoldMessengerKey
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Colors.white)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
          action: route != null ? SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              if (_onNavigate != null) _onNavigate!(route);
            },
          ) : null,
        ),
      );
    });

    // 5. Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageRoute(message);
    });

    // 6. Handle notification tap when app was terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data.containsKey('route')) {
      final route = initialMessage.data['route'] as String;
      PendingNotificationManager.instance.setPendingRoute(route);
    }

    // 7. Fetch & sync FCM token to Supabase
    final token = await _fcm.getToken();
    if (token != null) await syncTokenToSupabase(token);
    _fcm.onTokenRefresh.listen(syncTokenToSupabase);
  }

  void _handleMessageRoute(RemoteMessage message) {
    if (message.data.containsKey('route')) {
      final route = message.data['route'] as String;
      if (_onNavigate != null) {
        _onNavigate!(route);
      }
    }
  }

  Future<void> syncTokenToSupabase([String? providedToken]) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    
    final token = providedToken ?? await _fcm.getToken();
    if (token == null) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', session.user.id);
      print('FCM token synced to Supabase');
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }
}
