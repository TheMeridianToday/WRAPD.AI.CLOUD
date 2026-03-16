// gemma_bridge_web.dart — Web stub
// flutter_gemma is not available on web.
// On web we route through Anthropic (dev) or show a stub.
// This file satisfies the conditional import — never runs Gemma code.
import 'dart:async';

class GemmaBridge {
  static Future<bool> initialize({void Function(double)? onProgress}) async {
    return false; // web never uses Gemma
  }

  static Stream<String> stream(String prompt) async* {
    yield ''; // web routes via _anthropicStream, never reaches here
  }
}
