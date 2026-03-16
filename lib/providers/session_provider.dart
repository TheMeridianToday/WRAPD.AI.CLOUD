import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../services/storage_service.dart';
import '../services/voice_diarization_service.dart';

// ─────────────────────────────────────────────────────────
//  SessionProvider — App-wide state for sessions
// ─────────────────────────────────────────────────────────

class SessionProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<WrapdSession> _sessions = [];
  WrapdSession? _activeSession;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  
  String _userName = 'User';
  bool _isPro = false;
  String _searchQuery = '';
  bool _isLoading = false;
  String _selectedLanguage = 'en_US';
  bool _speakerIdEnabled = true;
  bool _autoPunctuationEnabled = true;

  SessionProvider() {
    _loadInitialData();
  }

  /// Load persisted data on initialization
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    
    _sessions = _storage.loadSessions();
    _userName = _storage.loadUserName();
    _isPro = _storage.loadProStatus();
    _selectedLanguage = _storage.loadLanguage();
    _speakerIdEnabled = _storage.loadSpeakerIdEnabled();
    _autoPunctuationEnabled = _storage.loadAutoPunctuationEnabled();
    voiceRecognitionService.setEnabled(_speakerIdEnabled);
    
    _isLoading = false;
    notifyListeners();
  }

  // ── Reads ──────────────────────────────────────────────
  List<WrapdSession> get sessions => List.unmodifiable(_sessions);
  WrapdSession? get activeSession => _activeSession;
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  String get userName => _userName;
  bool get isPro => _isPro;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;
  bool get speakerIdEnabled => _speakerIdEnabled;
  bool get autoPunctuationEnabled => _autoPunctuationEnabled;

  List<WrapdSession> get filteredSessions {
    return _sessions.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.segments.any((seg) => seg.text.toLowerCase().contains(_searchQuery.toLowerCase()));
      return !s.isArchived && matchesSearch;
    }).toList();
  }

  List<WrapdSession> get archivedSessions =>
      _sessions.where((s) => s.isArchived).toList();

  List<WrapdSession> get readySessions =>
      _sessions.where((s) => s.status == SessionStatus.ready).toList();

  // ── User Settings ──────────────────────────────────────
  void setUserName(String name) {
    _userName = name;
    _storage.saveUserName(name);
    notifyListeners();
  }

  void setProStatus(bool isPro) {
    _isPro = isPro;
    _storage.saveProStatus(isPro);
    notifyListeners();
  }

  void setLanguage(String code) {
    _selectedLanguage = code;
    _storage.saveLanguage(code);
    notifyListeners();
  }

  void setSpeakerIdEnabled(bool enabled) {
    _speakerIdEnabled = enabled;
    _storage.saveSpeakerIdEnabled(enabled);
    voiceRecognitionService.setEnabled(enabled);
    notifyListeners();
  }

  void setAutoPunctuationEnabled(bool enabled) {
    _autoPunctuationEnabled = enabled;
    _storage.saveAutoPunctuationEnabled(enabled);
    notifyListeners();
  }

  // ── Search ─────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Session CRUD ───────────────────────────────────────
  void setActiveSession(String id) {
    if (_sessions.isEmpty) return;
    _activeSession =
        _sessions.firstWhere((s) => s.id == id, orElse: () => _sessions.first);
    notifyListeners();
    _storage.saveSessions(_sessions);
  }

  void addSession(WrapdSession session) {
    _sessions.insert(0, session);
    notifyListeners();
  }

  void updateSession(WrapdSession updated) {
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _sessions[idx] = updated;
      if (_activeSession?.id == updated.id) {
        _activeSession = updated;
      }
      _storage.saveSession(updated);
      notifyListeners();
    }
  }

  void renameSession(String id, String newTitle) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sessions[idx] = _sessions[idx].copyWith(title: newTitle);
      if (_activeSession?.id == id) {
        _activeSession = _sessions[idx];
      }
      notifyListeners();
      _storage.saveSession(_sessions[idx]);
    }
  }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    if (_activeSession?.id == id) {
      _activeSession = _sessions.isNotEmpty ? _sessions.first : null;
    }
    notifyListeners();
    _storage.deleteSession(id);
  }

  void undoDelete(WrapdSession session) {
    _sessions.insert(0, session);
    _storage.saveSession(session);
    notifyListeners();
  }

  void toggleArchive(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = _sessions[idx].copyWith(isArchived: !_sessions[idx].isArchived);
      _sessions[idx] = updated;
      if (_activeSession?.id == id) _activeSession = updated;
      _storage.saveSession(updated);
      notifyListeners();
    }
  }

  // ── Recording State ────────────────────────────────────
  void startRecording() {
    _isRecording = true;
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  void tickDuration(Duration delta) {
    _recordingDuration += delta;
    notifyListeners();
  }

  void stopRecording(WrapdSession newSession) {
    _storage.saveSession(newSession);
    _isRecording = false;
    addSession(newSession);
    _activeSession = newSession;
    notifyListeners();
  }

  // ── Synthesis Messages ─────────────────────────────────
  void addSynthesisMessage(String sessionId, SynthesisMessage message) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final updated = _sessions[idx].copyWith(
        messages: [..._sessions[idx].messages, message],
      );
      updateSession(updated);
    }
  }

  /// Update the text of an existing synthesis message in-place (for streaming tokens)
  void updateSynthesisMessage(String sessionId, String messageId, String newText) {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final messages = _sessions[idx].messages.map((m) {
        return m.id == messageId
            ? SynthesisMessage(id: m.id, isUser: m.isUser, text: newText, chips: m.chips)
            : m;
      }).toList();
      _sessions[idx] = _sessions[idx].copyWith(messages: messages);
      if (_activeSession?.id == sessionId) {
        _activeSession = _sessions[idx];
      }
      notifyListeners();
    }
  }

  // ── Audio Player Control ───────────────────────────────
  void seekToTimestamp(String sessionId, Duration timestamp) {
    final session = _sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session != null && session.duration.inSeconds > 0) {
      // Calculate the slider value based on timestamp
      final totalSeconds = session.duration.inSeconds;
      final seekSeconds = timestamp.inSeconds;
      
      if (seekSeconds <= totalSeconds) {
        notifyListeners();
      }
    }
  }
}
