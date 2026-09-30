import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

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
  // UI-only draft selections local to this modal, handed back via onApply.
  // ValueNotifiers rather than `setState` so each section rebuilds only when
  // its own selection changes. Sets are reassigned (not mutated in place) so
  // the notifier actually fires.
  late final ValueNotifier<Set<String>> _classrooms;
  late final ValueNotifier<Set<String>> _tags;
  late final ValueNotifier<String?> _status;

  @override
  void initState() {
    super.initState();
    _classrooms = ValueNotifier<Set<String>>({...widget.selectedClassrooms});
    _tags = ValueNotifier<Set<String>>({...widget.selectedTags});
    _status = ValueNotifier<String?>(widget.selectedStatus);
  }

  @override
  void dispose() {
    _classrooms.dispose();
    _tags.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.md,
        bottom: AppSizes.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.filter,
                  style: AppTextStyles.heading18.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xxs),

            _Section(
              label: AppStrings.classroom,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: _classrooms,
                builder: (context, selected, _) => _chips(
                  widget.classroomOptions,
                  selected: selected,
                  onToggle: (v, on) {
                    final next = {..._classrooms.value};
                    on ? next.add(v) : next.remove(v);
                    _classrooms.value = next;
                  },
                  emptyText: AppStrings.noClassroomsAvailable,
                ),
              ),
            ),
            _Section(
              label: AppStrings.tag,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: _tags,
                builder: (context, selected, _) => _chips(
                  widget.tagOptions,
                  selected: selected,
                  onToggle: (v, on) {
                    final next = {..._tags.value};
                    on ? next.add(v) : next.remove(v);
                    _tags.value = next;
                  },
                  emptyText: AppStrings.noTagsAvailable,
                ),
              ),
            ),
            _Section(
              label: AppStrings.status,
              child: ValueListenableBuilder<String?>(
                valueListenable: _status,
                builder: (context, status, _) => Wrap(
                  spacing: AppSizes.xs,
                  runSpacing: AppSizes.xs,
                  children: widget.statusOptions.map((s) {
                    final on = status == s;
                    return ChoiceChip(
                      label: Text(_titleCase(s)),
                      selected: on,
                      selectedColor: AppColors.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                      onSelected: (_) => _status.value = on ? null : s,
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _classrooms.value = {};
                      _tags.value = {};
                      _status.value = null;
                      widget.onClear();
                      Navigator.of(context).pop();
                    },
                    child: const Text(AppStrings.clear),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.messagingOnAccent,
                    ),
                    onPressed: () {
                      widget.onApply(
                        _classrooms.value,
                        _tags.value,
                        _status.value,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text(AppStrings.apply),
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
        style: AppTextStyles.size14.copyWith(
          color: AppColors.messagingTextPlaceholder,
          fontSize: 13,
        ),
      );
    }
    return Wrap(
      spacing: AppSizes.xs,
      runSpacing: AppSizes.xs,
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
      padding: const EdgeInsets.only(top: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.sectionHeader.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          child,
        ],
      ),
    );
  }
}
