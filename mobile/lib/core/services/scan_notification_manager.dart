import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/features/scanner/data/models/trust_score_report.dart';

class ScanNotificationManager {
  static final ScanNotificationManager instance = ScanNotificationManager._internal();
  ScanNotificationManager._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final androidImplementation = PushNotificationService()
        .localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    const channel = AndroidNotificationChannel(
      'critical_scan_warnings', // id
      'Critical Scan Warnings', // title
      description: 'Notifications for high risk ingredients and allergens.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await androidImplementation?.createNotificationChannel(channel);
    _isInitialized = true;
  }

  Future<void> evaluateAndNotify(ScanResponse response) async {
    await initialize();

    final hasFlaggedIssues = response.trustScoreReport.flaggedIssues.isNotEmpty;
    final hasHighRiskIngredients = response.parsedData.highRiskIngredients.isNotEmpty;
    final isPoorRating = response.trustScoreReport.rating.toLowerCase() == 'poor';

    if (hasFlaggedIssues || hasHighRiskIngredients || isPoorRating) {
      String title = '⚠️ Critical Health Warning';
      String body = 'A high-risk ingredient was detected. Tap to review the full scan report.';

      if (hasFlaggedIssues) {
        title = '⚠️ Allergen Detected';
        body = '${response.trustScoreReport.flaggedIssues.first} was detected in your scanned product.';
      } else if (hasHighRiskIngredients) {
        title = '🚨 Critical Ingredient Warning';
        body = '${response.parsedData.highRiskIngredients.first} was detected. Please review carefully.';
      }

      try {
        await PushNotificationService().localNotifications.show(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'critical_scan_warnings',
              'Critical Scan Warnings',
              channelDescription: 'Notifications for high risk ingredients and allergens.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_notification', // We will create this
            ),
          ),
          payload: '/result',
        );
      } catch (e) {
        // Fallback for debugging
        print('Scan Notification failed: $e');
      }
    }
  }
}
