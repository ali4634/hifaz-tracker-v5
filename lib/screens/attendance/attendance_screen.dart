import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../localization/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../naagha/naagha_screen.dart';
import '../students/student_form_screen.dart';
import 'lesson_entry_sheet.dart';
import 'student_card.dart';

class AttendanceScreen extends StatefulWidget {
  /// Whether the date selector row (◀ date ▶) is visible.
  final bool showDateSelector;

  const AttendanceScreen({super.key, this.showDateSelector = true});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final students = app.sectionStudents;
    final query = _searchCtrl.text.trim().toLowerCase();
    final visible =
        query.isEmpty
            ? students
            : students
                  .where((s) => s.name.toLowerCase().contains(query))
                  .toList();
    return Column(
      children: [
        const _NaaghaBanner(),
        if (widget.showDateSelector)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                // Compact date navigation
                _CompactDateSelector(
                  date: app.selectedDate,
                  onDateChanged: app.setDate,
                  l10n: l10n,
                ),
                const SizedBox(width: 8),
                // Search bar
                Expanded(
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        if (!widget.showDateSelector)
          _SearchBar(
            controller: _searchCtrl,
            onChanged: () => setState(() {}),
          ),
        Expanded(
          child: students.isEmpty
              ? EmptyState(
                  icon: Icons.school_rounded,
                  title: l10n.t('noStudents'),
                  description: l10n.t('noStudentsDesc'),
                  actionLabel: l10n.t('addStudent'),
                  onAction: () => _openAddStudent(context),
                )
              : visible.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.t('noSearchResults'),
                  description: '',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final student = visible[i];
                    return StudentCard(
                      student: student,
                      record: app.recordFor(student.id),
                      onRecordLesson: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => LessonEntrySheet(student: student),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openAddStudent(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StudentFormScreen()));
  }
}

/// Compact date navigation with left/right arrows and calendar picker.
class _CompactDateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final AppLocalizations l10n;

  const _CompactDateSelector({
    required this.date,
    required this.onDateChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.glassFillStrong : AppColors.lightGlassFill;
    final border = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous day
          InkWell(
            onTap: () => onDateChanged(date.subtract(const Duration(days: 1))),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Container(
              width: 34,
              height: 38,
              alignment: Alignment.center,
              child: const Icon(Icons.chevron_left_rounded, size: 19),
            ),
          ),
          // Date display + calendar picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 38,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.relative(
                      date,
                      l10n.localeName,
                      todayLabel: l10n.t('today'),
                      yesterdayLabel: l10n.t('yesterday'),
                      tomorrowLabel: l10n.t('tomorrow'),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Next day
          InkWell(
            onTap: () => onDateChanged(date.add(const Duration(days: 1))),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              width: 34,
              height: 38,
              alignment: Alignment.center,
              child: const Icon(Icons.chevron_right_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass search field filtering the student list by name.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.glassFillStrong : AppColors.lightGlassFill;
    final border = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

    return TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.t('searchStudents'),
          hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 1.4),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  tooltip: l10n.t('cancel'),
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                )
              : null,
        ),
      );
  }
}

/// Red attention banner shown at the top of the Attendance tab when any
/// student has a gap (naagha) in Sabaq, Sabqi or Manzil. Hidden entirely
/// when everyone is up to date.
class _NaaghaBanner extends StatelessWidget {
  const _NaaghaBanner();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final count =
        app.naaghaUnseenStudentCount(settings.settings.missingSabqiDays);
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderColor: AppColors.danger.withValues(alpha: 0.5),
        glowColor: AppColors.danger,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NaaghaScreen()),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('naaghaBannerTitle'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.t('naaghaBannerBody', args: ['$count']),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

