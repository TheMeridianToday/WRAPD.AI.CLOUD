import 'package:flutter_test/flutter_test.dart';
import 'package:wrapd/models/session_model.dart';
import 'package:wrapd/models/workflow_model.dart';
import 'package:wrapd/services/storage_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('WrapdSession Model', () {
    test('copyWith should update specified fields', () {
      final session = WrapdSession(
        id: '1',
        title: 'Original',
        createdAt: DateTime.now(),
        duration: Duration.zero,
        status: SessionStatus.draft,
      );

      final updated = session.copyWith(title: 'Updated', isArchived: true);

      expect(updated.title, 'Updated');
      expect(updated.isArchived, true);
      expect(updated.id, '1'); // Unchanged
    });

    test('allowanceAvailable should return true when under limit', () {
      final session = WrapdSession(
        id: '1',
        title: 'Test',
        createdAt: DateTime.now(),
        duration: Duration.zero,
        status: SessionStatus.ready,
        exportAllowanceUsed: 1,
        exportAllowanceMax: 3,
      );

      expect(session.allowanceAvailable, true);
      expect(session.remainingAllowance, 2);
    });
  });

  group('Workflow Models', () {
    test('WorkflowAction should correctly identify target type icon', () {
      final action = WorkflowAction(
        id: '1',
        title: 'Email',
        description: 'Test',
        targetType: ExportTargetType.email,
        data: {},
      );

      expect(action.targetTypeDisplay, 'Email');
    });

    test('WorkflowPackage should calculate progress correctly', () {
      final action1 = WorkflowAction(
        id: '1',
        title: 'A',
        description: 'D',
        targetType: ExportTargetType.slack,
        data: {},
        isCompleted: true,
      );
      final action2 = WorkflowAction(
        id: '2',
        title: 'B',
        description: 'D',
        targetType: ExportTargetType.slack,
        data: {},
        isCompleted: false,
      );

      final package = WorkflowPackage(
        id: 'p1',
        sessionId: 's1',
        name: 'Pkg',
        actions: [action1, action2],
      );

      expect(package.progress, 0.5);
      expect(package.isComplete, false);
    });
  });

  group('StorageService', () {
    test('Singleton should return same instance', () {
      final s1 = StorageService();
      final s2 = StorageService();
      expect(identical(s1, s2), true);
    });
  });
}
