import 'package:equatable/equatable.dart';

/// Typed request for updating the *logged-in* staff member's basic profile +
/// address via `PATCH /api/v1/staff/staff/my-profile/{staffCode}`.
///
/// Replaces the raw `Map<String, dynamic>` body the edit-profile cubit used
/// to build and pass straight through the repository/datasource. JSON
/// shaping stays at the data-layer boundary: the repository calls
/// [toPayload] to hand the datasource the exact map it has always received.
class StaffMyProfileUpdate extends Equatable {
  const StaffMyProfileUpdate({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.addressStreet,
    required this.addressLine2,
    required this.addressCity,
    required this.addressState,
    required this.addressZipCode,
    required this.addressCountry,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String addressStreet;
  final String addressLine2;
  final String addressCity;
  final String addressState;
  final String addressZipCode;
  final String addressCountry;

  /// Reproduces the exact map shape the datasource has always PATCHed.
  Map<String, dynamic> toPayload() => {
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'addressStreet': addressStreet,
    'addressLine2': addressLine2,
    'addressCity': addressCity,
    'addressState': addressState,
    'addressZipCode': addressZipCode,
    'addressCountry': addressCountry,
  };

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    phoneNumber,
    addressStreet,
    addressLine2,
    addressCity,
    addressState,
    addressZipCode,
    addressCountry,
  ];
}
