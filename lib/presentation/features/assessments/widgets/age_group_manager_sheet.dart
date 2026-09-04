import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_age_group.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_confirm_dialog.dart';

/// Bottom-sheet manager for the school's age bands.
///
/// The seeded bands are the school's first preset; from here admins customise
/// them — rename, change month ranges, add new bands, deactivate old ones —
/// so the framework can match the school's own age grouping instead of the
/// preset's. Bands may not overlap (a child must resolve to at most one), and
/// editing a band never rewrites already-saved assessments. Staff get a
/// read-only view.
class AgeGroupManagerSheet extends StatelessWidget {
  const AgeGroupManagerSheet({super.key, required this.canManage});

  final bool canManage;

  static Future<void> show(BuildContext context, {required bool canManage}) {
    final cubit = context.read<AssessmentsCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Colors.white,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: AgeGroupManagerSheet(canManage: canManage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final groups = state.activeAgeGroups;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text(
                'Age Groups',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                canManage
                    ? 'Domains and milestones are assigned to these bands; '
                        'each child is matched by date of birth. Edit them to '
                        'fit your school\'s own age grouping.'
                    : 'Domains and milestones are assigned to these bands; '
                        'each child is matched by date of birth.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AssessmentUi.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No age groups defined yet.',
                        style: TextStyle(color: AssessmentUi.inkMuted)),
                  ),
                )
              else
                ...groups.map((g) => _AgeGroupRow(
                      group: g,
                      canManage: canManage,
                      onEdit: () => _edit(context, g),
                      onDeactivate: () => _deactivate(context, g),
                    )),
              if (canManage) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _edit(context, null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AssessmentUi.accent,
                    side: BorderSide(color: AssessmentUi.accent),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add age group'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, AssessmentAgeGroup? initial) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await AgeGroupFormSheet.show(context, initial: initial);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveAgeGroup(result);
    if (!ok && context.mounted) {
      final message =
          cubit.state.errorMessage ?? 'Failed to save the age group.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AssessmentUi.ink,
        ));
    }
  }

  Future<void> _deactivate(
      BuildContext context, AssessmentAgeGroup group) async {
    final confirmed = await AssessmentConfirmDialog.show(
      context,
      title: 'Deactivate "${group.name}"?',
      message: 'Parameters assigned to this band stop matching new '
          'assessments. Historical records are preserved.',
      confirmLabel: 'Deactivate',
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AssessmentsCubit>().deactivateAgeGroup(group.id);
  }
}

class _AgeGroupRow extends StatelessWidget {
  const _AgeGroupRow({
    required this.group,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
  });

  final AssessmentAgeGroup group;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final palette = AssessmentUi.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.brandSoftBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.child_care_rounded, size: 20, color: palette.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AssessmentUi.ink,
                  ),
                ),
                Text(
                  '${group.rangeLabel} · ${group.minMonths}–${group.maxMonths} months',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AssessmentUi.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_outlined, size: 18, color: palette.accent),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDeactivate,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFB91C1C)),
              tooltip: 'Deactivate',
            ),
          ],
        ],
      ),
    );
  }
}

/// Small form for creating/editing one band: name + month range.
class AgeGroupFormSheet extends StatefulWidget {
  const AgeGroupFormSheet({super.key, this.initial});

  final AssessmentAgeGroup? initial;

  static Future<AssessmentAgeGroup?> show(
    BuildContext context, {
    AssessmentAgeGroup? initial,
  }) {
    return showModalBottomSheet<AssessmentAgeGroup>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Colors.white,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: AgeGroupFormSheet(initial: initial),
      ),
    );
  }

  @override
  State<AgeGroupFormSheet> createState() => _AgeGroupFormSheetState();
}

class _AgeGroupFormSheetState extends State<AgeGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _min = TextEditingController(
      text: widget.initial == null ? '' : '${widget.initial!.minMonths}');
  late final TextEditingController _max = TextEditingController(
      text: widget.initial == null ? '' : '${widget.initial!.maxMonths}');

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial ??
        const AssessmentAgeGroup(id: '', name: '', minMonths: 0, maxMonths: 1);
    Navigator.pop(
      context,
      base.copyWith(
        name: _name.text.trim(),
        minMonths: int.parse(_min.text.trim()),
        maxMonths: int.parse(_max.text.trim()),
      ),
    );
  }

  String? _validateMonths(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 0) return 'Enter months (0+)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'Add Age Group' : 'Edit Age Group',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Eighteen to Twenty-Four Months',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Age group name is required'
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'From (months)',
                      hintText: 'e.g. 18',
                    ),
                    validator: _validateMonths,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Up to (months)',
                      hintText: 'e.g. 24',
                    ),
                    validator: (v) {
                      final base = _validateMonths(v);
                      if (base != null) return base;
                      final min = int.tryParse(_min.text.trim());
                      final max = int.parse(v!.trim());
                      if (min != null && max <= min) {
                        return 'Must be greater than "From"';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'The upper bound is exclusive: 18–24 covers a child from their '
              '18-month birthday up to (not including) 24 months.',
              style: TextStyle(fontSize: 11.5, color: AssessmentUi.inkMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AssessmentUi.accent,
                    ),
                    onPressed: _save,
                    child: Text(
                        widget.initial == null ? 'Add Age Group' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
