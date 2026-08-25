import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// Student-oriented filter bottom sheet for the Admin Chats list (Classroom +
/// Tag + Status), mirroring the web Admin Chats filter. Options are derived from
/// the loaded students and matched client-side against each conversation's
/// student. Deliberately NOT the staff-oriented [ConversationFilterSheet], whose
/// designation/staff-status fields and staffDirect-only cubit path don't apply
/// to student-scoped admin chats.
class AdminChatFilterSheet extends StatefulWidget {
  const AdminChatFilterSheet({
    super.key,
    required this.classroomOptions,
    required this.tagOptions,
    required this.statusOptions,
    required this.selectedClassrooms,
    required this.selectedTags,
    required this.selectedStatus,
    required this.onApply,
    required this.onClear,
  });

  final List<String> classroomOptions;
  final List<String> tagOptions;
  final List<String> statusOptions;
  final Set<String> selectedClassrooms;
  final Set<String> selectedTags;
  final String? selectedStatus;
  final void Function(Set<String> classrooms, Set<String> tags, String? status)
  onApply;
  final VoidCallback onClear;

  @override
  State<AdminChatFilterSheet> createState() => _AdminChatFilterSheetState();
}

class _AdminChatFilterSheetState extends State<AdminChatFilterSheet> {
  late Set<String> _classrooms;
  late Set<String> _tags;
  late String? _status;

  @override
  void initState() {
    super.initState();
    _classrooms = {...widget.selectedClassrooms};
    _tags = {...widget.selectedTags};
    _status = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter', style: AppTextStyles.heading),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),

            _Section(
              label: 'Classroom',
              child: _chips(
                widget.classroomOptions,
                selected: _classrooms,
                onToggle: (v, on) => setState(() {
                  on ? _classrooms.add(v) : _classrooms.remove(v);
                }),
                emptyText: 'No classrooms available',
              ),
            ),
            _Section(
              label: 'Tag',
              child: _chips(
                widget.tagOptions,
                selected: _tags,
                onToggle: (v, on) => setState(() {
                  on ? _tags.add(v) : _tags.remove(v);
                }),
                emptyText: 'No tags available',
              ),
            ),
            _Section(
              label: 'Status',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.statusOptions.map((s) {
                  final on = _status == s;
                  return ChoiceChip(
                    label: Text(_titleCase(s)),
                    selected: on,
                    selectedColor: AppColors.primaryColor.withValues(
                      alpha: 0.15,
                    ),
                    onSelected: (_) => setState(() => _status = on ? null : s),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _classrooms = {};
                        _tags = {};
                        _status = null;
                      });
                      widget.onClear();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      widget.onApply(_classrooms, _tags, _status);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(
    List<String> options, {
    required Set<String> selected,
    required void Function(String value, bool on) onToggle,
    required String emptyText,
  }) {
    if (options.isEmpty) {
      return Text(
        emptyText,
        style: AppTextStyles.label.copyWith(color: Color(0xFFB2BEC3)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: on,
          selectedColor: AppColors.primaryColor.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primaryColor,
          onSelected: (v) => onToggle(o, v),
        );
      }).toList(),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
