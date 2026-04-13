import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testevagaflutter/part2_implementation/notifications/notifications_cubit.dart';
import 'package:testevagaflutter/part2_implementation/notifications/notifications_page.dart';

import 'fakes/test_notifications_api.dart';

void main() {
  testWidgets('NotificationsPage mostra indicador e depois itens da lista', (tester) async {
    final cubit = NotificationsCubit(SuccessNotificationsApi())..onForeground();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationsCubit>.value(
          value: cubit,
          child: const NotificationsPage(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Teste'), findsOneWidget);
    expect(find.text('Corpo'), findsOneWidget);

    await cubit.close();
  });
}
