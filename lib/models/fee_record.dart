import 'package:hive_flutter/hive_flutter.dart';

import '../core/utils/id_gen.dart';

part 'fee_record.g.dart';

/// A monthly fee record for a student.
@HiveType(typeId: 5)
class FeeRecord {
  @HiveField(0)
  String id;

  @HiveField(1)
  String studentId;

  /// Month (1-12).
  @HiveField(2)
  int month;

  /// Year (e.g. 2026).
  @HiveField(3)
  int year;

  /// Whether the fee has been paid.
  @HiveField(4)
  bool paid;

  /// Date when the fee was marked as paid ('yyyy-MM-dd').
  @HiveField(5)
  String? paidDate;

  FeeRecord({
    required this.id,
    required this.studentId,
    required this.month,
    required this.year,
    this.paid = false,
    this.paidDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'month': month,
    'year': year,
    'paid': paid,
    'paidDate': paidDate,
  };

  factory FeeRecord.fromJson(Map<String, dynamic> json) => FeeRecord(
    id: json['id'] as String? ?? IdGen.newId(),
    studentId: json['studentId'] as String? ?? '',
    month: json['month'] as int? ?? DateTime.now().month,
    year: json['year'] as int? ?? DateTime.now().year,
    paid: json['paid'] as bool? ?? false,
    paidDate: json['paidDate'] as String?,
  );

  /// Unique key for this student's fee in a specific month.
  static String feeKey(String studentId, int month, int year) =>
      '${studentId}_${year}_${month.toString().padLeft(2, '0')}';
}
