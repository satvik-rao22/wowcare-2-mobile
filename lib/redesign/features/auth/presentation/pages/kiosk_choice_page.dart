import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/kiosk_top_bar.dart';

/// 2d. A family with one student in and one still out has to say which way
/// this visit goes before the picker can preselect anybody, so the kiosk asks
/// rather than guessing.
///
/// The well underneath shows what the PIN already knows, so the answer is not
/// given blind.
class KioskChoicePage extends StatelessWidget {
  const KioskChoicePage({required this.result, super.key});

  final KioskPinResult result;

  void _choose(BuildContext context, {required bool isSigningIn}) {
    context.pushReplacement(
      AppRoutes.kioskFamily,
      extra: KioskFamilyArgs(result: result, isSigningIn: isSigningIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const KioskTopBar.brand(),
            const AppHeaderBar(
              title: AuthStrings.signInOrOut,
              leading: BackKey(),
              isDetail: true,
            ),
            Expanded(
              child: Padding(
                padding: AuthSizes.chooserPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AuthSizes.chooserGap,
                  children: <Widget>[
                    PrimaryKey(
                      label: AppStrings.signIn,
                      padding: AuthSizes.chooserKeyPad,
                      onTap: () => _choose(context, isSigningIn: true),
                    ),
                    PrimaryKey(
                      label: AppStrings.signOut,
                      padding: AuthSizes.chooserKeyPad,
                      onTap: () => _choose(context, isSigningIn: false),
                    ),
                    _onThisPin(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onThisPin(BuildContext context) {
    final c = context.colours;

    return AppWell(
      padding: AuthSizes.onPinPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AuthSizes.onPinGap,
        children: <Widget>[
          SectionEyebrow(label: AuthStrings.onThisPin, color: c.ink2),
          for (final student in result.students)
            _PinRow(student: student),
        ],
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({required this.student});

  final KioskStudent student;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: AuthSizes.onPinRowGap,
      children: <Widget>[
        AppAvatar(
          initials: student.initials,
          size: AuthSizes.onPinAvatar,
          textStyle: AppTextStyles.rowSub,
        ),
        Expanded(
          child: Text(
            student.name,
            style: AppTextStyles.fieldText.copyWith(color: c.ink),
          ),
        ),
        StatusPill(
          label: _label,
          tone: student.isSignedIn ? PillTone.success : PillTone.neutral,
          line: student.isSignedIn ? null : c.cardBorder,
          small: true,
        ),
      ],
    );
  }

  String get _label => switch (student.attendance) {
    AttendanceStatus.signedIn => AppStrings.signedIn,
    AttendanceStatus.signedOut => AppStrings.signedOut,
    AttendanceStatus.absent => AppStrings.absent,
    AttendanceStatus.notMarked => AppStrings.notMarked,
  };
}
