import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

class DuplicateStudentBottomSheet extends StatefulWidget {
  const DuplicateStudentBottomSheet({
    super.key,
    required this.enteredName,
    required this.matches,
    required this.onTapMatch,
    this.isLoading = false,
  });

  final String enteredName;
  final List<String> matches;
  final void Function(String matchName) onTapMatch;
  final bool isLoading;

  @override
  State<DuplicateStudentBottomSheet> createState() =>
      _DuplicateStudentBottomSheetState();
}

class _DuplicateStudentBottomSheetState
    extends State<DuplicateStudentBottomSheet> {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final horizontalPadding = isLargeTablet
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;
    final verticalPadding = isLargeTablet
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;
    final titleFontSize = isLargeTablet
        ? 20.0
        : isTablet
        ? 18.0
        : 16.0;
    final borderRadius = isLargeTablet
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;

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
                  width: isLargeTablet ? 80 : (isTablet ? 70 : 60),
                  height: isLargeTablet ? 80 : (isTablet ? 70 : 60),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1E8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.primaryColor,
                    size: isLargeTablet ? 40 : (isTablet ? 36 : 32),
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding / 2,
                ),
                child: Text(
                  'Duplicate student found',
                  style: TextStyle(
                    fontFamily: "Manrope",
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
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding / 2,
                ),
                child: Text(
                  'A student with the name "${widget.enteredName}" already exists. Tap a name to view the profile, or add anyway to continue.',
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryColor.withValues(alpha: 0.65),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: verticalPadding),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  runSpacing: 10,
                  children: widget.matches.map((m) {
                    return InkWell(
                      onTap: _isLoading ? null : () => widget.onTapMatch(m),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              m,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: verticalPadding * 1.5),
              CustomButtonLayout(
                confirmButtonLabel: 'Add anyway',
                cancelButtonLabel: 'Cancel',
                onPressedConfirm: () {
                  if (_isLoading) return;
                  setState(() => _isLoading = true);
                  Navigator.of(context).pop(true);
                },
                onPressedCancel: () {
                  if (_isLoading) return;
                  Navigator.of(context).pop(false);
                },
                isForm: false,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
