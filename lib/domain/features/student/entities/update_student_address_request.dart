import 'package:equatable/equatable.dart';

/// Typed request for updating a student's address, replacing the raw
/// `Map<String, dynamic> fields` the repository contract used to take. Pure
/// domain — payload shaping lives in the data layer (see
/// `data/features/student/mappers/update_student_address_request_mapper.dart`).
class UpdateStudentAddressRequest extends Equatable {
  const UpdateStudentAddressRequest({
    required this.street,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    this.addressType = 'CURRENT',
    this.schoolCode,
  });

  /// Primary street line (sent as both `line1` and `street`).
  final String street;
  final String line2;
  final String city;

  /// State code (backend enum/abbreviation).
  final String state;

  /// Country code.
  final String country;

  /// Postal/ZIP code.
  final String postalCode;

  /// Address type, defaults to `CURRENT`.
  final String addressType;

  /// Optional school code — a cache-invalidation hint for the repository, not
  /// part of the API body.
  final String? schoolCode;

  @override
  List<Object?> get props => [
        street,
        line2,
        city,
        state,
        country,
        postalCode,
        addressType,
        schoolCode,
      ];
}
