// ─────────────────────────────────────────────────────────
//  WRAPD — Storage Service (Hive-based)
//  Provides offline-first persistence for session and workflow data
// ─────────────────────────────────────────────────────────

import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_model.dart';
import '../models/workflow_model.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _sessionsBoxKey = 'sessions';
  static const String _workflowsBoxKey = 'workflows';
  static const String _themeBoxKey = 'theme';
  static const String _settingsBoxKey = 'settings';

  /// Initialize all storage boxes
  Future<void> initialize() async {
    await Hive.openBox<WrapdSession>(_sessionsBoxKey);
    await Hive.openBox<WorkflowPackage>(_workflowsBoxKey);
    await Hive.openBox<String>(_themeBoxKey);
    await Hive.openBox<dynamic>(_settingsBoxKey);
  }

  // ── Session Storage ─────────────────────────────────

  /// Save all sessions
  Future<void> saveSessions(List<WrapdSession> sessions) async {
    final box = Hive.box<WrapdSession>(_sessionsBoxKey);
    await box.clear();
    for (final session in sessions) {
      await box.put(session.id, session);
    }
  }

  /// Load all sessions
  List<WrapdSession> loadSessions() {
    final box = Hive.box<WrapdSession>(_sessionsBoxKey);
    return box.values.toList();
  }

  /// Save a single session
  Future<void> saveSession(WrapdSession session) async {
    final box = Hive.box<WrapdSession>(_sessionsBoxKey);
    await box.put(session.id, session);
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    final box = Hive.box<WrapdSession>(_sessionsBoxKey);
    await box.delete(sessionId);
  }

  // ── Workflow Storage ────────────────────────────────

  /// Save all workflow packages
  Future<void> saveWorkflows(List<WorkflowPackage> workflows) async {
    final box = Hive.box<WorkflowPackage>(_workflowsBoxKey);
    await box.clear();
    for (final workflow in workflows) {
      await box.put(workflow.id, workflow);
    }
  }

  /// Load all workflow packages
  List<WorkflowPackage> loadWorkflows() {
    final box = Hive.box<WorkflowPackage>(_workflowsBoxKey);
    return box.values.toList();
  }

  /// Save a single workflow package
  Future<void> saveWorkflow(WorkflowPackage package) async {
    final box = Hive.box<WorkflowPackage>(_workflowsBoxKey);
    await box.put(package.id, package);
  }

  /// Delete a workflow package
  Future<void> deleteWorkflow(String workflowId) async {
    final box = Hive.box<WorkflowPackage>(_workflowsBoxKey);
    await box.delete(workflowId);
  }

  // ── Theme Storage ───────────────────────────────────

  /// Save theme preference
  Future<void> saveThemePreference(bool isDark) async {
    final box = Hive.box<String>(_themeBoxKey);
    await box.put('theme', isDark ? 'dark' : 'light');
  }

  /// Load theme preference
  bool loadThemePreference() {
    final box = Hive.box<String>(_themeBoxKey);
    return box.get('theme', defaultValue: 'dark') == 'dark';
  }

  // ── User Settings ───────────────────────────────────

  /// Save user name
  Future<void> saveUserName(String name) async {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    await box.put('user_name', name);
  }

  /// Load user name
  String loadUserName() {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    return box.get('user_name', defaultValue: 'User') as String;
  }

  /// Save Pro status
  Future<void> saveProStatus(bool isPro) async {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    await box.put('is_pro', isPro);
  }

  /// Load Pro status
  bool loadProStatus() {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    return box.get('is_pro', defaultValue: false) as bool;
  }

  /// Save selected language
  Future<void> saveLanguage(String languageCode) async {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    await box.put('selected_language', languageCode);
  }

  /// Load selected language
  String loadLanguage() {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    return box.get('selected_language', defaultValue: 'en_US') as String;
  }

  /// Save Speaker ID setting
  Future<void> saveSpeakerIdEnabled(bool enabled) async {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    await box.put('speaker_id_enabled', enabled);
  }

  /// Load Speaker ID setting
  bool loadSpeakerIdEnabled() {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    return box.get('speaker_id_enabled', defaultValue: true) as bool;
  }

  /// Save Auto-Punctuation setting
  Future<void> saveAutoPunctuationEnabled(bool enabled) async {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    await box.put('auto_punctuation_enabled', enabled);
  }

  /// Load Auto-Punctuation setting
  bool loadAutoPunctuationEnabled() {
    final box = Hive.box<dynamic>(_settingsBoxKey);
    return box.get('auto_punctuation_enabled', defaultValue: true) as bool;
  }

  // ── Session-Workflow Mapping ───────────────────────

  /// Get workflows for a specific session
  List<WorkflowPackage> getWorkflowsForSession(String sessionId) {
    final allWorkflows = loadWorkflows();
    return allWorkflows.where((w) => w.sessionId == sessionId).toList();
  }

  /// Map workflows to sessions for provider initialization
  Map<String, List<WorkflowPackage>> getSessionWorkflowMap() {
    final allWorkflows = loadWorkflows();
    final Map<String, List<WorkflowPackage>> map = {};
    
    for (final workflow in allWorkflows) {
      map.putIfAbsent(workflow.sessionId, () => []).add(workflow);
    }
    
    return map;
  }
}
