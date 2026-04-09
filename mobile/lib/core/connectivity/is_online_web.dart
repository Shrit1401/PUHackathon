// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Stream<bool> createOnlineStream() {
  final controller = StreamController<bool>.broadcast();

  void emit() => controller.add(html.window.navigator.onLine ?? true);

  // Emit initial state.
  scheduleMicrotask(emit);

  final subOnline = html.window.onOnline.listen((_) => emit());
  final subOffline = html.window.onOffline.listen((_) => emit());

  controller.onCancel = () async {
    await subOnline.cancel();
    await subOffline.cancel();
    await controller.close();
  };

  return controller.stream.distinct();
}

