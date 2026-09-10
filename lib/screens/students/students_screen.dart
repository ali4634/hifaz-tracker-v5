import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/student.dart';
import '../../providers/app_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import 'student_form_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _sectionFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);

    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered =
        app.students.where((s) {
          if (_sectionFilter != 'all' && s.section != _sectionFilter) {
            return false;
          }
          if (query.isNotEmpty && !s.name.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) {
          if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('studentsTitle')),
        actions: [
          IconButton(
            tooltip: l10n.t('addStudent'),
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.t('searchStudents'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _sectionFilter == 'all',
                  onTap: () => setState(() => _sectionFilter = 'all'),
                ),
                for (final sec in ['A', 'B', 'C'])
                  _FilterChip(
                    label: '${l10n.t('section')} $sec',
                    selected: _sectionFilter == sec,
                    onTap: () => setState(() => _sectionFilter = sec),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.group_off_rounded,
                    title: l10n.t('noStudents'),
                    description: l10n.t('noStudentsDesc'),
                    actionLabel: l10n.t('addStudent'),
                    onAction: () => _openForm(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _StudentTile(
                      student: filtered[i],
                      onTap: () => _openForm(context, student: filtered[i]),
                      onToggleStar: () => app.toggleStar(filtered[i].id),
                      onDelete: () => _confirmDelete(context, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {Student? student}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StudentFormScreen(existing: student)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Student student) async {
    final l10n = AppLocalizations.of(context);
    final app = context.read<AppProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('confirmDeleteTitle')),
        content: Text(l10n.t('confirmDeleteBody', args: [student.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteStudent(student.id);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.glassBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primarySoft : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;

  const _StudentTile({
    required this.student,
    required this.onTap,
    required this.onToggleStar,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.t('starHint'),
            onPressed: onToggleStar,
            icon: Icon(
              student.isStarred
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: student.isStarred
                  ? AppColors.warning
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (student.phone.isNotEmpty)
                  Text(
                    student.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${l10n.t('section')} ${student.section}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.t('delete'),
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
