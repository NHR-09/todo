import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  Future<void> loadNotifications() async {
    print('🔄 Loading notifications from local database...');
    _isLoading = true;
    notifyListeners();

    final local = await NotificationService.getLocalNotifications();
    _notifications = local;
    _unreadCount = await NotificationService.getUnreadCount();
    print('📊 Loaded ${local.length} notifications, ${_unreadCount} unread');

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNewNotifications() async {
    print('🔍 Checking for new notifications...');
    final newCount = await NotificationService.checkForUpdates();
    print('🆕 Found $newCount new notifications');
    if (newCount > 0) {
      await loadNotifications();
    }
  }

  Future<void> markAsRead(String id) async {
    await NotificationService.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead();
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await NotificationService.deleteNotification(id);
    _notifications.removeWhere((n) => n.id == id);
    _unreadCount = await NotificationService.getUnreadCount();
    notifyListeners();
  }

  Future<void> submitPollVote(String notificationId, String optionId) async {
    await NotificationService.submitPollVote(notificationId, optionId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(userVote: optionId);
      notifyListeners();
    }
  }

  Future<void> submitFeedback(String notificationId, String feedback) async {
    await NotificationService.submitFeedback(notificationId, feedback);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(userFeedback: feedback);
      notifyListeners();
    }
  }
}
