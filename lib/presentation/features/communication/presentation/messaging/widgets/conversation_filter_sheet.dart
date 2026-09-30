import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_state.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';

/// Filter bottom sheet for STAFF_DIRECT conversations.
///
/// Allows filtering by:
/// - Designation (e.g., DIRECTOR, TEACHER, etc.)
/// - Staff Status (e.g., ACTIVE, UPCOMING, INACTIVE)
/// - Classroom (assigned classroom code)
class ConversationFilterSheet extends StatefulWidget {
  const ConversationFilterSheet({super.key, this.onlyStaffDirect = true});

  /// If true, only shows when conversation type is STAFF_DIRECT.
  final bool onlyStaffDirect;

  @override
  State<ConversationFilterSheet> createState() =>
      _ConversationFilterSheetState();
}

class _ConversationFilterSheetState extends State<ConversationFilterSheet> {
  // UI-only draft selections local to this modal, applied to the cubit only on
  // "Apply". ValueNotifiers rather than `setState` so each section rebuilds on
  // its own change.
  final ValueNotifier<String?> _designation = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _staffStatus = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _classroom = ValueNotifier<String?>(null);

  final List<String> designations = [
    'DIRECTOR',
    'LEAD_TEACHER',
    'TEACHER',
    'ASSISTANT_TEACHER',
    'ADMINISTRATOR',
    'LIBRARIAN',
    'COUNSELOR',
    'PRINCIPAL',
    'VICE_PRINCIPAL',
    'STAFF',
  ];

  final List<String> staffStatuses = [
    'ACTIVE',
    'UPCOMING',
    'INACTIVE',
    'ARCHIVE',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<ConversationListCubit>().state;
    _designation.value = state.activeDesignations.isNotEmpty
        ? state.activeDesignations.first
        : null;
    _staffStatus.value = state.activeStaffStatuses.isNotEmpty
        ? state.activeStaffStatuses.first
        : null;
    _classroom.value = state.activeClassroomCodes.isNotEmpty
        ? state.activeClassroomCodes.first
        : null;
  }

  @override
  void dispose() {
    _designation.dispose();
    _staffStatus.dispose();
    _classroom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationListCubit, ConversationListState>(
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: AppSurfaces.sheet(topRadius: AppRadius.xl),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CustomTextWidget(
                          text: AppStrings.filters,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Filter options
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSizes.md),
                      children: [
                        // Designation filter
                        ValueListenableBuilder<String?>(
                          valueListenable: _designation,
                          builder: (context, selected, _) => _FilterSection(
                            title: AppStrings.designation,
                            options: designations,
                            selectedValue: selected,
                            onChanged: (value) => _designation.value = value,
                            onClear: () => _designation.value = null,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),

                        // Staff Status filter
                        ValueListenableBuilder<String?>(
                          valueListenable: _staffStatus,
                          builder: (context, selected, _) => _FilterSection(
                            title: AppStrings.staffStatus,
                            options: staffStatuses,
                            selectedValue: selected,
                            onChanged: (value) => _staffStatus.value = value,
                            onClear: () => _staffStatus.value = null,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),

                        // Classroom filter (text input)
                        ValueListenableBuilder<String?>(
                          valueListenable: _classroom,
                          builder: (context, selected, _) =>
                              _ClassroomFilterField(
                                value: selected ?? '',
                                onChanged: (value) => _classroom.value =
                                    value.isEmpty ? null : value,
                                onClear: () => _classroom.value = null,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context
                                  .read<ConversationListCubit>()
                                  .clearFilters();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primaryColor),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm,
                              ),
                            ),
                            child: Text(
                              AppStrings.clearAll,
                              style: AppTextStyles.mediumWeight.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ConversationListCubit>()
                                  .applyFilters(
                                    designations: _designation.value != null
                                        ? [_designation.value!]
                                        : const [],
                                    staffStatuses: _staffStatus.value != null
                                        ? [_staffStatus.value!]
                                        : const [],
                                    classroomCodes: _classroom.value != null
                                        ? [_classroom.value!]
                                        : const [],
                                  );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm,
                              ),
                            ),
                            child: Text(
                              AppStrings.apply,
                              style: AppTextStyles.mediumWeight.copyWith(
                                color: AppColors.messagingOnAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Single filter section with options.
class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    required this.onClear,
  });

  final String title;
  final List<String> options;
  final String? selectedValue;
  final Function(String?) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextWidget(
              text: title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            if (selectedValue != null)
              GestureDetector(
                onTap: onClear,
                child: Text(
                  AppStrings.clear,
                  style: AppTextStyles.size14.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) {
                onChanged(isSelected ? null : option);
              },
              backgroundColor: AppColors.transparentColor,
              selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.messagingBorderColor,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: AppTextStyles.mediumWeight.copyWith(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.messagingChipTextUnselected,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Classroom filter field with text input.
class _ClassroomFilterField extends StatefulWidget {
  const _ClassroomFilterField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String value;
  final Function(String) onChanged;
  final VoidCallback onClear;

  @override
  State<_ClassroomFilterField> createState() => _ClassroomFilterFieldState();
}

class _ClassroomFilterFieldState extends State<_ClassroomFilterField> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomTextWidget(
              text: AppStrings.classroomCode,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            if (widget.value.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  widget.onClear();
                },
                child: Text(
                  AppStrings.clear,
                  style: AppTextStyles.size14.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        TextField(
          controller: controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppSurfaces.fieldFill,
            hintText: AppStrings.classroomCodeHint,
            hintStyle: const TextStyle(color: AppColors.messagingHintText),
            border: AppSurfaces.fieldBorder(radius: 8),
            enabledBorder: AppSurfaces.fieldBorder(radius: 8),
            focusedBorder: AppSurfaces.fieldBorder(radius: 8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.sm,
            ),
            suffixIcon: widget.value.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      widget.onClear();
                    },
                    child: const Icon(Icons.clear, size: 18),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
