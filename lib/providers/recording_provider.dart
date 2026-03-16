import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/voice_diarization_service.dart';
import '../models/session_model.dart';

// ─────────────────────────────────────────────────────────
//  RecordingProvider
//  Fixed:
//  • Subscribes to partialStream — updates segment in-place (no duplicates)
//  • Audio + transcription both use device microphone; started together
//  • Speaker index forwarded immediately to transcription service
// ─────────────────────────────────────────────────────────

class RecordingProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final VoiceRecognitionService _voiceRecognitionService =
      VoiceRecognitionService();

  RecordingState _recordingState = RecordingState.idle;
  TranscriptionStatus _transcriptionStatus = TranscriptionStatus.uninitialized;
  Duration _duration = Duration.zero;
  // Mutable list — we update entries in-place for partials
  final List<TranscriptSegment> _segments = [];
  List<double> _waveform = [];
  String? _currentPath;

  StreamSubscription? _stateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _transcriptSub;
  StreamSubscription? _partialSub;
  StreamSubscription? _waveformSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _amplitudeSub;
  StreamSubscription? _speakerDetectedSub;
  StreamSubscription? _errorSub;

  String _lastError = '';
  late final Future<void> _initialized;

  RecordingProvider() {
    _initialized = _init();
  }

  Future<void> _init() async {
    await _audioService.initialize();
    await _voiceRecognitionService.initialize();

    _stateSub = _audioService.stateStream.listen((state) {
      _recordingState = state;
      notifyListeners();
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _waveformSub = _audioService.waveformStream.listen((data) {
      _waveform = data;
      notifyListeners();
    });

    _amplitudeSub = _audioService.amplitudeStream.listen((amplitude) {
      _voiceRecognitionService.processAmplitudeSample(amplitude);
    });

    // Final committed segments
    _transcriptSub = _transcriptionService.transcriptStream.listen((segment) {
      final idx = _segments.indexWhere((s) => s.id == segment.id);
      if (idx != -1) {
        _segments[idx] = segment;
      } else {
        _segments.add(segment);
      }
      notifyListeners();
    });

    // Partial results — update in-place so UI feels instant
    _partialSub = _transcriptionService.partialStream.listen((segment) {
      final idx = _segments.indexWhere((s) => s.id == segment.id);
      if (idx != -1) {
        _segments[idx] = segment;
      } else {
        _segments.add(segment);
      }
      notifyListeners();
    });

    _statusSub = _transcriptionService.statusStream.listen((status) {
      _transcriptionStatus = status;
      notifyListeners();
    });

    _errorSub = _transcriptionService.errorStream.listen((message) {
      _lastError = message;
      notifyListeners();
    });

    _speakerDetectedSub =
        _voiceRecognitionService.detectedSpeakerStream.listen((speakerIndex) {
      _transcriptionService.setSpeakerIndex(speakerIndex);
      notifyListeners();
    });
  }

  // ── Getters ────────────────────────────────────────────
  RecordingState get recordingState => _recordingState;
  TranscriptionStatus get transcriptionStatus => _transcriptionStatus;
  Duration get duration => _duration;
  List<TranscriptSegment> get segments => List.unmodifiable(_segments);
  List<double> get waveform => List.unmodifiable(_waveform);
  bool get isRecording => _recordingState == RecordingState.recording;
  bool get isPaused => _recordingState == RecordingState.paused;
  String? get currentAudioPath => _currentPath;
  String get lastError => _lastError;

  // ── Actions ────────────────────────────────────────────

  Future<bool> start() async {
    await _initialized;
    _lastError = '';
    _segments.clear();
    _waveform = [];
    _duration = Duration.zero;
    _currentPath = null;

    if (kIsWeb) {
      // Browser speech recognition is the primary goal on web.
      final startedTranscription =
          await _transcriptionService.startTranscription();
      if (!startedTranscription) {
        _lastError = 'Speech recognition could not start in this browser.';
        return false;
      }

      // Do not start recorder on web during live STT.
      // Opening a second mic consumer can starve browser speech recognition.
      _currentPath = null;

      await _voiceRecognitionService.startDiarization(useStandaloneMic: false);
      return true;
    }

    // Native: request mic permission first, then start recorder and STT.
    final hasPermission = await _audioService.requestPermission();
    if (!hasPermission) {
      _lastError = 'Microphone permission denied.';
      return false;
    }

    _currentPath = await _audioService.startRecording();
    if (_currentPath == null) {
      _lastError = 'Could not start audio recording.';
      return false;
    }

    await _voiceRecognitionService.startDiarization(useStandaloneMic: false);

    final startedTranscription = await _transcriptionService.startTranscription();
    if (!startedTranscription) {
      await _voiceRecognitionService.stopDiarization();
      await _audioService.stopRecording();
      _currentPath = null;
      _lastError = 'Speech recognition could not start.';
      return false;
    }
    return true;
  }

  Future<void> pause() async {
    await _initialized;
    await _audioService.pauseRecording();
    await _transcriptionService.pauseTranscription();
  }

  Future<void> resume() async {
    await _initialized;
    await _audioService.resumeRecording();
    await _transcriptionService.resumeTranscription();
  }

  Future<String?> stop() async {
    await _initialized;
    final path = await _audioService.stopRecording();
    await _voiceRecognitionService.stopDiarization();
    await _transcriptionService.stopTranscription();
    // Keep the path accessible for the session builder
    if (path != null) _currentPath = path;
    return _currentPath;
  }

  /// Rename a speaker — also retroactively updates existing segments in the list.
  void setSpeakerName(int index, String name) {
    _transcriptionService.setSpeakerName(index, name);
    _voiceRecognitionService.setSpeakerDisplayName(index, name);
    for (int i = 0; i < _segments.length; i++) {
      if (_segments[i].speakerIndex == index) {
        _segments[i] = TranscriptSegment(
          id: _segments[i].id,
          speakerIndex: index,
          speakerName: name,
          timestamp: _segments[i].timestamp,
          text: _segments[i].text,
        );
      }
    }
    notifyListeners();
  }

  /// Switch active speaker — forwarded immediately to transcription service.
  void setSpeakerIndex(int index) {
    _voiceRecognitionService.overrideDetectedSpeaker(index);
    _transcriptionService.setSpeakerIndex(index);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationSub?.cancel();
    _transcriptSub?.cancel();
    _partialSub?.cancel();
    _waveformSub?.cancel();
    _statusSub?.cancel();
    _amplitudeSub?.cancel();
    _speakerDetectedSub?.cancel();
    _errorSub?.cancel();
    _audioService.dispose();
    _transcriptionService.dispose();
    super.dispose();
  }
}
