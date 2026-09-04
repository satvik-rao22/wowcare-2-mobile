import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// The filter sheet over a classroom's roster (7d).
///
/// The working selection lives in the sheet until Apply, so nothing on the
/// roster moves while it is open.
class StudentFilterSheet extends StatefulWidget {
  const StudentFilterSheet({
    required this.filters,
    required this.activeCount,
    required this.upcomingCount,
    required this.signedInCount,
    required this.nappingCount,
    required this.tags,
    super.key,
  });

  final StudentFilters filters;

  final int activeCount;
  final int upcomingCount;
  final int signedInCount;
  final int nappingCount;

  /// Every care need anyone on this roster holds. Tags carry no count,
  /// because a student may hold several.
  final List<String> tags;

  /// Opens the sheet. Resolves to the chosen filters on Apply, and to null
  /// when it is dismissed.
  static Future<StudentFilters?> show(
    BuildContext context, {
    required StudentFilters filters,
    required int activeCount,
    required int upcomingCount,
    required int signedInCount,
    required int nappingCount,
    required List<String> tags,
  }) => showAppSheet<StudentFilters>(
    context,
    builder: (_) => StudentFilterSheet(
      filters: filters,
      activeCount: activeCount,
      upcomingCount: upcomingCount,
      signedInCount: signedInCount,
      nappingCount: nappingCount,
      tags: tags,
    ),
  );

  @override
  State<StudentFilterSheet> createState() => _StudentFilterSheetState();
}

class _StudentFilterSheetState extends State<StudentFilterSheet> {
  late StudentFilters _working = widget.filters;

  void _setStatus(StudentStatusFilter status) =>
      setState(() => _working = _working.copyWith(status: status));

  void _toggleTag(String tag) => setState(() {
    final next = <String>{..._working.tags};
    if (!next.remove(tag)) next.add(tag);
    _working = _working.copyWith(tags: next);
  });

  void _selectAllTags() =>
      setState(() => _working = _working.copyWith(tags: widget.tags.toSet()));

  void _clearAll() => setState(() => _working = const StudentFilters());

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppBottomSheet(
      title: ClassroomsStrings.filterStudents,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ClassroomsSizes.sheetGroupGap,
          children: <Widget>[
            _group(
              ClassroomsStrings.statusPickOne,
              Row(
                spacing: ClassroomsSizes.chipGap,
                children: <Widget>[
                  Expanded(
                    child: _StatusKey(
                      label: ClassroomsStrings.activeCount(widget.activeCount),
                      isSelected: _working.status == StudentStatusFilter.active,
                      onTap: () => _setStatus(StudentStatusFilter.active),
                    ),
                  ),
                  Expanded(
                    child: _StatusKey(
                      label: ClassroomsStrings.upcomingCount(
                        widget.upcomingCount,
                      ),
                      isSelected:
                          _working.status == StudentStatusFilter.upcoming,
                      onTap: () => _setStatus(StudentStatusFilter.upcoming),
                    ),
                  ),
                ],
              ),
            ),
            _group(
              ClassroomsStrings.inClassroomNow,
              Wrap(
                spacing: ClassroomsSizes.chipGap,
                runSpacing: ClassroomsSizes.chipGap,
                children: <Widget>[
                  AppChip(
                    label: ClassroomsStrings.signedInChip(widget.signedInCount),
                    selected: _working.signedInOnly,
                    onTap: () => setState(
                      () => _working = _working.copyWith(
                        signedInOnly: !_working.signedInOnly,
                      ),
                    ),
                  ),
                  AppChip(
                    label: ClassroomsStrings.nappingChip(widget.nappingCount),
                    selected: _working.nappingOnly,
                    onTap: () => setState(
                      () => _working = _working.copyWith(
                        nappingOnly: !_working.nappingOnly,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.tags.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: ClassroomsSizes.sheetFieldGap,
                children: <Widget>[
                  SectionEyebrow(
                    label: ClassroomsStrings.tags,
                    trailing: TextLink(
                      label: AppStrings.selectAll,
                      onTap: _selectAllTags,
                      color: c.ink2,
                    ),
                  ),
                  Wrap(
                    spacing: ClassroomsSizes.chipGap,
                    runSpacing: ClassroomsSizes.chipGap,
                    children: <Widget>[
                      for (final tag in widget.tags)
                        AppChip(
                          label: tag,
                          selected: _working.tags.contains(tag),
                          onTap: () => _toggleTag(tag),
                        ),
                    ],
                  ),
                  Text(
                    ClassroomsStrings.tagsCarryNoCount,
                    style: ClassroomsTextStyles.uploadHint.copyWith(
                      color: c.ink3,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      footer: <Widget>[
        SecondaryKey(label: AppStrings.clearAll, onTap: _clearAll),
        PrimaryKey(
          label: AppStrings.apply,
          onTap: () => Navigator.of(context).pop(_working),
        ),
      ],
    );
  }

  Widget _group(String eyebrow, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: ClassroomsSizes.sheetFieldGap,
    children: <Widget>[
      SectionEyebrow(label: eyebrow),
      child,
    ],
  );
}

/// One of the two-up Status keys: a card face that goes teal when picked.
class _StatusKey extends StatelessWidget {
  const _StatusKey({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isSelected
              ? AppSurfaces.tile(c, fill: c.studentBg, line: c.studentLine)
              : AppSurfaces.keySecondary(c),
          padding: ClassroomsSizes.statusKeyPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: ClassroomsTextStyles.statusKey.copyWith(
              color: isSelected ? c.student : c.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
