// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssessmentCollectionCollection on Isar {
  IsarCollection<AssessmentCollection> get assessmentCollections =>
      this.collection();
}

const AssessmentCollectionSchema = CollectionSchema(
  name: r'AssessmentCollection',
  id: -6522676297648678997,
  properties: {
    r'ageGroupId': PropertySchema(
      id: 0,
      name: r'ageGroupId',
      type: IsarType.string,
    ),
    r'assessedAt': PropertySchema(
      id: 1,
      name: r'assessedAt',
      type: IsarType.dateTime,
    ),
    r'assessedBy': PropertySchema(
      id: 2,
      name: r'assessedBy',
      type: IsarType.string,
    ),
    r'domainId': PropertySchema(
      id: 3,
      name: r'domainId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'impersonatorId': PropertySchema(
      id: 5,
      name: r'impersonatorId',
      type: IsarType.string,
    ),
    r'milestoneId': PropertySchema(
      id: 6,
      name: r'milestoneId',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'periodEnd': PropertySchema(
      id: 8,
      name: r'periodEnd',
      type: IsarType.dateTime,
    ),
    r'periodStart': PropertySchema(
      id: 9,
      name: r'periodStart',
      type: IsarType.dateTime,
    ),
    r'published': PropertySchema(
      id: 10,
      name: r'published',
      type: IsarType.bool,
    ),
    r'schoolId': PropertySchema(
      id: 11,
      name: r'schoolId',
      type: IsarType.string,
    ),
    r'score': PropertySchema(
      id: 12,
      name: r'score',
      type: IsarType.long,
    ),
    r'studentId': PropertySchema(
      id: 13,
      name: r'studentId',
      type: IsarType.string,
    ),
    r'subdomainId': PropertySchema(
      id: 14,
      name: r'subdomainId',
      type: IsarType.string,
    )
  },
  estimateSize: _assessmentCollectionEstimateSize,
  serialize: _assessmentCollectionSerialize,
  deserialize: _assessmentCollectionDeserialize,
  deserializeProp: _assessmentCollectionDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'studentId': IndexSchema(
      id: -6791323312898281473,
      name: r'studentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'studentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'milestoneId': IndexSchema(
      id: 6650917624138872266,
      name: r'milestoneId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'milestoneId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'domainId': IndexSchema(
      id: -9138809277110658179,
      name: r'domainId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'domainId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'schoolId': IndexSchema(
      id: 6631843591736686975,
      name: r'schoolId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'schoolId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'periodStart': IndexSchema(
      id: -7133903706047263368,
      name: r'periodStart',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'periodStart',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _assessmentCollectionGetId,
  getLinks: _assessmentCollectionGetLinks,
  attach: _assessmentCollectionAttach,
  version: '3.1.0+1',
);

int _assessmentCollectionEstimateSize(
  AssessmentCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.ageGroupId.length * 3;
  bytesCount += 3 + object.assessedBy.length * 3;
  bytesCount += 3 + object.domainId.length * 3;
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.impersonatorId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.milestoneId.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.schoolId.length * 3;
  bytesCount += 3 + object.studentId.length * 3;
  bytesCount += 3 + object.subdomainId.length * 3;
  return bytesCount;
}

void _assessmentCollectionSerialize(
  AssessmentCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.ageGroupId);
  writer.writeDateTime(offsets[1], object.assessedAt);
  writer.writeString(offsets[2], object.assessedBy);
  writer.writeString(offsets[3], object.domainId);
  writer.writeString(offsets[4], object.id);
  writer.writeString(offsets[5], object.impersonatorId);
  writer.writeString(offsets[6], object.milestoneId);
  writer.writeString(offsets[7], object.notes);
  writer.writeDateTime(offsets[8], object.periodEnd);
  writer.writeDateTime(offsets[9], object.periodStart);
  writer.writeBool(offsets[10], object.published);
  writer.writeString(offsets[11], object.schoolId);
  writer.writeLong(offsets[12], object.score);
  writer.writeString(offsets[13], object.studentId);
  writer.writeString(offsets[14], object.subdomainId);
}

AssessmentCollection _assessmentCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AssessmentCollection();
  object.ageGroupId = reader.readString(offsets[0]);
  object.assessedAt = reader.readDateTime(offsets[1]);
  object.assessedBy = reader.readString(offsets[2]);
  object.domainId = reader.readString(offsets[3]);
  object.id = reader.readString(offsets[4]);
  object.impersonatorId = reader.readStringOrNull(offsets[5]);
  object.milestoneId = reader.readString(offsets[6]);
  object.notes = reader.readStringOrNull(offsets[7]);
  object.periodEnd = reader.readDateTime(offsets[8]);
  object.periodStart = reader.readDateTime(offsets[9]);
  object.published = reader.readBool(offsets[10]);
  object.schoolId = reader.readString(offsets[11]);
  object.score = reader.readLong(offsets[12]);
  object.studentId = reader.readString(offsets[13]);
  object.subdomainId = reader.readString(offsets[14]);
  return object;
}

P _assessmentCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assessmentCollectionGetId(AssessmentCollection object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _assessmentCollectionGetLinks(
    AssessmentCollection object) {
  return [];
}

void _assessmentCollectionAttach(
    IsarCollection<dynamic> col, Id id, AssessmentCollection object) {}

extension AssessmentCollectionQueryWhereSort
    on QueryBuilder<AssessmentCollection, AssessmentCollection, QWhere> {
  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhere>
      anyPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'periodStart'),
      );
    });
  }
}

extension AssessmentCollectionQueryWhere
    on QueryBuilder<AssessmentCollection, AssessmentCollection, QWhereClause> {
  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      studentIdEqualTo(String studentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'studentId',
        value: [studentId],
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      studentIdNotEqualTo(String studentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentId',
              lower: [],
              upper: [studentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentId',
              lower: [studentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentId',
              lower: [studentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentId',
              lower: [],
              upper: [studentId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      milestoneIdEqualTo(String milestoneId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'milestoneId',
        value: [milestoneId],
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      milestoneIdNotEqualTo(String milestoneId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'milestoneId',
              lower: [],
              upper: [milestoneId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'milestoneId',
              lower: [milestoneId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'milestoneId',
              lower: [milestoneId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'milestoneId',
              lower: [],
              upper: [milestoneId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      domainIdEqualTo(String domainId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'domainId',
        value: [domainId],
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      domainIdNotEqualTo(String domainId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [],
              upper: [domainId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [domainId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [domainId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'domainId',
              lower: [],
              upper: [domainId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      schoolIdEqualTo(String schoolId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'schoolId',
        value: [schoolId],
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      schoolIdNotEqualTo(String schoolId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolId',
              lower: [],
              upper: [schoolId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolId',
              lower: [schoolId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolId',
              lower: [schoolId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolId',
              lower: [],
              upper: [schoolId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      periodStartEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'periodStart',
        value: [periodStart],
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      periodStartNotEqualTo(DateTime periodStart) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [periodStart],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'periodStart',
              lower: [],
              upper: [periodStart],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      periodStartGreaterThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [periodStart],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      periodStartLessThan(
    DateTime periodStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [],
        upper: [periodStart],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterWhereClause>
      periodStartBetween(
    DateTime lowerPeriodStart,
    DateTime upperPeriodStart, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'periodStart',
        lower: [lowerPeriodStart],
        includeLower: includeLower,
        upper: [upperPeriodStart],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AssessmentCollectionQueryFilter on QueryBuilder<AssessmentCollection,
    AssessmentCollection, QFilterCondition> {
  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ageGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ageGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ageGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ageGroupId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ageGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ageGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      ageGroupIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ageGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      ageGroupIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ageGroupId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ageGroupId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> ageGroupIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ageGroupId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assessedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assessedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assessedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assessedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assessedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assessedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assessedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assessedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assessedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assessedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      assessedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assessedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      assessedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assessedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assessedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> assessedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assessedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'domainId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      domainIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'domainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      domainIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'domainId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'domainId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> domainIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'domainId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'impersonatorId',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'impersonatorId',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'impersonatorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'impersonatorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'impersonatorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'impersonatorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'impersonatorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'impersonatorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      impersonatorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'impersonatorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      impersonatorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'impersonatorId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'impersonatorId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> impersonatorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'impersonatorId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'milestoneId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      milestoneIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'milestoneId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      milestoneIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'milestoneId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'milestoneId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> milestoneIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'milestoneId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodEndEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodEndGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodEndLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodEndBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodStartEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodStartGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodStartLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> periodStartBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> publishedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'published',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schoolId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schoolId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schoolId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schoolId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'schoolId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'schoolId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      schoolIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'schoolId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      schoolIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'schoolId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schoolId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> schoolIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'schoolId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> scoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> scoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> scoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> scoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'score',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      studentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      studentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> studentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studentId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subdomainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subdomainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subdomainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subdomainId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subdomainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subdomainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      subdomainIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subdomainId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
          QAfterFilterCondition>
      subdomainIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subdomainId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subdomainId',
        value: '',
      ));
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection,
      QAfterFilterCondition> subdomainIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subdomainId',
        value: '',
      ));
    });
  }
}

extension AssessmentCollectionQueryObject on QueryBuilder<AssessmentCollection,
    AssessmentCollection, QFilterCondition> {}

extension AssessmentCollectionQueryLinks on QueryBuilder<AssessmentCollection,
    AssessmentCollection, QFilterCondition> {}

extension AssessmentCollectionQuerySortBy
    on QueryBuilder<AssessmentCollection, AssessmentCollection, QSortBy> {
  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByAgeGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageGroupId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByAgeGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageGroupId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByAssessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedAt', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByAssessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedAt', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByAssessedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedBy', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByAssessedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedBy', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByDomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByDomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByImpersonatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'impersonatorId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByImpersonatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'impersonatorId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByMilestoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByMilestoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByPublished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByPublishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortBySchoolId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortBySchoolIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByStudentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortByStudentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortBySubdomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subdomainId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      sortBySubdomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subdomainId', Sort.desc);
    });
  }
}

extension AssessmentCollectionQuerySortThenBy
    on QueryBuilder<AssessmentCollection, AssessmentCollection, QSortThenBy> {
  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByAgeGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageGroupId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByAgeGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageGroupId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByAssessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedAt', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByAssessedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedAt', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByAssessedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedBy', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByAssessedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assessedBy', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByDomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByDomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'domainId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByImpersonatorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'impersonatorId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByImpersonatorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'impersonatorId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByMilestoneId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByMilestoneIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'milestoneId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByPeriodEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEnd', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStart', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByPublished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByPublishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'published', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenBySchoolId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenBySchoolIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByStudentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenByStudentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.desc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenBySubdomainId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subdomainId', Sort.asc);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QAfterSortBy>
      thenBySubdomainIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subdomainId', Sort.desc);
    });
  }
}

extension AssessmentCollectionQueryWhereDistinct
    on QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct> {
  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByAgeGroupId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ageGroupId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByAssessedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assessedAt');
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByAssessedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assessedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByDomainId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'domainId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByImpersonatorId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'impersonatorId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByMilestoneId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'milestoneId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByPeriodEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEnd');
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStart');
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByPublished() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'published');
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctBySchoolId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schoolId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'score');
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctByStudentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssessmentCollection, AssessmentCollection, QDistinct>
      distinctBySubdomainId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subdomainId', caseSensitive: caseSensitive);
    });
  }
}

extension AssessmentCollectionQueryProperty on QueryBuilder<
    AssessmentCollection, AssessmentCollection, QQueryProperty> {
  QueryBuilder<AssessmentCollection, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      ageGroupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ageGroupId');
    });
  }

  QueryBuilder<AssessmentCollection, DateTime, QQueryOperations>
      assessedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assessedAt');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      assessedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assessedBy');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      domainIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'domainId');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AssessmentCollection, String?, QQueryOperations>
      impersonatorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'impersonatorId');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      milestoneIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'milestoneId');
    });
  }

  QueryBuilder<AssessmentCollection, String?, QQueryOperations>
      notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<AssessmentCollection, DateTime, QQueryOperations>
      periodEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEnd');
    });
  }

  QueryBuilder<AssessmentCollection, DateTime, QQueryOperations>
      periodStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStart');
    });
  }

  QueryBuilder<AssessmentCollection, bool, QQueryOperations>
      publishedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'published');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      schoolIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schoolId');
    });
  }

  QueryBuilder<AssessmentCollection, int, QQueryOperations> scoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'score');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      studentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentId');
    });
  }

  QueryBuilder<AssessmentCollection, String, QQueryOperations>
      subdomainIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subdomainId');
    });
  }
}
