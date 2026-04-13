import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'notifications_cubit.dart';
import 'notifications_view_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationsCubit>().onForeground();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<NotificationsCubit>();
    if (state == AppLifecycleState.resumed) {
      cubit.onForeground();
    } else if (state == AppLifecycleState.paused) {
      cubit.onBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            Widget body;
            if (state is NotificationsLoading) {
              body = const Center(child: CircularProgressIndicator());
            } else if (state is NotificationsLoaded) {
              body = ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final item = state.notifications[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.body),
                  );
                },
              );
            } else {
              final err = state as NotificationsError;
              body = Center(child: Text(err.message));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state is NotificationsError)
                  MaterialBanner(
                    content: Text(state.message),
                    actions: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }
}
