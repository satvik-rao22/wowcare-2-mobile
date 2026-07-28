import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_bottom_sheet.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/activities/view/activity_custom_tab.dart'
    show PopupItem;
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
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
    final fromClassroomItems =
        classrooms.where((c) => !toClassrooms.contains(c)).toList();
    final toClassroomItems =
        classrooms.where((c) => !fromClassrooms.contains(c)).toList();
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
            enableSearch: true,
            searchHintText: 'Search students',
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'From Classrooms',
                  items: fromClassroomItems,
                  selectedItems: fromClassrooms,
                  onChanged: onFromClassroomsChanged,
                  showSelectAll: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'To Classrooms',
                  items: toClassroomItems,
                  selectedItems: toClassrooms,
                  onChanged: onToClassroomsChanged,
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
    required this.onActionSelected,
    required this.onDropToBucket,
    this.isViewOnly = false,
    this.canDragItem,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragGlobalUpdate,
    this.highlightCode,
    this.onStudentNameTap,
  });

  /// Movement id (as string) from a notification deep-link, forwarded to rows.
  final String? highlightCode;

  final List<MovementSection> sections;
  final int currentSectionIndex;
  final PageController sectionPageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(MovementItem item, IndividualMovementAction action)
      onActionSelected;
  final void Function(MovementItem item, MovementBucket targetBucket) onDropToBucket;
  final bool isViewOnly;
  final ValueChanged<MovementItem>? onStudentNameTap;
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
                        onActionSelected: onActionSelected,
                        onDropToBucket: onDropToBucket,
                        isViewOnly: isViewOnly,
                        canDragItem: canDragItem,
                        onDragStarted: onDragStarted,
                        onDragEnded: onDragEnded,
                        onDragGlobalUpdate: onDragGlobalUpdate,
                        highlightCode: highlightCode,
                        onStudentNameTap: onStudentNameTap,
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
    required this.onActionSelected,
    required this.onDropToBucket,
    this.isViewOnly = false,
    this.canDragItem,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragGlobalUpdate,
    this.highlightCode,
    this.onStudentNameTap,
  });

  final String? highlightCode;

  final MovementSection section;
  final void Function(MovementItem item, IndividualMovementAction action)
      onActionSelected;
  final void Function(MovementItem item, MovementBucket targetBucket) onDropToBucket;
  final bool isViewOnly;
  final bool Function(MovementItem item)? canDragItem;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final ValueChanged<Offset>? onDragGlobalUpdate;
  final ValueChanged<MovementItem>? onStudentNameTap;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DraggedMovementPayload>(
      onWillAcceptWithDetails: (details) =>
          !isViewOnly && details.data.item.id != 0,
      onAcceptWithDetails: (details) {
        if (isViewOnly) return;
        onDropToBucket(details.data.item, section.bucket);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
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
              Expanded(
                child: section.items.isEmpty
                    ? const Center(
                        child: Text(
                          'No movements available',
                          style: TextStyle(
                            fontFamily: Fonts.manrope,
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: section.items.length,
                        itemBuilder: (context, index) {
                          final item = section.items[index];
                          return _MovementRow(
                            item: item,
                            bucket: section.bucket,
                            onActionSelected: onActionSelected,
                            isViewOnly: isViewOnly,
                            canDrag:
                                !isViewOnly && (canDragItem?.call(item) ?? true),
                            cardBackgroundColor: section.backgroundColor,
                            onDragStarted: onDragStarted,
                            onDragEnded: onDragEnded,
                            onDragGlobalUpdate: onDragGlobalUpdate,
                            highlightCode: highlightCode,
                            onStudentNameTap: onStudentNameTap,
                          );
                        },
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
    required this.bucket,
    required this.onActionSelected,
    required this.isViewOnly,
    required this.canDrag,
    required this.cardBackgroundColor,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragGlobalUpdate,
    this.highlightCode,
    this.onStudentNameTap,
  });

  /// Movement id (as string) from a notification deep-link; matching row flashes.
  final String? highlightCode;

  final MovementItem item;
  final MovementBucket bucket;
  final void Function(MovementItem item, IndividualMovementAction action)
      onActionSelected;
  final bool isViewOnly;
  final bool canDrag;
  final Color cardBackgroundColor;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final ValueChanged<Offset>? onDragGlobalUpdate;
  final ValueChanged<MovementItem>? onStudentNameTap;

  List<PopupMenuEntry<IndividualMovementAction>> _buildMenuEntries() {
    final actions = <IndividualMovementAction>[];
    switch (bucket) {
      case MovementBucket.upcoming:
        actions.addAll(const [
          IndividualMovementAction.edit,
          IndividualMovementAction.confirm,
          IndividualMovementAction.reject,
          IndividualMovementAction.delete,
        ]);
        break;
      case MovementBucket.overdue:
        actions.addAll(const [
          IndividualMovementAction.edit,
          IndividualMovementAction.reject,
          IndividualMovementAction.delete,
        ]);
        break;
      case MovementBucket.confirmed:
        actions.addAll(const [
          IndividualMovementAction.edit,
          IndividualMovementAction.reject,
          IndividualMovementAction.delete,
        ]);
        break;
      case MovementBucket.rejected:
        actions.addAll(const [
          IndividualMovementAction.edit,
          IndividualMovementAction.delete,
        ]);
        break;
    }

    return actions
        .map(
          (a) => PopupMenuItem<IndividualMovementAction>(
            value: a,
            child: PopupItem(
              title: _labelForAction(a),
              icon: Icon(
                _iconForAction(a),
                color: AppColors.themeColor,
              ),
            ),
          ),
        )
        .toList();
  }

  String _labelForAction(IndividualMovementAction a) {
    switch (a) {
      case IndividualMovementAction.edit:
        return 'Edit';
      case IndividualMovementAction.confirm:
        return 'Confirm';
      case IndividualMovementAction.reject:
        return 'Reject';
      case IndividualMovementAction.moveToPending:
        return 'Move to Pending';
      case IndividualMovementAction.delete:
        return 'Delete';
    }
  }

  IconData _iconForAction(IndividualMovementAction a) {
    switch (a) {
      case IndividualMovementAction.edit:
        return Icons.edit;
      case IndividualMovementAction.confirm:
        return Icons.check_circle_outline;
      case IndividualMovementAction.reject:
        return Icons.cancel_outlined;
      case IndividualMovementAction.moveToPending:
        return Icons.schedule_rounded;
      case IndividualMovementAction.delete:
        return Icons.delete;
    }
  }

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
        Flexible(child: left),
        const SizedBox(width: 6),
        const Icon(
          Icons.arrow_right_alt_rounded,
          size: 20,
          color: AppColors.primaryColor,
        ),
        const SizedBox(width: 6),
        Flexible(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = HighlightableCard(
      code: item.id.toString(),
      highlightCode: highlightCode,
      scrollOnHighlight: true,
      borderRadius: 14,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
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
              if (!isViewOnly)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: PopupMenuButton<IndividualMovementAction>(
                    tooltip: 'More',
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: const Icon(Icons.more_horiz, size: 20),
                    onSelected: (action) => onActionSelected(item, action),
                    itemBuilder: (_) => _buildMenuEntries(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              DocumentImageWidget(
                fileUuid: item.studentCode,
                studentCode: item.studentCode.trim().isNotEmpty
                    ? item.studentCode.trim()
                    : null,
                mediaAssetCode: item.profilePhotoAssetCode,
                name: item.name,
                size: 30,
                fontSize: 11,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onStudentNameTap == null
                      ? null
                      : () => onStudentNameTap!(item),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: Fonts.manrope,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                      decoration: TextDecoration.none,
                    ),
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
          if (item.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.comment.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ],
      ),
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
