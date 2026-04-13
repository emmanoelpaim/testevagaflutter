import 'notification.dart' as notification_model;

sealed class NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<notification_model.Notification> notifications;

  NotificationsLoaded(this.notifications);
}

class NotificationsError extends NotificationsState {
  final String message;

  NotificationsError(this.message);
}
