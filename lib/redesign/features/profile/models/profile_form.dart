import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/profile/models/profile_address.dart';
import 'package:wowcare/redesign/features/profile/models/profile_record.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// What Edit My Profile lets a person change. Email and country are locked
/// (the frame's "Cannot be edited"), so they are not here.
///
/// Mirrors the PATCH body `edit_user_profile_screen.dart` builds: firstName,
/// lastName, phoneNumber, addressStreet, addressLine2, addressCity,
/// addressState, addressZipCode.
@immutable
class ProfileFormData extends Equatable {
  const ProfileFormData({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
  });

  factory ProfileFormData.fromRecord(ProfileRecord record) => ProfileFormData(
    firstName: record.firstName,
    lastName: record.lastName,
    phone: record.phone,
    street: record.address.street,
    line2: record.address.line2,
    city: record.address.city,
    state: record.address.state,
    zipCode: record.address.zipCode,
  );

  final String firstName;
  final String lastName;
  final String phone;
  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;

  ProfileAddress toAddress({required String country}) => ProfileAddress(
    street: street.trim(),
    line2: line2.trim(),
    city: city.trim(),
    state: state.trim(),
    zipCode: zipCode.trim(),
    country: country,
  );

  ProfileFormData copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? street,
    String? line2,
    String? city,
    String? state,
    String? zipCode,
  }) => ProfileFormData(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    street: street ?? this.street,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
  );

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    phone,
    street,
    line2,
    city,
    state,
    zipCode,
  ];
}

/// One error line per field, or null where the field is fine.
@immutable
class ProfileFormErrors extends Equatable {
  const ProfileFormErrors({
    this.firstName,
    this.lastName,
    this.phone,
    this.street,
    this.line2,
    this.city,
    this.state,
    this.zipCode,
  });

  static const ProfileFormErrors none = ProfileFormErrors();

  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? street;
  final String? line2;
  final String? city;
  final String? state;
  final String? zipCode;

  bool get isEmpty => props.every((e) => e == null);

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    phone,
    street,
    line2,
    city,
    state,
    zipCode,
  ];
}

/// The rules `edit_user_profile_screen.dart` applies, in the same order.
/// Address fields are required for staff and optional for a guardian.
abstract final class ProfileFormValidator {
  static final RegExp _name = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _zip = RegExp(r'^\d{5}(\d{4})?$');
  static final RegExp _nonDigit = RegExp(r'\D');

  static const int _nameMax = 50;
  static const int _streetMax = 150;
  static const int _cityMax = 50;
  static const int _line2Max = 150;
  static const int _phoneDigits = 10;

  static String digitsOf(String raw) => raw.replaceAll(_nonDigit, '');

  static ProfileFormErrors validate(
    ProfileFormData form, {
    required bool addressRequired,
  }) {
    final first = form.firstName.trim();
    final last = form.lastName.trim();
    final phone = digitsOf(form.phone);
    final street = form.street.trim();
    final city = form.city.trim();
    final zip = digitsOf(form.zipCode);

    return ProfileFormErrors(
      firstName: first.isEmpty
          ? ProfileStrings.firstNameRequired
          : (first.length > _nameMax || !_name.hasMatch(first))
          ? ProfileStrings.firstNameInvalid
          : null,
      lastName: last.isEmpty
          ? ProfileStrings.lastNameRequired
          : (last.length > _nameMax || !_name.hasMatch(last))
          ? ProfileStrings.lastNameInvalid
          : null,
      phone: phone.isEmpty
          ? ProfileStrings.phoneRequired
          : phone.length != _phoneDigits
          ? ProfileStrings.phoneInvalid
          : null,
      street: addressRequired && street.isEmpty
          ? ProfileStrings.streetRequired
          : street.length > _streetMax
          ? ProfileStrings.streetTooLong
          : null,
      line2: form.line2.trim().length > _line2Max
          ? ProfileStrings.line2TooLong
          : null,
      city: addressRequired && city.isEmpty
          ? ProfileStrings.cityRequired
          : city.length > _cityMax
          ? ProfileStrings.cityTooLong
          : null,
      zipCode: addressRequired && zip.isEmpty
          ? ProfileStrings.zipRequired
          : zip.isNotEmpty && !_zip.hasMatch(zip)
          ? ProfileStrings.zipInvalid
          : null,
      state: addressRequired && form.state.trim().isEmpty
          ? ProfileStrings.stateRequired
          : null,
    );
  }
}
