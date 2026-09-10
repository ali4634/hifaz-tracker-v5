import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/math_engine.dart';
import '../../core/utils/para_calculator.dart';
import '../../localization/app_localizations.dart';
import '../../models/daily_record.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_card.dart';

/// Which screen the lesson-entry sheet is currently showing: the track
/// chooser or one dedicated entry screen per lesson type.
enum _SheetPage { chooser, sabaq, sabqi, manzil }

/// Full lesson entry sheet for one student & the selected date.
///
/// Opens on a compact chooser; each lesson type (Sabaq / Sabqi / Manzil)
/// gets its own dedicated screen so the sheet never grows too long.
class LessonEntrySheet extends StatefulWidget {
  final Student student;

  const LessonEntrySheet({super.key, required this.student});

  @override
  State<LessonEntrySheet> createState() => _LessonEntrySheetState();
}

class _LessonEntrySheetState extends State<LessonEntrySheet> {
  AppLocalizations get _l10n => AppLocalizations.of(context);
  late final AppProvider _app;

  DailyRecord? _existing;

  // Attendance
  late bool _present;

  // Sabaq
  late int _sabaqJuz;
  final _pageLabelCtrl = TextEditingController();
  final _linesCtrl = TextEditingController();
  bool _isParaStart = false;
  bool _isParaEnd = false;
  String? _paraStartDate;

  // Sabqi
  late int _sabqiJuz;
  final _mushafPageCtrl = TextEditingController();
  String _sabqiMode = 'pages'; // 'pages', 'nisaf', 'para'
  bool _isDoubleSabqi = false;
  int? _doubleSabqiJuz;
  int? _doubleSabqiRuba;
  int _revisionCount = 0;

  // Manzil
  late int _manzilJuz;
  late int _manzilRuba;
  int? _manzilStartRuba;
  ManzilPosition? _suggestion;
  int _manzilCount = 0;
  bool _isMultipleManzil = false;
  final _manzilCustomCtrl = TextEditingController();

  bool get _isEdit => _existing != null;

  /// Currently shown screen inside this sheet.
  _SheetPage _page = _SheetPage.chooser;

  /// Most recent record with any lesson data for this student (across all dates).
  DailyRecord? _lastRecordAcrossDates() {
    final records = _app.recordsForStudent(widget.student.id);
    DailyRecord? last;
    for (final r in records) {
      if (r.hasAnyLesson) last = r;
    }
    return last;
  }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppProvider>();
    _existing = _app.recordFor(widget.student.id);
    // Find the last record across all dates to pre-fill when no record for today
    final lastRecord = _lastRecordAcrossDates();

    _present = _existing?.present ?? false;

    final s = widget.student;
    final lastSabaq = lastRecord?.sabaq;
    _sabaqJuz = _existing?.sabaq?.juz ?? lastSabaq?.juz ?? s.currentManzilJuz;
    if (_existing?.sabaq != null) {
      // Editing today's record — keep its values
      _pageLabelCtrl.text = _existing!.sabaq!.pageLabel;
      _linesCtrl.text = _existing!.sabaq!.lines == 0
          ? ''
          : '${_existing!.sabaq!.lines}';
    } else if (lastSabaq != null && lastSabaq.endPage > 0) {
      // No record today but there's a previous one — pre-fill from last record
      // (same juz: show same page so teacher knows where student stopped;
      //  different juz: show start page of new juz)
      final lastJuzSame = _sabaqJuz == lastSabaq.juz;
      _pageLabelCtrl.text = lastJuzSame ? '${lastSabaq.endPage}' : '';
      _linesCtrl.text = lastSabaq.lines == 0 ? '' : '${lastSabaq.lines}';
    } else {
      _pageLabelCtrl.text = '';
      _linesCtrl.text = '';
    }

    // Auto-fill Sabaq page label if it's new and empty
    if (_existing?.sabaq == null && _pageLabelCtrl.text.isEmpty) {
      final suggestion = _sabaqSuggestion;
      if (suggestion > 0) {
        _pageLabelCtrl.text = '$suggestion';
      }
    }

    _isParaStart = _existing?.sabaq?.isParaStart ?? false;
    _isParaEnd = _existing?.sabaq?.isParaEnd ?? false;
    _paraStartDate = _existing?.sabaq?.paraStartDate;

    _sabqiJuz = _existing?.sabqi?.juz ?? lastRecord?.sabqi?.juz ?? s.sabqiTargetJuz;
    // Initialize mushaf page from existing record (endPage is derived from it)
    if (_existing?.sabqi != null && _existing!.sabqi!.endPage > 0) {
      _mushafPageCtrl.text = _existing!.sabqi!.mushafPage != null
          ? '${_existing!.sabqi!.mushafPage}'
          : '${_existing!.sabqi!.endPage}';
    } else if (lastRecord?.sabqi != null && lastRecord!.sabqi!.endPage > 0) {
      // Pre-fill from last record so teacher knows where student stopped
      _mushafPageCtrl.text = lastRecord.sabqi!.mushafPage != null
          ? '${lastRecord.sabqi!.mushafPage}'
          : '${lastRecord.sabqi!.endPage}';
    } else {
      _mushafPageCtrl.text = '';
    }
    _revisionCount = _existing?.sabqi?.revisionCount ?? lastRecord?.sabqi?.revisionCount ?? 0;
    _isDoubleSabqi = _existing?.sabqi?.isDoubleSabqi ?? lastRecord?.sabqi?.isDoubleSabqi ?? false;
    _doubleSabqiJuz = _existing?.sabqi?.doubleSabqiJuz ?? lastRecord?.sabqi?.doubleSabqiJuz;
    _doubleSabqiRuba = _existing?.sabqi?.doubleSabqiRuba ?? lastRecord?.sabqi?.doubleSabqiRuba;

    _manzilJuz = _existing?.manzil?.juz ?? lastRecord?.manzil?.juz ?? s.currentManzilJuz;
    _manzilRuba = _existing?.manzil?.ruba ?? lastRecord?.manzil?.ruba ?? 1;
    _manzilStartRuba = _existing?.manzil?.startRuba ?? lastRecord?.manzil?.startRuba;
    _isMultipleManzil = _existing?.manzil?.customText != null &&
        _existing!.manzil!.customText!.trim().isNotEmpty;
    _manzilCustomCtrl.text = _existing?.manzil?.customText ?? '';
    _suggestion = _computeSuggestion();
  }

  ManzilPosition? _computeSuggestion() {
    final s = widget.student;
    ManzilEntry? last;
    for (final r in _app.recordsForStudent(s.id)) {
      if (r.manzil != null) last = r.manzil;
    }
    return MathEngine.suggestNextManzil(
      hasLog: last != null,
      lastLogged: last == null ? null : ManzilPosition(last.juz, last.ruba),
      startJuz: s.manzilStartJuz,
      endJuz: s.manzilEndJuz,
      reverse: s.manzilReverse,
    );
  }

  SabqiEntry? get _lastSabqi {
    final selectedDateStr = AppDateUtils.key(_app.selectedDate);
    final records = _app.recordsForStudent(widget.student.id);
    SabqiEntry? last;
    for (final r in records) {
      if (r.date != selectedDateStr && r.sabqi != null) {
        last = r.sabqi;
      }
    }
    return last;
  }

  /// Human-readable label for the Last Records info box with progress.
  String _lastSabqiLabel(SabqiEntry last) {
    final details = <String>['${_l10n.t('lastRecords')}: ${_l10n.t('juz')} ${last.juz}'];
    if (last.endPage > 0) {
      String pageStr = '${_l10n.t('page')} ${last.endPage}';
      try {
        final calc = MathEngine.computeParaSabqi(
          juz: last.juz,
          startPage: ParaCalculator.getStartPageForPara(
            last.juz,
            linesPerPage: widget.student.mushafLines,
          ),
          endPage: last.endPage,
          heardPage: last.endPage,
          linesPerPage: widget.student.mushafLines,
        );
        if (calc.valid && calc.totalPages > 0) {
          pageStr += ' (${calc.completedPages}/${calc.totalPages})';
        }
      } catch (_) {}
      details.add(pageStr);
    }
    if (last.revisionCount > 0) {
      details.add('${last.revisionCount} ${_l10n.t('sabaqi')}');
    }
    return details.join(' · ');
  }

  // ── Previous record helpers ──────────────────────────────────────────────

  /// Most recent record with a Sabaq entry (excluding today).
  DailyRecord? get _lastSabaqRecord {
    final selectedDateStr = AppDateUtils.key(_app.selectedDate);
    final records = _app.recordsForStudent(widget.student.id);
    DailyRecord? last;
    for (final r in records) {
      if (r.date != selectedDateStr && r.sabaq != null) {
        last = r;
      }
    }
    return last;
  }

  /// Most recent record with a Sabqi entry (excluding today).
  DailyRecord? get _lastSabqiRecord {
    final selectedDateStr = AppDateUtils.key(_app.selectedDate);
    final records = _app.recordsForStudent(widget.student.id);
    DailyRecord? last;
    for (final r in records) {
      if (r.date != selectedDateStr && r.sabqi != null) {
        last = r;
      }
    }
    return last;
  }

  /// Most recent record with a Manzil entry (excluding today).
  DailyRecord? get _lastManzilRecord {
    final selectedDateStr = AppDateUtils.key(_app.selectedDate);
    final records = _app.recordsForStudent(widget.student.id);
    DailyRecord? last;
    for (final r in records) {
      if (r.date != selectedDateStr && r.manzil != null) {
        last = r;
      }
    }
    return last;
  }

  /// Previous record info banner widget.
  Widget _previousRecordBanner({
    required Color color,
    required String title,
    required String detail,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10.5,
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

  @override
  void dispose() {
    _pageLabelCtrl.dispose();
    _linesCtrl.dispose();
    _mushafPageCtrl.dispose();
    super.dispose();
  }

  int _intVal(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  /// End page of this Sabaq lesson = the page number typed into the
  /// page/surah field (the app figures out the start itself).
  int get _sabaqEndPage => _intVal(_pageLabelCtrl);

  /// Start page of this Sabaq lesson: the page after the previous Sabaq record
  /// (when it sits inside the selected Para), otherwise the Para's first page.
  /// Editing an existing record keeps its original start page.
  int get _sabaqStartPage {
    final stored = _existing?.sabaq;
    if (stored != null && stored.startPage > 0) {
      final paraStart = ParaCalculator.getStartPageForPara(
        _sabaqJuz,
        linesPerPage: widget.student.mushafLines,
      );
      final paraEnd = ParaCalculator.getEndPageForPara(
        _sabaqJuz,
        linesPerPage: widget.student.mushafLines,
      );
      if (stored.startPage >= paraStart && stored.startPage <= paraEnd) {
        return stored.startPage;
      }
    }
    return _deriveStartPage(
      juz: _sabaqJuz,
      latestEndPage: _lastEndPageFor(_app.recordsForStudent(widget.student.id), (r) => r.sabaq?.endPage),
    );
  }

  /// Suggested page for a brand-new Sabaq lesson: the page after the previous
  /// Sabaq record (or the Para's first page when nothing was logged yet).
  int get _sabaqSuggestion {
    final stored = _existing?.sabaq;
    if (stored != null) return 0; // editing — no suggestion needed
    return _deriveStartPage(
      juz: _sabaqJuz,
      latestEndPage: _lastEndPageFor(_app.recordsForStudent(widget.student.id), (r) => r.sabaq?.endPage),
    );
  }

  /// Suggested end page for a brand-new Sabqi lesson: start page + the
  /// student's target pages − 1, capped to the Para's last page.
  int get _sabqiSuggestion {
    final stored = _existing?.sabqi;
    if (stored != null) return 0; // editing — no suggestion needed
    final start = _sabqiStartPage;
    if (start <= 0) return 0;
    final target = widget.student.sabqiTargetPages.clamp(1, AppConstants.maxPagesPerPara);
    final paraEnd = _sabqiParaEnd;
    if (paraEnd <= 0) return 0;
    final end = start + target - 1;
    return end > paraEnd ? paraEnd : end;
  }

  /// Last page of the selected Sabqi Para (0 when out of range).
  int get _sabqiParaEnd {
    try {
      return ParaCalculator.getEndPageForPara(
        _sabqiJuz,
        linesPerPage: widget.student.mushafLines,
      );
    } catch (_) {
      return 0;
    }
  }

  /// End page of a given Ruba (1–4) inside [juz], 0 when out of range.
  int _rubaEndPage(int juz, int ruba) {
    try {
      return ParaCalculator.getEndPageForRuba(
        juz,
        ruba,
        linesPerPage: widget.student.mushafLines,
      );
    } catch (_) {
      return 0;
    }
  }

  /// Which Ruba (1–4) the given mushaf page falls into inside [juz], or null
  /// when the page is outside the para — used to highlight the quick buttons.
  int? _rubaForPage(int juz, int page) {
    if (page <= 0 || juz < 1 || juz > AppConstants.maxJuz) return null;
    for (var r = 1; r <= 4; r++) {
      final end = _rubaEndPage(juz, r);
      if (end <= 0) return null;
      if (page <= end) return r;
    }
    return null;
  }

  /// Whether the typed Sabaq page number is outside the selected Para's real
  /// page range (or before the derived start page). Blocks saving.
  bool get _sabaqInvalid {
    final end = _sabaqEndPage;
    if (end <= 0) return false;
    if (_sabaqJuz < 1 || _sabaqJuz > AppConstants.maxJuz) return true;
    final paraEnd = ParaCalculator.getEndPageForPara(
      _sabaqJuz,
      linesPerPage: widget.student.mushafLines,
    );
    // Must be inside the para and never before where the lesson starts.
    return end > paraEnd || end < _sabaqStartPage;
  }

  /// Last page of the selected Para (0 when out of range) — used by the
  /// Sabaq out-of-range warning message.
  int get _sabaqParaEnd {
    try {
      return ParaCalculator.getEndPageForPara(
        _sabaqJuz,
        linesPerPage: widget.student.mushafLines,
      );
    } catch (_) {
      return 0;
    }
  }

  /// Start page of this Sabqi lesson: the page after the previous Sabqi record
  /// (when it sits inside the selected Para), otherwise the Para's first page.
  /// Editing an existing record keeps its original start page.
  int get _sabqiStartPage {
    final stored = _existing?.sabqi;
    if (stored != null && stored.startPage > 0) {
      // Only use the stored start page if it still falls within the
      // currently selected Para's range (the user may have changed the
      // Juz dropdown since the record was created).
      final paraStart = ParaCalculator.getStartPageForPara(
        _sabqiJuz,
        linesPerPage: widget.student.mushafLines,
      );
      final paraEnd = ParaCalculator.getEndPageForPara(
        _sabqiJuz,
        linesPerPage: widget.student.mushafLines,
      );
      if (stored.startPage >= paraStart && stored.startPage <= paraEnd) {
        return stored.startPage;
      }
    }
    return _deriveStartPage(
      juz: _sabqiJuz,
      latestEndPage: _lastEndPageFor(_app.recordsForStudent(widget.student.id), (r) => r.sabqi?.endPage),
    );
  }

  /// Latest non-zero end page for a track across the student's records.
  int _lastEndPageFor(
    List<DailyRecord> records,
    int? Function(DailyRecord r) endPageOf,
  ) {
    int? last;
    for (final r in records) {
      final end = endPageOf(r);
      if (end != null && end > 0) last = end;
    }
    return last ?? 0;
  }

  /// Derives the start page for [juz]: previous end page + 1 when it falls
  /// inside the Para's real page range, otherwise the Para's first page.
  int _deriveStartPage({required int juz, required int latestEndPage}) {
    final paraStart = ParaCalculator.getStartPageForPara(
      juz,
      linesPerPage: widget.student.mushafLines,
    );
    final paraEnd = ParaCalculator.getEndPageForPara(
      juz,
      linesPerPage: widget.student.mushafLines,
    );
    final next = latestEndPage + 1;
    if (latestEndPage > 0 && next >= paraStart && next <= paraEnd) {
      return next;
    }
    return paraStart;
  }

  /// Sabqi computation; null when no Sabqi fields were filled in.
  /// End page and heard page are both derived from the mushaf page field.
  SabqiCalc? get _sabqiCalc {
    if (_mushafPageCtrl.text.trim().isEmpty) return null;
    final start = _sabqiStartPage;
    final end = _intVal(_mushafPageCtrl);
    return MathEngine.computeSabqi(
      startPage: start,
      endPage: end,
      heardPage: end,
    );
  }

  /// Total pages of the selected Juz for the student's mushaf (fallback to the
  /// global cap when the para is somehow out of range).
  int get _paraTotalPages {
    try {
      return ParaCalculator.getTotalPagesForPara(
        _sabqiJuz,
        linesPerPage: widget.student.mushafLines,
      );
    } catch (_) {
      return AppConstants.maxPagesPerPara;
    }
  }

  bool get _sabqiInvalid {
    final calc = _sabqiCalc;
    if (calc == null) return false;
    if (calc.totalPages <= 0) return true;
    // Allow up to the para's real page count for this mushaf (e.g. 25 pages
    // in 15-line Para 30) instead of the flat 20-page cap.
    return calc.totalPages > _paraTotalPages;
  }

  bool get _hasSabaqInput =>
      _pageLabelCtrl.text.trim().isNotEmpty ||
      _linesCtrl.text.trim().isNotEmpty;

  bool get _hasSabqiInput => _mushafPageCtrl.text.trim().isNotEmpty;

  /// Saves only the Sabaq lesson, keeping any recorded Sabqi / Manzil intact.
  Future<void> _saveSabaq() async {
    final startP = _sabaqStartPage;
    final endP = _sabaqEndPage;
    final paraStartDate = _isParaStart
        ? (_paraStartDate ?? AppDateUtils.key(_app.selectedDate))
        : _paraStartDate;
    await _app.saveLessons(
      studentId: widget.student.id,
      date: _app.selectedDate,
      present: _present,
      sabaq: _hasSabaqInput
          ? SabaqEntry(
              juz: _sabaqJuz,
              pageLabel: _pageLabelCtrl.text.trim(),
              lines: _intVal(_linesCtrl),
              startPage: startP,
              endPage: endP,
              isParaStart: _isParaStart,
              isParaEnd: _isParaEnd,
              paraStartDate: paraStartDate,
            )
          : null,
      sabqi: _existing?.sabqi,
      manzil: _existing?.manzil,
    );
    if (mounted) Navigator.pop(context);
  }

  /// Saves only the Sabqi lesson, keeping any recorded Sabaq / Manzil intact.
  Future<void> _saveSabqi() async {
    final calc = _sabqiCalc;
    await _app.saveLessons(
      studentId: widget.student.id,
      date: _app.selectedDate,
      present: _present,
      sabaq: _existing?.sabaq,
      sabqi: calc == null
          ? null
          : SabqiEntry(
              juz: _sabqiJuz,
              startPage: _sabqiStartPage,
              endPage: _intVal(_mushafPageCtrl),
              heardPage: _intVal(_mushafPageCtrl),
              revisionCount: _revisionCount,
              isDoubleSabqi: _isDoubleSabqi,
              doubleSabqiJuz: _doubleSabqiJuz,
              doubleSabqiRuba: _doubleSabqiRuba,
              mushafPage: int.tryParse(_mushafPageCtrl.text.trim()),
            ),
      manzil: _existing?.manzil,
    );
    if (mounted) Navigator.pop(context);
  }

  /// Saves only the Manzil lesson, keeping any recorded Sabaq / Sabqi intact.
  Future<void> _saveManzil() async {
    final customText = _isMultipleManzil ? _manzilCustomCtrl.text.trim() : null;
    await _app.saveLessons(
      studentId: widget.student.id,
      date: _app.selectedDate,
      present: _present,
      sabaq: _existing?.sabaq,
      sabqi: _existing?.sabqi,
      manzil: ManzilEntry(
        juz: _manzilJuz,
        ruba: _manzilRuba,
        startRuba: _manzilStartRuba,
        customText: customText,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgElevated.withValues(alpha: 0.96)
            : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.glassBorder
              : AppColors.lightGlassBorder,
        ),
      ),
      child: Column(
        children: [
          _dragHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(s),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _currentPage(s),
                  ),
                ],
              ),
            ),
          ),
          if (_page != _SheetPage.chooser) _saveBar(),
        ],
      ),
    );
  }

  /// The screen shown for the current page: chooser or one lesson type.
  Widget _currentPage(Student s) {
    return switch (_page) {
      _SheetPage.chooser => _chooserPage(s),
      _SheetPage.sabaq => _sabaqSection(),
      _SheetPage.sabqi => _sabqiSection(),
      _SheetPage.manzil => _manzilSection(s),
    };
  }

  Widget _dragHandle() => Container(
    margin: const EdgeInsets.only(top: 10),
    width: 42,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.textMuted.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _header(Student s) {
    final isChooser = _page == _SheetPage.chooser;
    final (title, subtitle) = switch (_page) {
      _SheetPage.chooser => (
        s.name,
        '${_l10n.t('section')} ${s.section} · ${AppDateUtils.format(_app.selectedDate, _l10n.localeName)}',
      ),
      _SheetPage.sabaq => (
        _l10n.t('sabaqTitle'),
        '${s.name} · ${AppDateUtils.format(_app.selectedDate, _l10n.localeName)}',
      ),
      _SheetPage.sabqi => (
        _l10n.t('sabqiTitle'),
        '${s.name} · ${AppDateUtils.format(_app.selectedDate, _l10n.localeName)}',
      ),
      _SheetPage.manzil => (
        _l10n.t('manzilTitle'),
        '${s.name} · ${AppDateUtils.format(_app.selectedDate, _l10n.localeName)}',
      ),
    };
    return Row(
      children: [
        if (!isChooser)
          IconButton(
            tooltip: _l10n.t('back'),
            onPressed: () => setState(() => _page = _SheetPage.chooser),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: _l10n.t('cancel'),
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _attendanceToggle() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _l10n.t('attendance'),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(_l10n.t('present')),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(_l10n.t('absent')),
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                  ),
                ],
                selected: {_present},
                onSelectionChanged: (v) => setState(() => _present = v.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _present
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.danger.withValues(alpha: 0.25),
                  selectedForegroundColor: _present
                      ? AppColors.primarySoft
                      : AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chooser ───────────────────────────────────────────────────────────────

  /// Landing screen: attendance + one tappable card per lesson type.
  Widget _chooserPage(Student s) {
    return Column(
      key: const ValueKey('chooser'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _attendanceToggle(),
        const SizedBox(height: 14),
        Text(
          _l10n.t('recordWhat'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _trackOptionCard(
          title: _l10n.t('sabaq'),
          icon: Icons.auto_stories_rounded,
          color: AppColors.info,
          status: _sabaqStatus,
          onTap: () => setState(() => _page = _SheetPage.sabaq),
        ),
        const SizedBox(height: 10),
        _trackOptionCard(
          title: _l10n.t('sabqi'),
          icon: Icons.repeat_rounded,
          color: AppColors.indigo,
          status: _sabqiStatus,
          onTap: () => setState(() => _page = _SheetPage.sabqi),
        ),
        const SizedBox(height: 10),
        _trackOptionCard(
          title: _l10n.t('manzil'),
          icon: Icons.all_inclusive_rounded,
          color: AppColors.primary,
          status: _manzilStatus,
          onTap: () => setState(() => _page = _SheetPage.manzil),
        ),
      ],
    );
  }

  /// Short summary of the already-recorded Sabaq for the chooser card.
  String? get _sabaqStatus {
    final s = _existing?.sabaq;
    if (s == null) return null;
    final details = <String>['${_l10n.t('juz')} ${s.juz}'];
    if (s.pageLabel.isNotEmpty) details.add(s.pageLabel);
    if (s.lines > 0) details.add('${s.lines} ${_l10n.t('lines')}');
    return details.join(' · ');
  }

  /// Short summary of the already-recorded Sabqi for the chooser card.
  String? get _sabqiStatus {
    final s = _existing?.sabqi;
    if (s == null) return null;
    final details = <String>['${_l10n.t('juz')} ${s.juz}'];
    if (s.endPage > 0) {
      String pageStr = '${_l10n.t('page')} ${s.endPage}';
      try {
        final calc = MathEngine.computeParaSabqi(
          juz: s.juz,
          startPage: ParaCalculator.getStartPageForPara(
            s.juz,
            linesPerPage: widget.student.mushafLines,
          ),
          endPage: s.endPage,
          heardPage: s.endPage,
          linesPerPage: widget.student.mushafLines,
        );
        if (calc.valid && calc.totalPages > 0) {
          pageStr += ' (${calc.completedPages}/${calc.totalPages})';
        }
      } catch (_) {}
      details.add(pageStr);
    }
    if (s.revisionCount > 0) {
      details.add('${s.revisionCount} ${_l10n.t('sabaqi')}');
    }
    return details.join(' · ');
  }

  /// Short summary of the already-recorded Manzil for the chooser card.
  String? get _manzilStatus {
    final m = _existing?.manzil;
    if (m == null) return null;
    final isFullPara = (m.startJuz == null || m.startJuz == m.juz) &&
        (m.startRuba == null || m.startRuba == 1) &&
        m.ruba == 4;
    final rubaLabel = isFullPara
        ? _l10n.t('pooraPara')
        : (m.startRuba == 1 && m.ruba == 2
            ? _l10n.t('nisafAwal')
            : (m.startRuba == 3 && m.ruba == 4
                ? _l10n.t('nisafAkhir')
                : '${_l10n.t('ruba')} ${m.ruba}'));
    return '${_l10n.t('juz')} ${m.juz} · $rubaLabel';
  }

  // ── Sabaq ────────────────────────────────────────────────────────────────

  Widget _sabaqSection() {
    final lastSabaqRec = _lastSabaqRecord;
    return _SectionCard(
      title: _l10n.t('sabaqTitle'),
      icon: Icons.auto_stories_rounded,
      color: AppColors.info,
      children: [
        // Previous record banner
        if (lastSabaqRec != null && lastSabaqRec.sabaq != null) ...[
          _previousRecordBanner(
            color: AppColors.info,
            title: _l10n.t('previousSabaq'),
            detail: _l10n.t('previousSabaqDetail', args: [
              '${lastSabaqRec.sabaq!.juz}',
              '${lastSabaqRec.sabaq!.endPage > 0 ? lastSabaqRec.sabaq!.endPage : "—"}',
              '${lastSabaqRec.sabaq!.lines > 0 ? lastSabaqRec.sabaq!.lines : "—"}',
            ]),
            date: _l10n.t('previousRecordOn', args: [
              AppDateUtils.format(
                DateTime.parse(lastSabaqRec.date),
                _l10n.localeName,
              ),
            ]),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: _juzDropdown(
                key: const ValueKey('sabaq_juz_dropdown'),
                value: _sabaqJuz,
                onChanged: (v) => setState(() {
                  _sabaqJuz = v;
                  if (_existing?.sabaq == null) {
                    final suggestion = _sabaqSuggestion;
                    _pageLabelCtrl.text = suggestion > 0 ? '$suggestion' : '';
                  }
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _pageLabelCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _l10n.t('page'),
                  prefixIcon: const Icon(Icons.pages_rounded, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _paraRangeRibbon(juz: _sabaqJuz, color: AppColors.info),
        if (_pageLabelCtrl.text.trim().isEmpty && _sabaqSuggestion > 0) ...[
          const SizedBox(height: 6),
          _suggestionChip(
            color: AppColors.info,
            page: _sabaqSuggestion,
            onTap: () => setState(() => _pageLabelCtrl.text = '$_sabaqSuggestion'),
          ),
        ],
        _startPageHint(_sabaqStartPage),
        const SizedBox(height: 10),
        TextField(
          controller: _linesCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '${_l10n.t('lines')} (1–15)',
            prefixIcon: const Icon(
              Icons.format_list_numbered_rounded,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Para Start & Para End Action Row
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _isParaStart = !_isParaStart;
                  if (_isParaStart) {
                    _isParaEnd = false;
                    _paraStartDate = AppDateUtils.key(_app.selectedDate);
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isParaStart
                        ? AppColors.info.withValues(alpha: 0.18)
                        : AppColors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isParaStart
                          ? AppColors.info
                          : AppColors.info.withValues(alpha: 0.3),
                      width: _isParaStart ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isParaStart ? Icons.play_circle_fill_rounded : Icons.play_circle_outline_rounded,
                        size: 18,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _l10n.t('paraStart'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _isParaEnd = !_isParaEnd;
                  if (_isParaEnd) {
                    _isParaStart = false;
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isParaEnd
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isParaEnd
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: _isParaEnd ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isParaEnd ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _l10n.t('paraEnd'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _sabaqParaDaysBanner(),
        if (_sabaqInvalid) ...[
          const SizedBox(height: 10),
          _AlertBox(
            color: AppColors.danger,
            icon: Icons.error_rounded,
            message: _l10n.t(
              'sabaqPageOutOfRange',
              args: [
                '$_sabaqEndPage',
                '$_sabaqJuz',
                '$_sabaqStartPage',
                '$_sabaqParaEnd',
              ],
            ),
          ),
        ] else
          _sabaqParaProgress(),
      ],
    );
  }

  /// Live para-based "pages read" progress for the Sabaq lesson.
  Widget _sabaqParaProgress() {
    final end = _sabaqEndPage;
    final start = _sabaqStartPage;
    if (end <= 0) return const SizedBox.shrink();
    if (_sabaqJuz < 1 || _sabaqJuz > AppConstants.maxJuz) {
      return const SizedBox.shrink();
    }
    final calc = MathEngine.computeParaSabqi(
      juz: _sabaqJuz,
      startPage: start,
      endPage: end,
      heardPage: end > 0 ? end : start,
      linesPerPage: widget.student.mushafLines,
    );
    if (!calc.valid || calc.totalPages <= 0) return const SizedBox.shrink();
    final paraStart = ParaCalculator.getStartPageForPara(
      _sabaqJuz,
      linesPerPage: widget.student.mushafLines,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GlassCard(
        fill: AppColors.info.withValues(alpha: 0.06),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _l10n.t('paraProgress'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.info,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_l10n.t('juz')} $_sabaqJuz · ${_l10n.t('page')} $paraStart–${paraStart + calc.totalPages - 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: calc.progress / 100,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      color: calc.remainingPages > 0
                          ? AppColors.warning
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${calc.completedPages}/${calc.totalPages} · ${calc.progress}%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: calc.remainingPages > 0
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Banner showing how many days the current Sabaq Juz has been active/ongoing.
  Widget _sabaqParaDaysBanner() {
    final studentRecords = _app.recordsForStudent(widget.student.id);
    final paraRecords = studentRecords.where((r) => r.sabaq?.juz == _sabaqJuz).toList();
    if (paraRecords.isEmpty && !_isParaStart) return const SizedBox.shrink();

    paraRecords.sort((a, b) => a.date.compareTo(b.date));
    final startRec = paraRecords.firstWhere(
      (r) => r.sabaq?.isParaStart == true || r.sabaq?.paraStartDate != null,
      orElse: () => paraRecords.isNotEmpty ? paraRecords.first : DailyRecord(id: '', studentId: widget.student.id, date: AppDateUtils.key(_app.selectedDate)),
    );
    final startDateStr = _isParaStart
        ? (_paraStartDate ?? AppDateUtils.key(_app.selectedDate))
        : (startRec.sabaq?.paraStartDate ?? startRec.date);

    final startDt = DateTime.tryParse(startDateStr);
    final currentDt = _app.selectedDate;
    if (startDt == null) return const SizedBox.shrink();

    final daysDiff = currentDt.difference(startDt).inDays + 1;
    final days = daysDiff > 0 ? daysDiff : 1;

    final color = _isParaEnd ? AppColors.primary : AppColors.info;
    final icon = _isParaEnd ? Icons.task_alt_rounded : Icons.timer_outlined;
    final message = _isParaEnd
        ? _l10n.t('paraCompletedInDays', args: ['$days'])
        : _l10n.t('paraOngoingDays', args: ['$days']);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sabqi ────────────────────────────────────────────────────────────────

  Widget _sabqiSection() {
    final calc = _sabqiCalc;
    final last = _lastSabqi;
    final lastSabqiRec = _lastSabqiRecord;
    return _SectionCard(
      title: _l10n.t('sabqiTitle'),
      icon: Icons.repeat_rounded,
      color: AppColors.indigo,
      children: [
        // Previous record banner
        if (lastSabqiRec != null && lastSabqiRec.sabqi != null) ...[
          _previousRecordBanner(
            color: AppColors.indigo,
            title: _l10n.t('previousSabqi'),
            detail: _l10n.t('previousSabqiDetail', args: [
              '${lastSabqiRec.sabqi!.juz}',
              '${lastSabqiRec.sabqi!.endPage > 0 ? lastSabqiRec.sabqi!.endPage : "—"}',
              '${lastSabqiRec.sabqi!.endPage > 0 ? (lastSabqiRec.sabqi!.endPage - lastSabqiRec.sabqi!.startPage + 1) : "—"}',
            ]),
            date: _l10n.t('previousRecordOn', args: [
              AppDateUtils.format(
                DateTime.parse(lastSabqiRec.date),
                _l10n.localeName,
              ),
            ]),
          ),
        ],
        // Mode Selector (Pages / Nisaf / Para)
        Row(
          children: [
            Expanded(
              child: _modeButton(
                label: _l10n.t('pagesMode'),
                isSelected: _sabqiMode == 'pages',
                color: AppColors.indigo,
                onTap: () => setState(() => _sabqiMode = 'pages'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _modeButton(
                label: _l10n.t('nisafMode'),
                isSelected: _sabqiMode == 'nisaf',
                color: AppColors.indigo,
                onTap: () => setState(() => _sabqiMode = 'nisaf'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _modeButton(
                label: _l10n.t('fullPara'),
                isSelected: _sabqiMode == 'para',
                color: AppColors.indigo,
                onTap: () {
                  setState(() {
                    _sabqiMode = 'para';
                    // Auto-fill mushaf page to end of para
                    final end = _sabqiParaEnd;
                    if (end > 0) {
                      _mushafPageCtrl.text = '$end';
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (last != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.indigo.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 15,
                  color: AppColors.indigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastSabqiLabel(last),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Juz + Mushaf Page + End Page
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _juzDropdown(
                key: const ValueKey('sabqi_juz_dropdown'),
                value: _sabqiJuz,
                onChanged: (v) => setState(() {
                  _sabqiJuz = v;
                  // In para mode, auto-fill mushaf page when juz changes
                  if (_sabqiMode == 'para') {
                    final end = _sabqiParaEnd;
                    if (end > 0) _mushafPageCtrl.text = '$end';
                  }
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _mushafPageCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                readOnly: _sabqiMode == 'para',
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _sabqiMode == 'para'
                      ? _l10n.t('fullPara')
                      : _l10n.t('mushafPage'),
                  filled: _sabqiMode == 'para',
                  fillColor: _sabqiMode == 'para'
                      ? AppColors.indigo.withValues(alpha: 0.08)
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _paraRangeRibbon(juz: _sabqiJuz, color: AppColors.indigo),

        // Mode-specific UI: Para mode shows full para info, Nisaf quick buttons or Pages suggestion
        if (_sabqiMode == 'para') ...[
          const SizedBox(height: 12),
          GlassCard(
            fill: AppColors.indigo.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.bookmark_rounded, size: 18, color: AppColors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _l10n.t('fullParaDesc'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_sabqiMode == 'nisaf') ...[
          const SizedBox(height: 12),
          Text(
            _l10n.t('quickSelect'),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          // Ruba quick buttons (Ruba 1–4): fill the page to that Ruba's end.
          Row(
            children: [
              for (var r = 1; r <= 4; r++) ...[
                Expanded(
                  child: _QuickButton(
                    key: ValueKey('sabqi_ruba_$r'),
                    label: '${_l10n.t('ruba')} $r',
                    color: AppColors.indigo,
                    selected: _rubaForPage(_sabqiJuz, _intVal(_mushafPageCtrl)) == r,
                    onTap: () {
                      final end = _rubaEndPage(_sabqiJuz, r);
                      if (end > 0) setState(() => _mushafPageCtrl.text = '$end');
                    },
                  ),
                ),
                if (r != 4) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _QuickButton(
                  label: _l10n.t('nisafAwal'),
                  color: AppColors.indigo,
                  onTap: () {
                    final end = _rubaEndPage(_sabqiJuz, 2);
                    if (end > 0) setState(() => _mushafPageCtrl.text = '$end');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickButton(
                  label: _l10n.t('nisafAkhir'),
                  color: AppColors.indigo,
                  onTap: () {
                    final end = _rubaEndPage(_sabqiJuz, 4);
                    if (end > 0) setState(() => _mushafPageCtrl.text = '$end');
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          // Pages mode - show suggestion chip if mushaf page is empty
          if (_mushafPageCtrl.text.trim().isEmpty && _sabqiSuggestion > 0) ...[
            const SizedBox(height: 6),
            _suggestionChip(
              color: AppColors.indigo,
              page: _sabqiSuggestion,
              onTap: () => setState(() => _mushafPageCtrl.text = '$_sabqiSuggestion'),
            ),
          ],
        ],
        _startPageHint(_sabqiStartPage),

        // Revision Counter (V4-style)
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded, size: 18, color: AppColors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.t('sabaqi'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_revisionCount > 0)
                IconButton(
                  onPressed: () => setState(() => _revisionCount--),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppColors.danger,
                  visualDensity: VisualDensity.compact,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_revisionCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _revisionCount++),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.indigo,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        if (calc != null) ...[const SizedBox(height: 10), _paraProgressPanel()],

        // Double Sabqi Toggle
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.queue_rounded,
                size: 18,
                color: AppColors.indigo,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.t('doubleSabqi'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: _isDoubleSabqi,
                onChanged: (v) => setState(() {
                  _isDoubleSabqi = v;
                  if (!v) {
                    _doubleSabqiJuz = null;
                    _doubleSabqiRuba = null;
                  }
                }),
                activeThumbColor: AppColors.indigo,
              ),
            ],
          ),
        ),

        // Double Sabqi Fields
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isDoubleSabqi
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    _juzDropdown(
                      key: const ValueKey('double_sabqi_juz_dropdown'),
                      value: _doubleSabqiJuz ?? _sabqiJuz,
                      onChanged: (v) => setState(() => _doubleSabqiJuz = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var r = 1; r <= 4; r++) ...[
                          Expanded(
                            child: _QuickButton(
                              key: ValueKey('double_sabqi_ruba_$r'),
                              label: '${_l10n.t('ruba')} $r',
                              color: AppColors.indigo,
                              selected: _doubleSabqiRuba == r,
                              onTap: () => setState(() => _doubleSabqiRuba = r),
                            ),
                          ),
                          if (r != 4) const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickButton(
                            label: _l10n.t('nisafAwal'),
                            color: AppColors.indigo,
                            selected: _doubleSabqiRuba == 2,
                            onTap: () => setState(() => _doubleSabqiRuba = 2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _QuickButton(
                            label: _l10n.t('nisafAkhir'),
                            color: AppColors.indigo,
                            selected: _doubleSabqiRuba == 4,
                            onTap: () => setState(() => _doubleSabqiRuba = 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        if (calc != null && calc.totalPages > _paraTotalPages) ...[
          const SizedBox(height: 10),
          _AlertBox(
            color: AppColors.danger,
            icon: Icons.error_rounded,
            message: _l10n.t('pageLimitWarning'),
          ),
        ],
        if (calc != null && calc.remainingPages > 0 && calc.valid) ...[
          const SizedBox(height: 10),
          _AlertBox(
            color: AppColors.warning,
            icon: Icons.warning_amber_rounded,
            message: _l10n.t(
              'remainingPagesAlert',
              args: ['${calc.remainingPages}'],
            ),
          ),
        ],
      ],
    );
  }


  /// Para-aware progress: where the student stands inside the whole Juz for
  /// their mushaf (15/16 lines), based on the heard page.
  Widget _paraProgressPanel() {
    final end = _intVal(_mushafPageCtrl);
    if (end <= 0) return const SizedBox.shrink();
    if (_sabqiJuz < 1 || _sabqiJuz > AppConstants.maxJuz) {
      return const SizedBox.shrink();
    }
    final paraCalc = MathEngine.computeParaSabqi(
      juz: _sabqiJuz,
      startPage: _sabqiStartPage,
      endPage: end,
      heardPage: end,
      linesPerPage: widget.student.mushafLines,
    );
    final paraStart = ParaCalculator.getStartPageForPara(
      _sabqiJuz,
      linesPerPage: widget.student.mushafLines,
    );
    return GlassCard(
      fill: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.t('paraProgress'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primarySoft,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_l10n.t('juz')} $_sabqiJuz · ${_l10n.t('page')} $paraStart–${paraStart + paraCalc.totalPages - 1}',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: paraCalc.progress / 100,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: paraCalc.remainingPages > 0
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${paraCalc.completedPages}/${paraCalc.totalPages} · ${paraCalc.progress}%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: paraCalc.remainingPages > 0
                      ? AppColors.warning
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  // ── Manzil ───────────────────────────────────────────────────────────────



  Widget _manzilSection(Student s) {
    final lastManzilRec = _lastManzilRecord;
    return _SectionCard(
      title: _l10n.t('manzilTitle'),
      icon: Icons.all_inclusive_rounded,
      color: AppColors.primary,
      children: [
        // Previous record banner
        if (lastManzilRec != null && lastManzilRec.manzil != null) ...[
          _previousRecordBanner(
            color: AppColors.primary,
            title: _l10n.t('previousManzil'),
            detail: () {
              final m = lastManzilRec.manzil!;
              final isFullPara = (m.startJuz == null || m.startJuz == m.juz) &&
                  (m.startRuba == null || m.startRuba == 1) &&
                  m.ruba == 4;
              final rubaLabel = isFullPara
                  ? _l10n.t('pooraPara')
                  : (m.startRuba == 1 && m.ruba == 2
                      ? _l10n.t('nisafAwal')
                      : (m.startRuba == 3 && m.ruba == 4
                          ? _l10n.t('nisafAkhir')
                          : '${_l10n.t('ruba')} ${m.ruba}'));
              return _l10n.t('previousManzilDetail', args: [
                '${m.juz}',
                rubaLabel,
              ]);
            }(),
            date: _l10n.t('previousRecordOn', args: [
              AppDateUtils.format(
                DateTime.parse(lastManzilRec.date),
                _l10n.localeName,
              ),
            ]),
          ),
        ],

        // Cycle Progress (V4-style)
        GlassCard(
          fill: AppColors.primary.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.autorenew_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.t('manzilProgress'),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getManzilProgressText(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (_suggestion != null)
                Text(
                  _l10n.t('cycle', args: ['${s.manzilCycle}']),
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 1. Primary Para Selector (Har waqat visible)
        Row(
          children: [
            Icon(Icons.bookmark_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              _l10n.t('juz'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _juzDropdown(
          key: const ValueKey('manzil_end_juz_dropdown'),
          value: _manzilJuz,
          onChanged: (v) => setState(() {
            _manzilJuz = v;
          }),
        ),
        const SizedBox(height: 8),
        _RubaNisafPicker(
          juz: _manzilJuz,
          color: AppColors.primary,
          linesPerPage: widget.student.mushafLines,
          selectedRuba: _manzilRuba,
          selectedStartRuba: _manzilStartRuba,
          showMultipleParaToggle: false,
          showNisafRow: true,
          onSelect: (juz, ruba, [startRuba]) => setState(() {
            _manzilJuz = juz;
            _manzilRuba = ruba;
            _manzilStartRuba = startRuba ?? ruba;
          }),
          onSelectFullPara: (juz) => setState(() {
            _manzilJuz = juz;
            _manzilRuba = 4;
            _manzilStartRuba = 1;
          }),
        ),

        const SizedBox(height: 12),

        // 2. Multiple Paras Button + Text Field Input
        GestureDetector(
          onTap: () => setState(() {
            _isMultipleManzil = !_isMultipleManzil;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isMultipleManzil
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isMultipleManzil
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isMultipleManzil
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _l10n.t('multipleParas'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isMultipleManzil) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _manzilCustomCtrl,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: _l10n.t('multipleParasHint'),
              labelText: _l10n.t('multipleParasLabel'),
              prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.glassFillStrong
                  : AppColors.lightGlassFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],

        if (_suggestion != null) ...[
          const SizedBox(height: 12),
          GlassCard(
            fill: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _l10n.t('nextSuggestion'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_l10n.t('juz')} ${_suggestion!.juz} · ${_l10n.t('ruba')} ${_suggestion!.ruba}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primarySoft,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _manzilJuz = _suggestion!.juz;
                    _manzilRuba = _suggestion!.ruba;
                  }),
                  child: Text(_l10n.t('useSuggestion')),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Manzil Count (V4-style)
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tag_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.t('manzilCycleLabel'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_manzilCount > 0)
                IconButton(
                  onPressed: () => setState(() => _manzilCount--),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppColors.danger,
                  visualDensity: VisualDensity.compact,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_manzilCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _manzilCount++),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '🔄 ${_l10n.t('completedCycles', args: ['${s.manzilCycle}'])}',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── Shared controls ──────────────────────────────────────────────────────

  String _getManzilProgressText() {
    var juz = _manzilJuz;
    var ruba = _manzilRuba;
    var count = 1;
    while ((juz != _manzilJuz || ruba != _manzilRuba) && count < 120) {
      count++;
      if (ruba < 4) {
        ruba++;
      } else {
        ruba = 1;
        if (widget.student.manzilReverse) {
          juz = juz > widget.student.manzilEndJuz ? juz - 1 : widget.student.manzilStartJuz;
        } else {
          juz = juz < widget.student.manzilEndJuz ? juz + 1 : widget.student.manzilStartJuz;
        }
      }
    }
    final totalParas = widget.student.manzilEndJuz - widget.student.manzilStartJuz + 1;
    final targetRubas = totalParas * 4;
    return '$count / $targetRubas ${_l10n.t('ruba')} ${_l10n.t('completed')}';
  }

  /// Mode selector button (V4-style) used by Sabqi and Manzil sections.
  Widget _modeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  /// Big tappable card on the chooser opening one lesson type's own screen.
  Widget _trackOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String? status,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      borderColor: color.withValues(alpha: 0.35),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status ?? _l10n.t('noLesson'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: status == null
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            status == null
                ? Icons.add_circle_outline_rounded
                : Icons.check_circle_rounded,
            size: 22,
            color: status == null ? color : AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Thin ribbon showing the selected Para's real page range (start–end) for
  /// the student's mushaf. Appears under the Juz dropdown as soon as a Para
  /// is selected, so the teacher sees where the Para sits in the Mushaf.
  Widget _paraRangeRibbon({required int juz, required Color color}) {
    return _ParaRangeRibbon(
      juz: juz,
      color: color,
      linesPerPage: widget.student.mushafLines,
    );
  }

  Widget _juzDropdown({
    Key? key,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: _l10n.t('juz'),
        prefixIcon: const Icon(Icons.filter_1_rounded, size: 20),
      ),
      items: [
        for (final j in AppConstants.juzNumbers)
          DropdownMenuItem(
            value: j,
            child: Text(
              '${_l10n.t('juz')} $j',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  /// Tappable suggestion under an empty page field: fills it with [page] so
  /// the teacher only confirms the miqdaar. Used for Sabaq & Sabqi.
  Widget _suggestionChip({
    required Color color,
    required int page,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates_rounded, size: 15, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _l10n.t('pageSuggestion'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              '${_l10n.t('page')} $page',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.add_circle_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  /// Small hint under the end-page field showing the start page the app
  /// derives automatically (previous end + 1, or the Para's first page).
  Widget _startPageHint(int startPage) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _l10n.t('startsFromPage', args: ['$startPage']),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBar() {
    final (canSave, onSave) = switch (_page) {
      _SheetPage.sabaq => (
        !_sabaqInvalid && _hasSabaqInput,
        _saveSabaq,
      ),
      _SheetPage.sabqi => (
        !_sabqiInvalid && _hasSabqiInput,
        _saveSabqi,
      ),
      _SheetPage.manzil => (_manzilJuz > 0, _saveManzil),
      _SheetPage.chooser => (false, _saveSabaq), // unreachable — no bar on chooser
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          onPressed: canSave ? onSave : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.2),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isEdit ? '${_l10n.t('save')} ✓' : _l10n.t('save'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

// ── Small building blocks ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: color.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Compact quick-select button used for Ruba / Nisaf shortcuts.
class _QuickButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  const _QuickButton({
    Key? key,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.25 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.8 : 0.35),
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A Ruba (quarter) boundary marker on the para-range ribbon: the Ruba
/// number above a thin vertical tick that hangs from the track.
class _RubaBoundaryTick extends StatelessWidget {
  final int ruba;
  final Color color;

  const _RubaBoundaryTick({required this.ruba, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$ruba',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 2,
            height: 15,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// One end of the para-range ribbon: a tiny label above the page number.
class _RibbonPageEnd extends StatelessWidget {
  final String label;
  final int page;
  final Color color;
  final bool alignEnd;

  const _RibbonPageEnd({
    required this.label,
    required this.page,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),
        Text(
          '$page',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Thin ribbon showing a Para's real page range (start–end) for the student's
/// mushaf, with Ruba 1–4 boundary ticks. Shown under Juz dropdowns.
class _ParaRangeRibbon extends StatelessWidget {
  final int juz;
  final Color color;
  final int linesPerPage;

  const _ParaRangeRibbon({
    required this.juz,
    required this.color,
    required this.linesPerPage,
  });

  @override
  Widget build(BuildContext context) {
    if (juz < 1 || juz > AppConstants.maxJuz) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final start =
        ParaCalculator.getStartPageForPara(juz, linesPerPage: linesPerPage);
    final end = ParaCalculator.getEndPageForPara(juz, linesPerPage: linesPerPage);
    final rubaEnds = <int>[
      for (var r = 1; r <= 4; r++)
        ParaCalculator.getEndPageForRuba(juz, r, linesPerPage: linesPerPage),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _RibbonPageEnd(
            label: l10n.t('startPage'),
            page: start,
            color: color,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 30,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final span = end - start;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 12,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [color.withValues(alpha: 0.3), color],
                              ),
                            ),
                          ),
                        ),
                        for (var r = 1; r <= 4; r++) ...[
                          Positioned(
                            left: (span <= 0
                                    ? 0
                                    : ((rubaEnds[r - 1] - start) / span) *
                                        w) -
                                6,
                            top: 0,
                            child: _RubaBoundaryTick(
                              ruba: r,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          _RibbonPageEnd(
            label: l10n.t('endPage'),
            page: end,
            color: color,
            alignEnd: true,
          ),
        ],
      ),
    );
  }
}

/// Quick Ruba / Nisaf picker shared by the Sabqi & Manzil sections: four Ruba
/// buttons, Nisaf Awal/Akhir shortcuts and a collapsible "Multiple para" panel
/// that adds a para selector + the same buttons for another para.
class _RubaNisafPicker extends StatefulWidget {
  final int juz;
  final Color color;
  final int linesPerPage;
  final int? selectedRuba;
  final int? selectedStartRuba;
  final void Function(int juz, int ruba, [int? startRuba]) onSelect;
  final void Function(int juz)? onSelectFullPara;
  final bool showMultipleParaToggle;
  final bool showNisafRow;

  const _RubaNisafPicker({
    required this.juz,
    required this.color,
    required this.linesPerPage,
    required this.onSelect,
    this.selectedRuba,
    this.selectedStartRuba,
    this.onSelectFullPara,
    this.showMultipleParaToggle = true,
    this.showNisafRow = true,
  });

  @override
  State<_RubaNisafPicker> createState() => _RubaNisafPickerState();
}

class _RubaNisafPickerState extends State<_RubaNisafPicker> {
  bool _showMulti = false;
  int? _multiJuz;
  int? _multiRuba;

  int get _multi => _multiJuz ?? widget.juz;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('quickSelect'),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _rubaRow(l10n, juz: widget.juz, selected: widget.selectedRuba),
        if (widget.showNisafRow) ...[
          const SizedBox(height: 6),
          _nisafRow(l10n, juz: widget.juz),
        ],
        if (widget.showMultipleParaToggle) ...[
          const SizedBox(height: 8),
          _multiToggle(l10n),
          if (_showMulti) ...[const SizedBox(height: 8), _multiPanel(l10n)],
        ],
      ],
    );
  }

  Widget _rubaRow(
    AppLocalizations l10n, {
    required int juz,
    int? selected,
    bool isMulti = false,
    void Function(int ruba)? beforeSelect,
  }) {
    return Row(
      children: [
        for (var r = 1; r <= 4; r++) ...[
          Expanded(
            child: _QuickButton(
              key: ValueKey('ruba-$juz-${isMulti ? 'multi' : 'main'}-$r'),
              label: '${l10n.t('ruba')} $r',
              color: widget.color,
              selected: selected == r && (widget.selectedStartRuba == null || widget.selectedStartRuba == r),
              onTap: () {
                beforeSelect?.call(r);
                widget.onSelect(juz, r, r);
              },
            ),
          ),
          if (r != 4) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _nisafRow(
    AppLocalizations l10n, {
    required int juz,
    bool isMulti = false,
    void Function(int ruba)? beforeSelect,
  }) {
    final isFullParaSelected = widget.selectedRuba == 4 && (widget.selectedStartRuba == null || widget.selectedStartRuba == 1);
    final isNisafAwalSelected = widget.selectedRuba == 2 && widget.selectedStartRuba == 1;
    final isNisafAkhirSelected = widget.selectedRuba == 4 && widget.selectedStartRuba == 3;

    return Row(
      children: [
        Expanded(
          child: _QuickButton(
            key: ValueKey('nisaf-$juz-awal-${isMulti ? 'multi' : 'main'}'),
            label: l10n.t('nisafAwal'),
            color: widget.color,
            selected: isNisafAwalSelected,
            onTap: () {
              beforeSelect?.call(2);
              widget.onSelect(juz, 2, 1);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickButton(
            key: ValueKey('nisaf-$juz-akhir-${isMulti ? 'multi' : 'main'}'),
            label: l10n.t('nisafAkhir'),
            color: widget.color,
            selected: isNisafAkhirSelected,
            onTap: () {
              beforeSelect?.call(4);
              widget.onSelect(juz, 4, 3);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickButton(
            key: ValueKey('poora-para-$juz-${isMulti ? 'multi' : 'main'}'),
            label: l10n.t('pooraPara'),
            color: widget.color,
            selected: isFullParaSelected,
            onTap: () {
              if (widget.onSelectFullPara != null) {
                widget.onSelectFullPara!(juz);
              } else {
                beforeSelect?.call(4);
                widget.onSelect(juz, 4, 1);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _multiToggle(AppLocalizations l10n) {
    return InkWell(
      onTap: () => setState(() {
        _showMulti = !_showMulti;
        if (_showMulti) {
          _multiJuz = widget.juz;
          _multiRuba = null;
        }
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _showMulti
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: widget.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.t('multiplePara'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Revealed panel: para selector + ribbon + the same Ruba/Nisaf buttons,
  /// all applying to the para chosen here.
  Widget _multiPanel(AppLocalizations l10n) {
    final multi = _multi;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            key: const ValueKey('sabqi_multi_juz_dropdown'),
            value: multi,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.t('juz'),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            items: [
              for (final j in AppConstants.juzNumbers)
                DropdownMenuItem(value: j, child: Text('${l10n.t('juz')} $j')),
            ],
            onChanged: (v) => setState(() => _multiJuz = v),
          ),
          const SizedBox(height: 8),
          _ParaRangeRibbon(
            juz: multi,
            color: widget.color,
            linesPerPage: widget.linesPerPage,
          ),
          const SizedBox(height: 8),
          _rubaRow(
            l10n,
            juz: multi,
            selected: _multiRuba,
            isMulti: true,
            beforeSelect: (r) => setState(() => _multiRuba = r),
          ),
          if (widget.showNisafRow) ...[
            const SizedBox(height: 6),
            _nisafRow(
              l10n,
              juz: multi,
              isMulti: true,
              beforeSelect: (r) => setState(() => _multiRuba = r),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _AlertBox({
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
