import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_state.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

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
  late String? selectedDesignation;
  late String? selectedStaffStatus;
  late String? selectedClassroom;

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
    selectedDesignation = state.activeDesignation;
    selectedStaffStatus = state.activeStaffStatus;
    selectedClassroom = state.activeClassroom;
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CustomTextWidget(
                          text: 'Filters',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: [
                        // Designation filter
                        _FilterSection(
                          title: 'Designation',
                          options: designations,
                          selectedValue: selectedDesignation,
                          onChanged: (value) {
                            setState(() => selectedDesignation = value);
                          },
                          onClear: () {
                            setState(() => selectedDesignation = null);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Staff Status filter
                        _FilterSection(
                          title: 'Staff Status',
                          options: staffStatuses,
                          selectedValue: selectedStaffStatus,
                          onChanged: (value) {
                            setState(() => selectedStaffStatus = value);
                          },
                          onClear: () {
                            setState(() => selectedStaffStatus = null);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Classroom filter (text input)
                        _ClassroomFilterField(
                          value: selectedClassroom ?? '',
                          onChanged: (value) {
                            setState(
                              () => selectedClassroom = value.isEmpty
                                  ? null
                                  : value,
                            );
                          },
                          onClear: () {
                            setState(() => selectedClassroom = null);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ConversationListCubit>()
                                  .applyFilters(
                                    designation: selectedDesignation,
                                    staffStatus: selectedStaffStatus,
                                    classroom: selectedClassroom,
                                  );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
            CustomTextWidget(text: title, fontSize: 14, fontWeight: FontWeight.w600),
            if (selectedValue != null)
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) {
                onChanged(isSelected ? null : option);
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.grey[700],
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
              text: 'Classroom Code',
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
                  'Clear',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: 'Enter classroom code (e.g., CLS_123)',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
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
