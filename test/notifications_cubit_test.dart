import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testevagaflutter/part2_implementation/notifications/notifications_cubit.dart';
import 'package:testevagaflutter/part2_implementation/notifications/notifications_view_model.dart';

import 'fakes/test_notifications_api.dart';

void main() {
  group('NotificationsCubit', () {
    test('estado inicial é carregando', () {
      final cubit = NotificationsCubit(SuccessNotificationsApi());
      expect(cubit.state, isA<NotificationsLoading>());
      cubit.close();
    });

    blocTest<NotificationsCubit, NotificationsState>(
      'após sucesso da API emite NotificationsLoaded',
      build: () => NotificationsCubit(SuccessNotificationsApi()),
      act: (cubit) => cubit.onForeground(),
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        expect(cubit.state, isA<NotificationsLoaded>());
        final loaded = cubit.state as NotificationsLoaded;
        expect(loaded.notifications, isNotEmpty);
      },
    );

    test('três ciclos falhos consecutivos emitem NotificationsError', () {
      fakeAsync((async) {
        final cubit = NotificationsCubit(FailingNotificationsApi());
        cubit.onForeground();
        async.elapse(const Duration(seconds: 80));
        expect(cubit.state, isA<NotificationsError>());
        final err = cubit.state as NotificationsError;
        expect(err.message, isNotEmpty);
        cubit.close();
      });
    });

    test('onBackground cancela o timer sem lançar', () {
      fakeAsync((async) {
        final cubit = NotificationsCubit(SuccessNotificationsApi());
        cubit.onForeground();
        cubit.onBackground();
        async.elapse(const Duration(seconds: 60));
        cubit.close();
      });
    });

    test('após erro fatal onForeground pode recuperar quando a API volta a responder', () {
      fakeAsync((async) {
        final cubit = NotificationsCubit(FailThenSuccessNotificationsApi());
        cubit.onForeground();
        async.elapse(const Duration(seconds: 80));
        expect(cubit.state, isA<NotificationsError>());
        cubit.onForeground();
        async.elapse(const Duration(milliseconds: 200));
        expect(cubit.state, isA<NotificationsLoaded>());
        cubit.close();
      });
    });
  });
}
