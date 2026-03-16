// ─────────────────────────────────────────────────────────
//  AudioService — Real microphone recording engine
//  Handles audio capture, file management, and waveform processing
// ─────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_session.dart';
import '../config/wrapd_config.dart';
import 'logger_service.dart';

enum RecordingState {
  idle,
  starting,
  recording,
  stopping,
  paused,
  error
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Core recording components
  late final AudioRecorder _recorder;
  String? _recordingsDirectory;
  
  // Recording state
  RecordingState _recordingState = RecordingState.idle;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Timer? _waveformTimer;
  Duration _recordingDuration = Duration.zero;
  
  // Waveform processing
  List<double> _waveformData = [];
  double _maxAmplitude = 0.0;
  
  // Listeners for UI updates
  final StreamController<RecordingState> _stateController = 
      StreamController<RecordingState>.broadcast();
  final StreamController<Duration> _durationController = 
      StreamController<Duration>.broadcast();
  final StreamController<List<double>> _waveformController = 
      StreamController<List<double>>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  final StreamController<List<double>> _waveformFullController = 
      StreamController<List<double>>.broadcast();

  // Public streams for UI consumption
  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<List<double>> get waveformStream => _waveformController.stream;
  Stream<List<double>> get waveformFullStream => _waveformFullController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  RecordingState get currentState => _recordingState;
  Duration get currentDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the audio service and recording directories
  Future<void> initialize() async {
    try {
      _recorder = AudioRecorder();
      
      if (!kIsWeb) {
        // Get application documents directory (Native only)
        final appDir = await getApplicationDocumentsDirectory();
        _recordingsDirectory = '${appDir.path}/recordings';
        
        // Create recordings directory if it doesn't exist
        final dir = io.Directory(_recordingsDirectory!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      
      _updateState(RecordingState.idle);
    } catch (e) {
      WrapdLogger.e('AudioService initialization error', e);
      _updateState(RecordingState.error);
    }
  }

  /// Start a new recording session
  Future<String?> startRecording() async {
    if (_recordingState != RecordingState.idle && 
        _recordingState != RecordingState.paused) {
      return null;
    }

    try {
      _updateState(RecordingState.starting);
      
      if (kIsWeb) {
        // Web: pass null path — empty string throws on some browsers
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: '',
        );
        _currentRecordingPath = 'web_recording.webm';
      } else {
        // Native: use file system
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'recording_$timestamp.aac';
        _currentRecordingPath = '$_recordingsDirectory/$filename';
        
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
          ),
          path: _currentRecordingPath!,
        );
      }
      
      // Start timer for duration tracking
      _startRecordingTimer();
      
      // Start waveform processing
      _startWaveformProcessing();
      
      _updateState(RecordingState.recording);
      return _currentRecordingPath;
    } catch (e) {
      WrapdLogger.e('Recording start error', e);
      _updateState(RecordingState.error);
      return null;
    }
  }

  /// Stop the current recording
  Future<String?> stopRecording() async {
    if (_recordingState != RecordingState.recording && 
        _recordingState != RecordingState.paused) {
      return null;
    }

    try {
      _updateState(RecordingState.stopping);
      
      // Stop waveform processing first
      _stopWaveformProcessing();
      
      // Stop the timer
      _recordingTimer?.cancel();
      
      // Stop recording and get path
      final path = await _recorder.stop();
      if (path != null) {
        _currentRecordingPath = path;
      }
      
      // Finalize waveform data (Native only for FFmpeg)
      if (!kIsWeb) {
        await _finalizeWaveformData();
      }
      
      // Capture path BEFORE resetting state
      final savedPath = _currentRecordingPath;
      
      // Reset state
      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;
      _waveformData.clear();
      
      _updateState(RecordingState.idle);
      return savedPath;
    } catch (e) {
      WrapdLogger.e('Recording stop error', e);
      _updateState(RecordingState.error);
      return null;
    }
  }

  /// Pause the current recording
  Future<bool> pauseRecording() async {
    if (_recordingState != RecordingState.recording) {
      return false;
    }

    try {
      await _recorder.pause();
      _recordingTimer?.cancel();
      _stopWaveformProcessing();
      
      _updateState(RecordingState.paused);
      return true;
    } catch (e) {
      WrapdLogger.e('Recording pause error', e);
      _updateState(RecordingState.error);
      return false;
    }
  }

  /// Resume a paused recording
  Future<bool> resumeRecording() async {
    if (_recordingState != RecordingState.paused) {
      return false;
    }

    try {
      await _recorder.resume();
      _startRecordingTimer();
      _startWaveformProcessing();
      
      _updateState(RecordingState.recording);
      return true;
    } catch (e) {
      WrapdLogger.e('Recording resume error', e);
      _updateState(RecordingState.error);
      return false;
    }
  }

  /// Start recording timer for duration updates
  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDuration += const Duration(seconds: 1);
      _durationController.add(_recordingDuration);
    });
  }

  /// Process audio data for waveform visualization
  void _startWaveformProcessing() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(WrapdConfig.waveformUpdateInterval, (_) async {
      if (_recordingState == RecordingState.recording) {
        try {
          // Get current amplitude for real-time visualization
          final amplitude = await _recorder.getAmplitude();
          final normalizedAmplitude = (amplitude.current + 160).clamp(0.0, 160.0) / 160.0;
          _amplitudeController.add(normalizedAmplitude);
          
          // Update waveform data
          _updateWaveform(normalizedAmplitude);
        } catch (e) {
          // Ignore amplitude errors during recording
        }
      }
    });
  }

  /// Stop waveform processing
  void _stopWaveformProcessing() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
  }

  /// Update waveform data with new amplitude value
  void _updateWaveform(double amplitude) {
    // Add to waveform buffer
    _waveformData.add(amplitude);
    
    // Keep waveform data manageable
    if (_waveformData.length > WrapdConfig.waveformBufferLength) {
      _waveformData.removeAt(0);
    }
    
    // Update max amplitude for scaling
    if (amplitude > _maxAmplitude) {
      _maxAmplitude = amplitude;
    }
    
    _waveformController.add(_waveformData);
  }

  /// Finalize waveform data after recording completes
  Future<void> _finalizeWaveformData() async {
    if (_currentRecordingPath == null || kIsWeb) return;
    
    try {
      // Extract waveform data using FFmpeg
      final outputPath = '${_currentRecordingPath!}.waveform.txt';
      final command = '-i "${_currentRecordingPath!}" -af "astats=metadata=1:reset=1,ametadata=print:file=\'$outputPath\'" -f null -';
      
      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (returnCode != null && returnCode.isValueSuccess()) {
          final file = io.File(outputPath);
          if (await file.exists()) {
            final lines = await file.readAsLines();
            final List<double> fullWaveform = [];
            for (var line in lines) {
              if (line.contains('RMS_level')) {
                final value = double.tryParse(line.split('=').last) ?? -60.0;
                fullWaveform.add((value + 60).clamp(0.0, 60.0) / 60.0);
              }
            }
            _waveformFullController.add(fullWaveform);
            await file.delete(); // Cleanup
          }
        }
      });
    } catch (e) {
      WrapdLogger.e('Waveform finalization error', e);
    }
  }

  /// Update state and notify listeners
  void _updateState(RecordingState newState) {
    _recordingState = newState;
    _stateController.add(newState);
  }

  /// Get current amplitude for UI feedback
  Future<double?> getCurrentAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      return (amplitude.current + 160).clamp(0.0, 160.0) / 160.0;
    } catch (e) {
      return null;
    }
  }

  /// Check if recording permissions are granted
  Future<bool> hasRecordingPermission() async {
    return await _recorder.hasPermission();
  }

  /// Request recording permissions
  /// FIXED: was calling hasPermission() which never triggers the system dialog.
  /// Now properly requests via permission_handler so the user sees the prompt.
  Future<bool> requestPermission() async {
    // Web permissions are requested by the browser on first mic use.
    // permission_handler is inconsistent on web, so rely on recorder APIs.
    if (kIsWeb) {
      try {
        return await _recorder.hasPermission();
      } catch (_) {
        return true;
      }
    }

    // First check if already granted
    if (await _recorder.hasPermission()) return true;

    // Not granted — show the system permission dialog
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;

    // Permanently denied — user must go to Settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  /// Clean up resources
  Future<void> dispose() async {
    // Stop any active recording
    if (_recordingState == RecordingState.recording || 
        _recordingState == RecordingState.paused) {
      await stopRecording();
    }
    
    _recordingTimer?.cancel();
    _waveformTimer?.cancel();
    
    // Close streams
    await _stateController.close();
    await _durationController.close();
    await _waveformController.close();
    await _amplitudeController.close();
    await _waveformFullController.close();
    
    // Dispose recorder
    await _recorder.dispose();
  }
}
