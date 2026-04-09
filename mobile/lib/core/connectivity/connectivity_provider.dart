import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'is_online.dart';

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  yield* onlineStream();
});

