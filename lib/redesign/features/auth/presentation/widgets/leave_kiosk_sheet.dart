import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_cubit.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/pin_dots.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/pin_pad.dart';

/// The one way out of kiosk lockdown: an admin's own Sign-In PIN.
///
/// A sheet rather than a screen, because leaving is an interruption of the
/// door rather than a place in it. Nothing else on 2b navigates anywhere.
Future<void> showLeaveKioskSheet(BuildContext context) {
  final kiosk = context.read<KioskCubit>();
  final session = context.read<SessionCubit>();

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<KioskCubit>.value(value: kiosk),
        BlocProvider<SessionCubit>.value(value: session),
      ],
      child: const _LeaveKioskSheet(),
    ),
  );
}

class _LeaveKioskSheet extends StatefulWidget {
  const _LeaveKioskSheet();

  @override
  State<_LeaveKioskSheet> createState() => _LeaveKioskSheetState();
}

class _LeaveKioskSheetState extends State<_LeaveKioskSheet> {
  String _pin = '';
  bool _isChecking = false;

  void _press(String digit) {
    if (_pin.length >= KioskCubit.pinLength || _isChecking) return;
    setState(() => _pin += digit);
    if (_pin.length == KioskCubit.pinLength) unawaited(_unlock());
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _unlock() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final isAdmin = await context.read<KioskCubit>().verifyAdminPin(_pin);
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _pin = '';
    });

    if (!isAdmin) {
      showAppToast(context, AuthStrings.invalidPin, tone: ToastTone.error);
      return;
    }
    context.read<SessionCubit>().leaveKiosk();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    title: AuthStrings.leaveKiosk,
    subtitle: AuthStrings.leaveKioskSubtitle,
    footer: <Widget>[
      SecondaryKey(
        label: AppStrings.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      PrimaryKey(
        label: AuthStrings.nextKey,
        isLoading: _isChecking,
        enabled: _pin.length == KioskCubit.pinLength,
        onTap: () => unawaited(_unlock()),
      ),
    ],
    body: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSizes.sheetGap,
      children: <Widget>[
        PinDots(filled: _pin.length, length: KioskCubit.pinLength),
        PinPad(
          onDigit: _press,
          onBackspace: _backspace,
          padding: AuthSizes.sheetPadGridPad,
        ),
      ],
    ),
  );
}
