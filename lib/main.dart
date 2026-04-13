import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:testevagaflutter/part2_implementation/notifications/notifications_api.dart';
import 'package:testevagaflutter/part2_implementation/notifications/notifications_cubit.dart';
import 'package:testevagaflutter/part2_implementation/notifications/notifications_page.dart';
import 'fake_notifications_api.dart';

final GetIt locator = GetIt.instance;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerDependencies();
  runApp(const AssessmentApp());
}

void _registerDependencies() {
  locator.registerLazySingleton<NotificationsApi>(FakeNotificationsApi.new);
  locator.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(locator<NotificationsApi>()),
  );
}

class AssessmentApp extends StatelessWidget {
  const AssessmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste técnico Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider<NotificationsCubit>(
        create: (_) => locator<NotificationsCubit>(),
        child: const NotificationsPage(),
      ),
    );
  }
}
