import 'package:json_annotation/json_annotation.dart';

part 'student_tags_response.g.dart';

/// The `{tags: [...]}` envelope returned by the student-tags endpoint.
///
/// Entries are stringified rather than cast, because the backend has been seen
/// to send both bare strings and numbers here.
@JsonSerializable(createToJson: false)
class StudentTagsResponse {
  const StudentTagsResponse({this.tags});

  factory StudentTagsResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentTagsResponseFromJson(json);

  final List<dynamic>? tags;

  List<String> get names =>
      (tags ?? const []).map((tag) => tag.toString()).toList();
}
