// ─────────────────────────────────────────────────────────
//  WRAPD — WORKFLOW AUTOMATION PROVIDER
//  Managing "Final Stop" workflow actions - Feb 26 2026
//  Added by: AI Analysis for holding company valuation
// ─────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import '../models/workflow_model.dart';
import '../models/session_model.dart';

import '../services/storage_service.dart';

class WorkflowProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<WorkflowPackage> _packages = [];
  Map<String, List<WorkflowPackage>> _sessionWorkflows = {};

  WorkflowProvider() {
    _loadInitialData();
  }

  /// Load persisted workflows on initialization
  Future<void> _loadInitialData() async {
    _packages = _storage.loadWorkflows();
    _sessionWorkflows = _storage.getSessionWorkflowMap();
    notifyListeners();
  }

  // ── Reads ──────────────────────────────────────────────
  List<WorkflowPackage> get packages => List.unmodifiable(_packages);
  
  List<WorkflowPackage> getSessionWorkflows(String sessionId) =>
      List.unmodifiable(_sessionWorkflows[sessionId] ?? []);

  /// Get all packages for a specific session that are incomplete
  List<WorkflowPackage> getPendingWorkflows(String sessionId) =>
      getSessionWorkflows(sessionId).where((pkg) => !pkg.isComplete).toList();

  /// Get all workflows completed today
  List<WorkflowPackage> getTodaysCompletedWorkflows() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _packages.where((pkg) => 
        pkg.completedAt != null && 
        pkg.completedAt!.isAfter(startOfDay)
    ).toList();
  }

  /// Get statistics for workflow automation
  WorkflowStats get stats => WorkflowStats(
    totalPackages: _packages.length,
    completedPackages: _packages.where((pkg) => pkg.isComplete).length,
    todayCompleted: getTodaysCompletedWorkflows().length,
    totalActions: _packages.expand((pkg) => pkg.actions).length,
    completedActions: _packages
        .expand((pkg) => pkg.actions)
        .where((action) => action.isCompleted).length,
  );

  // ── Workflow Package Management ───────────────────────
  
  /// Create a new workflow package from a WrapdSession
  WorkflowPackage createWorkflowFromSession(WrapdSession session) {
    final package = _generateWorkflowPackage(session);
    _packages.add(package);
    _sessionWorkflows.putIfAbsent(session.id, () => []).add(package);
    
    _storage.saveWorkflow(package);
    notifyListeners();
    return package;
  }

  /// Update a specific workflow package
  void updateWorkflow(WorkflowPackage updated) {
    final packageIndex = _packages.indexWhere((pkg) => pkg.id == updated.id);
    if (packageIndex != -1) {
      _packages[packageIndex] = updated;
      
      // Update in session workflows too
      final sessionWorkflows = _sessionWorkflows[updated.sessionId];
      if (sessionWorkflows != null) {
        final sessionIndex = sessionWorkflows.indexWhere((pkg) => pkg.id == updated.id);
        if (sessionIndex != -1) {
          sessionWorkflows[sessionIndex] = updated;
        }
      }
      
      _storage.saveWorkflow(updated);
      notifyListeners();
    }
  }

  /// Complete a specific workflow action
  void completeAction(String packageId, String actionId) {
    final package = _packages.firstWhere((pkg) => pkg.id == packageId);
    final updatedActions = package.actions.map((action) {
      if (action.id == actionId) {
        return action.complete();
      }
      return action;
    }).toList();

    final updatedPackage = package.copyWith(
      actions: updatedActions,
      completedAt: updatedActions.every((a) => a.isCompleted) 
          ? DateTime.now() 
          : null,
    );

    updateWorkflow(updatedPackage);
  }

  void failAction(String packageId, String actionId, String error) {
    final package = _packages.firstWhere((pkg) => pkg.id == packageId);
    final updatedActions = package.actions.map((action) {
      if (action.id == actionId) {
        return action.fail(error);
      }
      return action;
    }).toList();
    
    updateWorkflow(package.copyWith(actions: updatedActions));
  }

  void setTargetApp(String packageId, String actionId, String appName) {
    final package = _packages.firstWhere((pkg) => pkg.id == packageId);
    final updatedActions = package.actions.map((action) {
      if (action.id == actionId) {
        return action.copyWith(targetApp: appName);
      }
      return action;
    }).toList();
    
    updateWorkflow(package.copyWith(actions: updatedActions));
  }

  /// Delete a workflow package
  void deleteWorkflow(String packageId) {
    _packages.removeWhere((pkg) => pkg.id == packageId);
    
    // Remove from session workflows
    for (final sessionId in _sessionWorkflows.keys) {
      _sessionWorkflows[sessionId]?.removeWhere((pkg) => pkg.id == packageId);
      if (_sessionWorkflows[sessionId]?.isEmpty == true) {
        _sessionWorkflows.remove(sessionId);
      }
    }
    
    _storage.deleteWorkflow(packageId);
    notifyListeners();
  }

  // ── AI Workflow Generation ─────────────────────────────

  /// Generate workflow actions based on meeting content
  List<WorkflowAction> generateWorkflowActions(WrapdSession session) {
    final actions = <WorkflowAction>[];
    final sessionTitle = session.title;

    // Base actions for any meeting
    actions.add(WorkflowAction.calendar(
      id: 'cal-${session.id}-followup',
      title: 'Follow-up: $sessionTitle',
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      description: 'Follow-up meeting from ${session.title}',
      attendees: const [], // Would extract from transcript
    ));

    actions.add(WorkflowAction.email(
      id: 'email-${session.id}-summary',
      subject: 'Meeting Summary: $sessionTitle',
      body: _generateMeetingSummary(session),
      toRecipients: const [], // Would extract from transcript
    ));

    // Document storage action
    final meetingContent = _extractKeyContent(session);
    if (meetingContent.isNotEmpty) {
      actions.add(WorkflowAction.documentStore(
        id: 'doc-${session.id}-notes',
        title: sessionTitle,
        content: meetingContent,
        fileName: '${sessionTitle.replaceAll(' ', '_')}_notes.md',
        folder: 'OneDrive',
      ));
    }

    // Team notification if multiple speakers (indicates team meeting)
    if (session.speakerCount > 2) {
      actions.add(WorkflowAction.teamNotification(
        id: 'team-${session.id}-summary',
        message: 'Meeting Summary: ${sessionTitle}\n\nKey points: ${_extractKeyPoints(session)}',
        channel: 'general',
      ));
    }

    return actions;
  }

  // ── Private Helper Methods ─────────────────────────────

  WorkflowPackage _generateWorkflowPackage(WrapdSession session) {
    final actions = generateWorkflowActions(session);
    
    return WorkflowPackage(
      id: 'workflow-${session.id}-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: session.id,
      name: 'Post-Meeting Actions: ${session.title}',
      actions: actions,
    );
  }

  String _generateMeetingSummary(WrapdSession session) {
    // Basic summary generation for MVP
    return '''
Meeting: ${session.title}
Date: ${session.createdAt.toString().split(' ')[0]}
Duration: ${session.duration.inMinutes} minutes
Participants: ${session.speakerCount} attendees

Key Points:
${_extractKeyPoints(session)}

Next Steps:
- Schedule follow-up meeting (calendar action created)
- Review action items with team
- Update project documentation

This summary was automatically generated by WRAPD
    '''.trim();
  }

  String _extractKeyContent(WrapdSession session) {
    if (session.segments.isEmpty) {
      return 'Transcript: Processing pending...';
    }

    // Extract first significant segments (first 5 segments or 500 chars)
    final keySegments = session.segments.take(5).toList();
    final content = keySegments.map((segment) {
      final timestamp = 'Timestamp ${segment.timestamp.inMinutes}:${(segment.timestamp.inSeconds % 60).toString().padLeft(2, '0')}';
      return '$timestamp - ${segment.speakerName}: ${segment.text}';
    }).join('\n');

    return '''# ${session.title}

**Date:** ${session.createdAt.toString().split(' ')[0]}
**Duration:** ${session.duration.inMinutes} minutes
**Participants:** ${session.speakerCount} attendees

## Transcript Excerpt

$content

## Summary
Auto-generated meeting notes. Full transcript available in session.

---
*Generated by WRAPD - Your Final Stop for Meeting Management*
    ''';
  }

  String _extractKeyPoints(WrapdSession session) {
    if (session.segments.isEmpty) return 'Processing transcript...';

    // Look for action words or decisions
    final actionIndicators = ['need to', 'should', 'will', 'action', 'todo', 'follow up', 'schedule'];
    final decisions = session.segments
        .map((segment) => segment.text)
        .where((text) => 
            actionIndicators.any((indicator) => text.toLowerCase().contains(indicator)))
        .take(3)
        .join('\n• ');

    return decisions.isNotEmpty ? '• $decisions' : '• Review transcript for action items';
  }
}

// ── Workflow Statistics ──────────────────────────────────

class WorkflowStats {
  final int totalPackages;
  final int completedPackages;
  final int todayCompleted;
  final int totalActions;
  final int completedActions;

  const WorkflowStats({
    required this.totalPackages,
    required this.completedPackages,
    required this.todayCompleted,
    required this.totalActions,
    required this.completedActions,
  });

  double get packageCompletionRate => totalPackages == 0 
      ? 0.0 
      : (completedPackages / totalPackages).clamp(0.0, 1.0);

  double get actionCompletionRate => totalActions == 0 
      ? 0.0 
      : (completedActions / totalActions).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() {
    return {
      'totalPackages': totalPackages,
      'completedPackages': completedPackages,
      'todayCompleted': todayCompleted,
      'totalActions': totalActions,
      'completedActions': completedActions,
      'packageCompletionRate': packageCompletionRate,
      'actionCompletionRate': actionCompletionRate,
    };
  }
}
