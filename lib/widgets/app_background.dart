import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Full-screen gradient background with soft glow blobs.
///
/// Follows the active theme brightness, so the gradient, glow blobs and
/// contrast always match the current dark/light mode.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.bgDeep, AppColors.bgBase, AppColors.bgElevated]
              : [AppColors.lightBg, AppColors.lightBgDeep],
        ),
      ),
      child: Stack(
        children: [
          // Glow blobs
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(
              size: 320,
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(
              size: 360,
              color: isDark
                  ? AppColors.indigo.withValues(alpha: 0.10)
                  : AppColors.info.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.35,
            right: -140,
            child: _Glow(
              size: 300,
              color: isDark
                  ? AppColors.warning.withValues(alpha: 0.05)
                  : AppColors.warning.withValues(alpha: 0.10),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
