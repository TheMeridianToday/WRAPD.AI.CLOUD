// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkflowActionAdapter extends TypeAdapter<WorkflowAction> {
  @override
  final int typeId = 11;

  @override
  WorkflowAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkflowAction(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      targetType: fields[3] as ExportTargetType,
      data: (fields[4] as Map).cast<String, dynamic>(),
      isCompleted: fields[5] as bool,
      completedAt: fields[6] as DateTime?,
      errorMessage: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      targetApp: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkflowAction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.targetType)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.targetApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkflowPackageAdapter extends TypeAdapter<WorkflowPackage> {
  @override
  final int typeId = 12;

  @override
  WorkflowPackage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkflowPackage(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      name: fields[2] as String,
      actions: (fields[3] as List).cast<WorkflowAction>(),
      createdAt: fields[4] as DateTime?,
      completedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkflowPackage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.actions)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkflowPackageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExportTargetTypeAdapter extends TypeAdapter<ExportTargetType> {
  @override
  final int typeId = 10;

  @override
  ExportTargetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExportTargetType.calendar;
      case 1:
        return ExportTargetType.email;
      case 2:
        return ExportTargetType.notion;
      case 3:
        return ExportTargetType.onedrive;
      case 4:
        return ExportTargetType.slack;
      case 5:
        return ExportTargetType.teams;
      case 6:
        return ExportTargetType.outlook;
      case 7:
        return ExportTargetType.gmail;
      case 8:
        return ExportTargetType.notion_page;
      default:
        return ExportTargetType.calendar;
    }
  }

  @override
  void write(BinaryWriter writer, ExportTargetType obj) {
    switch (obj) {
      case ExportTargetType.calendar:
        writer.writeByte(0);
        break;
      case ExportTargetType.email:
        writer.writeByte(1);
        break;
      case ExportTargetType.notion:
        writer.writeByte(2);
        break;
      case ExportTargetType.onedrive:
        writer.writeByte(3);
        break;
      case ExportTargetType.slack:
        writer.writeByte(4);
        break;
      case ExportTargetType.teams:
        writer.writeByte(5);
        break;
      case ExportTargetType.outlook:
        writer.writeByte(6);
        break;
      case ExportTargetType.gmail:
        writer.writeByte(7);
        break;
      case ExportTargetType.notion_page:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportTargetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
