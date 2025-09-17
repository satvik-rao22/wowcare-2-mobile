class FilterData {
  final List<int> classroomIds;
  final List<String> classrooms;
  final List<String> statuses;
  final List<String> tags;
  final List<int> tagIds;

  FilterData({
    required this.classroomIds,
    required this.classrooms,
    required this.statuses,
    required this.tags,
    this.tagIds = const [],
  });

  bool get hasFilters =>
      classrooms.isNotEmpty || statuses.isNotEmpty || tags.isNotEmpty || tagIds.isNotEmpty;

  FilterData copyWith({
    List<int>? classroomIds,
    List<String>? classrooms,
    List<String>? statuses,
    List<String>? tags,
    List<int>? tagIds,
  }) {
    return FilterData(
      classroomIds: classroomIds ?? this.classroomIds,
      classrooms: classrooms ?? this.classrooms,
      statuses: statuses ?? this.statuses,
      tags: tags ?? this.tags,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterData &&
        _listEquals(other.classroomIds, classroomIds) &&
        _listEquals(other.classrooms, classrooms) &&
        _listEquals(other.statuses, statuses) &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.tagIds, tagIds);
  }

  @override
  int get hashCode =>
      classroomIds.hashCode ^
      classrooms.hashCode ^
      statuses.hashCode ^
      tags.hashCode ^
      tagIds.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Map tag names to their corresponding IDs
  static List<int> mapTagNamesToIds(List<String> tagNames) {
    print('🏷️ [FILTER DATA] Mapping tag names to IDs:');
    print('   📝 Input tag names: $tagNames');
    
    const tagMapping = {
      '1 Day': 208,
      '2 Days': 206,
      '3 Days': 207,
      'Class-c': 209,
      'Half Day': 205,
      // Add more mappings as needed
    };

    final mappedIds = tagNames
        .map((tagName) {
          final id = tagMapping[tagName];
          print('   🏷️ Mapping "$tagName" -> $id');
          return id;
        })
        .where((id) => id != null)
        .cast<int>()
        .toList();
    
    print('   ✅ Final mapped IDs: $mappedIds');
    return mappedIds;
  }

  /// Create FilterData with automatic tag ID mapping
  static FilterData createWithTagMapping({
    required List<int> classroomIds,
    required List<String> classrooms,
    required List<String> statuses,
    required List<String> tags,
  }) {
    print('🏗️ [FILTER DATA] Creating FilterData with tag mapping:');
    print('   🏫 Classrooms: $classrooms');
    print('   🏷️ Tags: $tags');
    print('   📊 Statuses: $statuses');
    
    final tagIds = mapTagNamesToIds(tags);
    
    final filterData = FilterData(
      classroomIds: classroomIds,
      classrooms: classrooms,
      statuses: statuses,
      tags: tags,
      tagIds: tagIds,
    );
    
    print('   ✅ Created FilterData with tag IDs: $tagIds');
    return filterData;
  }
}
