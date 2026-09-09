import 'package:equatable/equatable.dart';

/// Typed UI view-model for a student's siblings, replacing the former raw
/// `Map<String, dynamic>` (`{'name': [...], 'relation': [...], 'status': [...]}`)
/// passed down the profile widget tree. Three index-aligned lists.
class StudentSiblingInfo extends Equatable {
  const StudentSiblingInfo({
    this.names = const <String>[],
    this.relations = const <String>[],
    this.statuses = const <String>[],
  });

  final List<String> names;
  final List<String> relations;
  final List<String> statuses;

  bool get isEmpty => names.isEmpty;

  @override
  List<Object?> get props => [names, relations, statuses];
}
