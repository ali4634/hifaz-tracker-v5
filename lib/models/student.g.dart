// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 0;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      section: fields[3] as String,
      isStarred: fields[4] as bool,
      manzilStartJuz: fields[5] as int,
      manzilEndJuz: fields[6] as int,
      manzilReverse: fields[7] as bool,
      sabqiTargetJuz: fields[8] as int,
      sabqiTargetPages: fields[9] as int,
      currentManzilJuz: fields[10] as int,
      currentManzilRuba: fields[11] as int,
      manzilCycle: fields[12] as int,
      mushafLines: fields[15] as int,
      acknowledgedWarnings: (fields[13] as List?)?.cast<String>(),
      createdAt: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.section)
      ..writeByte(4)
      ..write(obj.isStarred)
      ..writeByte(5)
      ..write(obj.manzilStartJuz)
      ..writeByte(6)
      ..write(obj.manzilEndJuz)
      ..writeByte(7)
      ..write(obj.manzilReverse)
      ..writeByte(8)
      ..write(obj.sabqiTargetJuz)
      ..writeByte(9)
      ..write(obj.sabqiTargetPages)
      ..writeByte(10)
      ..write(obj.currentManzilJuz)
      ..writeByte(11)
      ..write(obj.currentManzilRuba)
      ..writeByte(12)
      ..write(obj.manzilCycle)
      ..writeByte(13)
      ..write(obj.acknowledgedWarnings)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.mushafLines);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
