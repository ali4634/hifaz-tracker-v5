import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../core/utils/app_date_utils.dart';
import '../localization/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/student.dart';
import '../services/export_service.dart';

/// Shared styling constants for PDF report widgets
class _PdfStyle {
  static const double pageWidth = 595; // A4 width in points (8.27in × 72dpi)
  static const double padding = 24;
  static const double sectionGap = 12;

  static const TextStyle headerTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color.fromARGB(255, 200, 230, 201),
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFF757575),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// DAILY REPORT PDF WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class DailyReportPdfWidget extends StatelessWidget {
  final DateTime date;
  final String section;
  final List<Student> students;
  final List<DailyRecord> records;
  final AppLocalizations l10n;

  const DailyReportPdfWidget({
    super.key,
    required this.date,
    required this.section,
    required this.students,
    required this.records,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final dateKey = AppDateUtils.key(date);
    final dayRecords = records.where((r) => r.date == dateKey).toList();
    // Only this section's students count; no record = absent by default.
    final present = students
        .where((s) => dayRecords.any((r) => r.studentId == s.id && r.present))
        .length;
    final absent = students.length - present;

    final textDir = l10n.isUrdu ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: textDir,
      child: Container(
        width: _PdfStyle.pageWidth,
        color: Colors.white,
        padding: const EdgeInsets.all(_PdfStyle.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header banner
            _buildHeader(present, absent),
            const SizedBox(height: _PdfStyle.sectionGap),
            // Student table
            _buildStudentTable(dayRecords),
            const SizedBox(height: _PdfStyle.sectionGap),
            // Footer
            Text(
              '${l10n.t('generatedOn')} ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
              style: _PdfStyle.smallText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int present, int absent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('appName'), style: _PdfStyle.headerTitle),
                const SizedBox(height: 2),
                Text(
                  l10n.t('dailyReport', args: [
                    AppDateUtils.format(date, l10n.localeName),
                    section,
                  ]),
                  style: _PdfStyle.headerSubtitle,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${l10n.t('totalPresent')}: $present  ${l10n.t('totalAbsent')}: $absent',
              style: _PdfStyle.headerTitle.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTable(List<DailyRecord> dayRecords) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(1.2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 0.5,
      ),
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF424242)),
          children: [
            _tableHeader('#'),
            _tableHeader(l10n.t('student')),
            _tableHeader(l10n.t('sabaq')),
            _tableHeader(l10n.t('sabqi')),
            _tableHeader(l10n.t('manzil')),
            _tableHeader(l10n.t('attendance')),
          ],
        ),
        // Data rows
        for (var i = 0; i < students.length; i++)
          _buildStudentRow(students[i], dayRecords, i),
      ],
    );
  }

  TableRow _buildStudentRow(
    Student student,
    List<DailyRecord> dayRecords,
    int index,
  ) {
    final rec = dayRecords
        .where((r) => r.studentId == student.id)
        .firstOrNull;
    final isEven = index % 2 == 0;

    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
      ),
      children: [
        _tableCell('${index + 1}', center: true),
        _tableCell(student.name, bold: true),
        _tableCell(_formatSabaq(rec)),
        _tableCell(_formatSabqi(rec)),
        _tableCell(_formatManzil(rec)),
        _tableCell(
          rec != null && rec.present ? l10n.t('present') : l10n.t('absent'),
          center: true,
          color: rec != null && rec.present
              ? AppColors.primary
              : AppColors.danger,
          bold: true,
        ),
      ],
    );
  }

  String _formatSabaq(DailyRecord? rec) {
    if (rec?.sabaq == null) return '—';
    final s = rec!.sabaq!;
    return '${l10n.t('juz')} ${s.juz} ${s.pageLabel} (${s.lines})';
  }

  String _formatSabqi(DailyRecord? rec) {
    if (rec?.sabqi == null) return '—';
    final s = rec!.sabqi!;
    return '${l10n.t('juz')} ${s.juz} ${s.startPage}–${s.endPage}';
  }

  String _formatManzil(DailyRecord? rec) {
    if (rec?.manzil == null) return '—';
    final m = rec!.manzil!;
    return '${l10n.t('juz')} ${m.juz} ${l10n.t('ruba')} ${m.ruba}';
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: _PdfStyle.bodyText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool center = false,
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: _PdfStyle.bodyText.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STUDENT MONTHLY REPORT PDF WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class StudentMonthlyReportPdfWidget extends StatelessWidget {
  final Student student;
  final DateTime month;
  final List<DailyRecord> records;
  final AppSettings settings;
  final AppLocalizations l10n;

  const StudentMonthlyReportPdfWidget({
    super.key,
    required this.student,
    required this.month,
    required this.records,
    required this.settings,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final monthRecords = records
        .where((r) =>
            r.studentId == student.id &&
            r.date.startsWith(AppDateUtils.monthKey(month)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final stats = StudentMonthlyStats.compute(
      records: monthRecords,
      linesPerPage: student.mushafLines,
    );

    final totalDays = stats.presentDays + stats.absentDays;
    final attendancePct =
        totalDays > 0 ? ((stats.presentDays / totalDays) * 100).round() : 0;

    final bt = settings.gradingBehtareen;
    final bh = settings.gradingBehtar;
    final ac = settings.gradingAcha;
    final sabaqGrade = stats.sabaqGrade(l10n.t, behtareen: bt, behtar: bh, acha: ac);
    final sabqiGrade = stats.sabqiGrade(l10n.t, behtareen: bt, behtar: bh, acha: ac);
    final manzilGrade = stats.manzilGrade(l10n.t, behtareen: bt, behtar: bh, acha: ac);
    final overall = stats.overallGrade(l10n.t, behtareen: bt, behtar: bh, acha: ac);

    final textDir = l10n.isUrdu ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: textDir,
      child: Container(
        width: _PdfStyle.pageWidth,
        color: Colors.white,
        padding: const EdgeInsets.all(_PdfStyle.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header
            _buildHeader(),
            const SizedBox(height: 10),
            // 2. Student info bar
            _buildStudentInfoBar(),
            const SizedBox(height: 10),
            // 3. KPI Grid
            _buildKpiGrid(attendancePct, stats, sabaqGrade, sabqiGrade, manzilGrade),
            const SizedBox(height: 10),
            // 4. Overall grade
            _buildOverallGrade(overall),
            const SizedBox(height: 10),
            // 5. Daily records table
            _buildDailyRecords(monthRecords),
            const SizedBox(height: 10),
            // 6. Parents message
            _buildParentsMessage(),
            const SizedBox(height: 8),
            // 7. Footer
            Text(
              '${l10n.t('generatedOn')} ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
              style: _PdfStyle.smallText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final monthName = AppDateUtils.formatMonthYear(month, l10n.localeName);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.madrasaName.isNotEmpty
                      ? settings.madrasaName
                      : l10n.t('appName'),
                  style: _PdfStyle.headerTitle,
                ),
                const SizedBox(height: 2),
                Text(l10n.t('monthlyHifzReport'), style: _PdfStyle.headerSubtitle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(monthName, style: _PdfStyle.headerTitle.copyWith(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${l10n.t('studentLabel')}: ${student.name} (${l10n.t('section')} ${student.section})',
              style: _PdfStyle.bodyText.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (settings.teacherName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '${l10n.t('teacherLabel')}: ${settings.teacherName}',
              style: _PdfStyle.smallText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    int attendancePct,
    StudentMonthlyStats stats,
    String sabaqGrade,
    String sabqiGrade,
    String manzilGrade,
  ) {
    return Row(
      children: [
        _kpiCard(
          title: l10n.t('attendance'),
          value: '$attendancePct%',
          subtitle: '${stats.presentDays} ${l10n.t('present')} / ${stats.absentDays} ${l10n.t('absent')}',
          color: AppColors.primary,
          grade: null,
        ),
        const SizedBox(width: 6),
        _kpiCard(
          title: l10n.t('sabaqSummaryTitle'),
          value: '${stats.sabaqLessons} ${l10n.t('lessonsCount')}',
          subtitle: stats.sabaqPages > 0 ? '${stats.sabaqPages} ${l10n.t('pagesCount')}' : '—',
          color: AppColors.info,
          grade: sabaqGrade,
        ),
        const SizedBox(width: 6),
        _kpiCard(
          title: l10n.t('sabqiSummaryTitle'),
          value: '${stats.sabqiLessons} ${l10n.t('lessonsCount')}',
          subtitle: '${stats.sabqiCompletedPages}/${stats.sabqiTotalPages} ${l10n.t('pagesCount')}',
          color: AppColors.indigo,
          grade: sabqiGrade,
        ),
        const SizedBox(width: 6),
        _kpiCard(
          title: l10n.t('manzilSummaryTitle'),
          value: '${stats.manzilLessons} ${l10n.t('lessonsCount')}',
          subtitle: '${stats.manzilRubas} ${l10n.t('rubasCount')}',
          color: AppColors.primary,
          grade: manzilGrade,
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    String? grade,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _PdfStyle.bodyText.copyWith(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                if (grade != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    grade,
                    style: _PdfStyle.bodyText.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: _gradeColor(grade),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: _PdfStyle.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _PdfStyle.smallText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallGrade(String overall) {
    final color = _gradeColor(overall);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${l10n.t('overallPerformance')}:',
            style: _PdfStyle.bodyText.copyWith(fontWeight: FontWeight.w800),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              overall,
              style: _PdfStyle.bodyText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecords(List<DailyRecord> monthRecords) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF424242),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            '${l10n.t('dailyRecordUrdu')} (${monthRecords.length})',
            style: _PdfStyle.bodyText.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (monthRecords.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Text(l10n.t('noRecords'), style: _PdfStyle.smallText),
          )
        else
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(2.2),
              3: FlexColumnWidth(1.8),
              4: FlexColumnWidth(1.4),
            },
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF616161)),
                children: [
                  _tableHeader(l10n.t('dateUrdu')),
                  _tableHeader(l10n.t('attendanceUrdu')),
                  _tableHeader(l10n.t('sabaqUrdu')),
                  _tableHeader(l10n.t('sabqiUrdu')),
                  _tableHeader(l10n.t('manzilUrdu')),
                ],
              ),
              for (var i = 0; i < monthRecords.length; i++)
                _buildRecordRow(monthRecords[i], i),
            ],
          ),
      ],
    );
  }

  TableRow _buildRecordRow(DailyRecord r, int index) {
    final isEven = index % 2 == 0;
    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
      ),
      children: [
        _tableCell(
          AppDateUtils.format(AppDateUtils.fromKey(r.date), l10n.localeName),
          bold: true,
        ),
        _tableCell(
          r.present ? l10n.t('present') : l10n.t('absent'),
          center: true,
          color: r.present ? AppColors.primary : AppColors.danger,
          bold: true,
        ),
        _tableCell(
          r.sabaq == null
              ? '—'
              : '${l10n.t('juz')} ${r.sabaq!.juz}, ${r.sabaq!.startPage}–${r.sabaq!.endPage}',
        ),
        _tableCell(
          r.sabqi == null
              ? '—'
              : '${l10n.t('juz')} ${r.sabqi!.juz}, ${r.sabqi!.startPage}–${r.sabqi!.endPage}',
        ),
        _tableCell(
          r.manzil == null
              ? '—'
              : '${l10n.t('juz')} ${r.manzil!.juz}, ${l10n.t('ruba')} ${r.manzil!.ruba}',
        ),
      ],
    );
  }

  Widget _buildParentsMessage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF9A825), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF9A825),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              l10n.t('parentsMessageTitle'),
              style: _PdfStyle.bodyText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              l10n.t('parentsMessage'),
              style: _PdfStyle.bodyText.copyWith(fontSize: 9.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String grade) {
    if (grade == l10n.t('gradeExcellent')) return AppColors.primary;
    if (grade == l10n.t('gradeGood')) return AppColors.indigo;
    if (grade == l10n.t('gradePassable')) return AppColors.info;
    return AppColors.danger;
  }

  // Reuse table helpers from DailyReport
  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        style: _PdfStyle.bodyText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool center = false,
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: _PdfStyle.bodyText.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COLLECTIVE REPORT PDF WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class CollectiveReportPdfWidget extends StatelessWidget {
  final DateTime month;
  final List<Student> students;
  final List<DailyRecord> records;
  final AppLocalizations l10n;

  const CollectiveReportPdfWidget({
    super.key,
    required this.month,
    required this.students,
    required this.records,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final monthKey = AppDateUtils.monthKey(month);
    final sortedStudents = students.toList()
      ..sort((a, b) {
        if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final textDir = l10n.isUrdu ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: textDir,
      child: Container(
        width: _PdfStyle.pageWidth,
        color: Colors.white,
        padding: const EdgeInsets.all(_PdfStyle.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: _PdfStyle.sectionGap),
            // Student table
            _buildStudentTable(sortedStudents, monthKey),
            const SizedBox(height: _PdfStyle.sectionGap),
            // Footer
            Text(
              '${l10n.t('generatedOn')} ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}',
              style: _PdfStyle.smallText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              l10n.t('collectiveReport'),
              style: _PdfStyle.headerTitle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppDateUtils.formatMonthYear(month, l10n.localeName),
            style: _PdfStyle.headerSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTable(List<Student> sortedStudents, String monthKey) {
    if (sortedStudents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(l10n.t('noRecords'), style: _PdfStyle.smallText),
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 0.5,
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF424242)),
          children: [
            _tableHeader('#'),
            _tableHeader(l10n.t('student')),
            _tableHeader(l10n.t('attendance')),
            _tableHeader(l10n.t('sabaq')),
            _tableHeader(l10n.t('sabqi')),
            _tableHeader(l10n.t('manzil')),
          ],
        ),
        for (var i = 0; i < sortedStudents.length; i++)
          _buildRow(sortedStudents[i], monthKey, i),
      ],
    );
  }

  TableRow _buildRow(Student student, String monthKey, int index) {
    final monthRecords = records
        .where((r) => r.studentId == student.id && r.date.startsWith(monthKey))
        .toList();
    final stats = StudentMonthlyStats.compute(
      records: monthRecords,
      linesPerPage: student.mushafLines,
    );
    final isEven = index % 2 == 0;

    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
      ),
      children: [
        _tableCell('${index + 1}', center: true),
        _tableCell(student.name, bold: true),
        _tableCell(
          '${stats.presentDays}/${stats.presentDays + stats.absentDays}',
          center: true,
        ),
        _tableCell('${stats.sabaqLessons}', center: true),
        _tableCell('${stats.sabqiLessons}', center: true),
        _tableCell('${stats.manzilLessons}', center: true),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: _PdfStyle.bodyText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool center = false,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: _PdfStyle.bodyText.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: 9.5,
        ),
      ),
    );
  }
}
