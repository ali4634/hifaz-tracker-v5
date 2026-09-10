import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/naagha_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../reports/student_monthly_report_screen.dart';

/// Attention-grabbing list of students who made a gap (naagha) in Sabaq,
/// Sabqi or Manzil, with the number of days since their last recitation.
///
/// Opening this screen counts as "viewing" the alerts: the bell badge clears
/// for everything shown here until a NEW gap appears.
class NaaghaScreen extends StatefulWidget {
  const NaaghaScreen({super.key});

  @override
  State<NaaghaScreen> createState() => _NaaghaScreenState();
}

class _NaaghaScreenState extends State<NaaghaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppProvider>();
      final settings = context.read<SettingsProvider>();
      final alerts = app.naaghaAlerts(settings.settings.missingSabqiDays);
      app.markNaaghaSeen(alerts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final threshold = settings.settings.missingSabqiDays;

    final alerts = app.naaghaAlerts(threshold);
    // Group by student, keeping the most severe (longest) gap for sorting.
    final byStudent = <String, List<NaaghaAlert>>{};
    for (final a in alerts) {
      byStudent.putIfAbsent(a.student.id, () => []).add(a);
    }
    final students = byStudent.values.toList()
      ..sort((a, b) {
        final maxA = a.map((x) => x.daysWithout).reduce((x, y) => x > y ? x : y);
        final maxB = b.map((x) => x.daysWithout).reduce((x, y) => x > y ? x : y);
        if (maxA != maxB) return maxB - maxA;
        return a.first.student.name
            .toLowerCase()
            .compareTo(b.first.student.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('naaghaAlerts')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l10n.t(
                  'naaghaThreshold',
                  args: ['$threshold'],
                ),
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? EmptyState(
              icon: Icons.task_alt_rounded,
              title: l10n.t('naaghaEmpty'),
              description: l10n.t('naaghaEmptyDesc'),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: students.length,
              itemBuilder: (context, i) => _NaaghaStudentCard(
                alerts: students[i],
                thresholdDays: threshold,
              ),
            ),
    );
  }
}

class _NaaghaStudentCard extends StatelessWidget {
  final List<NaaghaAlert> alerts;
  final int thresholdDays;

  const _NaaghaStudentCard({
    required this.alerts,
    required this.thresholdDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final student = alerts.first.student;
    final worst = alerts
        .map((a) => a.daysWithout)
        .reduce((x, y) => x > y ? x : y);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: worst >= thresholdDays * 2
          ? AppColors.danger.withValues(alpha: 0.5)
          : AppColors.warning.withValues(alpha: 0.5),
      glowColor: worst >= thresholdDays * 2 ? AppColors.danger : AppColors.warning,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentMonthlyReportScreen(student: student),
        ),
      ),
      child: Row(
        children: [
          _Avatar(student: student),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${l10n.t('section')} ${student.section}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final a in alerts) _TrackChip(alert: a, l10n: l10n),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Student student;

  const _Avatar({required this.student});

  @override
  Widget build(BuildContext context) {
    final initials = student.name.trim().isEmpty
        ? '?'
        : student.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.danger, AppColors.warning],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TrackChip extends StatelessWidget {
  final NaaghaAlert alert;
  final AppLocalizations l10n;

  const _TrackChip({required this.alert, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (alert.track) {
      NaaghaTrack.sabaq => (l10n.t('sabaq'), AppColors.info),
      NaaghaTrack.sabqi => (l10n.t('sabqi'), AppColors.indigo),
      NaaghaTrack.manzil => (l10n.t('manzil'), AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        l10n.t('naaghaTrackChip', args: [label, '${alert.daysWithout}']),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
