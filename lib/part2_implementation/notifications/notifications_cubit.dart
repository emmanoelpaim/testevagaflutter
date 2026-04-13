import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'notification.dart' as notification_model;
import 'notifications_api.dart';
import 'notifications_view_model.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._api) : super(NotificationsLoading());

  final NotificationsApi _api;

  Timer? _pollTimer;
  bool _inForeground = false;
  bool _fatalStop = false;
  int _consecutiveFailedCycles = 0;
  bool _cycleRunning = false;

  static const _pollInterval = Duration(seconds: 30);
  static const _backoffDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  void onForeground() {
    _inForeground = true;
    if (_fatalStop) {
      _fatalStop = false;
      _consecutiveFailedCycles = 0;
      emit(NotificationsLoading());
    }
    _startPolling();
  }

  void onBackground() {
    _inForeground = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_inForeground || _fatalStop) {
      return;
    }
    unawaited(_runPollCycle());
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_runPollCycle());
    });
  }

  Future<void> _runPollCycle() async {
    if (!_inForeground || _fatalStop || _cycleRunning) {
      return;
    }
    _cycleRunning = true;
    try {
      if (state is! NotificationsLoaded) {
        emit(NotificationsLoading());
      }
      final list = await _fetchWithRetries();
      _consecutiveFailedCycles = 0;
      emit(NotificationsLoaded(list));
    } catch (_) {
      _consecutiveFailedCycles++;
      if (_consecutiveFailedCycles >= 3) {
        _fatalStop = true;
        _pollTimer?.cancel();
        _pollTimer = null;
        emit(NotificationsError(
          'Não foi possível carregar as notificações após várias tentativas.',
        ));
      }
    } finally {
      _cycleRunning = false;
    }
  }

  Future<List<notification_model.Notification>> _fetchWithRetries() async {
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        return await _api.getUnreadNotifications();
      } catch (e) {
        lastError = e;
        if (attempt < 3) {
          await Future<void>.delayed(_backoffDelays[attempt]);
        }
      }
    }
    throw lastError!;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
