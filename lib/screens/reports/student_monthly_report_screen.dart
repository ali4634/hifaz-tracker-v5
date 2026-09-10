import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/math_engine.dart';
import '../../core/utils/para_calculator.dart';
import '../../localization/app_localizations.dart';
import '../../models/daily_record.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/glass_card.dart';

/// Per-student monthly report: khulasa (totals + grades + missed counts),
/// daily records and share options (text / WhatsApp / SMS / PDF).
/// Ported from v4's MonthlyReportScreen and restyled for the glass UI.
class StudentMonthlyReportScreen extends StatefulWidget {
  final Student student;

  const StudentMonthlyReportScreen({super.key, required this.student});

  @override
  State<StudentMonthlyReportScreen> createState() =>
      _StudentMonthlyReportScreenState();
}

class _StudentMonthlyReportScreenState
    extends State<StudentMonthlyReportScreen> {
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final monthKey = AppDateUtils.monthKey(_month);
    final records =
        app.records
            .where(
              (r) =>
                  r.studentId == widget.student.id &&
                  r.date.startsWith(monthKey),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final stats = StudentMonthlyStats.compute(
      records: records,
      linesPerPage: widget.student.mushafLines,
    );

    // Sabaq para progress (v4-style): current para = latest Sabaq Juz across
    // all history; pages read = max endPage reached within that para.
    DailyRecord? latestSabaqRec;
    for (final r in app.recordsForStudent(widget.student.id).reversed) {
      if (r.sabaq != null) {
        latestSabaqRec = r;
        break;
      }
    }
    final sabaqPara = latestSabaqRec?.sabaq?.juz;
    var sabaqParaMaxEnd = 0;
    if (sabaqPara != null) {
      for (final r in app.recordsForStudent(widget.student.id)) {
        final s = r.sabaq;
        if (s != null && s.juz == sabaqPara && s.endPage > sabaqParaMaxEnd) {
          sabaqParaMaxEnd = s.endPage;
        }
      }
    }
    int? sabaqPagesRead;
    int? sabaqParaTotal;
    if (sabaqPara != null && sabaqParaMaxEnd > 0) {
      final pStart = ParaCalculator.getStartPageForPara(
        sabaqPara,
        linesPerPage: widget.student.mushafLines,
      );
      final pTotal = ParaCalculator.getTotalPagesForPara(
        sabaqPara,
        linesPerPage: widget.student.mushafLines,
      );
      if (sabaqParaMaxEnd >= pStart) {
        sabaqPagesRead = (sabaqParaMaxEnd - pStart + 1).clamp(0, pTotal);
        sabaqParaTotal = pTotal;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t('studentMonthlyReport', args: [widget.student.name]),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onShare(v, records, stats),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'text',
                child: Row(
                  children: [
                    const Icon(Icons.text_snippet_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(l10n.t('shareText')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    const Icon(Icons.chat_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(l10n.t('sendViaWhatsApp')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sms',
                child: Row(
                  children: [
                    const Icon(Icons.sms_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(l10n.t('sendViaSMS')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(l10n.t('exportPdf')),
                  ],
                ),
              ),
            ],
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _StudentHeader(student: widget.student),
                const SizedBox(height: 10),
                _KhulasaCard(
                  stats: stats,
                  l10n: l10n,
                  sabaqPara: sabaqPara,
                  sabaqPagesRead: sabaqPagesRead,
                  sabaqParaTotal: sabaqParaTotal,
                ),
                const SizedBox(height: 10),
                _PresentAbsentRow(stats: stats, l10n: l10n),
                const SizedBox(height: 16),
                Text(
                  '${l10n.t('dailyRecords')} (${records.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  GlassCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note_rounded,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('noRecords'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  for (final r in records) ...[
                    _DailyRecordCard(record: r, l10n: l10n),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onShare(
    String action,
    List<DailyRecord> records,
    StudentMonthlyStats stats,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final text = ExportService.instance.buildStudentMonthlyTextReport(
        student: widget.student,
        month: _month,
        records: records,
        t: (key, {args}) => l10n.t(key, args: args ?? const []),
        locale: l10n.localeName,
      );

      switch (action) {
        case 'text':
          await ExportService.instance.shareText(
            text,
            subject: l10n.t('monthlyReport'),
          );
        case 'whatsapp':
          await _sendViaChannel(whatsapp: true, text: text, l10n: l10n);
        case 'sms':
          await _sendViaChannel(whatsapp: false, text: text, l10n: l10n);
        case 'pdf':
          await _sharePdf(l10n);
      }
    } catch (e) {
      debugPrint('Student report share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('errorGenerating'))));
      }
    }
  }

  Future<void> _sharePdf(AppLocalizations l10n) async {
    try {
      final app = context.read<AppProvider>();
      final settings = context.read<SettingsProvider>();
      final monthKey = AppDateUtils.monthKey(_month);
      final monthRecords = app.records
          .where(
            (r) =>
                r.studentId == widget.student.id &&
                r.date.startsWith(monthKey),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final bytes = await ScreenshotPdfExport.instance.buildStudentMonthlyPdfReport(
        context: context,
        student: widget.student,
        month: _month,
        records: monthRecords,
        settings: settings.settings,
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
        filename:
            'hifaz_report_${widget.student.name.replaceAll(' ', '_')}_${AppDateUtils.monthKey(_month)}.pdf',
      );
    } catch (e) {
      debugPrint('Student PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.t('errorGenerating')}: $e')),
        );
      }
    }
  }

  Future<void> _sendViaChannel({
    required bool whatsapp,
    required String text,
    required AppLocalizations l10n,
  }) async {
    final phone = widget.student.phone;
    if (phone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('noPhoneNumber'))));
      }
      return;
    }
    final svc = ExportService.instance;
    final available = whatsapp
        ? await svc.canOpenWhatsApp(phone)
        : true; // SMS: allow the platform to resolve
    if (!available) {
      final ok = await _showFallbackDialog(
        title: l10n.t('whatsappNotAvailable'),
        message: l10n.t('whatsappNotAvailableMessage'),
        l10n: l10n,
      );
      if (ok) await _copyToClipboard(text, l10n);
      return;
    }
    try {
      if (whatsapp) {
        await svc.sendViaWhatsApp(phone, text);
      } else {
        await svc.sendViaSms(phone, text);
      }
    } catch (_) {
      final ok = await _showFallbackDialog(
        title: whatsapp
            ? l10n.t('whatsappNotAvailable')
            : l10n.t('smsNotAvailable'),
        message: whatsapp
            ? l10n.t('whatsappNotAvailableMessage')
            : l10n.t('smsNotAvailableMessage'),
        l10n: l10n,
      );
      if (ok) await _copyToClipboard(text, l10n);
    }
  }

  Future<bool> _showFallbackDialog({
    required String title,
    required String message,
    required AppLocalizations l10n,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('copyReport')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _copyToClipboard(String text, AppLocalizations l10n) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('reportCopied'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('errorCopying'))));
      }
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _StudentHeader extends StatelessWidget {
  final Student student;

  const _StudentHeader({required this.student});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initials = student.name.trim().isEmpty
        ? '?'
        : student.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.indigo, AppColors.primary],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (student.isStarred) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.t('section')} ${student.section}'
                  '${student.phone.isNotEmpty ? ' · ${student.phone}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Khulasa (lesson totals) ────────────────────────────────────────────────

class _KhulasaCard extends StatelessWidget {
  final StudentMonthlyStats stats;
  final AppLocalizations l10n;
  final int? sabaqPara;
  final int? sabaqPagesRead;
  final int? sabaqParaTotal;

  const _KhulasaCard({
    required this.stats,
    required this.l10n,
    this.sabaqPara,
    this.sabaqPagesRead,
    this.sabaqParaTotal,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.info.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_rounded,
                size: 18,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('lessonTotals'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if (sabaqPara != null &&
              sabaqPagesRead != null &&
              sabaqParaTotal != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.t('juz')} $sabaqPara · $sabaqPagesRead/$sabaqParaTotal ${l10n.t('pagesCount')}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (sabaqPagesRead! / sabaqParaTotal!).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${((sabaqPagesRead! / sabaqParaTotal!) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _TrackRow(
            icon: Icons.auto_stories_rounded,
            color: AppColors.info,
            title: l10n.t('sabaqTotal'),
            main:
                '${stats.sabaqLessons} ${l10n.t('lessonsCount')}'
                '${stats.sabaqPages > 0 ? ' · ${stats.sabaqPages} ${l10n.t('pagesCount')}' : ''}',
            grade: stats.sabaqGrade(
              (k, {args}) => l10n.t(k, args: args ?? const []),
            ),
            missed: stats.missedSabaq,
            missedLabel: l10n.t('missedSabaq'),
            l10n: l10n,
          ),
          const SizedBox(height: 10),
          _TrackRow(
            icon: Icons.repeat_rounded,
            color: AppColors.indigo,
            title: l10n.t('sabqiTotal'),
            main:
                '${stats.sabqiLessons} ${l10n.t('lessonsCount')} · ${stats.sabqiCompletedPages}/${stats.sabqiTotalPages} ${l10n.t('pagesCount')}',
            grade: stats.sabqiGrade(
              (k, {args}) => l10n.t(k, args: args ?? const []),
            ),
            missed: stats.missedSabqi,
            missedLabel: l10n.t('missedSabqi'),
            l10n: l10n,
          ),
          const SizedBox(height: 10),
          _TrackRow(
            icon: Icons.all_inclusive_rounded,
            color: AppColors.primary,
            title: l10n.t('manzilTotal'),
            main:
                '${stats.manzilLessons} ${l10n.t('lessonsCount')} · ${stats.manzilRubas} ${l10n.t('rubasCount')}',
            grade: stats.manzilGrade(
              (k, {args}) => l10n.t(k, args: args ?? const []),
            ),
            missed: stats.missedManzil,
            missedLabel: l10n.t('missedManzil'),
            l10n: l10n,
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String main;
  final String grade;
  final int missed;
  final String missedLabel;
  final AppLocalizations l10n;

  const _TrackRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.main,
    required this.grade,
    required this.missed,
    required this.missedLabel,
    required this.l10n,
  });

  Color get _gradeColor {
    if (grade == l10n.t('gradeExcellent')) return AppColors.primary;
    if (grade == l10n.t('gradeGood')) return AppColors.indigo;
    if (grade == l10n.t('gradePassable')) return AppColors.info;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  main,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$missedLabel: $missed',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gradeColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: _gradeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentAbsentRow extends StatelessWidget {
  final StudentMonthlyStats stats;
  final AppLocalizations l10n;

  const _PresentAbsentRow({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.presentDays}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  l10n.t('presentDays'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const Icon(
                  Icons.cancel_rounded,
                  size: 22,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.absentDays}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger,
                  ),
                ),
                Text(
                  l10n.t('absentDays'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Daily record card ──────────────────────────────────────────────────────

class _DailyRecordCard extends StatefulWidget {
  final DailyRecord record;
  final AppLocalizations l10n;

  const _DailyRecordCard({required this.record, required this.l10n});

  @override
  State<_DailyRecordCard> createState() => _DailyRecordCardState();
}

class _DailyRecordCardState extends State<_DailyRecordCard> {
  bool _manzilExpanded = true;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final l10n = widget.l10n;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppDateUtils.format(
                  AppDateUtils.fromKey(record.date),
                  l10n.localeName,
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (record.present ? AppColors.primary : AppColors.danger)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (record.present ? AppColors.primary : AppColors.danger)
                            .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  record.present ? l10n.t('present') : l10n.t('absent'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: record.present
                        ? AppColors.primary
                        : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!record.present)
            Text(
              l10n.t('absent'),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            if (record.sabaq != null)
              _LessonLine(
                icon: Icons.auto_stories_rounded,
                color: AppColors.info,
                text:
                    '${l10n.t('sabaq')}: ${l10n.t('juz')} ${record.sabaq!.juz} · ${record.sabaq!.pageLabel} · ${record.sabaq!.lines} ${l10n.t('lines')}',
              ),
            if (record.sabqi != null) _SabqiLine(record: record, l10n: l10n),
            if (record.manzil != null) ...[
              // ── منزل / دوسرا پارہ ─ show/hide toggle ──────────────────
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _manzilExpanded = !_manzilExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.all_inclusive_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.t('manzil'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '— ${l10n.t('juz')} ${record.manzil!.juz}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _manzilExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_manzilExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 21, top: 2),
                  child: Text(
                    () {
                      final m = record.manzil!;
                      final isFullPara = (m.startJuz == null || m.startJuz == m.juz) &&
                          (m.startRuba == null || m.startRuba == 1) &&
                          m.ruba == 4;
                      return isFullPara
                          ? l10n.t('pooraPara')
                          : (m.startRuba == 1 && m.ruba == 2
                              ? l10n.t('nisafAwal')
                              : (m.startRuba == 3 && m.ruba == 4
                                  ? l10n.t('nisafAkhir')
                                  : '${l10n.t('ruba')} ${record.manzil!.ruba}'));
                    }(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
            ],
            if (!record.hasAnyLesson)
              Text(
                l10n.t('noLesson'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SabqiLine extends StatelessWidget {
  final DailyRecord record;
  final AppLocalizations l10n;

  const _SabqiLine({required this.record, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final s = record.sabqi!;
    final calc = MathEngine.computeSabqi(
      startPage: s.startPage,
      endPage: s.endPage,
      heardPage: s.heardPage,
    );
    return _LessonLine(
      icon: Icons.repeat_rounded,
      color: AppColors.indigo,
      text:
          '${l10n.t('sabqi')}: ${l10n.t('juz')} ${s.juz} · ${s.startPage}–${s.endPage} · ${calc.completedPages}/${calc.totalPages}',
    );
  }
}

class _LessonLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _LessonLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
