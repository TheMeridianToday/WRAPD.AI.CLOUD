// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptSegmentAdapter extends TypeAdapter<TranscriptSegment> {
  @override
  final int typeId = 3;

  @override
  TranscriptSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranscriptSegment(
      id: fields[0] as String,
      speakerIndex: fields[1] as int,
      speakerName: fields[2] as String,
      timestamp: fields[3] as Duration,
      text: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TranscriptSegment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.speakerIndex)
      ..writeByte(2)
      ..write(obj.speakerName)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TopicMarkerAdapter extends TypeAdapter<TopicMarker> {
  @override
  final int typeId = 4;

  @override
  TopicMarker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopicMarker(
      id: fields[0] as String,
      label: fields[1] as String,
      timestamp: fields[2] as Duration,
      isUserNote: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TopicMarker obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isUserNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicMarkerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SynthesisMessageAdapter extends TypeAdapter<SynthesisMessage> {
  @override
  final int typeId = 5;

  @override
  SynthesisMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SynthesisMessage(
      id: fields[0] as String,
      isUser: fields[1] as bool,
      text: fields[2] as String,
      chips: (fields[3] as List).cast<TimestampChip>(),
    );
  }

  @override
  void write(BinaryWriter writer, SynthesisMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isUser)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.chips);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SynthesisMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimestampChipAdapter extends TypeAdapter<TimestampChip> {
  @override
  final int typeId = 6;

  @override
  TimestampChip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimestampChip(
      label: fields[0] as String,
      timestamp: fields[1] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, TimestampChip obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimestampChipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WrapdSessionAdapter extends TypeAdapter<WrapdSession> {
  @override
  final int typeId = 0;

  @override
  WrapdSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WrapdSession(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      duration: fields[3] as Duration,
      status: fields[4] as SessionStatus,
      segments: (fields[5] as List).cast<TranscriptSegment>(),
      topics: (fields[6] as List).cast<TopicMarker>(),
      messages: (fields[7] as List).cast<SynthesisMessage>(),
      speakerCount: fields[8] as int,
      exportAllowanceUsed: fields[9] as int,
      exportAllowanceMax: fields[10] as int,
      isArchived: fields[11] as bool,
      hasAudio: fields[12] as bool,
      audioPath: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WrapdSession obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.segments)
      ..writeByte(6)
      ..write(obj.topics)
      ..writeByte(7)
      ..write(obj.messages)
      ..writeByte(8)
      ..write(obj.speakerCount)
      ..writeByte(9)
      ..write(obj.exportAllowanceUsed)
      ..writeByte(10)
      ..write(obj.exportAllowanceMax)
      ..writeByte(11)
      ..write(obj.isArchived)
      ..writeByte(12)
      ..write(obj.hasAudio)
      ..writeByte(13)
      ..write(obj.audioPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WrapdSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionStatusAdapter extends TypeAdapter<SessionStatus> {
  @override
  final int typeId = 1;

  @override
  SessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionStatus.draft;
      case 1:
        return SessionStatus.processing;
      case 2:
        return SessionStatus.failed;
      case 3:
        return SessionStatus.ready;
      default:
        return SessionStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, SessionStatus obj) {
    switch (obj) {
      case SessionStatus.draft:
        writer.writeByte(0);
        break;
      case SessionStatus.processing:
        writer.writeByte(1);
        break;
      case SessionStatus.failed:
        writer.writeByte(2);
        break;
      case SessionStatus.ready:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportTierAdapter extends TypeAdapter<ExportTier> {
  @override
  final int typeId = 2;

  @override
  ExportTier read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExportTier.free;
      case 1:
        return ExportTier.standard;
      case 2:
        return ExportTier.extended;
      default:
        return ExportTier.free;
    }
  }

  @override
  void write(BinaryWriter writer, ExportTier obj) {
    switch (obj) {
      case ExportTier.free:
        writer.writeByte(0);
        break;
      case ExportTier.standard:
        writer.writeByte(1);
        break;
      case ExportTier.extended:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
