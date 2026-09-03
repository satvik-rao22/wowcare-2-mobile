part of 'kiosk_family_cubit.dart';

enum KioskFamilyStatus { picking, recording, recorded }

@immutable
class KioskFamilyState extends Equatable {
  const KioskFamilyState({
    required this.result,
    required this.isSigningIn,
    required this.selected,
    this.status = KioskFamilyStatus.picking,
    this.recordedCount = 0,
  });

  final KioskPinResult result;

  /// Which way this visit goes. 2d sets it when the family is mixed.
  final bool isSigningIn;

  final Set<String> selected;
  final KioskFamilyStatus status;

  /// How many students the last record moved, for the receipt.
  final int recordedCount;

  bool get isRecording => status == KioskFamilyStatus.recording;
  bool get isRecorded => status == KioskFamilyStatus.recorded;
  bool get hasSelection => selected.isNotEmpty;

  List<KioskStudent> get students => result.students;

  /// A student already the right way round has nothing to record.
  bool canMove(KioskStudent student) =>
      isSigningIn ? !student.isSignedIn : student.isSignedIn;

  bool isSelected(KioskStudent student) => selected.contains(student.id);

  KioskFamilyState copyWith({
    KioskPinResult? result,
    bool? isSigningIn,
    Set<String>? selected,
    KioskFamilyStatus? status,
    int? recordedCount,
  }) => KioskFamilyState(
    result: result ?? this.result,
    isSigningIn: isSigningIn ?? this.isSigningIn,
    selected: selected ?? this.selected,
    status: status ?? this.status,
    recordedCount: recordedCount ?? this.recordedCount,
  );

  @override
  List<Object?> get props => [
    result,
    isSigningIn,
    selected,
    status,
    recordedCount,
  ];
}
