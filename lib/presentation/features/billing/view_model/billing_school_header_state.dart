part of 'billing_school_header_cubit.dart';

/// Resolved school header values (name + optional tagline + address).
class BillingSchoolHeaderState extends Equatable {
  const BillingSchoolHeaderState({
    this.name = 'School',
    this.tagline = '',
    this.address = '',
  });

  final String name;
  final String tagline;
  final String address;

  BillingSchoolHeaderState copyWith({
    String? name,
    String? tagline,
    String? address,
  }) {
    return BillingSchoolHeaderState(
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [name, tagline, address];
}
