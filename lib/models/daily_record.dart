import 'package:hive_flutter/hive_flutter.dart';

part 'daily_record.g.dart';

/// One day's attendance + lesson tracks for a student.
@HiveType(typeId: 1)
class DailyRecord {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  /// 'yyyy-MM-dd'.
  @HiveField(2)
  String date;

  @HiveField(3)
  bool present;

  @HiveField(4)
  SabaqEntry? sabaq;

  @HiveField(5)
  SabqiEntry? sabqi;

  @HiveField(6)
  ManzilEntry? manzil;

  @HiveField(7)
  int lastUpdated;

  DailyRecord({
    required this.id,
    required this.studentId,
    required this.date,
    // Default is ABSENT: a student is only present once the teacher
    // explicitly marks them so (or a record says so).
    this.present = false,
    this.sabaq,
    this.sabqi,
    this.manzil,
    this.lastUpdated = 0,
  });

  bool get hasAnyLesson => sabaq != null || sabqi != null || manzil != null;

  /// Signature of the logged lesson(s) used by the repetition detector.
  String? get lessonSignature {
    if (sabaq != null) {
      return 's|${sabaq!.juz}|${sabaq!.pageLabel}|${sabaq!.lines}';
    }
    if (sabqi != null) {
      return 'q|${sabqi!.juz}|${sabqi!.startPage}|${sabqi!.endPage}';
    }
    if (manzil != null) {
      return 'm|${manzil!.juz}|${manzil!.ruba}';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'date': date,
    'present': present,
    'sabaq': sabaq?.toJson(),
    'sabqi': sabqi?.toJson(),
    'manzil': manzil?.toJson(),
    'lastUpdated': lastUpdated,
  };

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
    id: json['id'] as String? ?? '',
    studentId: json['studentId'] as String? ?? '',
    date: json['date'] as String? ?? '',
    present: json['present'] as bool? ?? false,
    sabaq: json['sabaq'] == null
        ? null
        : SabaqEntry.fromJson(json['sabaq'] as Map<String, dynamic>),
    sabqi: json['sabqi'] == null
        ? null
        : SabqiEntry.fromJson(json['sabqi'] as Map<String, dynamic>),
    manzil: json['manzil'] == null
        ? null
        : ManzilEntry.fromJson(json['manzil'] as Map<String, dynamic>),
    lastUpdated: json['lastUpdated'] as int? ?? 0,
  );
}

/// Sabaq (new lesson): Juz, page/surah label, lines count and page range
/// (startPage/endPage drive the para-based "pages read" progress).
@HiveType(typeId: 2)
class SabaqEntry {
  @HiveField(0)
  int juz;

  @HiveField(1)
  String pageLabel;

  @HiveField(2)
  int lines;

  @HiveField(3)
  int startPage;

  @HiveField(4)
  int endPage;

  @HiveField(5)
  bool isParaStart;

  @HiveField(6)
  bool isParaEnd;

  @HiveField(7)
  String? paraStartDate;

  SabaqEntry({
    this.juz = 1,
    this.pageLabel = '',
    this.lines = 0,
    this.startPage = 0,
    this.endPage = 0,
    this.isParaStart = false,
    this.isParaEnd = false,
    this.paraStartDate,
  });

  /// Page count of this record (endPage - startPage + 1), 0 when not set.
  int get pages =>
      (endPage >= startPage && endPage > 0) ? endPage - startPage + 1 : 0;

  Map<String, dynamic> toJson() => {
    'juz': juz,
    'pageLabel': pageLabel,
    'lines': lines,
    'startPage': startPage,
    'endPage': endPage,
    'isParaStart': isParaStart,
    'isParaEnd': isParaEnd,
    'paraStartDate': paraStartDate,
  };

  factory SabaqEntry.fromJson(Map<String, dynamic> json) => SabaqEntry(
    juz: json['juz'] as int? ?? 1,
    pageLabel: json['pageLabel'] as String? ?? '',
    lines: json['lines'] as int? ?? 0,
    startPage: json['startPage'] as int? ?? 0,
    endPage: json['endPage'] as int? ?? 0,
    isParaStart: json['isParaStart'] as bool? ?? false,
    isParaEnd: json['isParaEnd'] as bool? ?? false,
    paraStartDate: json['paraStartDate'] as String?,
  );
}

/// Sabqi / Tahreer (daily revision): Juz, page range and heard page.
@HiveType(typeId: 3)
class SabqiEntry {
  @HiveField(0)
  int juz;

  @HiveField(1)
  int startPage;

  @HiveField(2)
  int endPage;

  @HiveField(3)
  int heardPage;

  /// Revision count (تجدید) – how many times this revision was repeated.
  @HiveField(4)
  int revisionCount;

  /// Whether this is a double-Sabqi entry (دوہرا سبقی).
  @HiveField(5)
  bool isDoubleSabqi;

  /// Previous Juz for double-Sabqi (پچھلا پارہ).
  @HiveField(6)
  int? doubleSabqiJuz;

  /// Previous Ruba for double-Sabqi.
  @HiveField(7)
  int? doubleSabqiRuba;

  /// Mushaf page number (مصحف صفحہ).
  @HiveField(8)
  int? mushafPage;

  SabqiEntry({
    this.juz = 1,
    this.startPage = 1,
    this.endPage = 1,
    this.heardPage = 1,
    this.revisionCount = 0,
    this.isDoubleSabqi = false,
    this.doubleSabqiJuz,
    this.doubleSabqiRuba,
    this.mushafPage,
  });

  Map<String, dynamic> toJson() => {
    'juz': juz,
    'startPage': startPage,
    'endPage': endPage,
    'heardPage': heardPage,
    'revisionCount': revisionCount,
    'isDoubleSabqi': isDoubleSabqi,
    'doubleSabqiJuz': doubleSabqiJuz,
    'doubleSabqiRuba': doubleSabqiRuba,
    'mushafPage': mushafPage,
  };

  factory SabqiEntry.fromJson(Map<String, dynamic> json) => SabqiEntry(
    juz: json['juz'] as int? ?? 1,
    startPage: json['startPage'] as int? ?? 1,
    endPage: json['endPage'] as int? ?? 1,
    heardPage: json['heardPage'] as int? ?? 1,
    revisionCount: json['revisionCount'] as int? ?? 0,
    isDoubleSabqi: json['isDoubleSabqi'] as bool? ?? false,
    doubleSabqiJuz: json['doubleSabqiJuz'] as int?,
    doubleSabqiRuba: json['doubleSabqiRuba'] as int?,
    mushafPage: json['mushafPage'] as int?,
  );
}

/// Manzil (old review): Juz + Ruba quarter.
@HiveType(typeId: 4)
class ManzilEntry {
  @HiveField(0)
  int juz;

  @HiveField(1)
  int ruba;

  @HiveField(2)
  int? startJuz;

  @HiveField(3)
  int? startRuba;

  @HiveField(4)
  String? customText;

  ManzilEntry({
    this.juz = 1,
    this.ruba = 1,
    this.startJuz,
    this.startRuba,
    this.customText,
  });

  Map<String, dynamic> toJson() => {
    'juz': juz,
    'ruba': ruba,
    'startJuz': startJuz,
    'startRuba': startRuba,
    'customText': customText,
  };

  factory ManzilEntry.fromJson(Map<String, dynamic> json) => ManzilEntry(
    juz: json['juz'] as int? ?? 1,
    ruba: json['ruba'] as int? ?? 1,
    startJuz: json['startJuz'] as int?,
    startRuba: json['startRuba'] as int?,
    customText: json['customText'] as String?,
  );
}
