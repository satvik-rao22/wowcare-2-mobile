import 'package:equatable/equatable.dart';

/// Typed request for updating a staff member's address via
/// `PATCH /api/v1/staff-address/{staffCode}`.
///
/// Replaces the raw `Map<String, dynamic>` body the edit-profile view used to
/// build inline. JSON shaping stays at the data-layer boundary: the repository
/// calls [toPayload] to hand the datasource the exact Map it has always
/// received. The values carried here are the already-transformed ones the view
/// computed (state/country mapped to codes, zip reduced to digits) — this model
/// only carries them, it does not transform.
class StaffAddressUpdate extends Equatable {
  const StaffAddressUpdate({
    required this.addressStreet,
    required this.addressLine2,
    required this.addressCity,
    required this.addressState,
    required this.addressZipCode,
    required this.addressCountry,
  });

  final String addressStreet;
  final String addressLine2;
  final String addressCity;
  final String addressState;
  final String addressZipCode;
  final String addressCountry;

  /// Reproduces the exact Map the edit-profile view used to build, key-for-key.
  Map<String, dynamic> toPayload() => {
    'addressStreet': addressStreet,
    'addressLine2': addressLine2,
    'addressCity': addressCity,
    'addressState': addressState,
    'addressZipCode': addressZipCode,
    'addressCountry': addressCountry,
  };

  @override
  List<Object?> get props => [
    addressStreet,
    addressLine2,
    addressCity,
    addressState,
    addressZipCode,
    addressCountry,
  ];
}
