import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/utils/app_date_utils.dart';
import '../localization/app_localizations.dart';

/// Glass date navigation: ◀ date ▶ + calendar picker.
class DateSelectorRow extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  const DateSelectorRow({
    super.key,
    required this.date,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.glassFillStrong : AppColors.lightGlassFill;
    final border = isDark ? AppColors.glassBorder : AppColors.lightGlassBorder;

    Widget navBtn(IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 19, color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          navBtn(
            Icons.chevron_left_rounded,
            () => onDateChanged(date.subtract(const Duration(days: 1))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) onDateChanged(picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.relative(
                        date,
                        l10n.localeName,
                        todayLabel: l10n.t('today'),
                        yesterdayLabel: l10n.t('yesterday'),
                        tomorrowLabel: l10n.t('tomorrow'),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          navBtn(
            Icons.chevron_right_rounded,
            () => onDateChanged(date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}
