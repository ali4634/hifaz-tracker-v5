import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../localization/app_localizations.dart';

/// Glass dropdown pill for switching between sections A / B / C.
class SectionSwitcher extends StatelessWidget {
  final String section;
  final ValueChanged<String> onChanged;

  const SectionSwitcher({
    super.key,
    required this.section,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassFillStrong : AppColors.lightGlassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
        ),
      ),
      child: PopupMenuButton<String>(
        initialValue: section,
        tooltip: l10n.t('section'),
        color: isDark ? AppColors.bgElevated : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: onChanged,
        itemBuilder: (context) => [
          for (final s in ['A', 'B', 'C'])
            PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(
                    s == section ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: s == section
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.t('section')} $s',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '${l10n.t('section')} $section',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
