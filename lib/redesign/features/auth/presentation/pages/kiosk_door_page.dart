import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/kiosk_notice.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/kiosk_qr_panel.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/kiosk_top_bar.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/leave_kiosk_sheet.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/pin_dots.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/pin_pad.dart';

/// 2b. The door screen: the QR and the PIN pad on one screen.
///
/// A family either scans the code from a phone or types the PIN into this
/// pad, and both roads end at the same person. The pad verifies itself on the
/// fourth digit; Next is a retry rather than the way through.
///
/// 2e's four QR states live in the panel above the pad, so pulling the screen
/// down cycles them, which is what that frame demonstrates.
class KioskDoorPage extends StatefulWidget {
  const KioskDoorPage({super.key});

  @override
  State<KioskDoorPage> createState() => _KioskDoorPageState();
}

class _KioskDoorPageState extends State<KioskDoorPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<KioskCubit>().load());
  }

  /// A staff member's own PIN records them here; a guardian's goes on to the
  /// family, either straight to the picker or through 2d's question first.
  void _onResult(KioskPinResult result) {
    final cubit = context.read<KioskCubit>();

    if (result.isStaff) {
      unawaited(
        cubit.recordStaff(
          isSigningIn: result.staffAttendance != AttendanceStatus.signedIn,
        ),
      );
      return;
    }

    cubit.clearPin();
    if (result.isMixed) {
      unawaited(context.push(AppRoutes.kioskChoice, extra: result));
      return;
    }
    unawaited(
      context.push(
        AppRoutes.kioskFamily,
        extra: KioskFamilyArgs(
          result: result,
          isSigningIn: result.signedInStudents.isEmpty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<KioskCubit>();

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: BlocConsumer<KioskCubit, KioskState>(
          listenWhen: (previous, current) =>
              previous.result != current.result && current.result != null,
          listener: (context, state) => _onResult(state.result!),
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              KioskTopBar(
                action: IconKey(
                  icon: AppIcons.moreHorizontal,
                  size: AppSizes.backKey,
                  semanticLabel: AuthStrings.leaveKiosk,
                  onTap: () => unawaited(showLeaveKioskSheet(context)),
                ),
              ),
              Expanded(child: _pad(state, cubit)),
              _footer(state, cubit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pad(KioskState state, KioskCubit cubit) {
    final c = context.colours;

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      color: c.pink,
      backgroundColor: c.card,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: <Widget>[
          KioskQrPanel(
            schoolName: state.qr?.schoolName ?? '',
            status: state.qrStatus,
            errorMessage: state.qrError,
            onRefresh: () => unawaited(cubit.refresh()),
          ),
          Container(
            margin: AuthSizes.padDividerMargin,
            height: AppSizes.hairline,
            color: c.divider,
          ),
          Padding(
            padding: AuthSizes.pinTitlePad,
            child: Text(
              AuthStrings.enterPin,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(color: c.ink),
            ),
          ),
          Padding(
            padding: AuthSizes.pinDotsPad,
            child: PinDots(
              filled: state.pin.length,
              length: KioskCubit.pinLength,
            ),
          ),
          if (state.notice != null)
            Padding(
              padding: AuthSizes.pinNoticeMargin,
              child: KioskNotice(
                message: state.notice!,
                tone: state.noticeTone,
              ),
            ),
          PinPad(
            onDigit: (digit) => unawaited(cubit.press(digit)),
            onBackspace: cubit.backspace,
          ),
        ],
      ),
    );
  }

  Widget _footer(KioskState state, KioskCubit cubit) => Padding(
    padding: AuthSizes.padFooterPad,
    child: Row(
      spacing: AuthSizes.padFooterGap,
      children: <Widget>[
        Expanded(
          child: SecondaryKey(
            label: AppStrings.cancel,
            padding: AppSizes.fieldPadLarge,
            onTap: cubit.cancel,
          ),
        ),
        Expanded(
          child: PrimaryKey(
            label: AuthStrings.nextKey,
            isLoading: state.isVerifying,
            padding: AppSizes.fieldPadLarge,
            enabled: state.canSubmit,
            onTap: () => unawaited(cubit.submit()),
          ),
        ),
      ],
    ),
  );
}
