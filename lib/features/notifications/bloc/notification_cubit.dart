import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  const NotificationsLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.read).length;

  @override
  List<Object?> get props => [notifications];
}

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription? _subscription;

  NotificationCubit({required NotificationRepository repository})
      : _repository = repository,
        super(NotificationInitial());

  void loadForUser(String userId) {
    _subscription?.cancel();
    _subscription = _repository.watchUserNotifications(userId).listen(
          (notifications) => emit(NotificationsLoaded(notifications)),
        );
  }

  Future<void> markAsRead(String notificationId) =>
      _repository.markAsRead(notificationId);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
