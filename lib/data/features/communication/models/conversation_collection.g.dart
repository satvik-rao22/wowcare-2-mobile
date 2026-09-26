// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConversationCollectionCollection on Isar {
  IsarCollection<ConversationCollection> get conversationCollections =>
      this.collection();
}

const ConversationCollectionSchema = CollectionSchema(
  name: r'ConversationCollection',
  id: -7341108499240689352,
  properties: {
    r'avatarUrl': PropertySchema(
      id: 0,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'classroomCode': PropertySchema(
      id: 1,
      name: r'classroomCode',
      type: IsarType.string,
    ),
    r'code': PropertySchema(id: 2, name: r'code', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdBy': PropertySchema(
      id: 4,
      name: r'createdBy',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'id': PropertySchema(id: 6, name: r'id', type: IsarType.long),
    r'lastMessageAt': PropertySchema(
      id: 7,
      name: r'lastMessageAt',
      type: IsarType.dateTime,
    ),
    r'lastMessageBy': PropertySchema(
      id: 8,
      name: r'lastMessageBy',
      type: IsarType.string,
    ),
    r'lastMessagePreview': PropertySchema(
      id: 9,
      name: r'lastMessagePreview',
      type: IsarType.string,
    ),
    r'lastMessageSenderName': PropertySchema(
      id: 10,
      name: r'lastMessageSenderName',
      type: IsarType.string,
    ),
    r'organizationCode': PropertySchema(
      id: 11,
      name: r'organizationCode',
      type: IsarType.string,
    ),
    r'participantCount': PropertySchema(
      id: 12,
      name: r'participantCount',
      type: IsarType.long,
    ),
    r'participants': PropertySchema(
      id: 13,
      name: r'participants',
      type: IsarType.objectList,

      target: r'ConversationParticipantCollection',
    ),
    r'privateModeActivatedAt': PropertySchema(
      id: 14,
      name: r'privateModeActivatedAt',
      type: IsarType.dateTime,
    ),
    r'privateModeActivatedBy': PropertySchema(
      id: 15,
      name: r'privateModeActivatedBy',
      type: IsarType.string,
    ),
    r'privateModeActive': PropertySchema(
      id: 16,
      name: r'privateModeActive',
      type: IsarType.bool,
    ),
    r'schoolCode': PropertySchema(
      id: 17,
      name: r'schoolCode',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 18, name: r'status', type: IsarType.string),
    r'studentStatus': PropertySchema(
      id: 19,
      name: r'studentStatus',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 20, name: r'title', type: IsarType.string),
    r'type': PropertySchema(id: 21, name: r'type', type: IsarType.string),
    r'unreadCount': PropertySchema(
      id: 22,
      name: r'unreadCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 23,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'updatedBy': PropertySchema(
      id: 24,
      name: r'updatedBy',
      type: IsarType.string,
    ),
  },

  estimateSize: _conversationCollectionEstimateSize,
  serialize: _conversationCollectionSerialize,
  deserialize: _conversationCollectionDeserialize,
  deserializeProp: _conversationCollectionDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'ConversationParticipantCollection':
        ConversationParticipantCollectionSchema,
  },

  getId: _conversationCollectionGetId,
  getLinks: _conversationCollectionGetLinks,
  attach: _conversationCollectionAttach,
  version: '3.3.2',
);

int _conversationCollectionEstimateSize(
  ConversationCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.avatarUrl.length * 3;
  {
    final value = object.classroomCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.createdBy.length * 3;
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.lastMessageBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.lastMessagePreview.length * 3;
  {
    final value = object.lastMessageSenderName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.organizationCode.length * 3;
  {
    final list = object.participants;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[ConversationParticipantCollection]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += ConversationParticipantCollectionSchema.estimateSize(
            value,
            offsets,
            allOffsets,
          );
        }
      }
    }
  }
  {
    final value = object.privateModeActivatedBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.schoolCode.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.studentStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.length * 3;
  bytesCount += 3 + object.updatedBy.length * 3;
  return bytesCount;
}

void _conversationCollectionSerialize(
  ConversationCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarUrl);
  writer.writeString(offsets[1], object.classroomCode);
  writer.writeString(offsets[2], object.code);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.createdBy);
  writer.writeString(offsets[5], object.description);
  writer.writeLong(offsets[6], object.id);
  writer.writeDateTime(offsets[7], object.lastMessageAt);
  writer.writeString(offsets[8], object.lastMessageBy);
  writer.writeString(offsets[9], object.lastMessagePreview);
  writer.writeString(offsets[10], object.lastMessageSenderName);
  writer.writeString(offsets[11], object.organizationCode);
  writer.writeLong(offsets[12], object.participantCount);
  writer.writeObjectList<ConversationParticipantCollection>(
    offsets[13],
    allOffsets,
    ConversationParticipantCollectionSchema.serialize,
    object.participants,
  );
  writer.writeDateTime(offsets[14], object.privateModeActivatedAt);
  writer.writeString(offsets[15], object.privateModeActivatedBy);
  writer.writeBool(offsets[16], object.privateModeActive);
  writer.writeString(offsets[17], object.schoolCode);
  writer.writeString(offsets[18], object.status);
  writer.writeString(offsets[19], object.studentStatus);
  writer.writeString(offsets[20], object.title);
  writer.writeString(offsets[21], object.type);
  writer.writeLong(offsets[22], object.unreadCount);
  writer.writeDateTime(offsets[23], object.updatedAt);
  writer.writeString(offsets[24], object.updatedBy);
}

ConversationCollection _conversationCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConversationCollection();
  object.avatarUrl = reader.readString(offsets[0]);
  object.classroomCode = reader.readStringOrNull(offsets[1]);
  object.code = reader.readString(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.createdBy = reader.readString(offsets[4]);
  object.description = reader.readString(offsets[5]);
  object.id = reader.readLong(offsets[6]);
  object.lastMessageAt = reader.readDateTimeOrNull(offsets[7]);
  object.lastMessageBy = reader.readStringOrNull(offsets[8]);
  object.lastMessagePreview = reader.readString(offsets[9]);
  object.lastMessageSenderName = reader.readStringOrNull(offsets[10]);
  object.organizationCode = reader.readString(offsets[11]);
  object.participantCount = reader.readLong(offsets[12]);
  object.participants = reader
      .readObjectList<ConversationParticipantCollection>(
        offsets[13],
        ConversationParticipantCollectionSchema.deserialize,
        allOffsets,
        ConversationParticipantCollection(),
      );
  object.privateModeActivatedAt = reader.readDateTimeOrNull(offsets[14]);
  object.privateModeActivatedBy = reader.readStringOrNull(offsets[15]);
  object.privateModeActive = reader.readBool(offsets[16]);
  object.schoolCode = reader.readString(offsets[17]);
  object.status = reader.readString(offsets[18]);
  object.studentStatus = reader.readStringOrNull(offsets[19]);
  object.title = reader.readString(offsets[20]);
  object.type = reader.readString(offsets[21]);
  object.unreadCount = reader.readLong(offsets[22]);
  object.updatedAt = reader.readDateTime(offsets[23]);
  object.updatedBy = reader.readString(offsets[24]);
  return object;
}

P _conversationCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readObjectList<ConversationParticipantCollection>(
            offset,
            ConversationParticipantCollectionSchema.deserialize,
            allOffsets,
            ConversationParticipantCollection(),
          ))
          as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    case 23:
      return (reader.readDateTime(offset)) as P;
    case 24:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _conversationCollectionGetId(ConversationCollection object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _conversationCollectionGetLinks(
  ConversationCollection object,
) {
  return [];
}

void _conversationCollectionAttach(
  IsarCollection<dynamic> col,
  Id id,
  ConversationCollection object,
) {}

extension ConversationCollectionQueryWhereSort
    on QueryBuilder<ConversationCollection, ConversationCollection, QWhere> {
  QueryBuilder<ConversationCollection, ConversationCollection, QAfterWhere>
  anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ConversationCollectionQueryWhere
    on
        QueryBuilder<
          ConversationCollection,
          ConversationCollection,
          QWhereClause
        > {
  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
}

extension ConversationCollectionQueryFilter
    on
        QueryBuilder<
          ConversationCollection,
          ConversationCollection,
          QFilterCondition
        > {
  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'avatarUrl',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'avatarUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'avatarUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'avatarUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'classroomCode'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'classroomCode'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'classroomCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'classroomCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'classroomCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'classroomCode',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'classroomCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'classroomCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'classroomCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'classroomCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'classroomCode', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  classroomCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'classroomCode', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'code',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'code',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'code',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'code',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'code',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'code',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'code',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'code',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'code', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'code', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdBy',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'createdBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'createdBy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdBy', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'createdBy', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'description',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'description',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'description',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'description', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastMessageAt'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastMessageAt'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastMessageAt', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastMessageAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastMessageAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastMessageAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastMessageBy'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastMessageBy'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastMessageBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastMessageBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastMessageBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastMessageBy',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastMessageBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastMessageBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastMessageBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastMessageBy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastMessageBy', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastMessageBy', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastMessagePreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastMessagePreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastMessagePreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastMessagePreview',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastMessagePreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastMessagePreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastMessagePreview',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastMessagePreview',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastMessagePreview', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessagePreviewIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastMessagePreview', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastMessageSenderName'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastMessageSenderName'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastMessageSenderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastMessageSenderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastMessageSenderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastMessageSenderName',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastMessageSenderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastMessageSenderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastMessageSenderName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastMessageSenderName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastMessageSenderName', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  lastMessageSenderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'lastMessageSenderName',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'participantCount', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'participantCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'participantCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'participantCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'participants'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'participants'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'participants', length, true, length, true);
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'participants', 0, true, 0, true);
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'participants', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'participants', 0, true, length, include);
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'participants', length, include, 999999, true);
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'privateModeActivatedAt'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'privateModeActivatedAt'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'privateModeActivatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'privateModeActivatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'privateModeActivatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'privateModeActivatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'privateModeActivatedBy'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'privateModeActivatedBy'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'privateModeActivatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'privateModeActivatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'privateModeActivatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'privateModeActivatedBy',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'privateModeActivatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'privateModeActivatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'privateModeActivatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'privateModeActivatedBy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'privateModeActivatedBy', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActivatedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'privateModeActivatedBy',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  privateModeActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'privateModeActive', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'studentStatus'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'studentStatus'),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'studentStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'studentStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'studentStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'studentStatus',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'studentStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'studentStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'studentStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'studentStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'studentStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  studentStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'studentStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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
    ConversationCollection,
    ConversationCollection,
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

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedBy',
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
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'updatedBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'updatedBy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedBy', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  updatedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'updatedBy', value: ''),
      );
    });
  }
}

extension ConversationCollectionQueryObject
    on
        QueryBuilder<
          ConversationCollection,
          ConversationCollection,
          QFilterCondition
        > {
  QueryBuilder<
    ConversationCollection,
    ConversationCollection,
    QAfterFilterCondition
  >
  participantsElement(FilterQuery<ConversationParticipantCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'participants');
    });
  }
}

extension ConversationCollectionQueryLinks
    on
        QueryBuilder<
          ConversationCollection,
          ConversationCollection,
          QFilterCondition
        > {}

extension ConversationCollectionQuerySortBy
    on QueryBuilder<ConversationCollection, ConversationCollection, QSortBy> {
  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByClassroomCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByClassroomCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessageBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessageByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessagePreview() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessagePreviewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessageSenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByLastMessageSenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByParticipantCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByPrivateModeActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByPrivateModeActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByPrivateModeActivatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByPrivateModeActivatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByPrivateModeActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByPrivateModeActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByStudentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentStatus', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByStudentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentStatus', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByUpdatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  sortByUpdatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.desc);
    });
  }
}

extension ConversationCollectionQuerySortThenBy
    on
        QueryBuilder<
          ConversationCollection,
          ConversationCollection,
          QSortThenBy
        > {
  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByClassroomCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByClassroomCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessageBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessageByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessagePreview() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessagePreviewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessageSenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByLastMessageSenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByParticipantCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByPrivateModeActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByPrivateModeActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByPrivateModeActivatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByPrivateModeActivatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByPrivateModeActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByPrivateModeActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByStudentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentStatus', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByStudentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentStatus', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByUpdatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QAfterSortBy>
  thenByUpdatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.desc);
    });
  }
}

extension ConversationCollectionQueryWhereDistinct
    on QueryBuilder<ConversationCollection, ConversationCollection, QDistinct> {
  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByAvatarUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByClassroomCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'classroomCode',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByCreatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctById() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageAt');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByLastMessageBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastMessageBy',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByLastMessagePreview({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastMessagePreview',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByLastMessageSenderName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastMessageSenderName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByOrganizationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'organizationCode',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'participantCount');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByPrivateModeActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateModeActivatedAt');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByPrivateModeActivatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'privateModeActivatedBy',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByPrivateModeActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateModeActive');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctBySchoolCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schoolCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByStudentStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'studentStatus',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unreadCount');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ConversationCollection, ConversationCollection, QDistinct>
  distinctByUpdatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedBy', caseSensitive: caseSensitive);
    });
  }
}

extension ConversationCollectionQueryProperty
    on
        QueryBuilder<
          ConversationCollection,
          ConversationCollection,
          QQueryProperty
        > {
  QueryBuilder<ConversationCollection, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarUrl');
    });
  }

  QueryBuilder<ConversationCollection, String?, QQueryOperations>
  classroomCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'classroomCode');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<ConversationCollection, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ConversationCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ConversationCollection, DateTime?, QQueryOperations>
  lastMessageAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageAt');
    });
  }

  QueryBuilder<ConversationCollection, String?, QQueryOperations>
  lastMessageByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageBy');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  lastMessagePreviewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessagePreview');
    });
  }

  QueryBuilder<ConversationCollection, String?, QQueryOperations>
  lastMessageSenderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageSenderName');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  organizationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationCode');
    });
  }

  QueryBuilder<ConversationCollection, int, QQueryOperations>
  participantCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participantCount');
    });
  }

  QueryBuilder<
    ConversationCollection,
    List<ConversationParticipantCollection>?,
    QQueryOperations
  >
  participantsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participants');
    });
  }

  QueryBuilder<ConversationCollection, DateTime?, QQueryOperations>
  privateModeActivatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeActivatedAt');
    });
  }

  QueryBuilder<ConversationCollection, String?, QQueryOperations>
  privateModeActivatedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeActivatedBy');
    });
  }

  QueryBuilder<ConversationCollection, bool, QQueryOperations>
  privateModeActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeActive');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  schoolCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schoolCode');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<ConversationCollection, String?, QQueryOperations>
  studentStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentStatus');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<ConversationCollection, int, QQueryOperations>
  unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unreadCount');
    });
  }

  QueryBuilder<ConversationCollection, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ConversationCollection, String, QQueryOperations>
  updatedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedBy');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ConversationParticipantCollectionSchema = Schema(
  name: r'ConversationParticipantCollection',
  id: 4457480724760800877,
  properties: {
    r'active': PropertySchema(id: 0, name: r'active', type: IsarType.bool),
    r'avatarUrl': PropertySchema(
      id: 1,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'conversationId': PropertySchema(
      id: 2,
      name: r'conversationId',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'id': PropertySchema(id: 4, name: r'id', type: IsarType.long),
    r'joinedAt': PropertySchema(
      id: 5,
      name: r'joinedAt',
      type: IsarType.dateTime,
    ),
    r'lastReadAt': PropertySchema(
      id: 6,
      name: r'lastReadAt',
      type: IsarType.dateTime,
    ),
    r'leftAt': PropertySchema(id: 7, name: r'leftAt', type: IsarType.dateTime),
    r'muted': PropertySchema(id: 8, name: r'muted', type: IsarType.bool),
    r'notificationsEnabled': PropertySchema(
      id: 9,
      name: r'notificationsEnabled',
      type: IsarType.bool,
    ),
    r'role': PropertySchema(id: 10, name: r'role', type: IsarType.string),
    r'staffCode': PropertySchema(
      id: 11,
      name: r'staffCode',
      type: IsarType.string,
    ),
    r'staffStatus': PropertySchema(
      id: 12,
      name: r'staffStatus',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userCode': PropertySchema(
      id: 14,
      name: r'userCode',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 15,
      name: r'userName',
      type: IsarType.string,
    ),
  },

  estimateSize: _conversationParticipantCollectionEstimateSize,
  serialize: _conversationParticipantCollectionSerialize,
  deserialize: _conversationParticipantCollectionDeserialize,
  deserializeProp: _conversationParticipantCollectionDeserializeProp,
);

int _conversationParticipantCollectionEstimateSize(
  ConversationParticipantCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.role.length * 3;
  {
    final value = object.staffCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.staffStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userCode.length * 3;
  bytesCount += 3 + object.userName.length * 3;
  return bytesCount;
}

void _conversationParticipantCollectionSerialize(
  ConversationParticipantCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeString(offsets[1], object.avatarUrl);
  writer.writeLong(offsets[2], object.conversationId);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeLong(offsets[4], object.id);
  writer.writeDateTime(offsets[5], object.joinedAt);
  writer.writeDateTime(offsets[6], object.lastReadAt);
  writer.writeDateTime(offsets[7], object.leftAt);
  writer.writeBool(offsets[8], object.muted);
  writer.writeBool(offsets[9], object.notificationsEnabled);
  writer.writeString(offsets[10], object.role);
  writer.writeString(offsets[11], object.staffCode);
  writer.writeString(offsets[12], object.staffStatus);
  writer.writeDateTime(offsets[13], object.updatedAt);
  writer.writeString(offsets[14], object.userCode);
  writer.writeString(offsets[15], object.userName);
}

ConversationParticipantCollection _conversationParticipantCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConversationParticipantCollection();
  object.active = reader.readBoolOrNull(offsets[0]);
  object.avatarUrl = reader.readStringOrNull(offsets[1]);
  object.conversationId = reader.readLong(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = reader.readLong(offsets[4]);
  object.joinedAt = reader.readDateTime(offsets[5]);
  object.lastReadAt = reader.readDateTimeOrNull(offsets[6]);
  object.leftAt = reader.readDateTimeOrNull(offsets[7]);
  object.muted = reader.readBoolOrNull(offsets[8]);
  object.notificationsEnabled = reader.readBoolOrNull(offsets[9]);
  object.role = reader.readString(offsets[10]);
  object.staffCode = reader.readStringOrNull(offsets[11]);
  object.staffStatus = reader.readStringOrNull(offsets[12]);
  object.updatedAt = reader.readDateTime(offsets[13]);
  object.userCode = reader.readString(offsets[14]);
  object.userName = reader.readString(offsets[15]);
  return object;
}

P _conversationParticipantCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset)) as P;
    case 9:
      return (reader.readBoolOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ConversationParticipantCollectionQueryFilter
    on
        QueryBuilder<
          ConversationParticipantCollection,
          ConversationParticipantCollection,
          QFilterCondition
        > {
  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  activeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'active'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  activeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'active'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  activeEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'active', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'avatarUrl'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'avatarUrl'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'avatarUrl',
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'avatarUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'avatarUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'avatarUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'avatarUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  conversationIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conversationId', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  conversationIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conversationId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  conversationIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conversationId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  conversationIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conversationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  joinedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'joinedAt', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  joinedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'joinedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  joinedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'joinedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  joinedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'joinedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  lastReadAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastReadAt'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  lastReadAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastReadAt'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  lastReadAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastReadAt', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  lastReadAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastReadAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  lastReadAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastReadAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  lastReadAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastReadAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  leftAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'leftAt'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  leftAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'leftAt'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  leftAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'leftAt', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  leftAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'leftAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  leftAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'leftAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  leftAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'leftAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  mutedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'muted'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  mutedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'muted'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  mutedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'muted', value: value),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  notificationsEnabledIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notificationsEnabled'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  notificationsEnabledIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notificationsEnabled'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  notificationsEnabledEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notificationsEnabled',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'role',
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'role',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'staffCode'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'staffCode'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'staffCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'staffCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'staffCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'staffCode',
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'staffCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'staffCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'staffCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'staffCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'staffCode', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'staffCode', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'staffStatus'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'staffStatus'),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'staffStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'staffStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'staffStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'staffStatus',
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'staffStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'staffStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'staffStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'staffStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'staffStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  staffStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'staffStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
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

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userCode',
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userCode', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userCode', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userName',
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
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userName', value: ''),
      );
    });
  }

  QueryBuilder<
    ConversationParticipantCollection,
    ConversationParticipantCollection,
    QAfterFilterCondition
  >
  userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userName', value: ''),
      );
    });
  }
}

extension ConversationParticipantCollectionQueryObject
    on
        QueryBuilder<
          ConversationParticipantCollection,
          ConversationParticipantCollection,
          QFilterCondition
        > {}
