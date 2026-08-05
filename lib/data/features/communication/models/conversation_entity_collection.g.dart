// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_entity_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConversationEntityCollectionCollection on Isar {
  IsarCollection<ConversationEntityCollection>
      get conversationEntityCollections => this.collection();
}

const ConversationEntityCollectionSchema = CollectionSchema(
  name: r'ConversationEntityCollection',
  id: 8564550651245806416,
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
    r'code': PropertySchema(
      id: 2,
      name: r'code',
      type: IsarType.string,
    ),
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
    r'id': PropertySchema(
      id: 6,
      name: r'id',
      type: IsarType.long,
    ),
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
    r'lastSyncedAt': PropertySchema(
      id: 11,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'localOnly': PropertySchema(
      id: 12,
      name: r'localOnly',
      type: IsarType.bool,
    ),
    r'organizationCode': PropertySchema(
      id: 13,
      name: r'organizationCode',
      type: IsarType.string,
    ),
    r'participantCount': PropertySchema(
      id: 14,
      name: r'participantCount',
      type: IsarType.long,
    ),
    r'participants': PropertySchema(
      id: 15,
      name: r'participants',
      type: IsarType.objectList,
      target: r'ParticipantEntityCollection',
    ),
    r'pendingDelete': PropertySchema(
      id: 16,
      name: r'pendingDelete',
      type: IsarType.bool,
    ),
    r'privateModeActivatedAt': PropertySchema(
      id: 17,
      name: r'privateModeActivatedAt',
      type: IsarType.dateTime,
    ),
    r'privateModeActivatedBy': PropertySchema(
      id: 18,
      name: r'privateModeActivatedBy',
      type: IsarType.string,
    ),
    r'privateModeActive': PropertySchema(
      id: 19,
      name: r'privateModeActive',
      type: IsarType.bool,
    ),
    r'privateModeStatesJson': PropertySchema(
      id: 20,
      name: r'privateModeStatesJson',
      type: IsarType.string,
    ),
    r'schoolCode': PropertySchema(
      id: 21,
      name: r'schoolCode',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 22,
      name: r'status',
      type: IsarType.string,
    ),
    r'studentCode': PropertySchema(
      id: 23,
      name: r'studentCode',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 24,
      name: r'title',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 25,
      name: r'type',
      type: IsarType.string,
    ),
    r'unreadCount': PropertySchema(
      id: 26,
      name: r'unreadCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 27,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'updatedBy': PropertySchema(
      id: 28,
      name: r'updatedBy',
      type: IsarType.string,
    )
  },
  estimateSize: _conversationEntityCollectionEstimateSize,
  serialize: _conversationEntityCollectionSerialize,
  deserialize: _conversationEntityCollectionDeserialize,
  deserializeProp: _conversationEntityCollectionDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'code': IndexSchema(
      id: 329780482934683790,
      name: r'code',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'code',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'studentCode': IndexSchema(
      id: 3982672933658509782,
      name: r'studentCode',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'studentCode',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'lastMessageAt': IndexSchema(
      id: -4158431681644325911,
      name: r'lastMessageAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastMessageAt',
          type: IndexType.value,
          caseSensitive: false,
        )
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
        )
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
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'ParticipantEntityCollection': ParticipantEntityCollectionSchema
  },
  getId: _conversationEntityCollectionGetId,
  getLinks: _conversationEntityCollectionGetLinks,
  attach: _conversationEntityCollectionAttach,
  version: '3.1.0+1',
);

int _conversationEntityCollectionEstimateSize(
  ConversationEntityCollection object,
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
        final offsets = allOffsets[ParticipantEntityCollection]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += ParticipantEntityCollectionSchema.estimateSize(
              value, offsets, allOffsets);
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
  {
    final value = object.privateModeStatesJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.schoolCode.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.studentCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.length * 3;
  bytesCount += 3 + object.updatedBy.length * 3;
  return bytesCount;
}

void _conversationEntityCollectionSerialize(
  ConversationEntityCollection object,
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
  writer.writeDateTime(offsets[11], object.lastSyncedAt);
  writer.writeBool(offsets[12], object.localOnly);
  writer.writeString(offsets[13], object.organizationCode);
  writer.writeLong(offsets[14], object.participantCount);
  writer.writeObjectList<ParticipantEntityCollection>(
    offsets[15],
    allOffsets,
    ParticipantEntityCollectionSchema.serialize,
    object.participants,
  );
  writer.writeBool(offsets[16], object.pendingDelete);
  writer.writeDateTime(offsets[17], object.privateModeActivatedAt);
  writer.writeString(offsets[18], object.privateModeActivatedBy);
  writer.writeBool(offsets[19], object.privateModeActive);
  writer.writeString(offsets[20], object.privateModeStatesJson);
  writer.writeString(offsets[21], object.schoolCode);
  writer.writeString(offsets[22], object.status);
  writer.writeString(offsets[23], object.studentCode);
  writer.writeString(offsets[24], object.title);
  writer.writeString(offsets[25], object.type);
  writer.writeLong(offsets[26], object.unreadCount);
  writer.writeDateTime(offsets[27], object.updatedAt);
  writer.writeString(offsets[28], object.updatedBy);
}

ConversationEntityCollection _conversationEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConversationEntityCollection();
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
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[11]);
  object.localOnly = reader.readBool(offsets[12]);
  object.organizationCode = reader.readString(offsets[13]);
  object.participantCount = reader.readLong(offsets[14]);
  object.participants = reader.readObjectList<ParticipantEntityCollection>(
    offsets[15],
    ParticipantEntityCollectionSchema.deserialize,
    allOffsets,
    ParticipantEntityCollection(),
  );
  object.pendingDelete = reader.readBool(offsets[16]);
  object.privateModeActivatedAt = reader.readDateTimeOrNull(offsets[17]);
  object.privateModeActivatedBy = reader.readStringOrNull(offsets[18]);
  object.privateModeActive = reader.readBool(offsets[19]);
  object.privateModeStatesJson = reader.readStringOrNull(offsets[20]);
  object.schoolCode = reader.readString(offsets[21]);
  object.status = reader.readString(offsets[22]);
  object.studentCode = reader.readStringOrNull(offsets[23]);
  object.title = reader.readString(offsets[24]);
  object.type = reader.readString(offsets[25]);
  object.unreadCount = reader.readLong(offsets[26]);
  object.updatedAt = reader.readDateTime(offsets[27]);
  object.updatedBy = reader.readString(offsets[28]);
  return object;
}

P _conversationEntityCollectionDeserializeProp<P>(
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
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readObjectList<ParticipantEntityCollection>(
        offset,
        ParticipantEntityCollectionSchema.deserialize,
        allOffsets,
        ParticipantEntityCollection(),
      )) as P;
    case 16:
      return (reader.readBool(offset)) as P;
    case 17:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readString(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (reader.readLong(offset)) as P;
    case 27:
      return (reader.readDateTime(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _conversationEntityCollectionGetId(ConversationEntityCollection object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _conversationEntityCollectionGetLinks(
    ConversationEntityCollection object) {
  return [];
}

void _conversationEntityCollectionAttach(
    IsarCollection<dynamic> col, Id id, ConversationEntityCollection object) {}

extension ConversationEntityCollectionByIndex
    on IsarCollection<ConversationEntityCollection> {
  Future<ConversationEntityCollection?> getByCode(String code) {
    return getByIndex(r'code', [code]);
  }

  ConversationEntityCollection? getByCodeSync(String code) {
    return getByIndexSync(r'code', [code]);
  }

  Future<bool> deleteByCode(String code) {
    return deleteByIndex(r'code', [code]);
  }

  bool deleteByCodeSync(String code) {
    return deleteByIndexSync(r'code', [code]);
  }

  Future<List<ConversationEntityCollection?>> getAllByCode(
      List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndex(r'code', values);
  }

  List<ConversationEntityCollection?> getAllByCodeSync(
      List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'code', values);
  }

  Future<int> deleteAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'code', values);
  }

  int deleteAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'code', values);
  }

  Future<Id> putByCode(ConversationEntityCollection object) {
    return putByIndex(r'code', object);
  }

  Id putByCodeSync(ConversationEntityCollection object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'code', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCode(List<ConversationEntityCollection> objects) {
    return putAllByIndex(r'code', objects);
  }

  List<Id> putAllByCodeSync(List<ConversationEntityCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'code', objects, saveLinks: saveLinks);
  }
}

extension ConversationEntityCollectionQueryWhereSort on QueryBuilder<
    ConversationEntityCollection, ConversationEntityCollection, QWhere> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhere> anyLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastMessageAt'),
      );
    });
  }
}

extension ConversationEntityCollectionQueryWhere on QueryBuilder<
    ConversationEntityCollection, ConversationEntityCollection, QWhereClause> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
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

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> codeEqualTo(String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> codeNotEqualTo(String code) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> typeEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> typeNotEqualTo(String type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> studentCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'studentCode',
        value: [null],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> studentCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'studentCode',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> studentCodeEqualTo(String? studentCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'studentCode',
        value: [studentCode],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> studentCodeNotEqualTo(String? studentCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentCode',
              lower: [],
              upper: [studentCode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentCode',
              lower: [studentCode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentCode',
              lower: [studentCode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'studentCode',
              lower: [],
              upper: [studentCode],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastMessageAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastMessageAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtEqualTo(DateTime? lastMessageAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastMessageAt',
        value: [lastMessageAt],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtNotEqualTo(DateTime? lastMessageAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastMessageAt',
              lower: [],
              upper: [lastMessageAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastMessageAt',
              lower: [lastMessageAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastMessageAt',
              lower: [lastMessageAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastMessageAt',
              lower: [],
              upper: [lastMessageAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtGreaterThan(
    DateTime? lastMessageAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastMessageAt',
        lower: [lastMessageAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtLessThan(
    DateTime? lastMessageAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastMessageAt',
        lower: [],
        upper: [lastMessageAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> lastMessageAtBetween(
    DateTime? lowerLastMessageAt,
    DateTime? upperLastMessageAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastMessageAt',
        lower: [lowerLastMessageAt],
        includeLower: includeLower,
        upper: [upperLastMessageAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> organizationCodeEqualTo(String organizationCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'organizationCode',
        value: [organizationCode],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> organizationCodeNotEqualTo(String organizationCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationCode',
              lower: [],
              upper: [organizationCode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationCode',
              lower: [organizationCode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationCode',
              lower: [organizationCode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'organizationCode',
              lower: [],
              upper: [organizationCode],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> schoolCodeEqualTo(String schoolCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'schoolCode',
        value: [schoolCode],
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterWhereClause> schoolCodeNotEqualTo(String schoolCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolCode',
              lower: [],
              upper: [schoolCode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolCode',
              lower: [schoolCode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolCode',
              lower: [schoolCode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'schoolCode',
              lower: [],
              upper: [schoolCode],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ConversationEntityCollectionQueryFilter on QueryBuilder<
    ConversationEntityCollection,
    ConversationEntityCollection,
    QFilterCondition> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'classroomCode',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'classroomCode',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'classroomCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'classroomCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'classroomCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'classroomCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'classroomCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'classroomCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      classroomCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'classroomCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      classroomCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'classroomCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'classroomCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> classroomCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'classroomCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      codeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      codeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      createdByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      createdByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> createdByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> idGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> idLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> idBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
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

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
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

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
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

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageAt',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageAt',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageBy',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageBy',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessageBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessageBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      lastMessageByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessageBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      lastMessageByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessageBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessageBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessagePreview',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessagePreview',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessagePreview',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessagePreview',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessagePreview',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessagePreview',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      lastMessagePreviewContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessagePreview',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      lastMessagePreviewMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessagePreview',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessagePreview',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessagePreviewIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessagePreview',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastMessageSenderName',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastMessageSenderName',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastMessageSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastMessageSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastMessageSenderName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastMessageSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastMessageSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      lastMessageSenderNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastMessageSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      lastMessageSenderNameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastMessageSenderName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastMessageSenderName',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastMessageSenderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastMessageSenderName',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> localOnlyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localOnly',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'organizationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'organizationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'organizationCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'organizationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'organizationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      organizationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'organizationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      organizationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'organizationCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> organizationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'participantCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'participantCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'participantCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'participantCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'participants',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'participants',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'participants',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> participantsLengthBetween(
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

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> pendingDeleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'privateModeActivatedAt',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'privateModeActivatedAt',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateModeActivatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privateModeActivatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privateModeActivatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privateModeActivatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'privateModeActivatedBy',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'privateModeActivatedBy',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateModeActivatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privateModeActivatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privateModeActivatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privateModeActivatedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privateModeActivatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privateModeActivatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      privateModeActivatedByContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privateModeActivatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      privateModeActivatedByMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privateModeActivatedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateModeActivatedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActivatedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privateModeActivatedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateModeActive',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'privateModeStatesJson',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'privateModeStatesJson',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateModeStatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privateModeStatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privateModeStatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privateModeStatesJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privateModeStatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privateModeStatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      privateModeStatesJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privateModeStatesJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      privateModeStatesJsonMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privateModeStatesJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateModeStatesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> privateModeStatesJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privateModeStatesJson',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schoolCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schoolCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schoolCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schoolCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'schoolCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'schoolCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      schoolCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'schoolCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      schoolCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'schoolCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schoolCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> schoolCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'schoolCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'studentCode',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'studentCode',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studentCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      studentCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      studentCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studentCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> studentCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studentCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> unreadCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unreadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> unreadCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unreadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> unreadCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unreadCount',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> unreadCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unreadCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'updatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'updatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      updatedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'updatedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      updatedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'updatedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterFilterCondition> updatedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'updatedBy',
        value: '',
      ));
    });
  }
}

extension ConversationEntityCollectionQueryObject on QueryBuilder<
    ConversationEntityCollection,
    ConversationEntityCollection,
    QFilterCondition> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
          QAfterFilterCondition>
      participantsElement(FilterQuery<ParticipantEntityCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'participants');
    });
  }
}

extension ConversationEntityCollectionQueryLinks on QueryBuilder<
    ConversationEntityCollection,
    ConversationEntityCollection,
    QFilterCondition> {}

extension ConversationEntityCollectionQuerySortBy on QueryBuilder<
    ConversationEntityCollection, ConversationEntityCollection, QSortBy> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByClassroomCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByClassroomCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessageBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessageByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessagePreview() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessagePreviewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessageSenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastMessageSenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByParticipantCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPendingDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeActivatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeActivatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeStatesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeStatesJson', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByPrivateModeStatesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeStatesJson', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByStudentCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByStudentCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByUpdatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> sortByUpdatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.desc);
    });
  }
}

extension ConversationEntityCollectionQuerySortThenBy on QueryBuilder<
    ConversationEntityCollection, ConversationEntityCollection, QSortThenBy> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarUrl', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByClassroomCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByClassroomCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'classroomCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByCreatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByCreatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessageAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessageBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessageByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessagePreview() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessagePreviewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessagePreview', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessageSenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastMessageSenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastMessageSenderName', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByParticipantCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'participantCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPendingDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeActivatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeActivatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActivatedBy', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeActive', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeStatesJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeStatesJson', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByPrivateModeStatesJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateModeStatesJson', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByStudentCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentCode', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByStudentCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentCode', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByUnreadCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadCount', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByUpdatedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.asc);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QAfterSortBy> thenByUpdatedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedBy', Sort.desc);
    });
  }
}

extension ConversationEntityCollectionQueryWhereDistinct on QueryBuilder<
    ConversationEntityCollection, ConversationEntityCollection, QDistinct> {
  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByAvatarUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByClassroomCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'classroomCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByCreatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctById() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByLastMessageAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByLastMessageBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByLastMessagePreview({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessagePreview',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByLastMessageSenderName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastMessageSenderName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localOnly');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByOrganizationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByParticipantCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'participantCount');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingDelete');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByPrivateModeActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateModeActivatedAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByPrivateModeActivatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateModeActivatedBy',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByPrivateModeActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateModeActive');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByPrivateModeStatesJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateModeStatesJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctBySchoolCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schoolCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByStudentCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studentCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByUnreadCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unreadCount');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, ConversationEntityCollection,
      QDistinct> distinctByUpdatedBy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedBy', caseSensitive: caseSensitive);
    });
  }
}

extension ConversationEntityCollectionQueryProperty on QueryBuilder<
    ConversationEntityCollection,
    ConversationEntityCollection,
    QQueryProperty> {
  QueryBuilder<ConversationEntityCollection, int, QQueryOperations>
      isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarUrl');
    });
  }

  QueryBuilder<ConversationEntityCollection, String?, QQueryOperations>
      classroomCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'classroomCode');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<ConversationEntityCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      createdByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdBy');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ConversationEntityCollection, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ConversationEntityCollection, DateTime?, QQueryOperations>
      lastMessageAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, String?, QQueryOperations>
      lastMessageByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageBy');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      lastMessagePreviewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessagePreview');
    });
  }

  QueryBuilder<ConversationEntityCollection, String?, QQueryOperations>
      lastMessageSenderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastMessageSenderName');
    });
  }

  QueryBuilder<ConversationEntityCollection, DateTime?, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, bool, QQueryOperations>
      localOnlyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localOnly');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      organizationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationCode');
    });
  }

  QueryBuilder<ConversationEntityCollection, int, QQueryOperations>
      participantCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participantCount');
    });
  }

  QueryBuilder<ConversationEntityCollection, List<ParticipantEntityCollection>?,
      QQueryOperations> participantsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'participants');
    });
  }

  QueryBuilder<ConversationEntityCollection, bool, QQueryOperations>
      pendingDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingDelete');
    });
  }

  QueryBuilder<ConversationEntityCollection, DateTime?, QQueryOperations>
      privateModeActivatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeActivatedAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, String?, QQueryOperations>
      privateModeActivatedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeActivatedBy');
    });
  }

  QueryBuilder<ConversationEntityCollection, bool, QQueryOperations>
      privateModeActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeActive');
    });
  }

  QueryBuilder<ConversationEntityCollection, String?, QQueryOperations>
      privateModeStatesJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateModeStatesJson');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      schoolCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schoolCode');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<ConversationEntityCollection, String?, QQueryOperations>
      studentCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentCode');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<ConversationEntityCollection, int, QQueryOperations>
      unreadCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unreadCount');
    });
  }

  QueryBuilder<ConversationEntityCollection, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ConversationEntityCollection, String, QQueryOperations>
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

const ParticipantEntityCollectionSchema = Schema(
  name: r'ParticipantEntityCollection',
  id: -4408489523209438956,
  properties: {
    r'avatarUrl': PropertySchema(
      id: 0,
      name: r'avatarUrl',
      type: IsarType.string,
    ),
    r'conversationId': PropertySchema(
      id: 1,
      name: r'conversationId',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.long,
    ),
    r'joinedAt': PropertySchema(
      id: 4,
      name: r'joinedAt',
      type: IsarType.dateTime,
    ),
    r'lastReadAt': PropertySchema(
      id: 5,
      name: r'lastReadAt',
      type: IsarType.dateTime,
    ),
    r'leftAt': PropertySchema(
      id: 6,
      name: r'leftAt',
      type: IsarType.dateTime,
    ),
    r'muted': PropertySchema(
      id: 7,
      name: r'muted',
      type: IsarType.bool,
    ),
    r'notificationsEnabled': PropertySchema(
      id: 8,
      name: r'notificationsEnabled',
      type: IsarType.bool,
    ),
    r'role': PropertySchema(
      id: 9,
      name: r'role',
      type: IsarType.string,
    ),
    r'staffCode': PropertySchema(
      id: 10,
      name: r'staffCode',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userCode': PropertySchema(
      id: 12,
      name: r'userCode',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 13,
      name: r'userName',
      type: IsarType.string,
    )
  },
  estimateSize: _participantEntityCollectionEstimateSize,
  serialize: _participantEntityCollectionSerialize,
  deserialize: _participantEntityCollectionDeserialize,
  deserializeProp: _participantEntityCollectionDeserializeProp,
);

int _participantEntityCollectionEstimateSize(
  ParticipantEntityCollection object,
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
  bytesCount += 3 + object.userCode.length * 3;
  bytesCount += 3 + object.userName.length * 3;
  return bytesCount;
}

void _participantEntityCollectionSerialize(
  ParticipantEntityCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarUrl);
  writer.writeLong(offsets[1], object.conversationId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.id);
  writer.writeDateTime(offsets[4], object.joinedAt);
  writer.writeDateTime(offsets[5], object.lastReadAt);
  writer.writeDateTime(offsets[6], object.leftAt);
  writer.writeBool(offsets[7], object.muted);
  writer.writeBool(offsets[8], object.notificationsEnabled);
  writer.writeString(offsets[9], object.role);
  writer.writeString(offsets[10], object.staffCode);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeString(offsets[12], object.userCode);
  writer.writeString(offsets[13], object.userName);
}

ParticipantEntityCollection _participantEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ParticipantEntityCollection();
  object.avatarUrl = reader.readStringOrNull(offsets[0]);
  object.conversationId = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = reader.readLong(offsets[3]);
  object.joinedAt = reader.readDateTime(offsets[4]);
  object.lastReadAt = reader.readDateTimeOrNull(offsets[5]);
  object.leftAt = reader.readDateTimeOrNull(offsets[6]);
  object.muted = reader.readBoolOrNull(offsets[7]);
  object.notificationsEnabled = reader.readBoolOrNull(offsets[8]);
  object.role = reader.readString(offsets[9]);
  object.staffCode = reader.readStringOrNull(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  object.userCode = reader.readString(offsets[12]);
  object.userName = reader.readString(offsets[13]);
  return object;
}

P _participantEntityCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ParticipantEntityCollectionQueryFilter on QueryBuilder<
    ParticipantEntityCollection,
    ParticipantEntityCollection,
    QFilterCondition> {
  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarUrl',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarUrl',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      avatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      avatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> conversationIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'conversationId',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> conversationIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'conversationId',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> conversationIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'conversationId',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> conversationIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'conversationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> idGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> idLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> idBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> joinedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'joinedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> joinedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'joinedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> joinedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'joinedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> joinedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'joinedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> lastReadAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastReadAt',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> lastReadAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastReadAt',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> lastReadAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> lastReadAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> lastReadAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> lastReadAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReadAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> leftAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'leftAt',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> leftAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'leftAt',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> leftAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leftAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> leftAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leftAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> leftAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leftAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> leftAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leftAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> mutedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'muted',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> mutedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'muted',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> mutedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'muted',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> notificationsEnabledIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notificationsEnabled',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> notificationsEnabledIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notificationsEnabled',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> notificationsEnabledEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationsEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'role',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      roleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      roleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'role',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'staffCode',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'staffCode',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'staffCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'staffCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'staffCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'staffCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'staffCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      staffCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'staffCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      staffCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'staffCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> staffCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'staffCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      userCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      userCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      userNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
          QAfterFilterCondition>
      userNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<ParticipantEntityCollection, ParticipantEntityCollection,
      QAfterFilterCondition> userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }
}

extension ParticipantEntityCollectionQueryObject on QueryBuilder<
    ParticipantEntityCollection,
    ParticipantEntityCollection,
    QFilterCondition> {}
