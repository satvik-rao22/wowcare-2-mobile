import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A parent the school already knows, offered by step two's search and by the
/// filter sheet's Parent or guardian section.
@immutable
class GuardianOption extends Equatable {
  const GuardianOption({required this.id, required this.name, this.email = ''});

  final String id;
  final String name;
  final String email;

  @override
  List<Object?> get props => [id, name, email];
}
