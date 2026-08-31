import 'package:equatable/equatable.dart';

/// Pure-domain representation of a vaccine definition from immunization settings.
///
/// Preserves both the backend code (`VCC_*`) and the display name (e.g. `DTaP`).
class VaccineItem extends Equatable {
  const VaccineItem({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];

  @override
  String toString() => 'VaccineItem(code: $code, name: $name)';
}
