// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeeRecordAdapter extends TypeAdapter<FeeRecord> {
  @override
  final int typeId = 5;

  @override
  FeeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeeRecord(
      id: fields[0] as String,
      studentId: fields[1] as String,
      month: fields[2] as int,
      year: fields[3] as int,
      paid: fields[4] as bool,
      paidDate: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FeeRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.year)
      ..writeByte(4)
      ..write(obj.paid)
      ..writeByte(5)
      ..write(obj.paidDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
