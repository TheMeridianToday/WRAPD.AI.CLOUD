import 'package:hive/hive.dart';

part 'session_model.g.dart';

// ─────────────────────────────────────────────────────────
//  WRAPD — Data Models
//  Hive adapters generated - ready for persistence
// ─────────────────────────────────────────────────────────

@HiveType(typeId: 1)
enum SessionStatus {
  @HiveField(0) draft,
  @HiveField(1) processing,
  @HiveField(2) failed,
  @HiveField(3) ready,
}

@HiveType(typeId: 2)
enum ExportTier {
  @HiveField(0) free,
  @HiveField(1) standard,
  @HiveField(2) extended,
}

// A spoken segment by one speaker
@HiveType(typeId: 3)
class TranscriptSegment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int speakerIndex; // 0–5 maps to WrapdColors.speakers
  @HiveField(2)
  final String speakerName;
  @HiveField(3)
  final Duration timestamp;
  @HiveField(4)
  final String text;

  const TranscriptSegment({
    required this.id,
    required this.speakerIndex,
    required this.speakerName,
    required this.timestamp,
    required this.text,
  });
}

// A topic divider or user notation inserted during recording
@HiveType(typeId: 4)
class TopicMarker {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String label;
  @HiveField(2)
  final Duration timestamp;
  @HiveField(3)
  final bool isUserNote; // True if it's a user notation/header

  const TopicMarker({
    required this.id,
    required this.label,
    required this.timestamp,
    this.isUserNote = false,
  });
}

// Chat message in Synthesis tab
@HiveType(typeId: 5)
class SynthesisMessage {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final bool isUser;
  @HiveField(2)
  final String text;
  @HiveField(3)
  final List<TimestampChip> chips; // e.g. [Jump 04:20]

  const SynthesisMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.chips = const [],
  });
}

@HiveType(typeId: 6)
class TimestampChip {
  @HiveField(0)
  final String label;
  @HiveField(1)
  final Duration timestamp;

  const TimestampChip({required this.label, required this.timestamp});
}

// Root session object
@HiveType(typeId: 0)
class WrapdSession {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final DateTime createdAt;
  @HiveField(3)
  final Duration duration;
  @HiveField(4)
  final SessionStatus status;
  @HiveField(5)
  final List<TranscriptSegment> segments;
  @HiveField(6)
  final List<TopicMarker> topics;
  @HiveField(7)
  final List<SynthesisMessage> messages;
  @HiveField(8)
  final int speakerCount;
  @HiveField(9)
  final int exportAllowanceUsed; // out of weekly budget
  @HiveField(10)
  final int exportAllowanceMax;
  @HiveField(11)
  final bool isArchived;
  @HiveField(12)
  final bool hasAudio;
  @HiveField(13)
  final String? audioPath;

  const WrapdSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.duration,
    required this.status,
    this.segments = const [],
    this.topics = const [],
    this.messages = const [],
    this.speakerCount = 1,
    this.exportAllowanceUsed = 0,
    this.exportAllowanceMax = 3,
    this.isArchived = false,
    this.hasAudio = false,
    this.audioPath,
  });

  bool get allowanceAvailable =>
      exportAllowanceUsed < exportAllowanceMax;

  int get remainingAllowance =>
      (exportAllowanceMax - exportAllowanceUsed).clamp(0, exportAllowanceMax);

  WrapdSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    Duration? duration,
    SessionStatus? status,
    List<TranscriptSegment>? segments,
    List<TopicMarker>? topics,
    List<SynthesisMessage>? messages,
    int? speakerCount,
    int? exportAllowanceUsed,
    int? exportAllowanceMax,
    bool? isArchived,
    bool? hasAudio,
    String? audioPath,
  }) {
    return WrapdSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      segments: segments ?? this.segments,
      topics: topics ?? this.topics,
      messages: messages ?? this.messages,
      speakerCount: speakerCount ?? this.speakerCount,
      exportAllowanceUsed: exportAllowanceUsed ?? this.exportAllowanceUsed,
      exportAllowanceMax: exportAllowanceMax ?? this.exportAllowanceMax,
      isArchived: isArchived ?? this.isArchived,
      hasAudio: hasAudio ?? this.hasAudio,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  End of Data Models
// ─────────────────────────────────────────────────────────
