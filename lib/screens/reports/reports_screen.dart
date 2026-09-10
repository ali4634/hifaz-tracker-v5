import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../localization/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/date_selector_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import 'collective_report_screen.dart';
import 'monthly_matrix_screen.dart';
import 'student_monthly_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final students = app.sectionStudents;
    final dateKey = AppDateUtils.key(app.selectedDate);
    final dayRecords = app.records.where((r) => r.date == dateKey).toList();

    // Only students of this section count; a student with no record for the
    // day is absent by default (teacher must mark them present).
    final present = students.where((s) {
      final rec = dayRecords.where((r) => r.studentId == s.id).firstOrNull;
      return rec != null && rec.present;
    }).length;
    final absent = students.length - present;
    final sabaqCount = dayRecords.where((r) => r.sabaq != null).length;
    final sabqiCount = dayRecords.where((r) => r.sabqi != null).length;
    final manzilCount = dayRecords.where((r) => r.manzil != null).length;

    final absentNames = <String>[];
    for (final s in students) {
      final rec = dayRecords.where((r) => r.studentId == s.id).firstOrNull;
      if (rec == null || !rec.present) absentNames.add(s.name);
    }
    final attention = students
        .where((s) => app.warningsFor(s.id).isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        DateSelectorRow(date: app.selectedDate, onDateChanged: app.setDate),
        const SizedBox(height: 8),
        Row(
          children: [
            _BigStat(
              color: AppColors.primary,
              icon: Icons.check_circle_rounded,
              value: '$present',
              label: l10n.t('totalPresent'),
            ),
            const SizedBox(width: 10),
            _BigStat(
              color: AppColors.danger,
              icon: Icons.cancel_rounded,
              value: '$absent',
              label: l10n.t('totalAbsent'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('lessonsRecited'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _LessonStat(
                    color: AppColors.info,
                    label: l10n.t('sabaqCount'),
                    value: '$sabaqCount',
                  ),
                  const SizedBox(width: 8),
                  _LessonStat(
                    color: AppColors.indigo,
                    label: l10n.t('sabqiCount'),
                    value: '$sabqiCount',
                  ),
                  const SizedBox(width: 8),
                  _LessonStat(
                    color: AppColors.primary,
                    label: l10n.t('manzilCount'),
                    value: '$manzilCount',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (absentNames.isNotEmpty)
          GlassCard(
            borderColor: AppColors.danger.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '❌ ${l10n.t('absentList')} (${absentNames.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final n in absentNames)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          n,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (attention.isNotEmpty) ...[
          const SizedBox(height: 10),
          GlassCard(
            borderColor: AppColors.warning.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ ${l10n.t('attentionList')} (${attention.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in attention)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${s.name}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.bar_chart_rounded,
              title: l10n.t('noData'),
              description: l10n.t('noStudentsDesc'),
            ),
          ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('exportReport'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _ExportButton(
                icon: Icons.ios_share_rounded,
                label: l10n.t('shareText'),
                color: AppColors.info,
                onTap: () => _shareText(context),
              ),
              const SizedBox(height: 8),
              _ExportButton(
                icon: Icons.picture_as_pdf_rounded,
                label: l10n.t('exportPdf'),
                color: AppColors.danger,
                onTap: () => _exportPdf(context),
              ),
              const SizedBox(height: 8),
              _ExportButton(
                icon: Icons.calendar_month_rounded,
                label: l10n.t('viewMatrix'),
                color: AppColors.indigo,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MonthlyMatrixScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ExportButton(
                icon: Icons.person_search_rounded,
                label: l10n.t('openStudentReport'),
                color: AppColors.primary,
                onTap: () => _pickStudent(context),
              ),
              const SizedBox(height: 8),
              _ExportButton(
                icon: Icons.groups_rounded,
                label: l10n.t('collectiveReport'),
                color: AppColors.warning,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CollectiveReportScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickStudent(BuildContext context) {
    final app = context.read<AppProvider>();
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.bgElevated.withValues(alpha: 0.97)
              : AppColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.t('openStudentReport'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: app.students.isEmpty
                  ? Center(
                      child: Text(
                        l10n.t('noStudents'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: app.students.length,
                      itemBuilder: (ctx, i) {
                        final s = app.students[i];
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentMonthlyReportScreen(student: s),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.indigo.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${l10n.t('section')} ${s.section}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.indigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareText(BuildContext context) {
    final app = context.read<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final text = ExportService.instance.buildDailyTextReport(
      date: app.selectedDate,
      section: app.selectedSection,
      students: app.sectionStudents,
      records: app.records,
      t: (key, {args}) => l10n.t(key, args: args ?? const []),
      locale: l10n.localeName,
    );
    ExportService.instance.shareText(text, subject: l10n.t('appName'));
  }

  Future<void> _exportPdf(BuildContext context) async {
    final app = context.read<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await ScreenshotPdfExport.instance.buildDailyPdfReport(
        context: context,
        date: app.selectedDate,
        section: app.selectedSection,
        students: app.sectionStudents,
        records: app.records,
      );
      if (bytes.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.t('errorGenerating'))),
        );
        return;
      }
      await ExportService.instance.sharePdf(
        bytes,
        filename: 'hifaz_report_${AppDateUtils.key(app.selectedDate)}.pdf',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('errorGenerating'))),
      );
    }
  }
}

class _BigStat extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String label;

  const _BigStat({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonStat extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LessonStat({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
