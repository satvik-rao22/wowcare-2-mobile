/// The option lists an activity type's own parameters carry.
///
/// `GET /activity-types/{code}` already returns each parameter's display
/// order, required flag, help text, default and its dependent options; this
/// is that list written down for the UI phase, and Phase 5 replaces it with
/// the fetched one. Nothing here is a new field.
abstract final class ActivityOptions {
  // --- Bathroom, 8i ---------------------------------------------------------

  static const String diaper = 'Diaper';

  static const List<String> bathroomTypes = <String>[
    diaper,
    'Potty',
    'Toilet',
  ];

  /// The sub type depends on the type above it, which is the API's own
  /// `dependentOptions`.
  static List<String> bathroomSubTypes(String? type) => switch (type) {
    'Potty' || 'Toilet' => const <String>['Wet', 'Soiled', 'Attempted'],
    _ => const <String>['Wet', 'Soiled', 'Wet and soiled', 'Dry'],
  };

  /// Only a diaper has a size, so the field is only drawn for one.
  static const List<String> diaperSizes = <String>[
    'Newborn',
    'Size 1',
    'Size 2',
    'Size 3',
    'Size 4',
    'Size 5',
    'Size 6',
  ];

  // --- Bottle, 8j -----------------------------------------------------------

  static const List<String> consumptionStatuses = <String>[
    'Finished',
    'Most of it',
    'Some of it',
    'Refused',
  ];

  /// Steps of half an ounce, the way the shipped ounce input works.
  static const double ounceStep = .5;
  static const double ounceMin = 0;
  static const double ounceMax = 12;

  // --- Meal, 8k -------------------------------------------------------------

  static const List<String> mealTypes = <String>[
    'Breakfast',
    'Morning snack',
    'Lunch',
    'Afternoon snack',
    'Dinner',
  ];

  static const List<String> quantities = <String>[
    'All of it',
    'Most of it',
    'Some of it',
    'None of it',
  ];

  static const List<String> mealAmounts = <String>[
    'Whole bowl',
    '¾ bowl',
    '½ bowl',
    '¼ bowl',
  ];

  // --- Learning, 8r ---------------------------------------------------------

  static const List<String> learningCategories = <String>[
    'Numbers',
    'Letters',
    'Colors and shapes',
    'Music and movement',
    'Sensory play',
    'Story time',
  ];

  static List<String> learningSubCategories(String? category) =>
      switch (category) {
        'Numbers' => const <String>[
          'Counting and sorting',
          'Patterns',
          'Measuring',
        ],
        'Letters' => const <String>[
          'Letter sounds',
          'Name writing',
          'Tracing',
        ],
        'Colors and shapes' => const <String>['Matching', 'Building'],
        'Music and movement' => const <String>['Singing', 'Dancing'],
        'Sensory play' => const <String>['Water', 'Sand', 'Dough'],
        'Story time' => const <String>['Group reading', 'Retelling'],
        _ => const <String>[],
      };

  // --- Free text ------------------------------------------------------------

  /// `ActivityDescriptionLimits.maxLength`, shared by every description and
  /// notes field in the module.
  static const int descriptionMax = 500;
}
