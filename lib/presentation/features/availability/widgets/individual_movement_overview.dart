import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class IndividualMovementFilterCard extends StatelessWidget {
  const IndividualMovementFilterCard({
    super.key,
    required this.students,
    required this.classrooms,
    required this.selectedStudent,
    required this.toClassroom,
    required this.fromClassroom,
    required this.onStudentChanged,
    required this.onToClassroomChanged,
    required this.onFromClassroomChanged,
    required this.onClearAll,
  });

  final List<String> students;
  final List<String> classrooms;
  final String? selectedStudent;
  final String? toClassroom;
  final String? fromClassroom;
  final ValueChanged<String?> onStudentChanged;
  final ValueChanged<String?> onToClassroomChanged;
  final ValueChanged<String?> onFromClassroomChanged;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: <Widget>[
          CustomDropdown(
            hintText: 'Select Student',
            items: students,
            selectedItem: selectedStudent,
            showAsterisk: false,
            onSelect: onStudentChanged,
            selectedTextStyle: const TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: CustomDropdown(
                  hintText: 'To Classroom',
                  items: classrooms,
                  selectedItem: toClassroom,
                  showAsterisk: false,
                  onSelect: onToClassroomChanged,
                  selectedTextStyle: const TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomDropdown(
                  hintText: 'From Classroom',
                  items: classrooms,
                  selectedItem: fromClassroom,
                  showAsterisk: false,
                  onSelect: onFromClassroomChanged,
                  selectedTextStyle: const TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Expanded(child: AccountingDateRangeSelector()),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: CustomClearAllChip(
                  onTap: onClearAll,
                  label: 'Clear All',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IndividualMovementPager extends StatelessWidget {
  const IndividualMovementPager({
    super.key,
    required this.sections,
    required this.currentSectionIndex,
    required this.sectionPageController,
    required this.onPageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onMoreTap,
  });

  final List<MovementSection> sections;
  final int currentSectionIndex;
  final PageController sectionPageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<MovementItem> onMoreTap;

  @override
  Widget build(BuildContext context) {
    final double pagerHeight = _calculatePagerHeight(sections);
    return Column(
      children: <Widget>[
        SizedBox(
          height: pagerHeight,
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: PageView.builder(
                  controller: sectionPageController,
                  itemCount: sections.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: index == currentSectionIndex ? 2 : 4,
                        vertical: index == currentSectionIndex ? 0 : 4,
                      ),
                      child: _MovementSectionCard(
                        section: sections[index],
                        onMoreTap: onMoreTap,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _FloatingArrow(
                  icon: Icons.chevron_left_rounded,
                  isEnabled: currentSectionIndex > 0,
                  onTap: onPrevious,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _FloatingArrow(
                  icon: Icons.chevron_right_rounded,
                  isEnabled: currentSectionIndex < sections.length - 1,
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sections[currentSectionIndex].title,
          style: const TextStyle(
            fontFamily: Fonts.manrope,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  double _calculatePagerHeight(List<MovementSection> sections) {
    const double headerAndPaddingHeight = 70;
    const double rowApproxHeight = 88;
    final int maxRows = sections.fold<int>(
      0,
      (previousValue, section) =>
          section.items.length > previousValue ? section.items.length : previousValue,
    );
    final int safeRows = maxRows == 0 ? 1 : maxRows;
    return headerAndPaddingHeight + (safeRows * rowApproxHeight);
  }
}

class _MovementSectionCard extends StatelessWidget {
  const _MovementSectionCard({
    required this.section,
    required this.onMoreTap,
  });

  final MovementSection section;
  final ValueChanged<MovementItem> onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: section.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: const TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (section.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No movements available',
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            )
          else
            ...section.items.map((item) => _MovementRow(item: item, onMoreTap: onMoreTap)),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.item, required this.onMoreTap});

  final MovementItem item;
  final ValueChanged<MovementItem> onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${item.fromClassroom}  ->  ${item.toClassroom}',
                  style: const TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              InkWell(
                onTap: () => onMoreTap(item),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Icon(Icons.more_horiz, size: 20, color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              DocumentImageWidget(
                fileUuid: '',
                name: item.name,
                size: 24,
                fontSize: 9,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFFF3B413),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd').format(item.movementDate),
                style: const TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: 13,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingArrow extends StatelessWidget {
  const _FloatingArrow({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        onPressed: isEnabled ? onTap : null,
        splashRadius: 18,
        icon: Icon(
          icon,
          size: 24,
          color: isEnabled
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}
