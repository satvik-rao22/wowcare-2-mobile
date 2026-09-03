import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A postal address, mirroring `StaffProfileAddress` in the domain layer
/// (street, line2, city, state, zipCode, country).
@immutable
class ProfileAddress extends Equatable {
  const ProfileAddress({
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
  });

  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  bool get isEmpty =>
      street.isEmpty && city.isEmpty && state.isEmpty && zipCode.isEmpty;

  /// "118 Wexford Lane, Apt 4": the first line the profile card shows.
  String get streetLine =>
      <String>[street, line2].where((p) => p.isNotEmpty).join(', ');

  /// "Nashua, New Hampshire 03063": the second line.
  String get localityLine {
    final cityState = <String>[
      city,
      state,
    ].where((p) => p.isNotEmpty).join(', ');
    return <String>[cityState, zipCode].where((p) => p.isNotEmpty).join(' ');
  }

  ProfileAddress copyWith({
    String? street,
    String? line2,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) => ProfileAddress(
    street: street ?? this.street,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
    country: country ?? this.country,
  );

  @override
  List<Object?> get props => <Object?>[
    street,
    line2,
    city,
    state,
    zipCode,
    country,
  ];
}
