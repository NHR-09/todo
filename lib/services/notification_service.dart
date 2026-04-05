import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'database_service.dart';
import 'auth_service.dart';

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _lastFetchKey = 'last_notification_fetch';

  /// Fetch new notifications from Firestore
  static Future<List<AppNotification>> fetchNotifications() async {
    try {
      print('🔔 Fetching notifications from Firestore...');
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getString(_lastFetchKey);
      final currentUserId = AuthService.uid;
      print('📅 Last fetch: $lastFetch');
      print('👤 Current user ID: $currentUserId');
      
      // Simple query - just order by createdAt to avoid index requirement
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      print('📊 Found ${snapshot.docs.length} notifications in Firestore');

      final allNotifications = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('📄 Notification data: $data');
            return AppNotification.fromFirestore(data);
          })
          .toList();

      // Filter notifications for current user
      final notifications = allNotifications
          .where((n) {
            // Include if broadcast is true
            if (n.broadcast) {
              print('✅ Including broadcast notification: ${n.title}');
              return true;
            }
            // Include if user is in targetUserIds
            if (currentUserId != null && 
                n.targetUserIds != null && 
                n.targetUserIds!.contains(currentUserId)) {
              print('✅ Including targeted notification for user: ${n.title}');
              return true;
            }
            print('❌ Excluding notification (not for this user): ${n.title}');
            return false;
          })
          .toList();
      
      print('📊 ${notifications.length} notifications after user filtering');

      // Filter new notifications locally if lastFetch exists
      List<AppNotification> newNotifications = notifications;
      if (lastFetch != null) {
        final lastFetchDate = DateTime.parse(lastFetch);
        newNotifications = notifications.where((notification) {
          return notification.createdAt.isAfter(lastFetchDate);
        }).toList();
        print('🆕 Found ${newNotifications.length} new notifications since last fetch');
      } else {
        print('🆕 No previous fetch, treating all ${notifications.length} as new');
      }

      // Save to local database (save all, not just new ones)
      for (final notification in notifications) {
        await DatabaseService.insertNotification(notification);
        print('💾 Saved notification: ${notification.title}');
      }

      // Update last fetch time
      await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
      print('✅ Updated last fetch time');

      return newNotifications;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get all notifications from local database
  static Future<List<AppNotification>> getLocalNotifications() async {
    return DatabaseService.getNotifications();
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await DatabaseService.markNotificationAsRead(notificationId);
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    await DatabaseService.markAllNotificationsAsRead();
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await DatabaseService.deleteNotification(notificationId);
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    return DatabaseService.getUnreadNotificationCount();
  }

  /// Check for updates and fetch new notifications
  static Future<int> checkForUpdates() async {
    final newNotifications = await fetchNotifications();
    return newNotifications.length;
  }

  /// Submit poll vote
  static Future<void> submitPollVote(String notificationId, String optionId) async {
    try {
      final userId = AuthService.uid;
      if (userId == null) return;

      // Update local database
      await DatabaseService.updateNotificationVote(notificationId, optionId);

      // Submit to Firestore
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .collection('votes')
          .doc(userId)
          .set({
        'userId': userId,
        'optionId': optionId,
        'votedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Poll vote submitted');
    } catch (e) {
      print('❌ Error submitting poll vote: $e');
    }
  }

  /// Submit feedback
  static Future<void> submitFeedback(String notificationId, String feedback) async {
    try {
      final userId = AuthService.uid;
      if (userId == null) return;

      // Update local database
      await DatabaseService.updateNotificationFeedback(notificationId, feedback);

      // Submit to Firestore
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .collection('feedback')
          .doc(userId)
          .set({
        'userId': userId,
        'feedback': feedback,
        'submittedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Feedback submitted');
    } catch (e) {
      print('❌ Error submitting feedback: $e');
    }
  }

  /// Get user's vote for a poll
  static Future<String?> getUserVote(String notificationId) async {
    return DatabaseService.getNotificationVote(notificationId);
  }

  /// Get user's feedback
  static Future<String?> getUserFeedback(String notificationId) async {
    return DatabaseService.getNotificationFeedback(notificationId);
  }
}
