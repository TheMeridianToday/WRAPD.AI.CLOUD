import 'package:flutter_test/flutter_test.dart';
import 'package:wrapd/models/session_model.dart';
import 'package:wrapd/providers/session_provider.dart';
import 'package:wrapd/providers/recording_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Core Integration Flow', () {
    test('Session Recording to Library flow', () async {
      // 1. Initialize session provider
      final sessionProvider = SessionProvider();
      final initialCount = sessionProvider.sessions.length;

      // 2. Mock a recording result
      final sessionId = const Uuid().v4();
      final now = DateTime.now();
      
      final session = WrapdSession(
        id: sessionId,
        title: 'Test Integration Session',
        createdAt: now,
        duration: const Duration(minutes: 5),
        status: SessionStatus.ready,
        segments: [
          const TranscriptSegment(
            id: 'seg-1',
            speakerIndex: 0,
            speakerName: 'User',
            timestamp: Duration.zero,
            text: 'Hello integration test.',
          ),
        ],
      );

      // 3. Save to provider
      sessionProvider.stopRecording(session);

      // 4. Verify presence in library
      expect(sessionProvider.sessions.length, initialCount + 1);
      expect(sessionProvider.sessions.first.id, sessionId);
      expect(sessionProvider.sessions.first.title, 'Test Integration Session');

      // 5. Verify Archiving
      sessionProvider.toggleArchive(sessionId);
      expect(sessionProvider.sessions.first.isArchived, true);
      expect(sessionProvider.filteredSessions.length, initialCount); // Should be hidden in default list

      // 6. Verify Delete & Undo
      sessionProvider.deleteSession(sessionId);
      expect(sessionProvider.sessions.length, initialCount);
      
      sessionProvider.undoDelete(session);
      expect(sessionProvider.sessions.length, initialCount + 1);
    });
  });
}
