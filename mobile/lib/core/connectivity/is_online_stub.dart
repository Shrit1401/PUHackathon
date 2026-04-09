Stream<bool> createOnlineStream() async* {
  // Fallback for platforms without dart:io or dart:html.
  yield true;
}

