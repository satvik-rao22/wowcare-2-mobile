import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

/// Bottom sheet to pick existing students with the same surname as siblings.
/// Returns selected student codes (may be empty). Null if dismissed without action.
Future<List<String>?> showSameLastNameSiblingsDialog({
  required BuildContext context,
  required List<Student> candidates,
}) async {
  if (candidates.isEmpty) return <String>[];

  return showModalBottomSheet<List<String>?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparentColor,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _SameLastNameSiblingsBody(candidates: candidates),
      );
    },
  );
}

class _SameLastNameSiblingsBody extends StatefulWidget {
  const _SameLastNameSiblingsBody({required this.candidates});

  final List<Student> candidates;

  @override
  State<_SameLastNameSiblingsBody> createState() =>
      _SameLastNameSiblingsBodyState();
}

class _SameLastNameSiblingsBodyState extends State<_SameLastNameSiblingsBody> {
  final Set<String> _selectedCodes = <String>{};

  String? get _selectedCode =>
      _selectedCodes.isEmpty ? null : _selectedCodes.first;

  // Only one student can be chosen as a sibling, so selecting another replaces
  // the previous choice. Tapping the already-selected entry clears it.
  void _selectSingle(String code) {
    if (_selectedCodes.contains(code)) {
      _selectedCodes.remove(code);
      return;
    }
    _selectedCodes
      ..clear()
      ..add(code);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTabletCompact;
    final isLargeTablet = responsive.isWide;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final horizontalPadding =
        isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding =
        isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final titleFontSize =
        isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
    final buttonHeight =
        isLargeTablet ? 56.0 : (isTablet ? 48.0 : 40.0);
    final buttonFontSize =
        isLargeTablet ? 18.0 : (isTablet ? 16.0 : 14.0);
    final borderRadius =
        isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);
    final count = widget.candidates.length;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeTablet ? 1200.0 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: verticalPadding + bottomSafe,
          ),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: verticalPadding / 2),
              Center(
                child: Container(
                  width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  decoration: BoxDecoration(
                    gradient: AppColors.buildPrimaryGradient(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    color: AppColors.whiteColor,
                    size: isLargeTablet ? 40 : 36,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                child: Text(
                  'We found $count student${count == 1 ? '' : 's'} with the same last name',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              AppSpacing.gapVXs,
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                child: Text(
                  StudentStrings.wouldYouLikeToAddAnyOfThemAsSiblings,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: verticalPadding * 0.75),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: responsive.screenHeight * 0.42,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.candidates.length,
                  separatorBuilder: (_, __) => SizedBox(height: verticalPadding / 3),
                  itemBuilder: (context, index) {
                    final s = widget.candidates[index];
                    final code = s.code.trim();
                    final name =
                        s.fullName.isNotEmpty ? s.fullName : 'Student';
                    final status = s.status.trim().toUpperCase();
                    final classroom =
                        s.classroom.trim().isEmpty ? '—' : s.classroom;

                    return Material(
                      color: AppColors.transparentColor,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(borderRadius / 2),
                        onTap: () {
                          setState(() {
                            _selectSingle(code);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding / 2,
                            vertical: isTablet ? AppSpacing.sm : AppSpacing.s10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(borderRadius / 2),
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.s2),
                                child: ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) =>
                                      AppColors.buildPrimaryGradient()
                                          .createShader(bounds),
                                  child: Radio<String>(
                                    value: code,
                                    groupValue: _selectedCode,
                                    activeColor: AppColors.primaryColor,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (_) {
                                      setState(() {
                                        _selectSingle(code);
                                      });
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: horizontalPadding / 4),
                              DocumentImageWidget(
                                fileUuid: code,
                                name: name,
                                size: isTablet ? 44 : 40,
                                fontSize: 14,
                              ),
                              SizedBox(width: horizontalPadding / 3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: isTablet ? 16 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    AppSpacing.gapVXxs,
                                    Text(
                                      'Status: $status | Classroom: $classroom',
                                      style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 13,
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius:
                            BorderRadius.circular(borderRadius / 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(
                                borderRadius / 2 - 1),
                          ),
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(<String>[]),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    borderRadius / 2 - 1),
                              ),
                            ),
                            child: Text(
                              StudentStrings.skip,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: horizontalPadding / 2),
                  Expanded(
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(borderRadius / 2),
                        gradient: AppColors.buildPrimaryGradient(),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.of(context)
                            .pop(_selectedCodes.toList()),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                borderRadius / 2),
                          ),
                        ),
                        child: Text(
                          'Continue (${_selectedCodes.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.whiteColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
