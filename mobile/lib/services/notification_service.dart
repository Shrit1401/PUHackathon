import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void pushMock(String message) => _controller.add(message);

  void dispose() => _controller.close();
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});
