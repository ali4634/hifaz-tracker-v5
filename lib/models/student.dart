import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../core/utils/id_gen.dart';

part 'student.g.dart';

/// A student in a Hifz section, holding their Manzil / Sabqi configuration
/// and current review position.
@HiveType(typeId: 0)
class Student {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  /// Section: 'A', 'B' or 'C'.
  @HiveField(3)
  String section;

  /// Watchlist / star system: pinned students appear first.
  @HiveField(4)
  bool isStarred;

  // ── Manzil configuration ──────────────────────────────────────────────────
  @HiveField(5)
  int manzilStartJuz;

  @HiveField(6)
  int manzilEndJuz;

  /// Direction mode. true → reverse order (e.g. Juz 30 → 25), false → straight.
  @HiveField(7)
  bool manzilReverse;

  // ── Sabqi target ──────────────────────────────────────────────────────────
  @HiveField(8)
  int sabqiTargetJuz;

  @HiveField(9)
  int sabqiTargetPages;

  // ── Current position (the next Manzil lesson to be taught) ────────────────
  @HiveField(10)
  int currentManzilJuz;

  @HiveField(11)
  int currentManzilRuba;

  /// Number of completed Manzil cycles (wrap-arounds).
  @HiveField(12)
  int manzilCycle;

  /// Acknowledgement keys of dismissed warnings, e.g. "inactivity|2026-08-05".
  @HiveField(13)
  List<String> acknowledgedWarnings;

  @HiveField(14)
  String createdAt;

  /// Mushaf lines per page (15 or 16) — drives para-based page calculation.
  @HiveField(15)
  int mushafLines;

  Student({
    required this.id,
    required this.name,
    this.phone = '',
    this.section = 'A',
    this.isStarred = false,
    this.manzilStartJuz = 1,
    this.manzilEndJuz = 30,
    this.manzilReverse = false,
    this.sabqiTargetJuz = 1,
    this.sabqiTargetPages = 10,
    this.currentManzilJuz = 1,
    this.currentManzilRuba = 1,
    this.manzilCycle = 0,
    this.mushafLines = AppConstants.defaultMushafLines,
    List<String>? acknowledgedWarnings,
    String? createdAt,
  }) : acknowledgedWarnings = acknowledgedWarnings ?? [],
       createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Student.empty() => Student(id: IdGen.newId(), name: '');

  /// Whether the current position sits at the very start of the cycle.
  bool get isAtCycleStart =>
      currentManzilJuz == manzilStartJuz && currentManzilRuba == 1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'section': section,
    'isStarred': isStarred,
    'manzilStartJuz': manzilStartJuz,
    'manzilEndJuz': manzilEndJuz,
    'manzilReverse': manzilReverse,
    'sabqiTargetJuz': sabqiTargetJuz,
    'sabqiTargetPages': sabqiTargetPages,
    'currentManzilJuz': currentManzilJuz,
    'currentManzilRuba': currentManzilRuba,
    'manzilCycle': manzilCycle,
    'mushafLines': mushafLines,
    'acknowledgedWarnings': acknowledgedWarnings,
    'createdAt': createdAt,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as String? ?? IdGen.newId(),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    section: json['section'] as String? ?? 'A',
    isStarred: json['isStarred'] as bool? ?? false,
    manzilStartJuz: json['manzilStartJuz'] as int? ?? 1,
    manzilEndJuz: json['manzilEndJuz'] as int? ?? 30,
    manzilReverse: json['manzilReverse'] as bool? ?? false,
    sabqiTargetJuz: json['sabqiTargetJuz'] as int? ?? 1,
    sabqiTargetPages: json['sabqiTargetPages'] as int? ?? 10,
    currentManzilJuz:
        json['currentManzilJuz'] as int? ?? json['manzilStartJuz'] as int? ?? 1,
    currentManzilRuba: json['currentManzilRuba'] as int? ?? 1,
    manzilCycle: json['manzilCycle'] as int? ?? 0,
    mushafLines: json['mushafLines'] as int? ?? AppConstants.defaultMushafLines,
    acknowledgedWarnings:
        (json['acknowledgedWarnings'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
    createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
  );
}
