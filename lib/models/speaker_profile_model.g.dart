// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speaker_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceProfileAdapter extends TypeAdapter<VoiceProfile> {
  @override
  final int typeId = 21;

  @override
  VoiceProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      gender: fields[4] as SpeakerGender,
      voiceFeatures: (fields[5] as List).cast<double>(),
      voiceStatistics: (fields[6] as Map).cast<String, dynamic>(),
      usageCount: fields[7] as int,
      colorTag: fields[8] as String,
    )
      ..createdAt = fields[2] as DateTime
      ..updatedAt = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, VoiceProfile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.voiceFeatures)
      ..writeByte(6)
      ..write(obj.voiceStatistics)
      ..writeByte(7)
      ..write(obj.usageCount)
      ..writeByte(8)
      ..write(obj.colorTag);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SpeakerGenderAdapter extends TypeAdapter<SpeakerGender> {
  @override
  final int typeId = 20;

  @override
  SpeakerGender read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SpeakerGender.male;
      case 1:
        return SpeakerGender.female;
      case 2:
        return SpeakerGender.nonBinary;
      default:
        return SpeakerGender.male;
    }
  }

  @override
  void write(BinaryWriter writer, SpeakerGender obj) {
    switch (obj) {
      case SpeakerGender.male:
        writer.writeByte(0);
        break;
      case SpeakerGender.female:
        writer.writeByte(1);
        break;
      case SpeakerGender.nonBinary:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeakerGenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
