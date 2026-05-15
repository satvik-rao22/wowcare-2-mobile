import 'package:equatable/equatable.dart';

class Classroom extends Equatable {
  const Classroom({required this.code, required this.name});

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}
