import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

// ─────────────────────────────────────────────────────────
//  AudioProvider — Audio playback and waveform management
// ─────────────────────────────────────────────────────────

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<double> _waveformData = [];
  String? _currentAudioPath;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioProvider() {
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  // ── Reads ──────────────────────────────────────────────
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  List<double> get waveformData => List.unmodifiable(_waveformData);

  // ── Audio Controls ───────────────────────────────────
  Future<void> loadAudio(String audioPath) async {
    if (_currentAudioPath == audioPath && _waveformData.isNotEmpty) {
      return;
    }

    _currentAudioPath = audioPath;
    await _audioPlayer.setFilePath(audioPath);
    
    // Generate mock waveform data (in a real app, you'd use actual audio processing)
    _generateWaveformData();
    notifyListeners();
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToPosition(double progress) async {
    if (_duration.inMilliseconds > 0) {
      final position = Duration(milliseconds: (_duration.inMilliseconds * progress).round());
      await seek(position);
    }
  }

  Future<void> skipBackward() async {
    final newMs = position.inMilliseconds - 15000;
    final clampedMs = newMs.clamp(0, duration.inMilliseconds);
    await seek(Duration(milliseconds: clampedMs));
  }

  Future<void> skipForward() async {
    final newMs = position.inMilliseconds + 15000;
    final clampedMs = newMs.clamp(0, duration.inMilliseconds);
    await seek(Duration(milliseconds: clampedMs));
  }

  void setPlaybackSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  // ── Waveform Data Generation ──────────────────────────
  void _generateWaveformData() {
    // For demo purposes, generate realistic waveform-like data
    // In a real app, you'd use a library like audiowaveform to extract real data
    final sim = _WaveformSimulator(DateTime.now().millisecondsSinceEpoch);
    _waveformData = List.generate(120, (_) => sim.nextDouble() * 0.8 + 0.2);
  }

  // Update waveform data (could be called with real audio analysis)
  void updateWaveformData(List<double> data) {
    _waveformData = data;
    notifyListeners();
  }

  // ── Cleanup ────────────────────────────────────────────
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Simple pseudo-random generator for consistent waveform-like patterns.
/// Named to avoid shadowing dart:math.Random.
class _WaveformSimulator {
  int _state;
  
  _WaveformSimulator(this._state);
  
  double nextDouble() {
    _state = (_state * 9301 + 49297) % 233280;
    return _state / 233280.0;
  }
}

