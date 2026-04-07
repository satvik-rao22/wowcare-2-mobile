import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

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
    backgroundColor: Colors.transparent,
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

  void _showLimitReached() {
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Limit Reached: You can only select one student as a sibling',
      isWarning: true,
    );
  }

  void _toggleSingleSelect(String code) {
    final selected = _selectedCodes.contains(code);
    if (selected) {
      _selectedCodes.remove(code);
      return;
    }

    if (_selectedCodes.isNotEmpty) {
      _showLimitReached();
      return;
    }
    _selectedCodes.add(code);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
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
            color: Colors.white,
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
                    color: Colors.white,
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
                    fontFamily: 'Manrope',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff573353),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                child: Text(
                  'Would you like to add any of them as siblings?',
                  style: TextStyle(
                    fontFamily: 'Manrope',
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
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
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
                    final selected = _selectedCodes.contains(code);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(borderRadius / 2),
                        onTap: () {
                          setState(() {
                            _toggleSingleSelect(code);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding / 2,
                            vertical: isTablet ? 12 : 10,
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
                                padding: const EdgeInsets.only(top: 2),
                                child: CustomCheckbox(
                                  value: selected,
                                  scale: isTablet ? 1.15 : 1.1,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _toggleSingleSelect(code);
                                      } else {
                                        _selectedCodes.remove(code);
                                      }
                                    });
                                  },
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
                                        fontFamily: 'Manrope',
                                        fontSize: isTablet ? 16 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff573353),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: $status | Classroom: $classroom',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
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
                            color: Colors.white,
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
                              'Skip',
                              style: TextStyle(
                                fontFamily: 'Manrope',
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
                            fontFamily: 'Manrope',
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
