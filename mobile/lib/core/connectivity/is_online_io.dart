import 'dart:async';
import 'dart:io';

Stream<bool> createOnlineStream() async* {
  Future<bool> probe() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  yield await probe();

  final timer = Stream.periodic(const Duration(seconds: 6));
  await for (final _ in timer) {
    yield await probe();
  }
}

