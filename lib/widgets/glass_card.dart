import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A glassmorphic card: translucent fill, backdrop blur, soft border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? fill;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.fill,
    this.borderColor,
    this.glowColor,
    this.onTap,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);
    final baseFill =
        fill ?? (isDark ? AppColors.glassFill : AppColors.lightGlassFill);
    final baseBorder =
        borderColor ??
        (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: baseFill,
        borderRadius: radius,
        border: Border.all(color: baseBorder),
        boxShadow: [
          BoxShadow(
            color: glowColor ?? AppColors.glassShadow,
            blurRadius: glowColor != null ? 24 : 18,
            offset: const Offset(0, 8),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.14),
              blurRadius: 32,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return card;

    return _PressScale(onTap: onTap!, child: card);
  }
}

/// Smooth press scale micro-interaction.
class _PressScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressScale({required this.onTap, required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
