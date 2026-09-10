import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/math_engine.dart';
import '../../core/utils/warning_engine.dart';
import '../../localization/app_localizations.dart';
import '../../models/daily_record.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/progress_ring.dart';
import '../reports/student_monthly_report_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final students = app.sectionStudents;
    final dateKey = AppDateUtils.key(app.selectedDate);
    final dayRecords = app.records.where((r) => r.date == dateKey).toList();
    // Only this section's students count; no record = absent by default.
    final present = students.where((s) {
      final rec = dayRecords.where((r) => r.studentId == s.id).firstOrNull;
      return rec != null && rec.present;
    }).length;
    final absent = students.length - present;
    final flagged = students
        .where((s) => app.warningsFor(s.id).isNotEmpty)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        Row(
          children: [
            _StatTile(
              icon: Icons.group_rounded,
              color: AppColors.indigo,
              value: students.length,
              label: l10n.t('totalStudents'),
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.check_circle_rounded,
              color: AppColors.primary,
              value: present,
              label: l10n.t('presentToday'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatTile(
              icon: Icons.cancel_rounded,
              color: AppColors.danger,
              value: absent,
              label: l10n.t('absentToday'),
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              value: flagged,
              label: l10n.t('flaggedStudents'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (flagged > 0) ...[_WarningCenter(), const SizedBox(height: 18)],
        Text(
          l10n.t('currentStanding'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(
                  Icons.donut_large_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('noData'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          for (final s in students) ...[
            _StudentProgressCard(student: s),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
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

class _WarningCenter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final flaggedStudents = app.sectionStudents
        .where((s) => app.warningsFor(s.id).isNotEmpty)
        .toList();

    return GlassCard(
      borderColor: AppColors.warning.withValues(alpha: 0.4),
      glowColor: AppColors.warning,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('needsAttention'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final s in flaggedStudents) ...[
            _WarningRow(student: s, warnings: app.warningsFor(s.id)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  final Student student;
  final List<WarningInfo> warnings;

  const _WarningRow({required this.student, required this.warnings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.read<AppProvider>();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                for (final w in warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      _warningText(w, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              for (final w in warnings) {
                await app.acknowledgeWarning(student.id, w);
              }
            },
            child: Text(l10n.t('acknowledge')),
          ),
        ],
      ),
    );
  }

  String _warningText(WarningInfo w, AppLocalizations l10n) => switch (w.type) {
    'inactivity' => '⚠ ${l10n.t('warnInactivity', args: ['${w.count}'])}',
    'repetition' => '🔁 ${l10n.t('warnRepetition', args: ['${w.count}'])}',
    'skippedPages' => '📄 ${l10n.t('warnSkipped', args: ['${w.count}'])}',
    'manzilSkip' => '🔄 ${l10n.t('warnManzilSkip', args: ['${w.count}'])}',
    _ => '❌ ${l10n.t('warnAbsence', args: ['${w.count}', '10'])}',
  };
}

class _StudentProgressCard extends StatelessWidget {
  final Student student;

  const _StudentProgressCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final warnings = app.warningsFor(student.id);

    // Manzil ring
    final totalRubas = MathEngine.manzilTotalRubas(
      student.manzilStartJuz,
      student.manzilEndJuz,
    );
    final pos = ManzilPosition(
      student.currentManzilJuz,
      student.currentManzilRuba,
    );
    final idx = pos.isSet
        ? MathEngine.manzilIndexInCycle(
            pos,
            student.manzilStartJuz,
            reverse: student.manzilReverse,
          )
        : 0;
    final cycleProgress = totalRubas == 0
        ? 0.0
        : (idx / totalRubas).clamp(0.0, 1.0);
    final percent = (cycleProgress * 100).round();

    // Sabqi: latest record
    final sRecords = app.recordsForStudent(student.id);
    DailyRecord? latest;
    for (final r in sRecords.reversed) {
      if (r.sabqi != null) {
        latest = r;
        break;
      }
    }
    SabqiCalc? sabqiCalc;
    if (latest?.sabqi != null) {
      sabqiCalc = MathEngine.computeParaSabqi(
        juz: latest!.sabqi!.juz,
        startPage: latest.sabqi!.startPage,
        endPage: latest.sabqi!.endPage,
        heardPage: latest.sabqi!.heardPage,
        linesPerPage: student.mushafLines,
      );
    }

    return GlassCard(
      borderColor: warnings.isNotEmpty
          ? AppColors.warning.withValues(alpha: 0.45)
          : null,
      glowColor: warnings.isNotEmpty ? AppColors.warning : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (student.isStarred)
                Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
              if (warnings.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ProgressRing(
                value: cycleProgress,
                size: 84,
                strokeWidth: 8,
                color: AppColors.primary,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primarySoft,
                      ),
                    ),
                    Text(
                      l10n.t('manzilProgress').split(' ').first,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📕 ${l10n.t('manzilProgress')}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primarySoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🔄 ${l10n.t('completedCycles', args: ['${student.manzilCycle}'])}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${l10n.t('nextManzilLesson', args: [
                        '${student.currentManzilJuz}',
                        '${l10n.t('ruba')} ${student.currentManzilRuba}'
                      ])}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sabqiCalc != null) ...[
                      Text(
                        '🔁 ${l10n.t('sabqiStatus')} · ${l10n.t('juz')} ${latest!.sabqi!.juz}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: sabqiCalc.progress / 100,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: sabqiCalc.remainingPages > 0
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sabqiCalc.completedPages}/${sabqiCalc.totalPages} · ${sabqiCalc.progress}%'
                        '${sabqiCalc.remainingPages > 0 ? ' · ⚠️ ${sabqiCalc.remainingPages} ${l10n.t('remainingPages')}' : ''}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentMonthlyReportScreen(student: student),
                ),
              ),
              icon: const Icon(Icons.calendar_month_rounded, size: 15),
              label: Text(l10n.t('viewProfile')),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primarySoft,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
