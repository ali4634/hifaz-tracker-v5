// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeMode: fields[0] as String,
      locale: fields[1] as String,
      keepAwake: fields[2] as bool,
      notificationsEnabled: fields[3] as bool,
      revisionStandard: fields[4] as int,
      warningInactiveDays: fields[5] as int,
      warningRepetitionCount: fields[6] as int,
      absenceWindowDays: fields[7] as int,
      absenceWarningCount: fields[8] as int,
      notificationHour: fields[9] as int,
      notificationMinute: fields[10] as int,
      missingSabqiDays: fields[11] as int,
      accent: fields[12] as String,
      gradingBehtareen: fields.length > 13 ? fields[13] as int : 26,
      gradingBehtar: fields.length > 14 ? fields[14] as int : 20,
      gradingAcha: fields.length > 15 ? fields[15] as int : 15,
      madrasaName: fields.length > 16 ? fields[16] as String : '',
      teacherName: fields.length > 17 ? fields[17] as String : '',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.locale)
      ..writeByte(2)
      ..write(obj.keepAwake)
      ..writeByte(3)
      ..write(obj.notificationsEnabled)
      ..writeByte(4)
      ..write(obj.revisionStandard)
      ..writeByte(5)
      ..write(obj.warningInactiveDays)
      ..writeByte(6)
      ..write(obj.warningRepetitionCount)
      ..writeByte(7)
      ..write(obj.absenceWindowDays)
      ..writeByte(8)
      ..write(obj.absenceWarningCount)
      ..writeByte(9)
      ..write(obj.notificationHour)
      ..writeByte(10)
      ..write(obj.notificationMinute)
      ..writeByte(11)
      ..write(obj.missingSabqiDays)
      ..writeByte(12)
      ..write(obj.accent)
      ..writeByte(13)
      ..write(obj.gradingBehtareen)
      ..writeByte(14)
      ..write(obj.gradingBehtar)
      ..writeByte(15)
      ..write(obj.gradingAcha)
      ..writeByte(16)
      ..write(obj.madrasaName)
      ..writeByte(17)
      ..write(obj.teacherName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
