import 'package:testevagaflutter/part2_implementation/notifications/notification.dart';
import 'package:testevagaflutter/part2_implementation/notifications/notifications_api.dart';

class FakeNotificationsApi implements NotificationsApi {
  @override
  Future<List<Notification>> getUnreadNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      Notification(
        id: 1,
        title: 'Notificação de exemplo',
        body: 'O polling está ativo a cada 30 segundos em primeiro plano.',
        createdAt: now,
        isRead: false,
      ),
      Notification(
        id: 2,
        title: 'Teste técnico',
        body: 'Substitua FakeNotificationsApi por uma implementação HTTP real.',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
    ];
  }

  @override
  Future<void> markAsRead(int notificationId) async {}
}
