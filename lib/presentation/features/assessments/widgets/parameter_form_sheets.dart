import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';

/// Modal forms for the parameter hierarchy (PRD §9–§11). Rendered as a
/// constrained bottom sheet — centred and width-capped on tablet/desktop,
/// full-width on phones — so the same component is responsive everywhere.

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

/// Checkbox list of all school classrooms with a "Select All" toggle
/// (FR-DM-06, FR-SD-05, FR-MS-04).
class ClassroomChecklist extends StatefulWidget {
  const ClassroomChecklist({
    super.key,
    required this.classrooms,
    required this.selected,
    required this.onChanged,
  });

  final List<AssessmentClassroom> classrooms;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<ClassroomChecklist> createState() => _ClassroomChecklistState();
}

class _ClassroomChecklistState extends State<ClassroomChecklist> {
  late Set<String> _selected = {...widget.selected};

  bool get _allSelected =>
      widget.classrooms.isNotEmpty &&
      widget.classrooms.every((c) => _selected.contains(c.code));

  void _emit() => widget.onChanged({..._selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assigned Classrooms',
                style: TextStyle(fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_allSelected) {
                    _selected.clear();
                  } else {
                    _selected = widget.classrooms.map((c) => c.code).toSet();
                  }
                });
                _emit();
              },
              child: Text(_allSelected ? 'Clear all' : 'Select all'),
            ),
          ],
        ),
        ...widget.classrooms.map((c) {
          final checked = _selected.contains(c.code);
          return CheckboxListTile(
            value: checked,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(c.name),
            subtitle: c.ageGroup.isEmpty ? null : Text(c.ageGroup),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selected.add(c.code);
                } else {
                  _selected.remove(c.code);
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
                      backgroundColor: AppColors.themeColor,
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
  const DomainFormSheet({super.key, this.initial, required this.classrooms});

  final AssessmentDomain? initial;
  final List<AssessmentClassroom> classrooms;

  static Future<AssessmentDomain?> show(
    BuildContext context, {
    AssessmentDomain? initial,
    required List<AssessmentClassroom> classrooms,
  }) {
    return _showFormSheet<AssessmentDomain>(
      context,
      DomainFormSheet(initial: initial, classrooms: classrooms),
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
  late Set<String> _classrooms = {...?widget.initial?.assignedClassrooms};

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
      assignedClassrooms: _classrooms.toList(),
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
          ClassroomChecklist(
            classrooms: widget.classrooms,
            selected: _classrooms,
            onChanged: (s) => _classrooms = s,
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
    required this.classrooms,
  });

  final String domainId;
  final AssessmentSubdomain? initial;
  final List<AssessmentClassroom> classrooms;

  static Future<AssessmentSubdomain?> show(
    BuildContext context, {
    required String domainId,
    AssessmentSubdomain? initial,
    required List<AssessmentClassroom> classrooms,
  }) {
    return _showFormSheet<AssessmentSubdomain>(
      context,
      SubdomainFormSheet(
          domainId: domainId, initial: initial, classrooms: classrooms),
    );
  }

  @override
  State<SubdomainFormSheet> createState() => _SubdomainFormSheetState();
}

class _SubdomainFormSheetState extends State<SubdomainFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late Set<String> _classrooms = {...?widget.initial?.assignedClassrooms};

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
      assignedClassrooms: _classrooms.toList(),
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
          ClassroomChecklist(
            classrooms: widget.classrooms,
            selected: _classrooms,
            onChanged: (s) => _classrooms = s,
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
    required this.classrooms,
  });

  final String domainId;
  final String subdomainId;
  final AssessmentMilestone? initial;
  final List<AssessmentClassroom> classrooms;

  static Future<AssessmentMilestone?> show(
    BuildContext context, {
    required String domainId,
    required String subdomainId,
    AssessmentMilestone? initial,
    required List<AssessmentClassroom> classrooms,
  }) {
    return _showFormSheet<AssessmentMilestone>(
      context,
      MilestoneFormSheet(
        domainId: domainId,
        subdomainId: subdomainId,
        initial: initial,
        classrooms: classrooms,
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
  late final TextEditingController _ageGroup =
      TextEditingController(text: widget.initial?.ageGroup ?? '');
  late Set<String> _classrooms = {...?widget.initial?.assignedClassrooms};

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _ageGroup.dispose();
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
      ageGroup: _ageGroup.text.trim(),
      assignedClassrooms: _classrooms.toList(),
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
          TextFormField(
            controller: _ageGroup,
            decoration: const InputDecoration(
              labelText: 'Age group (optional)',
              hintText: 'e.g. 24–36m',
            ),
          ),
          const SizedBox(height: 8),
          ClassroomChecklist(
            classrooms: widget.classrooms,
            selected: _classrooms,
            onChanged: (s) => _classrooms = s,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------- Classroom assignment

class ClassroomAssignmentSheet extends StatefulWidget {
  const ClassroomAssignmentSheet({
    super.key,
    required this.milestone,
    required this.classrooms,
  });

  final AssessmentMilestone milestone;
  final List<AssessmentClassroom> classrooms;

  /// Returns the new set of classroom codes, or null if cancelled.
  static Future<List<String>?> show(
    BuildContext context, {
    required AssessmentMilestone milestone,
    required List<AssessmentClassroom> classrooms,
  }) {
    return _showFormSheet<List<String>>(
      context,
      ClassroomAssignmentSheet(milestone: milestone, classrooms: classrooms),
    );
  }

  @override
  State<ClassroomAssignmentSheet> createState() =>
      _ClassroomAssignmentSheetState();
}

class _ClassroomAssignmentSheetState extends State<ClassroomAssignmentSheet> {
  late Set<String> _selected = {...widget.milestone.assignedClassrooms};

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Assign Classrooms',
      saveLabel: 'Save Assignment',
      onSave: () => Navigator.pop(context, _selected.toList()),
      children: [
        Text(
          widget.milestone.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ClassroomChecklist(
          classrooms: widget.classrooms,
          selected: _selected,
          onChanged: (s) => _selected = s,
        ),
      ],
    );
  }
}
