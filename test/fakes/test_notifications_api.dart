import 'package:testevagaflutter/part2_implementation/notifications/notification.dart';
import 'package:testevagaflutter/part2_implementation/notifications/notifications_api.dart';

class SuccessNotificationsApi implements NotificationsApi {
  SuccessNotificationsApi({this.items});

  final List<Notification>? items;

  @override
  Future<List<Notification>> getUnreadNotifications() async {
    await Future<void>.delayed(Duration.zero);
    return items ??
        [
          Notification(
            id: 1,
            title: 'Teste',
            body: 'Corpo',
            createdAt: DateTime.utc(2026, 1, 1),
            isRead: false,
          ),
        ];
  }

  @override
  Future<void> markAsRead(int notificationId) async {}
}

class FailingNotificationsApi implements NotificationsApi {
  @override
  Future<List<Notification>> getUnreadNotifications() async {
    throw Exception('erro de rede');
  }

  @override
  Future<void> markAsRead(int notificationId) async {}
}

class FailThenSuccessNotificationsApi implements NotificationsApi {
  int _calls = 0;

  @override
  Future<List<Notification>> getUnreadNotifications() async {
    _calls++;
    if (_calls <= 12) {
      throw Exception('erro de rede');
    }
    return [
      Notification(
        id: 99,
        title: 'Recuperado',
        body: 'ok',
        createdAt: DateTime.utc(2026, 2, 1),
        isRead: false,
      ),
    ];
  }

  @override
  Future<void> markAsRead(int notificationId) async {}
}
