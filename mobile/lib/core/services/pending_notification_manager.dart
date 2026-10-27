class PendingNotificationManager {
  static final PendingNotificationManager instance = PendingNotificationManager._internal();
  
  PendingNotificationManager._internal();

  String? _pendingRoute;

  bool get hasPendingNotification => _pendingRoute != null;

  void setPendingRoute(String route) {
    _pendingRoute = route;
  }

  String? consumeRoute() {
    final route = _pendingRoute;
    _pendingRoute = null; // Clears the state after consuming
    return route;
  }
}
