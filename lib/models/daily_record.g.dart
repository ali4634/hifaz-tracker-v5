// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyRecordAdapter extends TypeAdapter<DailyRecord> {
  @override
  final int typeId = 1;

  @override
  DailyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyRecord(
      id: fields[0] as String,
      studentId: fields[1] as String,
      date: fields[2] as String,
      present: fields[3] as bool,
      sabaq: fields[4] as SabaqEntry?,
      sabqi: fields[5] as SabqiEntry?,
      manzil: fields[6] as ManzilEntry?,
      lastUpdated: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.present)
      ..writeByte(4)
      ..write(obj.sabaq)
      ..writeByte(5)
      ..write(obj.sabqi)
      ..writeByte(6)
      ..write(obj.manzil)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SabaqEntryAdapter extends TypeAdapter<SabaqEntry> {
  @override
  final int typeId = 2;

  @override
  SabaqEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SabaqEntry(
      juz: fields[0] as int,
      pageLabel: fields[1] as String,
      lines: fields[2] as int,
      startPage: fields[3] as int,
      endPage: fields[4] as int,
      isParaStart: fields.length > 5 ? fields[5] as bool? ?? false : false,
      isParaEnd: fields.length > 6 ? fields[6] as bool? ?? false : false,
      paraStartDate: fields.length > 7 ? fields[7] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, SabaqEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.juz)
      ..writeByte(1)
      ..write(obj.pageLabel)
      ..writeByte(2)
      ..write(obj.lines)
      ..writeByte(3)
      ..write(obj.startPage)
      ..writeByte(4)
      ..write(obj.endPage)
      ..writeByte(5)
      ..write(obj.isParaStart)
      ..writeByte(6)
      ..write(obj.isParaEnd)
      ..writeByte(7)
      ..write(obj.paraStartDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SabaqEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SabqiEntryAdapter extends TypeAdapter<SabqiEntry> {
  @override
  final int typeId = 3;

  @override
  SabqiEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SabqiEntry(
      juz: fields[0] as int,
      startPage: fields[1] as int,
      endPage: fields[2] as int,
      heardPage: fields[3] as int,
      revisionCount: fields[4] as int? ?? 0,
      isDoubleSabqi: fields[5] as bool? ?? false,
      doubleSabqiJuz: fields[6] as int?,
      doubleSabqiRuba: fields[7] as int?,
      mushafPage: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SabqiEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.juz)
      ..writeByte(1)
      ..write(obj.startPage)
      ..writeByte(2)
      ..write(obj.endPage)
      ..writeByte(3)
      ..write(obj.heardPage)
      ..writeByte(4)
      ..write(obj.revisionCount)
      ..writeByte(5)
      ..write(obj.isDoubleSabqi)
      ..writeByte(6)
      ..write(obj.doubleSabqiJuz)
      ..writeByte(7)
      ..write(obj.doubleSabqiRuba)
      ..writeByte(8)
      ..write(obj.mushafPage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SabqiEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ManzilEntryAdapter extends TypeAdapter<ManzilEntry> {
  @override
  final int typeId = 4;

  @override
  ManzilEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManzilEntry(
      juz: fields[0] as int,
      ruba: fields[1] as int,
      startJuz: fields[2] as int?,
      startRuba: fields[3] as int?,
      customText: fields.length > 4 ? fields[4] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, ManzilEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.juz)
      ..writeByte(1)
      ..write(obj.ruba)
      ..writeByte(2)
      ..write(obj.startJuz)
      ..writeByte(3)
      ..write(obj.startRuba)
      ..writeByte(4)
      ..write(obj.customText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManzilEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
