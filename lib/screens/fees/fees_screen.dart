import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../localization/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_card.dart';

/// Fees collection screen: shows all students in the current section with
/// their monthly fee paid/unpaid status. Teacher can tap to toggle.
class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final section = app.selectedSection;
    final students = app.students
        .where((s) => s.section == section)
        .toList()
      ..sort((a, b) {
        if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final paidCount = app.paidCountForMonth(section, _month, _year);
    final totalCount = students.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector + Summary
          _MonthSelector(
            month: _month,
            year: _year,
            onChanged: (m, y) => setState(() {
              _month = m;
              _year = y;
            }),
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            paid: paidCount,
            total: totalCount,
            month: _month,
            year: _year,
            l10n: l10n,
          ),
          const SizedBox(height: 12),
          // Student fee list
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      l10n.t('noStudents'),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: students.length,
                    itemBuilder: (context, i) => _FeeTile(
                      student: students[i],
                      month: _month,
                      year: _year,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Month navigation row with left/right arrows.
class _MonthSelector extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int month, int year) onChanged;

  const _MonthSelector({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthName = AppDateUtils.monthName(month, l10n.localeName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (month == 1) {
              onChanged(12, year - 1);
            } else {
              onChanged(month - 1, year);
            }
          },
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          color: AppColors.textSecondary,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassFillStrong : AppColors.lightGlassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '$monthName $year',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (month == 12) {
              onChanged(1, year + 1);
            } else {
              onChanged(month + 1, year);
            }
          },
          icon: const Icon(Icons.chevron_right_rounded, size: 24),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

/// Summary card showing paid/total count.
class _SummaryCard extends StatelessWidget {
  final int paid;
  final int total;
  final int month;
  final int year;
  final AppLocalizations l10n;

  const _SummaryCard({
    required this.paid,
    required this.total,
    required this.month,
    required this.year,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? paid / total : 0.0;

    return GlassCard(
      fill: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.t('totalCollection'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: paid == total && total > 0
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$paid/$total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: paid == total && total > 0
                        ? AppColors.primarySoft
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: progress >= 1.0 ? AppColors.primary : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual student fee tile with toggle.
class _FeeTile extends StatelessWidget {
  final dynamic student;
  final int month;
  final int year;

  const _FeeTile({
    required this.student,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final fee = app.feeForStudentMonth(student.id, month, year);
    final isPaid = fee?.paid ?? false;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: isPaid
          ? AppColors.primary.withValues(alpha: 0.4)
          : null,
      child: Row(
        children: [
          // Student avatar/icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 22,
              color: isPaid ? AppColors.primary : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          // Student name + section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? l10n.t('feePaid')
                      : l10n.t('feeUnpaid'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isPaid ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          // Toggle button
          GestureDetector(
            onTap: () => app.toggleFee(
              studentId: student.id,
              month: month,
              year: year,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPaid
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.warning.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle_rounded : Icons.money_off_rounded,
                    size: 15,
                    color: isPaid ? AppColors.primary : AppColors.warning,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPaid ? l10n.t('paid') : l10n.t('unpaid'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPaid ? AppColors.primary : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
