import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'workflow_model.g.dart';

/// Export targets for workflow automation
@HiveType(typeId: 10)
enum ExportTargetType {
  @HiveField(0) calendar,
  @HiveField(1) email,
  @HiveField(2) notion,
  @HiveField(3) onedrive,
  @HiveField(4) slack,
  @HiveField(5) teams,
  @HiveField(6) outlook,
  @HiveField(7) gmail,
  @HiveField(8) notion_page,
}

/// Individual workflow action to be performed after meeting completion
@HiveType(typeId: 11)
class WorkflowAction {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final ExportTargetType targetType;
  @HiveField(4)
  final Map<String, dynamic> data;
  @HiveField(5)
  final bool isCompleted;
  @HiveField(6)
  final DateTime? completedAt;
  @HiveField(7)
  final String? errorMessage;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final String? targetApp; // e.g. "Notion", "Outlook", "Gmail"

  WorkflowAction({
    required this.id,
    required this.title,
    required this.description,
    required this.targetType,
    required this.data,
    this.isCompleted = false,
    this.completedAt,
    this.errorMessage,
    DateTime? createdAt,
    this.targetApp,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a calendar event action
  factory WorkflowAction.calendar({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    List<String> attendees = const [],
    String? location,
  }) {
    return WorkflowAction(
      id: id,
      title: 'Add "$title" to Calendar',
      description: 'Create calendar event for meeting follow-up',
      targetType: ExportTargetType.calendar,
      data: {
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'description': description,
        'attendees': attendees,
        'location': location,
      },
    );
  }

  /// Create an email draft action
  factory WorkflowAction.email({
    required String id,
    required String subject,
    required String body,
    List<String> toRecipients = const [],
    List<String> ccRecipients = const [],
  }) {
    return WorkflowAction(
      id: id,
      title: 'Draft Email: "$subject"',
      description: 'Create email draft for meeting follow-up',
      targetType: ExportTargetType.email,
      data: {
        'subject': subject,
        'body': body,
        'toRecipients': toRecipients,
        'ccRecipients': ccRecipients,
      },
    );
  }

  /// Create a document storage action
  factory WorkflowAction.documentStore({
    required String id,
    required String title,
    required String content,
    String? fileName,
    String? folder,
  }) {
    return WorkflowAction(
      id: id,
      title: 'Save "$title" to $folder',
      description: 'Store meeting notes in cloud document system',
      targetType: folder?.toLowerCase().contains('notion') == true 
          ? ExportTargetType.notion 
          : ExportTargetType.onedrive,
      data: {
        'title': title,
        'content': content,
        'fileName': fileName,
        'folder': folder,
      },
    );
  }

  /// Create a team notification action
  factory WorkflowAction.teamNotification({
    required String id,
    required String message,
    String? channel,
    List<String> mentions = const [],
  }) {
    return WorkflowAction(
      id: id,
      title: 'Send Team Notification',
      description: 'Notify team about meeting outcomes',
      targetType: ExportTargetType.slack,
      data: {
        'message': message,
        'channel': channel,
        'mentions': mentions,
      },
    );
  }

  WorkflowAction copyWith({
    String? id,
    String? title,
    String? description,
    ExportTargetType? targetType,
    Map<String, dynamic>? data,
    bool? isCompleted,
    DateTime? completedAt,
    String? errorMessage,
    DateTime? createdAt,
    String? targetApp,
  }) {
    return WorkflowAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetType: targetType ?? this.targetType,
      data: data ?? this.data,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      targetApp: targetApp ?? this.targetApp,
    );
  }

  /// Complete the action
  WorkflowAction complete() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  /// Mark as failed with error message
  WorkflowAction fail(String error) {
    return copyWith(
      errorMessage: error,
    );
  }

  /// Get display name for target type
  String get targetTypeDisplay {
    switch (targetType) {
      case ExportTargetType.calendar:
        return 'Calendar';
      case ExportTargetType.email:
        return 'Email';
      case ExportTargetType.notion:
        return 'Notion';
      case ExportTargetType.onedrive:
        return 'OneDrive';
      case ExportTargetType.slack:
        return 'Slack';
      case ExportTargetType.teams:
        return 'Teams';
      case ExportTargetType.outlook:
        return 'Outlook';
      case ExportTargetType.gmail:
        return 'Gmail';
      case ExportTargetType.notion_page:
        return 'Notion Page';
    }
  }

  /// Get icon for target type
  IconData get targetTypeIcon {
    switch (targetType) {
      case ExportTargetType.calendar:
        return Icons.calendar_today_outlined;
      case ExportTargetType.email:
        return Icons.email_outlined;
      case ExportTargetType.notion:
        return Icons.note_alt_outlined;
      case ExportTargetType.onedrive:
        return Icons.cloud_done_outlined;
      case ExportTargetType.slack:
        return Icons.chat_outlined;
      case ExportTargetType.teams:
        return Icons.groups_outlined;
      case ExportTargetType.outlook:
        return Icons.alternate_email_outlined;
      case ExportTargetType.gmail:
        return Icons.email_outlined;
      case ExportTargetType.notion_page:
        return Icons.description_outlined;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetType': targetType.toString(),
      'data': data,
      'isCompleted': isCompleted,
      'errorMessage': errorMessage,
    };
  }

  factory WorkflowAction.fromJson(Map<String, dynamic> json) {
    return WorkflowAction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetType: ExportTargetType.values.firstWhere(
        (e) => e.toString() == json['targetType'],
        orElse: () => ExportTargetType.email,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      data: Map<String, dynamic>.from(json['data'] as Map),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Collection of actions for a complete workflow
@HiveType(typeId: 12)
class WorkflowPackage {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String sessionId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final List<WorkflowAction> actions;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime? completedAt;

  WorkflowPackage({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.actions,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get pending actions count
  int get pendingActionsCount => actions.where((a) => !a.isCompleted).length;

  /// Get completed actions count
  int get completedActionsCount => actions.where((a) => a.isCompleted).length;

  /// Get progress percentage
  double get progress => actions.isEmpty 
      ? 0.0 
      : (completedActionsCount / actions.length).clamp(0.0, 1.0);

  /// Check if workflow is complete
  bool get isComplete => actions.isNotEmpty && pendingActionsCount == 0;

  /// Get the next action to perform
  WorkflowAction? get nextAction => actions
      .where((a) => !a.isCompleted)
      .firstOrNull;

  WorkflowPackage copyWith({
    String? id,
    String? sessionId,
    String? name,
    List<WorkflowAction>? actions,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return WorkflowPackage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'name': name,
      'actions': actions.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory WorkflowPackage.fromJson(Map<String, dynamic> json) {
    return WorkflowPackage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      name: json['name'] as String,
      actions: (json['actions'] as List)
          .map((a) => WorkflowAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// Extension to add convenience methods to list 
extension WorkflowActionList on List<WorkflowAction> {
  /// Complete all actions in this list
  List<WorkflowAction> completeAll() {
    return map((action) => action.complete()).toList();
  }

  /// Get actions by target type
  List<WorkflowAction> byType(ExportTargetType type) {
    return where((action) => action.targetType == type).toList();
  }

  /// Get pending actions
  List<WorkflowAction> pending() {
    return where((action) => !action.isCompleted).toList();
  }

  /// Get completed actions
  List<WorkflowAction> completed() {
    return where((action) => action.isCompleted).toList();
  }
}
