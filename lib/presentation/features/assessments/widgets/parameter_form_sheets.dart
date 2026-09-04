import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_age_group.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Modal forms for the parameter hierarchy (PRD §9–§11). Rendered as a
/// constrained bottom sheet — centred and width-capped on tablet/desktop,
/// full-width on phones — so the same component is responsive everywhere.
///
/// Parameters are scoped to **age groups** (school-defined bands), not
/// classrooms: a child's visible milestones follow their date of birth.

Future<T?> _showFormSheet<T>(
  BuildContext context,
  Widget child,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    backgroundColor: Colors.white,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    ),
  );
}

/// Checkbox list of the school's active age bands with a "Select All" toggle
/// (adapts FR-DM-06, FR-SD-05, FR-MS-04 from classrooms to age groups).
class AgeGroupChecklist extends StatefulWidget {
  const AgeGroupChecklist({
    super.key,
    required this.ageGroups,
    required this.selected,
    required this.onChanged,
  });

  final List<AssessmentAgeGroup> ageGroups;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<AgeGroupChecklist> createState() => _AgeGroupChecklistState();
}

class _AgeGroupChecklistState extends State<AgeGroupChecklist> {
  late Set<String> _selected = {...widget.selected};

  bool get _allSelected =>
      widget.ageGroups.isNotEmpty &&
      widget.ageGroups.every((g) => _selected.contains(g.id));

  void _emit() => widget.onChanged({..._selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assigned Age Groups',
                style: TextStyle(fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_allSelected) {
                    _selected.clear();
                  } else {
                    _selected = widget.ageGroups.map((g) => g.id).toSet();
                  }
                });
                _emit();
              },
              child: Text(_allSelected ? 'Clear all' : 'Select all'),
            ),
          ],
        ),
        if (widget.ageGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No age groups defined yet — add them from the Age Groups '
              'card on the Parameters tab.',
              style: TextStyle(fontSize: 12.5, color: AssessmentUi.inkMuted),
            ),
          )
        else
          ...widget.ageGroups.map((g) {
            final checked = _selected.contains(g.id);
            return CheckboxListTile(
              value: checked,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AssessmentUi.brand,
              title: Text(g.name),
              subtitle: Text(g.rangeLabel),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(g.id);
                  } else {
                    _selected.remove(g.id);
                  }
                });
                _emit();
              },
            );
          }),
      ],
    );
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.saveLabel,
    required this.onSave,
    required this.children,
  });

  final String title;
  final String saveLabel;
  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...children,
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
                    onPressed: onSave,
                    child: Text(saveLabel),
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

// --------------------------------------------------------------- Domain form

class DomainFormSheet extends StatefulWidget {
  const DomainFormSheet({super.key, this.initial, required this.ageGroups});

  final AssessmentDomain? initial;
  final List<AssessmentAgeGroup> ageGroups;

  static Future<AssessmentDomain?> show(
    BuildContext context, {
    AssessmentDomain? initial,
    required List<AssessmentAgeGroup> ageGroups,
  }) {
    return _showFormSheet<AssessmentDomain>(
      context,
      DomainFormSheet(initial: initial, ageGroups: ageGroups),
    );
  }

  @override
  State<DomainFormSheet> createState() => _DomainFormSheetState();
}

class _DomainFormSheetState extends State<DomainFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late Set<String> _ageGroups = {...?widget.initial?.assignedAgeGroups};

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial;
    final now = DateTime.now();
    final result = (base ??
            AssessmentDomain(id: '', name: '', createdAt: now, updatedAt: now))
        .copyWith(
      name: _name.text.trim(),
      description: _description.text.trim(),
      assignedAgeGroups: _ageGroups.toList(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _FormScaffold(
        title: widget.initial == null ? 'Add Domain' : 'Edit Domain',
        saveLabel: widget.initial == null ? 'Add Domain' : 'Save Changes',
        onSave: _save,
        children: [
          TextFormField(
            controller: _name,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Social & Emotional',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Domain name is required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _description,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
          const SizedBox(height: 8),
          AgeGroupChecklist(
            ageGroups: widget.ageGroups,
            selected: _ageGroups,
            onChanged: (s) => _ageGroups = s,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Subdomain form

class SubdomainFormSheet extends StatefulWidget {
  const SubdomainFormSheet({
    super.key,
    required this.domainId,
    this.initial,
    required this.ageGroups,
  });

  final String domainId;
  final AssessmentSubdomain? initial;
  final List<AssessmentAgeGroup> ageGroups;

  static Future<AssessmentSubdomain?> show(
    BuildContext context, {
    required String domainId,
    AssessmentSubdomain? initial,
    required List<AssessmentAgeGroup> ageGroups,
  }) {
    return _showFormSheet<AssessmentSubdomain>(
      context,
      SubdomainFormSheet(
          domainId: domainId, initial: initial, ageGroups: ageGroups),
    );
  }

  @override
  State<SubdomainFormSheet> createState() => _SubdomainFormSheetState();
}

class _SubdomainFormSheetState extends State<SubdomainFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late Set<String> _ageGroups = {...?widget.initial?.assignedAgeGroups};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final result = (widget.initial ??
            AssessmentSubdomain(
              id: '',
              domainId: widget.domainId,
              name: '',
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      name: _name.text.trim(),
      assignedAgeGroups: _ageGroups.toList(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _FormScaffold(
        title: widget.initial == null ? 'Add Subdomain' : 'Edit Subdomain',
        saveLabel: widget.initial == null ? 'Add Subdomain' : 'Save Changes',
        onSave: _save,
        children: [
          TextFormField(
            controller: _name,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Emotional Regulation',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Subdomain name is required'
                : null,
          ),
          const SizedBox(height: 8),
          AgeGroupChecklist(
            ageGroups: widget.ageGroups,
            selected: _ageGroups,
            onChanged: (s) => _ageGroups = s,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Milestone form

class MilestoneFormSheet extends StatefulWidget {
  const MilestoneFormSheet({
    super.key,
    required this.domainId,
    required this.subdomainId,
    this.initial,
    required this.ageGroups,
  });

  final String domainId;
  final String subdomainId;
  final AssessmentMilestone? initial;
  final List<AssessmentAgeGroup> ageGroups;

  static Future<AssessmentMilestone?> show(
    BuildContext context, {
    required String domainId,
    required String subdomainId,
    AssessmentMilestone? initial,
    required List<AssessmentAgeGroup> ageGroups,
  }) {
    return _showFormSheet<AssessmentMilestone>(
      context,
      MilestoneFormSheet(
        domainId: domainId,
        subdomainId: subdomainId,
        initial: initial,
        ageGroups: ageGroups,
      ),
    );
  }

  @override
  State<MilestoneFormSheet> createState() => _MilestoneFormSheetState();
}

class _MilestoneFormSheetState extends State<MilestoneFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late Set<String> _ageGroups = {...?widget.initial?.assignedAgeGroups};

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final result = (widget.initial ??
            AssessmentMilestone(
              id: '',
              subdomainId: widget.subdomainId,
              domainId: widget.domainId,
              name: '',
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      name: _name.text.trim(),
      description: _description.text.trim(),
      assignedAgeGroups: _ageGroups.toList(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _FormScaffold(
        title: widget.initial == null ? 'Add Milestone' : 'Edit Milestone',
        saveLabel: widget.initial == null ? 'Add Milestone' : 'Save Changes',
        onSave: _save,
        children: [
          TextFormField(
            controller: _name,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Runs without falling',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Milestone name is required'
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _description,
            maxLength: 1000,
            maxLines: 2,
            decoration:
                const InputDecoration(labelText: 'Description (optional)'),
          ),
          const SizedBox(height: 8),
          AgeGroupChecklist(
            ageGroups: widget.ageGroups,
            selected: _ageGroups,
            onChanged: (s) => _ageGroups = s,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------- Age-group assignment

class AgeGroupAssignmentSheet extends StatefulWidget {
  const AgeGroupAssignmentSheet({
    super.key,
    required this.milestone,
    required this.ageGroups,
  });

  final AssessmentMilestone milestone;
  final List<AssessmentAgeGroup> ageGroups;

  /// Returns the new set of age-group ids, or null if cancelled.
  static Future<List<String>?> show(
    BuildContext context, {
    required AssessmentMilestone milestone,
    required List<AssessmentAgeGroup> ageGroups,
  }) {
    return _showFormSheet<List<String>>(
      context,
      AgeGroupAssignmentSheet(milestone: milestone, ageGroups: ageGroups),
    );
  }

  @override
  State<AgeGroupAssignmentSheet> createState() =>
      _AgeGroupAssignmentSheetState();
}

class _AgeGroupAssignmentSheetState extends State<AgeGroupAssignmentSheet> {
  late Set<String> _selected = {...widget.milestone.assignedAgeGroups};

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Assign Age Groups',
      saveLabel: 'Save Assignment',
      onSave: () => Navigator.pop(context, _selected.toList()),
      children: [
        Text(
          widget.milestone.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        AgeGroupChecklist(
          ageGroups: widget.ageGroups,
          selected: _selected,
          onChanged: (s) => _selected = s,
        ),
      ],
    );
  }
}
