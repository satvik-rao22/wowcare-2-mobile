// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unread_entity_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUnreadEntityCollectionCollection on Isar {
  IsarCollection<UnreadEntityCollection> get unreadEntityCollections =>
      this.collection();
}

const UnreadEntityCollectionSchema = CollectionSchema(
  name: r'UnreadEntityCollection',
  id: -4900450752235988931,
  properties: {
    r'conversationCode': PropertySchema(
      id: 0,
      name: r'conversationCode',
      type: IsarType.string,
    ),
    r'conversationType': PropertySchema(
      id: 1,
      name: r'conversationType',
      type: IsarType.string,
    ),
    r'id': PropertySchema(id: 2, name: r'id', type: IsarType.long),
    r'lastSyncedAt': PropertySchema(
      id: 3,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'lastUnreadAt': PropertySchema(
      id: 4,
      name: r'lastUnreadAt',
      type: IsarType.dateTime,
    ),
    r'lastUnreadMessageCode': PropertySchema(
      id: 5,
      name: r'lastUnreadMessageCode',
      type: IsarType.string,
    ),
    r'organizationCode': PropertySchema(
      id: 6,
      name: r'organizationCode',
      type: IsarType.string,
    ),
    r'schoolCode': PropertySchema(
      id: 7,
      name: r'schoolCode',
      type: IsarType.string,
    ),
    r'unreadCount': PropertySchema(
      id: 8,
      name: r'unreadCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _unreadEntityCollectionEstimateSize,
  serialize: _unreadEntityCollectionSerialize,
  deserialize: _unreadEntityCollectionDeserialize,
  deserializeProp: _unreadEntityCollectionDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'conversationCode': IndexSchema(
      id: 4813646130077065260,
      name: r'conversationCode',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'conversationCode',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'conversationType': IndexSchema(
      id: -358869070590991043,
      name: r'conversationType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'conversationType',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'organizationCode': IndexSchema(
      id: -3845389455591461273,
      name: r'organizationCode',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'organizationCode',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'schoolCode': IndexSchema(
      id: 5571938165117852778,
      name: r'schoolCode',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'schoolCode',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _unreadEntityCollectionGetId,
  getLinks: _unreadEntityCollectionGetLinks,
  attach: _unreadEntityCollectionAttach,
  version: '3.3.2',
);

int _unreadEntityCollectionEstimateSize(
  UnreadEntityCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.conversationCode.length * 3;
  bytesCount += 3 + object.conversationType.length * 3;
  {
    final value = object.lastUnreadMessageCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.organizationCode.length * 3;
  bytesCount += 3 + object.schoolCode.length * 3;
  return bytesCount;
}

void _unreadEntityCollectionSerialize(
  UnreadEntityCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.conversationCode);
  writer.writeString(offsets[1], object.conversationType);
  writer.writeLong(offsets[2], object.id);
  writer.writeDateTime(offsets[3], object.lastSyncedAt);
  writer.writeDateTime(offsets[4], object.lastUnreadAt);
  writer.writeString(offsets[5], object.lastUnreadMessageCode);
  writer.writeString(offsets[6], object.organizationCode);
  writer.writeString(offsets[7], object.schoolCode);
  writer.writeLong(offsets[8], object.unreadCount);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

UnreadEntityCollection _unreadEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UnreadEntityCollection();
  object.conversationCode = reader.readString(offsets[0]);
  object.conversationType = reader.readString(offsets[1]);
  object.id = reader.readLong(offsets[2]);
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[3]);
  object.lastUnreadAt = reader.readDateTimeOrNull(offsets[4]);
  object.lastUnreadMessageCode = reader.readStringOrNull(offsets[5]);
  object.organizationCode = reader.readString(offsets[6]);
  object.schoolCode = reader.readString(offsets[7]);
  object.unreadCount = reader.readLong(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  return object;
}

P _unreadEntityCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _unreadEntityCollectionGetId(UnreadEntityCollection object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _unreadEntityCollectionGetLinks(
  UnreadEntityCollection object,
) {
  return [];
}

void _unreadEntityCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  UnreadEntityCollection object,
) {}

extension UnreadEntityCollectionByIndex
    on IsarCollection<UnreadEntityCollection> {
  Future<UnreadEntityCollection?> getByConversationCode(
    String conversationCode,
  ) {
    return getByIndex(r'conversationCode', [conversationCode]);
  }

  UnreadEntityCollection? getByConversationCodeSync(String conversationCode) {
    return getByIndexSync(r'conversationCode', [conversationCode]);
  }

  Future<bool> deleteByConversationCode(String conversationCode) {
    return deleteByIndex(r'conversationCode', [conversationCode]);
  }

  bool deleteByConversationCodeSync(String conversationCode) {
    return deleteByIndexSync(r'conversationCode', [conversationCode]);
  }

  Future<List<UnreadEntityCollection?>> getAllByConversationCode(
    List<String> conversationCodeValues,
  ) {
    final values = conversationCodeValues.map((e) => [e]).toList();
    return getAllByIndex(r'conversationCode', values);
  }

  List<UnreadEntityCollection?> getAllByConversationCodeSync(
    List<String> conversationCodeValues,
  ) {
    final values = conversationCodeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'conversationCode', values);
  }

  Future<int> deleteAllByConversationCode(List<String> conversationCodeValues) {
    final values = conversationCodeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'conversationCode', values);
  }

  int deleteAllByConversationCodeSync(List<String> conversationCodeValues) {
    final values = conversationCodeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'conversationCode', values);
  }

  Future<Id> putByConversationCode(UnreadEntityCollection object) {
    return putByIndex(r'conversationCode', object);
  }

  Id putByConversationCodeSync(
    UnreadEntityCollection object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'conversationCode', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByConversationCode(
    List<UnreadEntityCollection> objects,
  ) {
    return putAllByIndex(r'conversationCode', objects);
  }

  List<Id> putAllByConversationCodeSync(
    List<UnreadEntityCollection> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'conversationCode',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension UnreadEntityCollectionQueryWhereSort
    on QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QWhere> {
  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UnreadEntityCollectionQueryWhere
    on
        QueryBuilder<
          UnreadEntityCollection,
          UnreadEntityCollection,
          QWhereClause
        > {
  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
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

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  conversationCodeEqualTo(String conversationCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'conversationCode',
          value: [conversationCode],
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  conversationCodeNotEqualTo(String conversationCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationCode',
                lower: [],
                upper: [conversationCode],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationCode',
                lower: [conversationCode],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationCode',
                lower: [conversationCode],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationCode',
                lower: [],
                upper: [conversationCode],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  conversationTypeEqualTo(String conversationType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'conversationType',
          value: [conversationType],
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  conversationTypeNotEqualTo(String conversationType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationType',
                lower: [],
                upper: [conversationType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationType',
                lower: [conversationType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationType',
                lower: [conversationType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conversationType',
                lower: [],
                upper: [conversationType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  organizationCodeEqualTo(String organizationCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'organizationCode',
          value: [organizationCode],
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  organizationCodeNotEqualTo(String organizationCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'organizationCode',
                lower: [],
                upper: [organizationCode],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'organizationCode',
                lower: [organizationCode],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'organizationCode',
                lower: [organizationCode],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'organizationCode',
                lower: [],
                upper: [organizationCode],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  schoolCodeEqualTo(String schoolCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'schoolCode', value: [schoolCode]),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterWhereClause
  >
  schoolCodeNotEqualTo(String schoolCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'schoolCode',
                lower: [],
                upper: [schoolCode],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'schoolCode',
                lower: [schoolCode],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'schoolCode',
                lower: [schoolCode],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'schoolCode',
                lower: [],
                upper: [schoolCode],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension UnreadEntityCollectionQueryFilter
    on
        QueryBuilder<
          UnreadEntityCollection,
          UnreadEntityCollection,
          QFilterCondition
        > {
  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conversationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conversationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conversationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conversationCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conversationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conversationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conversationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conversationCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conversationCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conversationCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conversationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conversationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conversationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conversationType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conversationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conversationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conversationType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conversationType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conversationType', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  conversationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conversationType', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  idGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  idLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  idBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  isarIdGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  isarIdLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSyncedAt'),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSyncedAt'),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncedAt', value: value),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastSyncedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastSyncedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUnreadAt'),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUnreadAt'),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUnreadAt', value: value),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUnreadAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUnreadAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUnreadAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUnreadMessageCode'),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUnreadMessageCode'),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastUnreadMessageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUnreadMessageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUnreadMessageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUnreadMessageCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastUnreadMessageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastUnreadMessageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastUnreadMessageCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastUnreadMessageCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUnreadMessageCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  lastUnreadMessageCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'lastUnreadMessageCode',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'organizationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'organizationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'organizationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'organizationCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'organizationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'organizationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'organizationCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'organizationCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'organizationCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  organizationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'organizationCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'schoolCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'schoolCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'schoolCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'schoolCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'schoolCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'schoolCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'schoolCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'schoolCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'schoolCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  schoolCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'schoolCode', value: ''),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  unreadCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unreadCount', value: value),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  unreadCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unreadCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  unreadCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unreadCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  unreadCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unreadCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    UnreadEntityCollection,
    UnreadEntityCollection,
    QAfterFilterCondition
  >
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension UnreadEntityCollectionQueryObject
    on
        QueryBuilder<
          UnreadEntityCollection,
          UnreadEntityCollection,
          QFilterCondition
        > {}

extension UnreadEntityCollectionQueryLinks
    on
        QueryBuilder<
          UnreadEntityCollection,
          UnreadEntityCollection,
          QFilterCondition
        > {}

extension UnreadEntityCollectionQuerySortBy
    on QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QSortBy> {
  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByConversationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByConversationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByConversationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationType', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByConversationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationType', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByLastUnreadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadAt', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByLastUnreadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadAt', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByLastUnreadMessageCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadMessageCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByLastUnreadMessageCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadMessageCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UnreadEntityCollectionQuerySortThenBy
    on
        QueryBuilder<
          UnreadEntityCollection,
          UnreadEntityCollection,
          QSortThenBy
        > {
  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByConversationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByConversationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByConversationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationType', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByConversationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationType', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByLastUnreadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadAt', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByLastUnreadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadAt', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByLastUnreadMessageCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadMessageCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByLastUnreadMessageCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUnreadMessageCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UnreadEntityCollectionQueryWhereDistinct
    on QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct> {
  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByConversationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'conversationCode',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByConversationType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'conversationType',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctById() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id');
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByLastUnreadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUnreadAt');
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByLastUnreadMessageCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastUnreadMessageCode',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByOrganizationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'organizationCode',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctBySchoolCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schoolCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unreadCount');
    });
  }

  QueryBuilder<UnreadEntityCollection, UnreadEntityCollection, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension UnreadEntityCollectionQueryProperty
    on
        QueryBuilder<
          UnreadEntityCollection,
          UnreadEntityCollection,
          QQueryProperty
        > {
  QueryBuilder<UnreadEntityCollection, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<UnreadEntityCollection, String, QQueryOperations>
  conversationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conversationCode');
    });
  }

  QueryBuilder<UnreadEntityCollection, String, QQueryOperations>
  conversationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conversationType');
    });
  }

  QueryBuilder<UnreadEntityCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UnreadEntityCollection, DateTime?, QQueryOperations>
  lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<UnreadEntityCollection, DateTime?, QQueryOperations>
  lastUnreadAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUnreadAt');
    });
  }

  QueryBuilder<UnreadEntityCollection, String?, QQueryOperations>
  lastUnreadMessageCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUnreadMessageCode');
    });
  }

  QueryBuilder<UnreadEntityCollection, String, QQueryOperations>
  organizationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationCode');
    });
  }

  QueryBuilder<UnreadEntityCollection, String, QQueryOperations>
  schoolCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schoolCode');
    });
  }

  QueryBuilder<UnreadEntityCollection, int, QQueryOperations>
  unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unreadCount');
    });
  }

  QueryBuilder<UnreadEntityCollection, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
