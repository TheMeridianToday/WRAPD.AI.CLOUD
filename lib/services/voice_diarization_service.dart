import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:hive/hive.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../config/wrapd_config.dart';
import '../models/speaker_profile_model.dart';
import 'logger_service.dart';

class VoiceRecognitionService {
  static final VoiceRecognitionService _instance =
      VoiceRecognitionService._internal();
  factory VoiceRecognitionService() => _instance;
  VoiceRecognitionService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final Uuid _uuid = const Uuid();

  final Map<String, VoiceProfile> _speakerProfiles = {};
  final Map<String, String> _speakerIdentifiers = {};
  final Map<int, double> _speakerPitchBaseline = {};
  final Map<int, String> _speakerNames = {};

  final StreamController<SpeakerDiarizationResult> _diarizationStream =
      StreamController<SpeakerDiarizationResult>.broadcast();
  final StreamController<List<VoiceProfile>> _speakersStream =
      StreamController<List<VoiceProfile>>.broadcast();
  final StreamController<int> _detectedSpeakerStream =
      StreamController<int>.broadcast();

  Timer? _processingTimer;

  bool _isInitialized = false;
  bool _isEnabled = true;
  bool _useStandaloneMic = false;

  final int _maxSpeakers = WrapdConfig.maxSpeakers;
  final double _confidenceThreshold = WrapdConfig.confidenceThreshold;

  String? _currentSessionId;
  final List<SpeakerDiarizationResult> _currentSegments = [];
  final List<double> _amplitudeWindow = [];

  int _sampleCount = 0;
  int _currentDetectedSpeaker = 0;
  Duration _currentSegmentStart = Duration.zero;
  Duration _lastHeartbeatEmission = Duration.zero;
  DateTime? _lastSpeakerSwitchAt;
  DateTime? _manualOverrideUntil;

  Stream<SpeakerDiarizationResult> get diarizationStream =>
      _diarizationStream.stream;
  Stream<List<VoiceProfile>> get speakersStream => _speakersStream.stream;
  Stream<int> get detectedSpeakerStream => _detectedSpeakerStream.stream;

  List<VoiceProfile> get speakerProfiles => _speakerProfiles.values.toList();
  bool get isEnabled => _isEnabled;
  int get currentDetectedSpeaker => _currentDetectedSpeaker;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _loadSpeakerProfiles();
      _isInitialized = true;
      WrapdLogger.i('Voice recognition service initialized successfully');
      return true;
    } catch (e) {
      WrapdLogger.e('Failed to initialize voice recognition', e);
      return false;
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _manualOverrideUntil = null;
    }
  }

  Future<bool> startDiarization({bool useStandaloneMic = true}) async {
    if (!_isInitialized) return false;

    try {
      _resetTrackingState();
      _useStandaloneMic = useStandaloneMic;
      _currentSessionId = _uuid.v4();
      _detectedSpeakerStream.add(_currentDetectedSpeaker);

      if (_useStandaloneMic) {
        await _startStandaloneMonitoring();
      }

      WrapdLogger.i(
        'Speaker diarization started for session: $_currentSessionId',
      );
      return true;
    } catch (e) {
      WrapdLogger.e('Failed to start diarization', e);
      return false;
    }
  }

  Future<void> stopDiarization() async {
    _processingTimer?.cancel();
    _processingTimer = null;

    if (_useStandaloneMic) {
      try {
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
      } catch (_) {}
    }

    _emitCurrentSegment(confidence: 0.68);

    _currentSessionId = null;
    _amplitudeWindow.clear();
    _sampleCount = 0;
    _useStandaloneMic = false;

    WrapdLogger.i('Speaker diarization stopped');
  }

  void processAmplitudeSample(double amplitude) {
    if (!_isEnabled || _currentSessionId == null) return;

    _sampleCount++;
    _amplitudeWindow.add(amplitude);
    if (_amplitudeWindow.length > 5) {
      _amplitudeWindow.removeAt(0);
    }

    if (_amplitudeWindow.length < 5 || _sampleCount % 3 != 0) {
      return;
    }

    final pitchEstimate = _estimatePitchProxy(_amplitudeWindow);
    _processAmplitudeWindow(amplitude, pitchEstimate);
  }

  void overrideDetectedSpeaker(int index) {
    final clampedIndex = index.clamp(0, _maxSpeakers - 1) as int;
    _speakerPitchBaseline.putIfAbsent(clampedIndex, () {
      return _speakerPitchBaseline[_currentDetectedSpeaker] ?? 120.0;
    });

    if (clampedIndex != _currentDetectedSpeaker) {
      _emitCurrentSegment(confidence: 0.82);
      _currentDetectedSpeaker = clampedIndex;
      _currentSegmentStart = _currentElapsed;
      _detectedSpeakerStream.add(_currentDetectedSpeaker);
    }

    _manualOverrideUntil = DateTime.now().add(const Duration(seconds: 2));
  }

  void setSpeakerDisplayName(int index, String name) {
    if (name.trim().isEmpty) return;
    _speakerNames[index] = name.trim();
  }

  void addSpeakerProfile(VoiceProfile profile) {
    _speakerProfiles[profile.id] = profile;

    if (profile.voiceFeatures.isNotEmpty) {
      final featureKey = _generateFeatureKey(profile.voiceFeatures);
      _speakerIdentifiers[featureKey] = profile.id;
    }

    _notifySpeakersUpdate();
    _saveSpeakerProfiles();
  }

  void removeSpeakerProfile(String speakerId) {
    final profile = _speakerProfiles[speakerId];
    if (profile != null) {
      final featureKey = _generateFeatureKey(profile.voiceFeatures);
      _speakerIdentifiers.remove(featureKey);
    }

    _speakerProfiles.remove(speakerId);
    _notifySpeakersUpdate();
    _saveSpeakerProfiles();
  }

  String? identifySpeaker(List<double> voiceFeatures) {
    if (voiceFeatures.isEmpty) return null;

    final featureKey = _generateFeatureKey(voiceFeatures);
    if (_speakerIdentifiers.containsKey(featureKey)) {
      return _speakerIdentifiers[featureKey];
    }

    final bestMatch = _findBestMatch(voiceFeatures);
    return (bestMatch?.confidence ?? 0.0) > _confidenceThreshold
        ? bestMatch?.speakerId
        : null;
  }

  void renameSpeaker(String speakerId, String newName) {
    final profile = _speakerProfiles[speakerId];
    if (profile != null) {
      _speakerProfiles[speakerId] = profile.copyWith(name: newName);
      _notifySpeakersUpdate();
      _saveSpeakerProfiles();
    }
  }

  void mergeSpeakerProfiles(String targetId, String sourceId) {
    final targetProfile = _speakerProfiles[targetId];
    final sourceProfile = _speakerProfiles[sourceId];

    if (targetProfile != null && sourceProfile != null) {
      final mergedFeatures = _averageVoiceFeatures([
        targetProfile.voiceFeatures,
        sourceProfile.voiceFeatures,
      ]);

      targetProfile.updateVoiceProfile(
        mergedFeatures,
        targetProfile.voiceStatistics,
      );
      targetProfile.usageCount += sourceProfile.usageCount;

      removeSpeakerProfile(sourceId);
      _notifySpeakersUpdate();
    }
  }

  Future<String> exportSpeakerProfiles() async {
    final profilesJson = _speakerProfiles.values.map((p) => p.toJson()).toList();
    return jsonEncode(profilesJson);
  }

  void importSpeakerProfiles(String jsonData) {
    try {
      final profilesList = jsonDecode(jsonData) as List;

      for (final profileData in profilesList) {
        final profile = VoiceProfile.fromJson(
          profileData as Map<String, dynamic>,
        );
        addSpeakerProfile(profile);
      }

      WrapdLogger.i('Imported ${profilesList.length} speaker profiles');
    } catch (e) {
      WrapdLogger.e('Failed to import speaker profiles', e);
    }
  }

  Future<void> _startStandaloneMonitoring() async {
    if (!await _audioRecorder.hasPermission()) return;

    await _audioRecorder.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits),
    );

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(
      WrapdConfig.waveformUpdateInterval,
      (_) async {
        if (_currentSessionId == null) return;
        try {
          final amplitude = await _audioRecorder.getAmplitude();
          final normalizedAmplitude =
              ((amplitude.current + 160).clamp(0.0, 160.0) as double) / 160.0;
          processAmplitudeSample(normalizedAmplitude);
        } catch (e) {
          WrapdLogger.e('Standalone diarization amplitude error', e);
        }
      },
    );
  }

  void _resetTrackingState() {
    _processingTimer?.cancel();
    _currentSegments.clear();
    _amplitudeWindow.clear();
    _speakerPitchBaseline
      ..clear()
      ..[0] = 120.0;
    _sampleCount = 0;
    _currentDetectedSpeaker = 0;
    _currentSegmentStart = Duration.zero;
    _lastHeartbeatEmission = Duration.zero;
    _lastSpeakerSwitchAt = null;
    _manualOverrideUntil = null;
  }

  void _processAmplitudeWindow(double amplitude, double pitchEstimate) {
    final currentTime = _currentElapsed;

    if (pitchEstimate <= 0.0 || amplitude < 0.08) {
      _emitHeartbeat(currentTime, amplitude);
      return;
    }

    final currentBaseline =
        _speakerPitchBaseline[_currentDetectedSpeaker] ?? pitchEstimate;
    final delta = (pitchEstimate - currentBaseline).abs() /
        (currentBaseline.abs() + 0.001);

    if (_manualOverrideUntil != null &&
        DateTime.now().isBefore(_manualOverrideUntil!)) {
      _speakerPitchBaseline[_currentDetectedSpeaker] =
          _smoothBaseline(currentBaseline, pitchEstimate);
      _emitHeartbeat(currentTime, amplitude);
      return;
    }

    if (_canSwitchSpeaker(delta, amplitude)) {
      final matchedSpeaker = _findSpeakerByPitch(pitchEstimate);
      if (matchedSpeaker != _currentDetectedSpeaker) {
        _emitCurrentSegment(confidence: _confidenceForDelta(delta));
        _currentDetectedSpeaker = matchedSpeaker;
        _currentSegmentStart = currentTime;
        _lastSpeakerSwitchAt = DateTime.now();
        _detectedSpeakerStream.add(_currentDetectedSpeaker);
      }
    }

    final baseline =
        _speakerPitchBaseline[_currentDetectedSpeaker] ?? pitchEstimate;
    _speakerPitchBaseline[_currentDetectedSpeaker] =
        _smoothBaseline(baseline, pitchEstimate);

    _emitHeartbeat(currentTime, amplitude);
  }

  double _estimatePitchProxy(List<double> window) {
    final mean = window.reduce((a, b) => a + b) / window.length;
    final centered = window.map((sample) => sample - mean).toList();
    final energy = math.sqrt(
      centered.fold<double>(0.0, (sum, sample) => sum + (sample * sample)) /
          centered.length,
    );

    if (energy < 0.015) return 0.0;

    int zeroCrossings = 0;
    for (int i = 1; i < centered.length; i++) {
      if ((centered[i - 1] <= 0 && centered[i] > 0) ||
          (centered[i - 1] >= 0 && centered[i] < 0)) {
        zeroCrossings++;
      }
    }

    final variance = centered.fold<double>(
          0.0,
          (sum, sample) => sum + (sample * sample),
        ) /
        centered.length;

    final slopeEnergy = (() {
      if (window.length < 2) return 0.0;
      double total = 0.0;
      for (int i = 1; i < window.length; i++) {
        total += (window[i] - window[i - 1]).abs();
      }
      return total / (window.length - 1);
    })();

    final proxy = 85.0 +
        (zeroCrossings / math.max(1, window.length - 1)) * 120.0 +
        variance * 700.0 +
        slopeEnergy * 180.0;

    return (proxy.clamp(75.0, 320.0) as num).toDouble();
  }

  bool _canSwitchSpeaker(double delta, double amplitude) {
    if (delta <= 0.15 || amplitude <= 0.10) return false;
    if (_lastSpeakerSwitchAt == null) return true;
    return DateTime.now().difference(_lastSpeakerSwitchAt!) >
        const Duration(milliseconds: 1200);
  }

  int _findSpeakerByPitch(double pitchEstimate) {
    if (_speakerPitchBaseline.isEmpty) {
      _speakerPitchBaseline[0] = pitchEstimate;
      return 0;
    }

    double bestDelta = double.infinity;
    int bestSpeaker = _currentDetectedSpeaker;

    for (final entry in _speakerPitchBaseline.entries) {
      final delta =
          (pitchEstimate - entry.value).abs() / (entry.value.abs() + 0.001);
      if (delta < bestDelta) {
        bestDelta = delta;
        bestSpeaker = entry.key;
      }
    }

    if (bestDelta <= 0.12) {
      return bestSpeaker;
    }

    for (int idx = 0; idx < _maxSpeakers; idx++) {
      if (!_speakerPitchBaseline.containsKey(idx)) {
        _speakerPitchBaseline[idx] = pitchEstimate;
        return idx;
      }
    }

    return bestSpeaker;
  }

  double _smoothBaseline(double baseline, double pitchEstimate) {
    return (baseline * 0.9) + (pitchEstimate * 0.1);
  }

  double _confidenceForDelta(double delta) {
    return ((0.92 - delta).clamp(0.55, 0.9) as num).toDouble();
  }

  Duration get _currentElapsed => Duration(
        milliseconds:
            _sampleCount * WrapdConfig.waveformUpdateInterval.inMilliseconds,
      );

  void _emitHeartbeat(Duration currentTime, double amplitude) {
    if (currentTime - _lastHeartbeatEmission <
        const Duration(milliseconds: 1500)) {
      return;
    }

    final end = currentTime;
    final start = end > const Duration(milliseconds: 600)
        ? end - const Duration(milliseconds: 600)
        : Duration.zero;
    final confidence =
        ((0.45 + (amplitude * 0.35)).clamp(0.45, 0.74) as num).toDouble();

    _emitSegment(
      speakerIndex: _currentDetectedSpeaker,
      start: start,
      end: end,
      confidence: confidence,
    );
    _lastHeartbeatEmission = currentTime;
  }

  void _emitCurrentSegment({required double confidence}) {
    final end = _currentElapsed;
    _emitSegment(
      speakerIndex: _currentDetectedSpeaker,
      start: _currentSegmentStart,
      end: end,
      confidence: confidence,
    );
    _currentSegmentStart = end;
  }

  void _emitSegment({
    required int speakerIndex,
    required Duration start,
    required Duration end,
    required double confidence,
  }) {
    if (end.compareTo(start) <= 0) return;

    final result = SpeakerDiarizationResult(
      speakerId: 'speaker_${speakerIndex + 1}',
      speakerName: _speakerNames[speakerIndex] ?? 'Speaker ${speakerIndex + 1}',
      startTime: start,
      endTime: end,
      confidence: confidence,
    );

    _currentSegments.add(result);
    _diarizationStream.add(result);
  }

  String _generateFeatureKey(List<double> features) {
    return features.take(10).map((f) => f.toStringAsFixed(3)).join('_');
  }

  SpeakerMatch? _findBestMatch(List<double> targetFeatures) {
    if (_speakerProfiles.isEmpty) return null;

    double bestSimilarity = 0.0;
    String? bestSpeakerId;

    for (final profile in _speakerProfiles.values) {
      final similarity = _calculateCosineSimilarity(
        targetFeatures,
        profile.voiceFeatures,
      );
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestSpeakerId = profile.id;
      }
    }

    return SpeakerMatch(
      speakerId: bestSpeakerId,
      confidence: bestSimilarity,
    );
  }

  double _calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  List<double> _averageVoiceFeatures(List<List<double>> featuresList) {
    if (featuresList.isEmpty) return [];

    final result = List<double>.filled(featuresList.first.length, 0.0);
    for (final features in featuresList) {
      for (int i = 0; i < features.length; i++) {
        result[i] += features[i];
      }
    }

    return result.map((value) => value / featuresList.length).toList();
  }

  void _notifySpeakersUpdate() {
    _speakersStream.add(speakerProfiles);
  }

  Future<void> _saveSpeakerProfiles() async {
    try {
      final box = await Hive.openBox<VoiceProfile>('speaker_profiles');
      await box.clear();
      for (final profile in _speakerProfiles.values) {
        await box.put(profile.id, profile);
      }
    } catch (e) {
      WrapdLogger.e('Failed to save speaker profiles', e);
    }
  }

  Future<void> _loadSpeakerProfiles() async {
    try {
      final box = await Hive.openBox<VoiceProfile>('speaker_profiles');
      _speakerProfiles.clear();
      for (final profile in box.values) {
        _speakerProfiles[profile.id] = profile;
        if (profile.voiceFeatures.isNotEmpty) {
          final featureKey = _generateFeatureKey(profile.voiceFeatures);
          _speakerIdentifiers[featureKey] = profile.id;
        }
      }
      _notifySpeakersUpdate();
    } catch (e) {
      WrapdLogger.e('Failed to load speaker profiles', e);
    }
  }

  void dispose() {
    _processingTimer?.cancel();
    _diarizationStream.close();
    _speakersStream.close();
    _detectedSpeakerStream.close();
    _audioRecorder.dispose();
  }
}

class SpeakerMatch {
  final String? speakerId;
  final double confidence;

  SpeakerMatch({required this.speakerId, required this.confidence});
}

final VoiceRecognitionService voiceRecognitionService = VoiceRecognitionService();
