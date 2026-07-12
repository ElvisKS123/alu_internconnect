import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../../../core/constants/app_constants.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Single equality field query (userId) -- sorted client-side, same
  // no-composite-index pattern used across the rest of the app.
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return (() async* {
      try {
        final stream = _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .snapshots();
        await for (final snap in stream) {
          final notifications = snap.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield notifications;
        }
      } catch (e) {
        debugPrint('[NotificationRepository] watchUserNotifications error: $e');
        yield <NotificationModel>[];
      }
    })();
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? applicationId,
  }) async {
    final ref = _firestore.collection(AppConstants.notificationsCollection).doc();
    await ref.set(NotificationModel(
      id: ref.id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      applicationId: applicationId,
      read: false,
      createdAt: DateTime.now(),
    ).toFirestore());
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('[NotificationRepository] markAsRead error: $e');
    }
  }
}
