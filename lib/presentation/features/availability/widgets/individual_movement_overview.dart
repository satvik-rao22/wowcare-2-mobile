import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class IndividualMovementFilterCard extends StatelessWidget {
  const IndividualMovementFilterCard({
    super.key,
    required this.students,
    required this.classrooms,
    required this.selectedStudents,
    required this.toClassrooms,
    required this.fromClassrooms,
    required this.onStudentsChanged,
    required this.onToClassroomsChanged,
    required this.onFromClassroomsChanged,
    required this.onClearAll,
    this.filterRangeStart,
    this.filterRangeEnd,
    required this.onDateRangeChanged,
  });

  final List<String> students;
  final List<String> classrooms;
  final List<String> selectedStudents;
  final List<String> toClassrooms;
  final List<String> fromClassrooms;
  final ValueChanged<List<String>> onStudentsChanged;
  final ValueChanged<List<String>> onToClassroomsChanged;
  final ValueChanged<List<String>> onFromClassroomsChanged;
  final VoidCallback onClearAll;
  final DateTime? filterRangeStart;
  final DateTime? filterRangeEnd;
  final void Function(DateTime? start, DateTime? end) onDateRangeChanged;

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
          CustomMultiSelectDropdown(
            hintText: 'Students',
            items: students,
            selectedItems: selectedStudents,
            onChanged: onStudentsChanged,
            showSelectAll: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'To Classrooms',
                  items: classrooms,
                  selectedItems: toClassrooms,
                  onChanged: onToClassroomsChanged,
                  showSelectAll: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'From Classrooms',
                  items: classrooms,
                  selectedItems: fromClassrooms,
                  onChanged: onFromClassroomsChanged,
                  showSelectAll: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: AccountingDateRangeSelector(
                  initialStartDate: filterRangeStart,
                  initialEndDate: filterRangeEnd,
                  onRangeChanged: onDateRangeChanged,
                ),
              ),
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
    required this.onDropToBucket,
    this.canDragItem,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragGlobalUpdate,
  });

  final List<MovementSection> sections;
  final int currentSectionIndex;
  final PageController sectionPageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<MovementItem> onMoreTap;
  final void Function(MovementItem item, MovementBucket targetBucket) onDropToBucket;
  final bool Function(MovementItem item)? canDragItem;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final ValueChanged<Offset>? onDragGlobalUpdate;

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
                        onDropToBucket: onDropToBucket,
                        canDragItem: canDragItem,
                        onDragStarted: onDragStarted,
                        onDragEnded: onDragEnded,
                        onDragGlobalUpdate: onDragGlobalUpdate,
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
    const double headerAndPaddingHeight = 90;
    const double rowApproxHeight = 116;
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
    required this.onDropToBucket,
    this.canDragItem,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragGlobalUpdate,
  });

  final MovementSection section;
  final ValueChanged<MovementItem> onMoreTap;
  final void Function(MovementItem item, MovementBucket targetBucket) onDropToBucket;
  final bool Function(MovementItem item)? canDragItem;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final ValueChanged<Offset>? onDragGlobalUpdate;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DraggedMovementPayload>(
      onWillAcceptWithDetails: (details) => details.data.item.id != 0,
      onAcceptWithDetails: (details) {
        onDropToBucket(details.data.item, section.bucket);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: section.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.themeColor.withValues(alpha: 0.75)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                section.title,
                style: const TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
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
                ...section.items.map(
                  (item) => _MovementRow(
                    item: item,
                    onMoreTap: onMoreTap,
                    canDrag: canDragItem?.call(item) ?? true,
                    onDragStarted: onDragStarted,
                    onDragEnded: onDragEnded,
                    onDragGlobalUpdate: onDragGlobalUpdate,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.item,
    required this.onMoreTap,
    required this.canDrag,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragGlobalUpdate,
  });

  final MovementItem item;
  final ValueChanged<MovementItem> onMoreTap;
  final bool canDrag;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final ValueChanged<Offset>? onDragGlobalUpdate;

  Widget _typeChip(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.18)),
      backgroundColor: scheme.surface,
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: Fonts.manrope,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _classroomLabel(String value) {
    final v = value.trim();
    return Text(
      v.isEmpty ? '—' : v,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildFromToRow(BuildContext context) {
    final from = item.fromClassroom.trim();
    final to = item.toClassroom.trim();

    final Widget left;
    final Widget right;

    switch (item.movementType) {
      case MovementType.moveToNextClassroom:
        left = _classroomLabel(from);
        right = _classroomLabel(to);
        break;
      case MovementType.startSchool:
        // Start school chip on the left; destination classroom on the right.
        left = _typeChip(context, 'Start School');
        right = _classroomLabel(to);
        break;
      case MovementType.leaveSchool:
        // Source classroom on the left; leave school chip on the right.
        left = _classroomLabel(from);
        right = _typeChip(context, 'Leave School');
        break;
    }

    return Row(
      children: <Widget>[
        Expanded(child: Align(alignment: Alignment.centerLeft, child: left)),
        const SizedBox(width: 10),
        const Icon(
          Icons.arrow_right_alt_rounded,
          size: 20,
          color: AppColors.primaryColor,
        ),
        const SizedBox(width: 10),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: right)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _buildFromToRow(context),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => onMoreTap(item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    size: 22,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              DocumentImageWidget(
                fileUuid: '',
                name: item.name,
                size: 30,
                fontSize: 11,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFFF3B413),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM dd').format(item.movementDate),
                style: const TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (!canDrag) return card;
    return LongPressDraggable<_DraggedMovementPayload>(
      data: _DraggedMovementPayload(item: item),
      // Keep dragged card centered under finger for better edge paging UX.
      dragAnchorStrategy: _centerDragAnchorStrategy,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded?.call(),
      onDragUpdate: (details) => onDragGlobalUpdate?.call(details.globalPosition),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Opacity(opacity: 0.95, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _DraggedMovementPayload {
  const _DraggedMovementPayload({required this.item});
  final MovementItem item;
}

Offset _centerDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox) {
    final size = renderObject.size;
    return Offset(size.width / 2, size.height / 2);
  }
  return const Offset(0, 0);
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
