import 'package:equatable/equatable.dart';

class SchoolFte extends Equatable {
  const SchoolFte({
    required this.schoolCode,
    required this.schoolFte,
  });

  final String schoolCode;
  final double schoolFte;

  @override
  List<Object?> get props => [schoolCode, schoolFte];
}
