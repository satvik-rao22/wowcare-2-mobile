/// The fixed 1–5 developmental assessment scale (PRD BR-AS-05).
///
/// The scale is invariant: it cannot be customised per school or domain. Labels
/// are business rules (so they live in the domain layer); the colour mapping for
/// score badges is a presentation concern handled in `assessment_ui_utils.dart`.
abstract final class AssessmentScale {
  const AssessmentScale._();

  /// Lowest valid score.
  static const int min = 1;

  /// Highest valid score.
  static const int max = 5;

  /// Fixed labels for each score point (PRD §17.2 / BR-AS-05).
  static const Map<int, String> labels = <int, String>{
    1: 'Beginner',
    2: 'Developing',
    3: 'Intermediate',
    4: 'Advanced',
    5: 'Proficient',
  };

  /// Ordered scale points, lowest to highest.
  static const List<int> values = <int>[1, 2, 3, 4, 5];

  /// Human label for [score], or empty when out of range.
  static String labelFor(int? score) {
    if (score == null) return '';
    return labels[score] ?? '';
  }

  /// Whether [score] is a valid integer score in the 1–5 range (VR-AS-01/02).
  static bool isValid(int? score) =>
      score != null && score >= min && score <= max;
}
