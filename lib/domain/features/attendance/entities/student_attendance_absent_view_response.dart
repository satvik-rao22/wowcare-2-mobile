import 'package:equatable/equatable.dart';

/// Typed model for the student absent-view list response.
///
/// This is a pure client-side typing of the raw response the
/// `student_attendance_absent_view` screen used to parse inline. The screen
/// reads only the top-level `data` object off the payload —
/// `data['data'] as Map<String, dynamic>? ?? {}` — and then hands that raw
/// page map to its own `_applyPagePayload(...)` (content/last/number parsing
/// and per-record model building) and to `_cacheManager.saveCache(...)`.
///
/// Because that page map is consumed as a raw `Map<String, dynamic>` by the
/// screen (and cached/re-read as one), it is exposed here verbatim via the
/// composed [data] field — a nullable `Map<String, dynamic>` read with the
/// exact `json['data'] as Map<String, dynamic>?` cast the screen applied,
/// with the `?? {}` default kept at the consume site so behaviour is
/// byte-identical.
class StudentAttendanceAbsentViewResponse extends Equatable {
  const StudentAttendanceAbsentViewResponse({
    required this.data,
  });

  /// `json['data'] as Map<String, dynamic>?` (raw page map; the screen applies
  /// its own `?? {}` default and its own paginated parse on this object).
  final Map<String, dynamic>? data;

  factory StudentAttendanceAbsentViewResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentAttendanceAbsentViewResponse(
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [data];
}
