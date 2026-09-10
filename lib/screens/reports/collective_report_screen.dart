import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../localization/app_localizations.dart';
import '../../models/daily_record.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';

/// Collective monthly report: one summary card per student with the monthly
/// khulasa and the latest logged lesson. Ported from v4's CollectiveReportScreen.
class CollectiveReportScreen extends StatefulWidget {
  const CollectiveReportScreen({super.key});

  @override
  State<CollectiveReportScreen> createState() => _CollectiveReportScreenState();
}

class _CollectiveReportScreenState extends State<CollectiveReportScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _previousMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1, 1);
    if (next.isAfter(DateTime(now.year, now.month, 1))) return;
    setState(() => _month = next);
  }

  Future<void> _share() async {
    final app = context.read<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final text = ExportService.instance.buildCollectiveTextReport(
      month: _month,
      students: app.students,
      records: app.records,
      t: (key, {args}) => l10n.t(key, args: args ?? const []),
      locale: l10n.localeName,
    );
    await ExportService.instance.shareText(
      text,
      subject: l10n.t('collectiveReport'),
    );
  }

  Future<void> _sharePdf() async {
    final app = context.read<AppProvider>();
    final l10n = AppLocalizations.of(context);
    try {
      final bytes = await ScreenshotPdfExport.instance.buildCollectivePdfReport(
        context: context,
        month: _month,
        students: app.students,
        records: app.records,
      );
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('errorGenerating'))),
          );
        }
        return;
      }
      await ExportService.instance.sharePdf(
        bytes,
        filename: 'hifaz_collective_${AppDateUtils.monthKey(_month)}.pdf',
      );
    } catch (e) {
      debugPrint('Collective PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('errorGenerating')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final monthKey = AppDateUtils.monthKey(_month);
    final monthRecords = app.records
        .where((r) => r.date.startsWith(monthKey))
        .toList();
    final students = app.students.toList()
      ..sort((a, b) {
        if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('collectiveReport')),
        actions: [
          IconButton(
            tooltip: l10n.t('exportPdf'),
            onPressed: _sharePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: l10n.t('shareText'),
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
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
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? EmptyState(
                    icon: Icons.group_off_rounded,
                    title: l10n.t('noStudents'),
                    description: l10n.t('noStudentsDesc'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: students.length,
                    itemBuilder: (context, i) => _StudentReportCard(
                      student: students[i],
                      monthRecords: monthRecords,
                      l10n: l10n,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentReportCard extends StatelessWidget {
  final Student student;
  final List<DailyRecord> monthRecords;
  final AppLocalizations l10n;

  const _StudentReportCard({
    required this.student,
    required this.monthRecords,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final records =
        monthRecords.where((r) => r.studentId == student.id).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final stats = StudentMonthlyStats.compute(
      records: records,
      linesPerPage: student.mushafLines,
    );

    final lastLesson = records.reversed
        .where((r) => r.hasAnyLesson)
        .firstOrNull;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (student.isStarred) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${l10n.t('section')} ${student.section}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('monthlyKhulasa'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatItem(
                      label: l10n.t('attendanceRate'),
                      value:
                          '${stats.presentDays}/${stats.presentDays + stats.absentDays}',
                      color: AppColors.primary,
                    ),
                    _StatItem(
                      label: l10n.t('sabaq'),
                      value: '${stats.sabaqLessons}',
                      color: AppColors.info,
                    ),
                    _StatItem(
                      label: l10n.t('sabqi'),
                      value: '${stats.sabqiLessons}',
                      color: AppColors.indigo,
                    ),
                    _StatItem(
                      label: l10n.t('manzil'),
                      value: '${stats.manzilLessons}',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (lastLesson != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.t('lastRecords'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            _LastLessonText(record: lastLesson, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LastLessonText extends StatelessWidget {
  final DailyRecord record;
  final AppLocalizations l10n;

  const _LastLessonText({required this.record, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (record.sabaq != null) {
      parts.add(
        '${l10n.t('sabaq')}: ${l10n.t('juz')} ${record.sabaq!.juz} ${record.sabaq!.pageLabel}',
      );
    }
    if (record.sabqi != null) {
      parts.add(
        '${l10n.t('sabqi')}: ${record.sabqi!.startPage}–${record.sabqi!.endPage}',
      );
    }
    if (record.manzil != null) {
      parts.add(
        '${l10n.t('manzil')}: ${l10n.t('juz')} ${record.manzil!.juz} R${record.manzil!.ruba}',
      );
    }
    final date = AppDateUtils.format(
      AppDateUtils.fromKey(record.date),
      l10n.localeName,
    );
    return Text(
      '${parts.isEmpty ? l10n.t('noLesson') : parts.join(' · ')} — $date',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}
