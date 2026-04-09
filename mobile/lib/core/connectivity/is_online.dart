import 'is_online_stub.dart'
    if (dart.library.html) 'is_online_web.dart'
    if (dart.library.io) 'is_online_io.dart';

/// Stream of online/offline state.
Stream<bool> onlineStream() => createOnlineStream();

