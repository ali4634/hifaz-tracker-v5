import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/google_drive_provider.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';
import '../../widgets/glass_card.dart';
import '../students/students_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        Text(
          l10n.t('tabSettings'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _AppearanceCard(),
        const SizedBox(height: 12),
        _ManageStudentsCard(),
        const SizedBox(height: 12),
        _BehaviorCard(),
        const SizedBox(height: 12),
        _WarningCard(),
        const SizedBox(height: 12),
        _GradingCard(),
        const SizedBox(height: 12),
        _MadrasaInfoCard(),
        const SizedBox(height: 12),
        _GoogleDriveCard(),
        const SizedBox(height: 12),
        _BackupCard(),
        const SizedBox(height: 12),
        _DangerCard(),
        const SizedBox(height: 12),
        _AboutCard(),
      ],
    );
  }
}

class _ManageStudentsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.people_alt_rounded,
            color: AppColors.primary,
            text: l10n.t('manageStudents'),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.people_alt_rounded,
            color: AppColors.primary,
            label: l10n.t('manageStudents'),
            desc: l10n.t('manageStudentsDesc'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appearance ─────────────────────────────────────────────────────────────

class _AppearanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.palette_rounded,
            color: AppColors.indigo,
            text: l10n.t('theme'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'dark',
                label: Text(l10n.t('dark')),
                icon: const Icon(Icons.dark_mode_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'light',
                label: Text(l10n.t('light')),
                icon: const Icon(Icons.light_mode_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'system',
                label: Text(l10n.t('system')),
                icon: const Icon(Icons.brightness_auto_rounded, size: 16),
              ),
            ],
            selected: {settings.settings.themeMode},
            onSelectionChanged: (v) => settings.setThemeMode(v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary.withValues(
                alpha: 0.25,
              ),
              selectedForegroundColor: AppColors.primarySoft,
            ),
          ),
          const SizedBox(height: 16),
          _CardTitle(
            icon: Icons.palette_outlined,
            color: AppColors.primary,
            text: l10n.t('accentColor'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AccentChip(
                label: l10n.t('accentEmerald'),
                color: AppColors.emeraldPrimary,
                selected: settings.settings.accent == AppColors.accentEmerald,
                onTap: () => settings.setAccent(AppColors.accentEmerald),
              ),
              const SizedBox(width: 10),
              _AccentChip(
                label: l10n.t('accentAmber'),
                color: AppColors.amberPrimary,
                selected: settings.settings.accent == AppColors.accentAmber,
                onTap: () => settings.setAccent(AppColors.accentAmber),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CardTitle(
            icon: Icons.translate_rounded,
            color: AppColors.primary,
            text: l10n.t('language'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.t('english'))),
              ButtonSegment(value: 'ur', label: Text(l10n.t('urdu'))),
            ],
            selected: {settings.settings.locale},
            onSelectionChanged: (v) => settings.setLocale(v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary.withValues(
                alpha: 0.25,
              ),
              selectedForegroundColor: AppColors.primarySoft,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Behavior ───────────────────────────────────────────────────────────────

class _BehaviorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final s = settings.settings;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.tune_rounded,
            color: AppColors.info,
            text: l10n.t('behavior'),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.keepAwake,
              onChanged: (v) => settings.setKeepAwake(v),
              secondary: Icon(
                Icons.brightness_high_rounded,
                color: AppColors.warning,
              ),
              title: Text(
                l10n.t('keepAwake'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                l10n.t('keepAwakeDesc'),
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.notificationsEnabled,
              onChanged: (v) => settings.setNotificationsEnabled(
                v,
                title: l10n.t('notifTitle'),
                body: l10n.t('notifBody'),
              ),
              secondary: Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                l10n.t('notifications'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                l10n.t('notificationsDesc'),
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.schedule_rounded,
                color: AppColors.indigo,
              ),
              title: Text(
                l10n.t('notificationTime'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Text(
                '${s.notificationHour.toString().padLeft(2, '0')}:${s.notificationMinute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primarySoft,
                ),
              ),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: s.notificationHour,
                    minute: s.notificationMinute,
                  ),
                );
                if (t != null) {
                  await settings.setNotificationTime(
                    t.hour,
                    t.minute,
                    title: l10n.t('notifTitle'),
                    body: l10n.t('notifBody'),
                  );
                }
              },
            ),
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('revisionStandard'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.t('revisionStandardDesc'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _Stepper(
                  value: s.revisionStandard,
                  min: 1,
                  max: 10,
                  onChanged: (v) => settings.setRevisionStandard(v),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.notification_important_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('naaghaDays'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.t('naaghaDaysDesc'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _Stepper(
                  value: s.missingSabqiDays,
                  min: 1,
                  max: 30,
                  onChanged: (v) => settings.setNaaghaDays(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Warning engine ─────────────────────────────────────────────────────────

class _WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final s = settings.settings;

    return GlassCard(
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            text: l10n.t('warningEngine'),
          ),
          const SizedBox(height: 8),
          _ThresholdRow(
            label: l10n.t('warnInactiveDays'),
            value: s.warningInactiveDays,
            min: 2,
            max: 10,
            onChanged: (v) => settings.setWarningThresholds(
              inactiveDays: v,
              repetitionCount: s.warningRepetitionCount,
              absenceWindow: s.absenceWindowDays,
              absenceCount: s.absenceWarningCount,
            ),
          ),
          _ThresholdRow(
            label: l10n.t('warnRepetitionCount'),
            value: s.warningRepetitionCount,
            min: 2,
            max: 10,
            onChanged: (v) => settings.setWarningThresholds(
              inactiveDays: s.warningInactiveDays,
              repetitionCount: v,
              absenceWindow: s.absenceWindowDays,
              absenceCount: s.absenceWarningCount,
            ),
          ),
          _ThresholdRow(
            label: l10n.t('absenceWindow'),
            value: s.absenceWindowDays,
            min: 3,
            max: 30,
            onChanged: (v) => settings.setWarningThresholds(
              inactiveDays: s.warningInactiveDays,
              repetitionCount: s.warningRepetitionCount,
              absenceWindow: v,
              absenceCount: s.absenceWarningCount,
            ),
          ),
          _ThresholdRow(
            label: l10n.t('absenceCount'),
            value: s.absenceWarningCount,
            min: 2,
            max: 10,
            onChanged: (v) => settings.setWarningThresholds(
              inactiveDays: s.warningInactiveDays,
              repetitionCount: s.warningRepetitionCount,
              absenceWindow: s.absenceWindowDays,
              absenceCount: v,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _ThresholdRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          _Stepper(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded, size: 18),
            color: AppColors.primary,
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}


// ── Performance Grading ────────────────────────────────────────────────────

class _GradingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final s = settings.settings;

    return GlassCard(
      borderColor: AppColors.indigo.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.emoji_events_rounded,
            color: AppColors.indigo,
            text: l10n.t('gradingSettings'),
          ),
          const SizedBox(height: 8),
          _ThresholdRow(
            label: l10n.t('gradingBehtareen'),
            value: s.gradingBehtareen,
            min: 1,
            max: 30,
            onChanged: (v) => settings.setGradingThresholds(
              behtareen: v,
              behtar: s.gradingBehtar,
              acha: s.gradingAcha,
            ),
          ),
          _ThresholdRow(
            label: l10n.t('gradingBehtar'),
            value: s.gradingBehtar,
            min: 1,
            max: 30,
            onChanged: (v) => settings.setGradingThresholds(
              behtareen: s.gradingBehtareen,
              behtar: v,
              acha: s.gradingAcha,
            ),
          ),
          _ThresholdRow(
            label: l10n.t('gradingAcha'),
            value: s.gradingAcha,
            min: 1,
            max: 30,
            onChanged: (v) => settings.setGradingThresholds(
              behtareen: s.gradingBehtareen,
              behtar: s.gradingBehtar,
              acha: v,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('gradingDesc'),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Madrasa Info ─────────────────────────────────────────────────────────

class _MadrasaInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final s = settings.settings;

    return GlassCard(
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.school_rounded,
            color: AppColors.info,
            text: l10n.t('madrasaNameLabel'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: TextEditingController(text: s.madrasaName),
              decoration: InputDecoration(
                labelText: l10n.t('madrasaNameLabel'),
                hintText: l10n.t('madrasaNameHint'),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => settings.setMadrasaName(v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextField(
              controller: TextEditingController(text: s.teacherName),
              decoration: InputDecoration(
                labelText: l10n.t('teacherNameLabel'),
                hintText: l10n.t('teacherNameHint'),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => settings.setTeacherName(v.trim()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google Drive Backup & Restore ───────────────────────────────────────────

class _GoogleDriveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gdrive = context.watch<GoogleDriveProvider>();

    return GlassCard(
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.cloud_rounded,
            color: AppColors.info,
            text: l10n.t('googleDriveBackup'),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('googleDriveBackupDesc'),
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          // Last backup info
          if (gdrive.lastBackupAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.t('lastBackup')}: ${_formatDate(gdrive.lastBackupAt!)}',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (gdrive.signedIn)
            _SignedInDriveTiles()
          else
            _ActionTile(
              icon: Icons.login_rounded,
              color: AppColors.primary,
              label: l10n.t('signInToGoogle'),
              desc: l10n.t('signInToGoogleDesc'),
              onTap: () => gdrive.signIn(),
            ),
          if (gdrive.error != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.t('driveError')}: ${gdrive.error}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy $hh:$min';
  }
}

class _SignedInDriveTiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gdrive = context.read<GoogleDriveProvider>();
    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Backup button
        _ActionTile(
          icon: Icons.cloud_upload_rounded,
          color: AppColors.primary,
          label: l10n.t('driveBackup'),
          desc: l10n.t('driveBackupDesc'),
          onTap: gdrive.busy
              ? null
              : () async {
                  final ok = await gdrive.backup(
                    students: app.students,
                    records: app.records,
                    settings: settings.settings,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? l10n.t('driveBackupSuccess')
                              : '${l10n.t('driveBackupFailed')}: ${gdrive.error ?? ''}',
                        ),
                      ),
                    );
                },
        ),
        const SizedBox(height: 8),
        // Restore button
        _ActionTile(
          icon: Icons.cloud_download_rounded,
          color: AppColors.info,
          label: l10n.t('driveRestore'),
          desc: l10n.t('driveRestoreDesc'),
          onTap: gdrive.busy
              ? null
              : () => _showRestoreDialog(context, gdrive, app, settings),
        ),
        const SizedBox(height: 8),
        // Sign out
        _ActionTile(
          icon: Icons.logout_rounded,
          color: AppColors.textSecondary,
          label: l10n.t('signOut'),
          desc: gdrive.currentUserEmail ?? '',
          onTap: () => gdrive.signOut(),
        ),
      ],
    );
  }

  Future<void> _showRestoreDialog(
    BuildContext context,
    GoogleDriveProvider gdrive,
    AppProvider app,
    SettingsProvider settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    // Load backup list
    await gdrive.refreshBackupList();
    if (!context.mounted) return;

    if (gdrive.backups.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.t('noBackupsFound'))));
      return;
    }

    final selected = await showDialog<DriveBackupEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('selectBackup')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: gdrive.backups.length,
            itemBuilder: (ctx, i) {
              final b = gdrive.backups[i];
              return ListTile(
                leading: const Icon(Icons.backup_rounded),
                title: Text(b.fileName),
                subtitle: Text(
                  '${b.studentCount} students, ${b.recordCount} records',
                ),
                onTap: () => Navigator.pop(ctx, b),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('cancel')),
          ),
        ],
      ),
    );

    if (selected == null || !context.mounted) return;

    // Confirm restore
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('confirmRestore')),
        content: Text(l10n.t('confirmRestoreBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('driveRestore')),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    // Perform restore
    final data = await gdrive.restore(fileId: selected.fileId);
    if (data == null || !context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${l10n.t('driveRestoreFailed')}: ${gdrive.error ?? ''}')),
        );
      return;
    }

    // Apply restored data
    await app.restoreBackup(BackupData(
      students: data.students,
      records: data.records,
      settings: data.settings,
    ));
    if (data.settings != null) {
      settings.settings = data.settings!;
      await settings.init();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.t('driveRestoreSuccess'))));
    }
  }
}

// ── Backup & restore ───────────────────────────────────────────────────────

class _BackupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.backup_rounded,
            color: AppColors.primary,
            text: l10n.t('backupRestore'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.file_upload_rounded,
            color: AppColors.primary,
            label: l10n.t('exportBackup'),
            desc: l10n.t('exportBackupDesc'),
            onTap: () async {
              final path = await app.exportBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('backupSuccess', args: [path])),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.file_download_rounded,
            color: AppColors.info,
            label: l10n.t('importBackup'),
            desc: l10n.t('importBackupDesc'),
            onTap: () => _importBackup(context, app, settings),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup(
    BuildContext context,
    AppProvider app,
    SettingsProvider settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    final data = await BackupService.instance.pickBackupFile();
    if (data == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('importFailed'))));
      }
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('importConfirmTitle')),
        content: Text(l10n.t('importConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('importBackup')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.restoreBackup(data);
      if (data.settings != null) {
        settings.settings = data.settings!;
        await settings.init();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('importSuccess'))));
      }
    }
  }
}

// ── Danger zone ────────────────────────────────────────────────────────────

class _DangerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.read<AppProvider>();
    return GlassCard(
      borderColor: AppColors.danger.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.report_rounded,
            color: AppColors.danger,
            text: l10n.t('dangerZone'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.delete_forever_rounded,
            color: AppColors.danger,
            label: l10n.t('deleteAllData'),
            desc: l10n.t('deleteAllConfirmBody'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.t('deleteAllConfirmTitle')),
                  content: Text(l10n.t('deleteAllConfirmBody')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.t('cancel')),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.t('delete')),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await app.eraseAllData();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── About ──────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradA, AppColors.gradB],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.t('appName')} v1.0.0',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.t('tagline'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Shared bits ────────────────────────────────────────────────────────────

class _AccentChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccentChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? color.withValues(alpha: 0.18) : AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.glassBorder,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _CardTitle({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
