import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/utils/id_gen.dart';
import '../../localization/app_localizations.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_card.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? existing;

  const StudentFormScreen({super.key, this.existing});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context);

  late final TextEditingController _nameCtrl;

  late final TextEditingController _phoneCtrl;

  late String _section;
  late bool _isStarred;

  // Manzil config
  late int _startJuz;
  late int _endJuz;
  late bool _reverse;

  // Sabqi target
  late int _sabqiJuz;
  late int _sabqiPages;

  // Mushaf
  late int _mushafLines;

  // Current position
  late int _curJuz;
  late int _curRuba;
  late int _cycle;

  late final bool _isEdit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _isEdit = e != null;

    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _section = e?.section ?? context.read<AppProvider>().selectedSection;
    _isStarred = e?.isStarred ?? false;
    _startJuz = e?.manzilStartJuz ?? AppConstants.defaultManzilStartJuz;
    _endJuz = e?.manzilEndJuz ?? AppConstants.defaultManzilEndJuz;
    _reverse = e?.manzilReverse ?? false;
    _sabqiJuz = e?.sabqiTargetJuz ?? AppConstants.defaultSabqiTargetJuz;
    _sabqiPages = e?.sabqiTargetPages ?? AppConstants.defaultSabqiTargetPages;
    _mushafLines = e?.mushafLines ?? AppConstants.defaultMushafLines;
    _curJuz = e?.currentManzilJuz ?? _startJuz;
    _curRuba = e?.currentManzilRuba ?? 1;
    _cycle = e?.manzilCycle ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _nameValid => _nameCtrl.text.trim().isNotEmpty;

  bool get _rangeValid {
    if (_startJuz == _endJuz) return true;
    return _reverse ? _endJuz < _startJuz : _endJuz > _startJuz;
  }

  bool get _canSave => _nameValid && _rangeValid;

  Future<void> _save() async {
    if (!_canSave) return;
    final app = context.read<AppProvider>();
    final existing = widget.existing;
    final student = Student(
      id: existing?.id ?? IdGen.newId(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      section: _section,
      isStarred: _isStarred,
      manzilStartJuz: _startJuz,
      manzilEndJuz: _endJuz,
      manzilReverse: _reverse,
      sabqiTargetJuz: _sabqiJuz,
      sabqiTargetPages: _sabqiPages,
      mushafLines: _mushafLines,
      currentManzilJuz: _curJuz,
      currentManzilRuba: _curRuba,
      manzilCycle: _cycle,
      acknowledgedWarnings: existing?.acknowledgedWarnings,
      createdAt: existing?.createdAt,
    );
    if (_isEdit) {
      await app.updateStudent(student);
    } else {
      await app.addStudent(student);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.t('editStudent') : l10n.t('addStudent')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(
            title: l10n.t('studentDetails'),
            icon: Icons.badge_rounded,
            color: AppColors.info,
            children: [
              TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.t('fullName'),
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  errorText: !_nameValid ? l10n.t('nameRequired') : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.t('phoneNumber'),
                  prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _section,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.t('section'),
                  prefixIcon: const Icon(Icons.grid_view_rounded, size: 20),
                ),
                items: [
                  for (final s in AppConstants.sections)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${l10n.t('section')} $s',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _section = v!),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isStarred,
                  onChanged: (v) => setState(() => _isStarred = v),
                  title: Text(
                    l10n.t('starHint'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  secondary: Icon(Icons.star_rounded, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.t('manzilConfig'),
            icon: Icons.all_inclusive_rounded,
            color: AppColors.primary,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _juzDropdown(
                      label: l10n.t('targetStartJuz'),
                      value: _startJuz,
                      onChanged: (v) => setState(() {
                        _startJuz = v;
                        _curJuz = v;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _juzDropdown(
                      label: l10n.t('targetEndJuz'),
                      value: _endJuz,
                      onChanged: (v) => setState(() => _endJuz = v),
                    ),
                  ),
                ],
              ),
              if (!_rangeValid) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _reverse
                        ? '${l10n.t('reverseOrder')}: end must be ≤ start'
                        : '${l10n.t('straightOrder')}: end must be ≥ start',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.t('direction'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.t('straightOrder')),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.t('reverseOrder')),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  ),
                ],
                selected: {_reverse},
                onSelectionChanged: (v) => setState(() => _reverse = v.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.25,
                  ),
                  selectedForegroundColor: AppColors.primarySoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.t('sabqiTarget'),
            icon: Icons.repeat_rounded,
            color: AppColors.indigo,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _juzDropdown(
                      label: l10n.t('targetJuz'),
                      value: _sabqiJuz,
                      onChanged: (v) => setState(() => _sabqiJuz = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.t('targetPages'),
                        prefixIcon: const Icon(Icons.pages_rounded, size: 20),
                      ),
                      onChanged: (v) => _sabqiPages = int.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l10n.t('mushafLines'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.t('mushafLinesDesc'),
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 15,
                    label: Text(l10n.t('lines15')),
                    icon: const Icon(Icons.view_day_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 16,
                    label: Text(l10n.t('lines16')),
                    icon: const Icon(Icons.view_day_rounded, size: 16),
                  ),
                ],
                selected: {_mushafLines},
                onSelectionChanged: (v) =>
                    setState(() => _mushafLines = v.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.indigo.withValues(
                    alpha: 0.25,
                  ),
                  selectedForegroundColor: AppColors.primarySoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: l10n.t('currentPosition'),
            icon: Icons.my_location_rounded,
            color: AppColors.warning,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _juzDropdown(
                      label: l10n.t('currentJuz'),
                      value: _curJuz,
                      onChanged: (v) => setState(() => _curJuz = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _curRuba,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.t('currentRuba'),
                        prefixIcon: const Icon(
                          Icons.filter_4_rounded,
                          size: 20,
                        ),
                      ),
                      items: [
                        for (final r in AppConstants.rubas)
                          DropdownMenuItem(
                            value: r,
                            child: Text(
                              '${l10n.t('ruba')} $r',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _curRuba = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '🔄 ${l10n.t('currentCycle')}:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _cycle > 0
                        ? () => setState(() => _cycle--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    '$_cycle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _cycle++),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.t('save')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.2),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _juzDropdown({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
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
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _Section({
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
