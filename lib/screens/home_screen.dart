import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../localization/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';

import '../services/naagha_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_bottom_nav.dart';
import '../widgets/section_switcher.dart';
import 'analytics/analytics_screen.dart';
import 'attendance/attendance_screen.dart';
import 'fees/fees_screen.dart';
import 'naagha/naagha_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _showDateSelector = true;
  bool _prevNotificationsEnabled = false;
  SettingsProvider? _settings;

  @override
  void initState() {
    super.initState();
    // Schedule per-student naagha (gap) reminders after the first frame,
    // mirroring v4's startup behaviour, and react when the user toggles
    // notifications on from the settings tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      _settings = settings;
      _prevNotificationsEnabled = settings.settings.notificationsEnabled;
      if (_prevNotificationsEnabled) _scheduleNaaghaNotifications();
      settings.addListener(_onSettingsChanged);
      _autoSyncOnce();
    });
  }

  @override
  void dispose() {
    // Never use `context.read` in dispose — the element is already deactivated.
    _settings?.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _autoSyncOnce() {
    // Google Drive sync removed — app is fully offline-first.
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final enabled = settings.settings.notificationsEnabled;
    if (enabled && !_prevNotificationsEnabled) {
      _scheduleNaaghaNotifications();
    }
    _prevNotificationsEnabled = enabled;
  }

  void _scheduleNaaghaNotifications() {
    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();
    final s = settings.settings;
    if (!s.notificationsEnabled) return;

    final alerts = app.naaghaAlerts(s.missingSabqiDays);
    if (alerts.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    NaaghaService.scheduleNotifications(
      alerts: alerts,
      hour: s.notificationHour,
      minute: s.notificationMinute,
      title: l10n.t('naaghaNotifTitle'),
      bodyBuilder: (student, studentAlerts) => l10n.t(
        'naaghaNotifBody',
        args: [
          student.name,
          studentAlerts
              .map(
                (a) => l10n.t(
                  'naaghaNotifTrack',
                  args: [_trackLabel(a.track, l10n), '${a.daysWithout}'],
                ),
              )
              .join(', '),
        ],
      ),
    );
  }

  String _trackLabel(NaaghaTrack track, AppLocalizations l10n) => switch (track) {
    NaaghaTrack.sabaq => l10n.t('sabaq'),
    NaaghaTrack.sabqi => l10n.t('sabqi'),
    NaaghaTrack.manzil => l10n.t('manzil'),
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                section: app.selectedSection,
                onSectionChanged: app.setSection,
                showDateToggle: _tab == 0,
                dateSelectorVisible: _showDateSelector,
                onToggleDateSelector: () => setState(
                  () => _showDateSelector = !_showDateSelector,
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    AttendanceScreen(showDateSelector: _showDateSelector),
                    const FeesScreen(),
                    const AnalyticsScreen(),
                    const ReportsScreen(),
                    const SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          (
            icon: Icons.checklist_rounded,
            activeIcon: Icons.checklist_rounded,
            label: l10n.t('tabAttendance'),
          ),
          (
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments_rounded,
            label: l10n.t('tabFees'),
          ),
          (
            icon: Icons.donut_large_rounded,
            activeIcon: Icons.donut_large_rounded,
            label: l10n.t('tabAnalytics'),
          ),
          (
            icon: Icons.bar_chart_rounded,
            activeIcon: Icons.bar_chart_rounded,
            label: l10n.t('tabReports'),
          ),
          (
            icon: Icons.settings_rounded,
            activeIcon: Icons.settings_rounded,
            label: l10n.t('tabSettings'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String section;
  final ValueChanged<String> onSectionChanged;

  /// Whether to show the date show/hide toggle (attendance tab only).
  final bool showDateToggle;

  /// Whether the date selector row is currently visible.
  final bool dateSelectorVisible;

  final VoidCallback onToggleDateSelector;

  const _Header({
    required this.section,
    required this.onSectionChanged,
    this.showDateToggle = false,
    this.dateSelectorVisible = true,
    required this.onToggleDateSelector,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gradA, AppColors.gradB],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('appName'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.t('tagline'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const _NaaghaBell(),
          const SizedBox(width: 6),
          if (showDateToggle) ...[
            _GlassIconButton(
              tooltip: dateSelectorVisible
                  ? l10n.t('hideDate')
                  : l10n.t('showDate'),
              onPressed: onToggleDateSelector,
              icon: Icon(
                dateSelectorVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 18,
              ),
              color: dateSelectorVisible
                  ? AppColors.textSecondary
                  : AppColors.primary,
            ),
            const SizedBox(width: 6),
          ],
          SectionSwitcher(section: section, onChanged: onSectionChanged),
        ],
      ),
    );
  }


}

/// Compact glass-framed icon button used in the home header.
class _GlassIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;
  final Color color;

  const _GlassIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassFillStrong : AppColors.lightGlassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
        color: color,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Bell button with a live badge counting students who have a gap (naagha).
/// Tapping it opens the naagha alerts screen.
class _NaaghaBell extends StatelessWidget {
  const _NaaghaBell();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count =
        app.naaghaUnseenStudentCount(settings.settings.missingSabqiDays);
    final hasAlerts = count > 0;

    return Container(
      decoration: BoxDecoration(
        color: hasAlerts
            ? AppColors.danger.withValues(alpha: 0.12)
            : isDark
            ? AppColors.glassFillStrong
            : AppColors.lightGlassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAlerts
              ? AppColors.danger.withValues(alpha: 0.6)
              : isDark
              ? AppColors.glassBorder
              : AppColors.lightGlassBorder,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: l10n.t('naaghaAlerts'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NaaghaScreen()),
            ),
            icon: Icon(
              hasAlerts
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 18,
              color: hasAlerts ? AppColors.danger : AppColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
          if (hasAlerts)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
