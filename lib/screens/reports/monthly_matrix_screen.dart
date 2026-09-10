import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/math_engine.dart';
import '../../localization/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_card.dart';

class MonthlyMatrixScreen extends StatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  State<MonthlyMatrixScreen> createState() => _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends State<MonthlyMatrixScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final students = app.sectionStudents;
    final days = AppDateUtils.daysInMonth(_month);
    final monthKey = AppDateUtils.monthKey(_month);
    final monthRecords = app.records
        .where((r) => r.date.startsWith(monthKey))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('monthlyMatrix'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1, 1),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      AppDateUtils.formatMonthYear(_month, l10n.localeName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1, 1),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.t('matrixHint'),
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      l10n.t('noData'),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _MatrixTable(
                        students: students,
                        days: days,
                        records: monthRecords,
                        l10n: l10n,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatrixTable extends StatelessWidget {
  final List students;
  final List<DateTime> days;
  final List records;
  final AppLocalizations l10n;

  const _MatrixTable({
    required this.students,
    required this.days,
    required this.records,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    const cellSize = 30.0;
    const nameWidth = 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: nameWidth,
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                l10n.t('student'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final d in days)
              SizedBox(
                width: cellSize,
                child: Text(
                  '${d.day}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final s in students) ...[
          _MatrixRow(
            student: s,
            days: days,
            records: records,
            cellSize: cellSize,
            nameWidth: nameWidth,
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _MatrixRow extends StatelessWidget {
  final dynamic student;
  final List<DateTime> days;
  final List records;
  final double cellSize;
  final double nameWidth;

  const _MatrixRow({
    required this.student,
    required this.days,
    required this.records,
    required this.cellSize,
    required this.nameWidth,
  });

  @override
  Widget build(BuildContext context) {
    final recordsByDay = <String, dynamic>{
      for (final r in records.where((r) => r.studentId == student.id))
        r.date: r,
    };

    return Row(
      children: [
        Container(
          width: nameWidth,
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              if (student.isStarred)
                Icon(Icons.star_rounded, size: 11, color: AppColors.warning),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final d in days)
          _DayCell(
            record: recordsByDay[AppDateUtils.key(d)],
            size: cellSize,
            onTap: () =>
                _showDayDetail(context, d, recordsByDay[AppDateUtils.key(d)]),
          ),
      ],
    );
  }

  void _showDayDetail(BuildContext context, DateTime day, dynamic record) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${student.name} · ${AppDateUtils.format(day, l10n.localeName)}',
        ),
        content: _buildDetail(record, l10n),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(dynamic record, AppLocalizations l10n) {
    if (record == null) {
      return Text(
        l10n.t('noRecords'),
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }
    final lines = <String>[
      '${record.present ? '✅' : '❌'} ${record.present ? l10n.t('present') : l10n.t('absent')}',
    ];
    if (record.sabaq != null) {
      final s = record.sabaq;
      final pages = s.pages > 0 ? ' · ${s.startPage}–${s.endPage}' : '';
      lines.add(
        '📗 ${l10n.t('sabaq')}: ${l10n.t('juz')} ${s.juz} · ${s.pageLabel} · ${s.lines}$pages',
      );
    }
    if (record.sabqi != null) {
      final calc = MathEngine.computeSabqi(
        startPage: record.sabqi.startPage,
        endPage: record.sabqi.endPage,
        heardPage: record.sabqi.heardPage,
      );
      lines.add(
        '🔁 ${l10n.t('sabqi')}: ${l10n.t('juz')} ${record.sabqi.juz} · ${record.sabqi.startPage}–${record.sabqi.endPage} · ${calc.completedPages}/${calc.totalPages}',
      );
    }
    if (record.manzil != null) {
      final m = record.manzil;
      final isFullPara = (m.startJuz == null || m.startJuz == m.juz) &&
          (m.startRuba == null || m.startRuba == 1) &&
          m.ruba == 4;
      final rubaLabel = isFullPara
          ? l10n.t('pooraPara')
          : (m.startRuba == 1 && m.ruba == 2
              ? l10n.t('nisafAwal')
              : (m.startRuba == 3 && m.ruba == 4
                  ? l10n.t('nisafAkhir')
                  : '${l10n.t('ruba')} ${record.manzil.ruba}'));
      lines.add(
        '📕 ${l10n.t('manzil')}: ${l10n.t('juz')} ${record.manzil.juz} · $rubaLabel',
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(l, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final dynamic record;
  final double size;
  final VoidCallback onTap;

  const _DayCell({
    required this.record,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (record == null) {
      color = Colors.transparent;
    } else if (!record.present) {
      color = AppColors.danger.withValues(alpha: 0.35);
    } else if (record.hasAnyLesson) {
      color = AppColors.primary.withValues(alpha: 0.85);
    } else {
      color = AppColors.primary.withValues(alpha: 0.25);
    }
    final hasLesson = record != null && record.hasAnyLesson;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color == Colors.transparent ? AppColors.glassBorder : color,
          ),
        ),
        child: hasLesson
            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : null,
      ),
    );
  }
}
