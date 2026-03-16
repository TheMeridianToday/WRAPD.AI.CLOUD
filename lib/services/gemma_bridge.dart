// gemma_bridge.dart — Native (iOS/Android) implementation
// Uses flutter_gemma for on-device inference.
import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'logger_service.dart';

class GemmaBridge {
  static Future<bool> initialize({void Function(double)? onProgress}) async {
    try {
      final gemma = FlutterGemma.instance;
      final installed = await gemma.isModelInstalled;
      if (installed) {
        await gemma.init(maxTokens: 512);
        return true;
      }
      await gemma.loadModel(
        ModelType.gemmaIt,
        onProgress: onProgress ?? (_) {},
      );
      await gemma.init(maxTokens: 512);
      return true;
    } catch (e) {
      WrapdLogger.e('GemmaBridge init error', e);
      return false;
    }
  }

  static Stream<String> stream(String prompt) async* {
    final gemma = FlutterGemma.instance;
    await for (final token in gemma.getResponseAsync(message: prompt)) {
      if (token != null && token.isNotEmpty) yield token;
    }
  }
}
