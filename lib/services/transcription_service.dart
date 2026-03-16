import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../config/wrapd_config.dart';
import 'logger_service.dart';

// ─────────────────────────────────────────────────────────
//  TranscriptionService — Real-time speech recognition
//  Fixes applied:
//  • No duplicate/repeating segments (partial dedup by id)
//  • Continuous listen loop restarts after every final result
//  • Speaker index snapshotted at emit time
//  • Dictation listen mode for natural on-device speech
// ─────────────────────────────────────────────────────────

class TranscriptionService {
  static final TranscriptionService _instance = TranscriptionService._internal();
  factory TranscriptionService() => _instance;
  TranscriptionService._internal() {
    _initializeService();
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasPermission = false;
  bool _shouldKeepListening = false;
  String _currentLanguage = 'en_US';

  // Partial dedup — track last partial text and its reusable id
  String _lastPartialText = '';
  String _lastPartialId = '';

  // Streams
  final StreamController<TranscriptSegment> _transcriptStream =
      StreamController<TranscriptSegment>.broadcast();
  // Partials stream: UI uses segment.id to update-in-place rather than append
  final StreamController<TranscriptSegment> _partialStream =
      StreamController<TranscriptSegment>.broadcast();
  final StreamController<String> _errorStream =
      StreamController<String>.broadcast();
  final StreamController<TranscriptionStatus> _statusStream =
      StreamController<TranscriptionStatus>.broadcast();

  Duration _currentTimestamp = Duration.zero;
  Timer? _timestampTimer;

  // Active speaker — driven by UI chip selection
  int _currentSpeakerIndex = 0;
  final Map<int, String> _speakerNames = {};

  static const Map<String, String> supportedLanguages = {
    'en_US': 'English (US)',
    'en_GB': 'English (UK)',
    'es_ES': 'Spanish',
    'fr_FR': 'French',
    'de_DE': 'German',
    'it_IT': 'Italian',
    'pt_BR': 'Portuguese (Brazil)',
    'ja_JP': 'Japanese',
    'ko_KR': 'Korean',
    'zh_CN': 'Chinese (Simplified)',
    'ru_RU': 'Russian',
  };

  Future<void> _initializeService() async {
    try {
      _hasPermission = await _speech.initialize(
        onError: (error) {
          WrapdLogger.e('STT error', error);
          _handleError('Speech error: $error');
          if (_shouldKeepListening) {
            Future.delayed(const Duration(milliseconds: 500), _restartListen);
          }
        },
        onStatus: _handleStatusChange,
        debugLogging: kDebugMode,
      );
      if (_hasPermission) {
        _isInitialized = true;
        _statusStream.add(TranscriptionStatus.ready);
      } else {
        if (kIsWeb) {
          await Future.delayed(const Duration(seconds: 1));
          _hasPermission = await _speech.initialize();
          if (_hasPermission) {
            _isInitialized = true;
            _statusStream.add(TranscriptionStatus.ready);
            return;
          }
        }
        _errorStream.add('Microphone permission denied');
      }
    } catch (e) {
      _handleError('Failed to initialize speech recognition: $e');
    }
  }

  // ── Public streams ─────────────────────────────────────
  Stream<TranscriptSegment> get transcriptStream => _transcriptStream.stream;
  Stream<TranscriptSegment> get partialStream => _partialStream.stream;
  Stream<String> get errorStream => _errorStream.stream;
  Stream<TranscriptionStatus> get statusStream => _statusStream.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  String get currentLanguage => _currentLanguage;

  // ── Start / Stop ───────────────────────────────────────

  Future<bool> startTranscription({String? languageCode}) async {
    if (!_isInitialized || !_hasPermission) {
      await _initializeService();
      if (!_isInitialized || !_hasPermission) {
        _errorStream.add('Speech recognition not ready or permission denied');
        return false;
      }
    }
    _currentLanguage = languageCode ?? _currentLanguage;
    _shouldKeepListening = true;
    _lastPartialText = '';
    _lastPartialId = '';
    _startTimestampTracking();
    return await _beginListening();
  }

  Future<bool> _beginListening() async {
    if (!_shouldKeepListening) return false;
    if (_speech.isListening) await _speech.stop();

    final connectivityResult = await _connectivity.checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    try {
      await _speech.listen(
        onResult: _handleSpeechResult,
        localeId: _currentLanguage,
        partialResults: true,
        // Dictation: no confirmation pause, best for continuous device mic usage
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      _isListening = true;
      _statusStream.add(isOffline
          ? TranscriptionStatus.listeningOffline
          : TranscriptionStatus.listening);
      return true;
    } catch (e) {
      _handleError('Failed to start transcription: $e');
      return false;
    }
  }

  /// Restarts listening after a final result or engine timeout.
  void _restartListen() {
    if (!_shouldKeepListening) return;
    _lastPartialText = '';
    _lastPartialId = '';
    _beginListening();
  }

  Future<void> stopTranscription() async {
    _shouldKeepListening = false;
    _isListening = false;
    await _speech.stop();
    _timestampTimer?.cancel();
    _lastPartialText = '';
    _lastPartialId = '';
    _statusStream.add(TranscriptionStatus.stopped);
  }

  Future<void> pauseTranscription() async {
    _shouldKeepListening = false;
    _isListening = false;
    await _speech.stop();
    _timestampTimer?.cancel();
    _statusStream.add(TranscriptionStatus.paused);
  }

  Future<void> resumeTranscription() async {
    _startTimestampTracking();
    await startTranscription(languageCode: _currentLanguage);
  }

  Future<bool> setLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      _errorStream.add('Unsupported language: $languageCode');
      return false;
    }
    final wasListening = _isListening;
    if (wasListening) await stopTranscription();
    _currentLanguage = languageCode;
    if (wasListening) return await startTranscription(languageCode: languageCode);
    return true;
  }

  // ── Speaker control ────────────────────────────────────

  void setSpeakerName(int index, String name) => _speakerNames[index] = name;

  /// Called when user taps a speaker chip in the UI.
  void setSpeakerIndex(int index) => _currentSpeakerIndex = index;

  // ── Core result handler ────────────────────────────────

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    // Snapshot speaker at recognition time
    final speakerIndex = _currentSpeakerIndex;
    final speakerName =
        _speakerNames[speakerIndex] ?? 'Speaker ${speakerIndex + 1}';
    final timestamp = _currentTimestamp;

    if (result.finalResult) {
      // Use the same id as the running partial so the UI can finalize in place
      final id = _lastPartialId.isNotEmpty ? _lastPartialId : _uuid.v4();
      _transcriptStream.add(TranscriptSegment(
        id: id,
        speakerIndex: speakerIndex,
        speakerName: speakerName,
        timestamp: timestamp,
        text: text,
      ));
      _lastPartialText = '';
      _lastPartialId = '';
      // Restart immediately for continuous capture
      Future.delayed(const Duration(milliseconds: 150), _restartListen);
    } else {
      // Only emit partials when text actually changes — prevents repeat flooding
      if (text == _lastPartialText) return;
      _lastPartialText = text;
      if (_lastPartialId.isEmpty) _lastPartialId = _uuid.v4();
      _partialStream.add(TranscriptSegment(
        id: _lastPartialId,
        speakerIndex: speakerIndex,
        speakerName: speakerName,
        timestamp: timestamp,
        text: text,
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────

  void _startTimestampTracking() {
    _currentTimestamp = Duration.zero;
    _timestampTimer?.cancel();
    _timestampTimer = Timer.periodic(WrapdConfig.waveformUpdateInterval, (_) {
      _currentTimestamp += WrapdConfig.waveformUpdateInterval;
    });
  }

  void _handleError(String msg) {
    _errorStream.add(msg);
    _statusStream.add(TranscriptionStatus.error);
  }

  void _handleStatusChange(String status) {
    // Engine stopped but session is still active — restart listen loop
    if ((status == 'notListening' || status == 'done') && _shouldKeepListening) {
      Future.delayed(const Duration(milliseconds: 200), _restartListen);
    }
    const statusMap = {
      'listening': TranscriptionStatus.listening,
      'notListening': TranscriptionStatus.stopped,
      'done': TranscriptionStatus.completed,
      'done_no_match': TranscriptionStatus.noMatch,
    };
    _statusStream.add(statusMap[status] ?? TranscriptionStatus.unknown);
  }

  void dispose() {
    _shouldKeepListening = false;
    _speech.cancel();
    _timestampTimer?.cancel();
    _transcriptStream.close();
    _partialStream.close();
    _errorStream.close();
    _statusStream.close();
  }
}

enum TranscriptionStatus {
  uninitialized, ready, listening, listeningOffline,
  paused, stopped, completed, noMatch, error, unknown,
}
