// ─────────────────────────────────────────────────────────
//  AIService — Platform-aware, offline-first
//
//  Web (browser testing):
//    → Anthropic API via env var WRAPD_API_KEY
//    → If no key set, returns helpful stub responses
//    → You keep full browser testing capability
//
//  Mobile (iOS/Android production):
//    → flutter_gemma — Gemma 3 on-device, zero cloud
//    → ~270MB one-time download, GPU accelerated
//    → Audio and transcripts never leave the device
//
//  Desktop (macOS/Windows/Linux):
//    → Ollama local server fallback
//    → ollama serve + ollama pull llama3.2:1b
// ─────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/session_model.dart';
import '../config/wrapd_config.dart';
import 'logger_service.dart';

// Conditional import — flutter_gemma only on native platforms
// ignore: uri_does_not_exist
import 'gemma_bridge.dart'
    if (dart.library.html) 'gemma_bridge_web.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _baseSystem =
      'You are WRAPD\'s Fact Engine — an AI embedded in a meeting app. '
      'Analyze transcripts, extract actions and decisions, answer questions. '
      'Be direct, concise, under 300 words. Never mention cloud or internet.';

  // ── Platform routing ──────────────────────────────────
  static bool get _isWeb => kIsWeb;
  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  // Gemma state (mobile only)
  bool _gemmaReady = false;
  bool _gemmaLoading = false;
  double _downloadProgress = 0.0;

  bool get isModelReady => _isWeb || (!_isMobile) || _gemmaReady;
  bool get isModelLoading => _gemmaLoading;
  double get downloadProgress => _downloadProgress;

  // ── Initialize (mobile only) ─────────────────────────
  Future<void> initializeModel({void Function(double)? onProgress}) async {
    if (!_isMobile || _gemmaReady || _gemmaLoading) return;
    _gemmaLoading = true;
    try {
      _gemmaReady = await GemmaBridge.initialize(
        onProgress: (p) {
          _downloadProgress = p;
          onProgress?.call(p);
        },
      );
    } catch (e) {
      WrapdLogger.e('Gemma init error', e);
      _gemmaReady = false;
    } finally {
      _gemmaLoading = false;
    }
  }

  // ── Core stream router ────────────────────────────────
  Stream<String> _stream(String prompt) async* {
    if (_isWeb) {
      yield* _anthropicStream(prompt);   // Web: Anthropic for testing
    } else if (_isMobile) {
      yield* _gemmaStream(prompt);       // Mobile: on-device Gemma
    } else {
      yield* _ollamaStream(prompt);      // Desktop: local Ollama
    }
  }

  // ── Web: Anthropic (browser testing only) ────────────
  // API key read from WrapdConfig — set for dev, remove for prod builds.
  // Web build is NEVER shipped to end users. This is for your testing only.
  Stream<String> _anthropicStream(String prompt) async* {
    const apiKey = WrapdConfig.anthropicDevKey;
    if (apiKey.isEmpty) {
      yield* _stubResponse(prompt);
      return;
    }
    try {
      final req = http.Request(
          'POST', Uri.parse('https://api.anthropic.com/v1/messages'));
      req.headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
        'accept': 'text/event-stream',
      });
      req.body = jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 512,
        'stream': true,
        'system': _baseSystem,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      });
      final res = await req.send().timeout(const Duration(seconds: 20));
      await for (final chunk in res.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]' || data.isEmpty) continue;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (json['type'] == 'content_block_delta') {
              final text =
                  (json['delta'] as Map?)?.entries
                      .firstWhere((e) => e.key == 'text',
                          orElse: () => const MapEntry('text', null))
                      .value as String?;
              if (text != null && text.isNotEmpty) yield text;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      WrapdLogger.e('Anthropic web stream error', e);
      yield 'Error: $e';
    }
  }

  // ── Mobile: on-device Gemma ───────────────────────────
  Stream<String> _gemmaStream(String prompt) async* {
    if (!_gemmaReady) {
      yield 'AI model not ready. Tap Settings → Download AI Model (270MB, one-time).';
      return;
    }
    try {
      yield* GemmaBridge.stream('$_baseSystem\n\n$prompt');
    } catch (e) {
      WrapdLogger.e('Gemma stream error', e);
      yield 'Error running local AI: $e';
    }
  }

  // ── Desktop: Ollama ───────────────────────────────────
  static String get _ollamaUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://${WrapdConfig.ollamaHost}:11434/api/chat';
    }
    return 'http://127.0.0.1:11434/api/chat';
  }

  Stream<String> _ollamaStream(String prompt) async* {
    try {
      final req = http.Request('POST', Uri.parse(_ollamaUrl));
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode({
        'model': WrapdConfig.ollamaModel,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': _baseSystem},
          {'role': 'user', 'content': prompt},
        ],
      });
      final res = await req.send().timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        yield 'Ollama error. Run: ollama serve && ollama pull ${WrapdConfig.ollamaModel}';
        return;
      }
      await for (final chunk in res.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final text = (json['message'] as Map?)?.entries
                .firstWhere((e) => e.key == 'content',
                    orElse: () => const MapEntry('content', null))
                .value as String?;
            if (text != null && text.isNotEmpty) yield text;
            if (json['done'] == true) return;
          } catch (_) {}
        }
      }
    } catch (e) {
      yield 'Ollama not running. Install from ollama.ai for desktop AI.';
    }
  }

  // ── Stub (web, no API key) ────────────────────────────
  Stream<String> _stubResponse(String prompt) async* {
    yield 'AI synthesis is available in the mobile app with on-device Gemma.\n\n'
        'For browser testing with real AI: add your Anthropic dev key to '
        'WrapdConfig.anthropicDevKey in wrapd_config.dart.\n\n'
        'This key is only used in web/debug builds — never in production.';
  }

  // ── Transcript context ────────────────────────────────
  String _ctx(WrapdSession s) {
    if (s.segments.isEmpty) return '[No transcript]';
    final buf = StringBuffer();
    buf.writeln('Meeting: "${s.title}" | ${s.duration.inMinutes}min | ${s.speakerCount} speakers');
    buf.writeln('---');
    for (final seg in s.segments) {
      final m = seg.timestamp.inMinutes.toString().padLeft(2, '0');
      final sc = seg.timestamp.inSeconds.remainder(60).toString().padLeft(2, '0');
      buf.writeln('[$m:$sc] ${seg.speakerName}: ${seg.text}');
    }
    return buf.toString();
  }

  // ── Public API ────────────────────────────────────────
  Stream<String> askAboutSession(WrapdSession s, String q) =>
      _stream('TRANSCRIPT:\n${_ctx(s)}\n\nQUESTION: $q');

  Stream<String> generateSummary(WrapdSession s) =>
      _stream('TRANSCRIPT:\n${_ctx(s)}\n\nConcise summary: main topics, decisions, outcome.');

  Stream<String> extractActionItems(WrapdSession s) =>
      _stream('TRANSCRIPT:\n${_ctx(s)}\n\nExtract action items. Format: "• [Owner]: [Task] — [Deadline]"');

  Stream<String> extractKeyQuestions(WrapdSession s) =>
      _stream('TRANSCRIPT:\n${_ctx(s)}\n\nList significant questions raised and whether answered.');

  Stream<String> extractDecisions(WrapdSession s) =>
      _stream('TRANSCRIPT:\n${_ctx(s)}\n\nList all decisions and agreements reached.');

  Future<String> liveFactCheck(List<TranscriptSegment> segs, String q) async {
    if (segs.isEmpty) return 'No transcript yet.';
    final buf = segs.take(40).map((s) => '${s.speakerName}: ${s.text}').join('\n');
    final result = StringBuffer();
    await for (final t in _stream('LIVE TRANSCRIPT:\n$buf\n\nQUESTION: $q\nAnswer in 1-2 sentences.')) {
      result.write(t);
    }
    return result.toString();
  }
}
