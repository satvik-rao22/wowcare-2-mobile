import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/auth/models/kiosk_pin_result.dart';

/// What 2c is opened with. A typed argument rather than a `Map` in
/// `state.extra`, so a wrong key is a compile error and not a crash at the
/// door.
///
/// [isSigningIn] is decided before the picker opens: by 2d when the family is
/// mixed, and by the family's own status when it is not.
@immutable
class KioskFamilyArgs extends Equatable {
  const KioskFamilyArgs({required this.result, required this.isSigningIn});

  final KioskPinResult result;
  final bool isSigningIn;

  @override
  List<Object?> get props => [result, isSigningIn];
}
