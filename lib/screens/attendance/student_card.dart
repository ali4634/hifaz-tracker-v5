import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/math_engine.dart';
import '../../core/utils/para_calculator.dart';
import '../../core/utils/warning_engine.dart';
import '../../localization/app_localizations.dart';
import '../../models/daily_record.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/warning_badge.dart';
import '../students/student_form_screen.dart';

/// One student's attendance + lesson row for the selected date.
class StudentCard extends StatefulWidget {
  final Student student;
  final DailyRecord? record;
  final VoidCallback onRecordLesson;
  final VoidCallback? onTapName;

  const StudentCard({
    super.key,
    required this.student,
    required this.record,
    required this.onRecordLesson,
    this.onTapName,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final warnings = app.warningsFor(widget.student.id);
    // No record for this date = absent by default; the teacher must mark
    // the student present explicitly.
    final isPresent = widget.record?.present ?? false;
    final borderColor = warnings.isNotEmpty ? AppColors.warning : null;
    final hasLesson = widget.record?.hasAnyLesson ?? false;
    final studentRecords = app.recordsForStudent(widget.student.id);
    final sabaqRec = studentRecords.reversed
        .cast<DailyRecord?>()
        .firstWhere((r) => r != null && r.sabaq != null, orElse: () => null);
    final sabqiRec = studentRecords.reversed
        .cast<DailyRecord?>()
        .firstWhere((r) => r != null && r.sabqi != null, orElse: () => null);
    final manzilRec = studentRecords.reversed
        .cast<DailyRecord?>()
        .firstWhere((r) => r != null && r.manzil != null, orElse: () => null);
    final showSummary = sabaqRec != null || sabqiRec != null || manzilRec != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderColor: borderColor?.withValues(alpha: 0.5),
          glowColor: borderColor,
          fill: isDark ? null : Colors.white,
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Name + Attendance Toggle + Edit Button
          Row(
            children: [
              Expanded(
                child:                  GestureDetector(
                  onTap: widget.onTapName ?? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentFormScreen(existing: widget.student),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.student.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (widget.student.isStarred) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AttendanceToggle(
                isPresent: isPresent,
                onTap: () => app.toggleAttendance(widget.student.id),
              ),
              const SizedBox(width: 8),
              _RecordButton(
                label: hasLesson
                    ? l10n.t('editLesson')
                    : l10n.t('recordLesson'),
                onTap: widget.onRecordLesson,
              ),
            ],
          ),

          // Lesson summary or no lesson text
          if (showSummary) ...[
            const SizedBox(height: 10),
            _LessonSummary(
              sabaqRecord: sabaqRec,
              sabqiRecord: sabqiRec,
              manzilRecord: manzilRec,
              todayRecord: widget.record,
              l10n: l10n,
              mushafLines: widget.student.mushafLines,
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              l10n.t('noLesson'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Warnings
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final w in warnings)
                  WarningBadge(
                    label: _warningLabel(w, l10n),
                    onTap: () =>
                        _showWarnings(context, widget.student, warnings),
                  ),
              ],
            ),
          ],
        ],
      ), // Column
      ), // GlassCard
      ), // AnimatedScale
    ); // GestureDetector
  }

  String _warningLabel(WarningInfo w, AppLocalizations l10n) =>
      switch (w.type) {
        'inactivity' => '⚠ ${l10n.t('warnInactivity')}',
        'repetition' => '🔁 ${l10n.t('warnRepetition')}',
        'skippedPages' => '📄 ${l10n.t('warnSkipped', args: ['${w.count}'])}',
        'manzilSkip' => '🔄 ${l10n.t('warnManzilSkip', args: ['${w.count}'])}',
        _ => '❌ ${l10n.t('warnAbsence')}',
      };

  void _showWarnings(BuildContext context, Student student, List warnings) {
    final app = context.read<AppProvider>();
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.bgElevated
              : AppColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('warnings'),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final w in warnings) ...[
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _warningLabel(w, l10n),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          app.acknowledgeWarning(student.id, w);
                          Navigator.pop(ctx);
                        },
                        child: Text(l10n.t('acknowledge')),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => app.resetAcknowledgedWarnings(student.id),
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceToggle extends StatelessWidget {
  final bool isPresent;
  final VoidCallback onTap;

  const _AttendanceToggle({required this.isPresent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = isPresent ? AppColors.primary : AppColors.danger;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isPresent ? 0.16 : 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isPresent ? 0.25 : 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 15,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              isPresent ? l10n.t('present') : l10n.t('absent'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RecordButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: const Icon(Icons.edit_note_rounded, size: 15),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        foregroundColor: AppColors.primarySoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LessonSummary extends StatelessWidget {
  final DailyRecord? sabaqRecord;
  final DailyRecord? sabqiRecord;
  final DailyRecord? manzilRecord;

  /// The selected date's record — drives the per-track tick/cross marks:
  /// track recited today → tick, track with history but missed today → cross.
  final DailyRecord? todayRecord;
  final AppLocalizations l10n;
  final int mushafLines;

  const _LessonSummary({
    this.sabaqRecord,
    this.sabqiRecord,
    this.manzilRecord,
    this.todayRecord,
    required this.l10n,
    required this.mushafLines,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (sabaqRecord?.sabaq != null) {
      final s = sabaqRecord!.sabaq!;
      final dateStr = AppDateUtils.format(
        AppDateUtils.fromKey(sabaqRecord!.date),
        l10n.localeName,
      );
      final details = <String>['${l10n.t('juz')} ${s.juz}'];
      if (s.pageLabel.isNotEmpty) {
        details.add('${l10n.t('page')} ${s.pageLabel}');
      }

      String progressSuffix = '';
      if (s.startPage > 0 && s.endPage > 0) {
        final calc = MathEngine.computeParaSabqi(
          juz: s.juz,
          startPage: s.startPage,
          endPage: s.endPage,
          heardPage: s.endPage,
          linesPerPage: mushafLines,
        );
        if (calc.valid && calc.totalPages > 0) {
          progressSuffix = ' (${calc.completedPages}/${calc.totalPages})';
        }
      }

      if (s.lines > 0) {
        details.add('${s.lines} ${l10n.t('lines')}$progressSuffix');
      } else if (progressSuffix.isNotEmpty) {
        details.add(progressSuffix.trim());
      }

      // Compute days active for this para
      final app = context.read<AppProvider>();
      final studentRecords = app.recordsForStudent(sabaqRecord!.studentId);
      final paraRecords = studentRecords.where((r) => r.sabaq?.juz == s.juz).toList();
      if (paraRecords.isNotEmpty) {
        paraRecords.sort((a, b) => a.date.compareTo(b.date));
        final startRec = paraRecords.firstWhere(
          (r) => r.sabaq?.isParaStart == true || r.sabaq?.paraStartDate != null,
          orElse: () => paraRecords.first,
        );
        final startDateStr = startRec.sabaq?.paraStartDate ?? startRec.date;
        final startDt = DateTime.tryParse(startDateStr) ?? DateTime.tryParse(startRec.date);
        final currentDt = AppDateUtils.fromKey(sabaqRecord!.date);
        if (startDt != null) {
          final daysDiff = currentDt.difference(startDt).inDays + 1;
          final days = daysDiff > 0 ? daysDiff : 1;
          if (s.isParaEnd) {
            details.add(l10n.t('paraCompletedShort', args: ['$days']));
          } else {
            details.add(l10n.t('paraOngoingShort', args: ['$days']));
          }
        }
      }

      rows.add(
        _TrackRow(
          done: todayRecord?.sabaq != null,
          child: _TrackChip(
            color: AppColors.info,
            icon: Icons.auto_stories_rounded,
            text: '${l10n.t('sabaq')}: ${details.join(' · ')} ($dateStr)',
          ),
        ),
      );
    }
    if (sabqiRecord?.sabqi != null) {
      final s = sabqiRecord!.sabqi!;
      final dateStr = AppDateUtils.format(
        AppDateUtils.fromKey(sabqiRecord!.date),
        l10n.localeName,
      );
      final details = <String>['${l10n.t('juz')} ${s.juz}'];
      if (s.endPage > 0) {
        // Show page with progress: e.g. Page 175 (11/18)
        String pageStr = '${l10n.t('page')} ${s.endPage}';
        if (s.endPage > 0) {
          try {
            final calc = MathEngine.computeParaSabqi(
              juz: s.juz,
              startPage: ParaCalculator.getStartPageForPara(
                s.juz,
                linesPerPage: mushafLines,
              ),
              endPage: s.endPage,
              heardPage: s.endPage,
              linesPerPage: mushafLines,
            );
            if (calc.valid && calc.totalPages > 0) {
              pageStr += ' (${calc.completedPages}/${calc.totalPages})';
            }
          } catch (_) {}
        }
        details.add(pageStr);
      }
      if (s.heardPage > 0 && s.heardPage != s.endPage) {
        details.add('${l10n.t('pagesHeardUntil')} ${s.heardPage}');
      }
      if (s.revisionCount > 0) {
        details.add('${l10n.t('tadaad')}: ${s.revisionCount}');
      }
      if (s.mushafPage != null && s.mushafPage! > 0 && s.endPage <= 0) {
        details.add('${l10n.t('safhaNumber')}: ${s.mushafPage}');
      }
      if (s.isDoubleSabqi && s.doubleSabqiJuz != null) {
        final doubleDetails = <String>['${l10n.t('juz')} ${s.doubleSabqiJuz}'];
        if (s.doubleSabqiRuba != null) {
          final rubaLabel = '${l10n.t('ruba')} ${s.doubleSabqiRuba}';
          doubleDetails.add(rubaLabel);
        }
        details.add('${l10n.t('doubleSabqi')}: ${doubleDetails.join(' · ')}');
      }
      final sabqiText = '${l10n.t('sabqi')}: ${details.join(' · ')}';
      rows.add(
        _TrackRow(
          done: todayRecord?.sabqi != null,
          child: _TrackChip(
            color: AppColors.indigo,
            icon: Icons.repeat_rounded,
            text: '$sabqiText ($dateStr)',
          ),
        ),
      );
    }
    if (manzilRecord?.manzil != null) {
      final m = manzilRecord!.manzil!;
      final dateStr = AppDateUtils.format(
        AppDateUtils.fromKey(manzilRecord!.date),
        l10n.localeName,
      );
      final isFullPara = (m.startJuz == null || m.startJuz == m.juz) &&
          (m.startRuba == null || m.startRuba == 1) &&
          m.ruba == 4;
      final isMultiFullPara = m.startJuz != null &&
          m.startJuz != m.juz &&
          (m.startRuba == null || m.startRuba == 1) &&
          m.ruba == 4;
      final isNisafAwal = (m.startJuz == null || m.startJuz == m.juz) &&
          m.startRuba == 1 &&
          m.ruba == 2;
      final isNisafAkhir = (m.startJuz == null || m.startJuz == m.juz) &&
          m.startRuba == 3 &&
          m.ruba == 4;
      final hasRange = m.startJuz != null &&
          m.startRuba != null &&
          (m.startJuz != m.juz || m.startRuba != m.ruba);

      final String label;
      if (m.customText != null && m.customText!.trim().isNotEmpty) {
        label = '${l10n.t('manzil')}: ${m.customText!.trim()} ($dateStr)';
      } else if (isFullPara) {
        label = '${l10n.t('manzil')}: ${l10n.t('juz')} ${m.juz} · ${l10n.t('pooraPara')} ($dateStr)';
      } else if (isMultiFullPara) {
        label = '${l10n.t('manzil')}: ${l10n.t('juz')} ${m.startJuz} – ${l10n.t('juz')} ${m.juz} (${l10n.t('pooraPara')}) ($dateStr)';
      } else if (isNisafAwal) {
        label = '${l10n.t('manzil')}: ${l10n.t('juz')} ${m.juz} · ${l10n.t('nisafAwal')} ($dateStr)';
      } else if (isNisafAkhir) {
        label = '${l10n.t('manzil')}: ${l10n.t('juz')} ${m.juz} · ${l10n.t('nisafAkhir')} ($dateStr)';
      } else if (hasRange) {
        final startRubaLabel = m.startRuba == 1 && m.ruba == 2
            ? l10n.t('nisafAwal')
            : '${l10n.t('ruba')} ${m.startRuba}';
        final endRubaLabel = '${l10n.t('ruba')} ${m.ruba}';
        label = '${l10n.t('manzil')}: ${l10n.t('juz')} ${m.startJuz} · $startRubaLabel – ${l10n.t('juz')} ${m.juz} · $endRubaLabel ($dateStr)';
      } else {
        final String rubaStr;
        if (m.startRuba == 1 && m.ruba == 2) {
          rubaStr = l10n.t('nisafAwal');
        } else if (m.startRuba == 3 && m.ruba == 4) {
          rubaStr = l10n.t('nisafAkhir');
        } else {
          rubaStr = '${l10n.t('ruba')} ${m.ruba}';
        }
        label = '${l10n.t('manzil')}: ${l10n.t('juz')} ${m.juz} · $rubaStr ($dateStr)';
      }
      rows.add(
        _TrackRow(
          done: todayRecord?.manzil != null,
          child: _TrackChip(
            color: AppColors.primary,
            icon: Icons.all_inclusive_rounded,
            text: label,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          rows[i],
        ],
      ],
    );
  }
}

/// A lesson chip with a per-track status mark: green tick when the track was
/// recited on the selected date, red cross when it was missed.
class _TrackRow extends StatelessWidget {
  final Widget child;
  final bool done;

  const _TrackRow({required this.child, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: child),
        const SizedBox(width: 6),
        Icon(
          done ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: done ? AppColors.primary : AppColors.danger,
        ),
      ],
    );
  }
}

class _TrackChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _TrackChip({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.15,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
