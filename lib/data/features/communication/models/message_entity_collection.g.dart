// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageEntityCollectionCollection on Isar {
  IsarCollection<MessageEntityCollection> get messageEntityCollections =>
      this.collection();
}

const MessageEntityCollectionSchema = CollectionSchema(
  name: r'MessageEntityCollection',
  id: -8914769720020888919,
  properties: {
    r'attachments': PropertySchema(
      id: 0,
      name: r'attachments',
      type: IsarType.objectList,
      target: r'AttachmentEntityCollection',
    ),
    r'code': PropertySchema(
      id: 1,
      name: r'code',
      type: IsarType.string,
    ),
    r'conversationCode': PropertySchema(
      id: 2,
      name: r'conversationCode',
      type: IsarType.string,
    ),
    r'deletedAt': PropertySchema(
      id: 3,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'deletedPlaceholder': PropertySchema(
      id: 4,
      name: r'deletedPlaceholder',
      type: IsarType.string,
    ),
    r'editedAt': PropertySchema(
      id: 5,
      name: r'editedAt',
      type: IsarType.dateTime,
    ),
    r'id': PropertySchema(
      id: 6,
      name: r'id',
      type: IsarType.long,
    ),
    r'isDeleted': PropertySchema(
      id: 7,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isEdited': PropertySchema(
      id: 8,
      name: r'isEdited',
      type: IsarType.bool,
    ),
    r'isPrivate': PropertySchema(
      id: 9,
      name: r'isPrivate',
      type: IsarType.bool,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 10,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'localOnly': PropertySchema(
      id: 11,
      name: r'localOnly',
      type: IsarType.bool,
    ),
    r'localTempCode': PropertySchema(
      id: 12,
      name: r'localTempCode',
      type: IsarType.string,
    ),
    r'messageType': PropertySchema(
      id: 13,
      name: r'messageType',
      type: IsarType.string,
    ),
    r'organizationCode': PropertySchema(
      id: 14,
      name: r'organizationCode',
      type: IsarType.string,
    ),
    r'pendingDelete': PropertySchema(
      id: 15,
      name: r'pendingDelete',
      type: IsarType.bool,
    ),
    r'privateParentUserCode': PropertySchema(
      id: 16,
      name: r'privateParentUserCode',
      type: IsarType.string,
    ),
    r'reactions': PropertySchema(
      id: 17,
      name: r'reactions',
      type: IsarType.objectList,
      target: r'MessageReactionEntityCollection',
    ),
    r'readReceipts': PropertySchema(
      id: 18,
      name: r'readReceipts',
      type: IsarType.objectList,
      target: r'ReadReceiptEntityCollection',
    ),
    r'schoolCode': PropertySchema(
      id: 19,
      name: r'schoolCode',
      type: IsarType.string,
    ),
    r'senderAvatarUrl': PropertySchema(
      id: 20,
      name: r'senderAvatarUrl',
      type: IsarType.string,
    ),
    r'senderCode': PropertySchema(
      id: 21,
      name: r'senderCode',
      type: IsarType.string,
    ),
    r'senderName': PropertySchema(
      id: 22,
      name: r'senderName',
      type: IsarType.string,
    ),
    r'senderRole': PropertySchema(
      id: 23,
      name: r'senderRole',
      type: IsarType.string,
    ),
    r'sentAt': PropertySchema(
      id: 24,
      name: r'sentAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 25,
      name: r'status',
      type: IsarType.string,
    ),
    r'syncAttempts': PropertySchema(
      id: 26,
      name: r'syncAttempts',
      type: IsarType.long,
    ),
    r'text': PropertySchema(
      id: 27,
      name: r'text',
      type: IsarType.string,
    ),
    r'textPlain': PropertySchema(
      id: 28,
      name: r'textPlain',
      type: IsarType.string,
    ),
    r'threadParentCode': PropertySchema(
      id: 29,
      name: r'threadParentCode',
      type: IsarType.string,
    ),
    r'threadParentSenderCode': PropertySchema(
      id: 30,
      name: r'threadParentSenderCode',
      type: IsarType.string,
    ),
    r'threadParentSenderName': PropertySchema(
      id: 31,
      name: r'threadParentSenderName',
      type: IsarType.string,
    ),
    r'threadParentText': PropertySchema(
      id: 32,
      name: r'threadParentText',
      type: IsarType.string,
    )
  },
  estimateSize: _messageEntityCollectionEstimateSize,
  serialize: _messageEntityCollectionSerialize,
  deserialize: _messageEntityCollectionDeserialize,
  deserializeProp: _messageEntityCollectionDeserializeProp,
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
    r'conversationCode': IndexSchema(
      id: 4813646130077065260,
      name: r'conversationCode',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'conversationCode',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'textPlain': IndexSchema(
      id: 780352328980402477,
      name: r'textPlain',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'textPlain',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'sentAt': IndexSchema(
      id: 6268635426847144979,
      name: r'sentAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sentAt',
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
    r'AttachmentEntityCollection': AttachmentEntityCollectionSchema,
    r'ReadReceiptEntityCollection': ReadReceiptEntityCollectionSchema,
    r'MessageReactionEntityCollection': MessageReactionEntityCollectionSchema
  },
  getId: _messageEntityCollectionGetId,
  getLinks: _messageEntityCollectionGetLinks,
  attach: _messageEntityCollectionAttach,
  version: '3.1.0+1',
);

int _messageEntityCollectionEstimateSize(
  MessageEntityCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.attachments;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[AttachmentEntityCollection]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += AttachmentEntityCollectionSchema.estimateSize(
              value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.conversationCode.length * 3;
  {
    final value = object.deletedPlaceholder;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localTempCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageType.length * 3;
  bytesCount += 3 + object.organizationCode.length * 3;
  {
    final value = object.privateParentUserCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.reactions;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[MessageReactionEntityCollection]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += MessageReactionEntityCollectionSchema.estimateSize(
              value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final list = object.readReceipts;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[ReadReceiptEntityCollection]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += ReadReceiptEntityCollectionSchema.estimateSize(
              value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.schoolCode.length * 3;
  {
    final value = object.senderAvatarUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.senderCode.length * 3;
  bytesCount += 3 + object.senderName.length * 3;
  bytesCount += 3 + object.senderRole.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.text.length * 3;
  bytesCount += 3 + object.textPlain.length * 3;
  {
    final value = object.threadParentCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.threadParentSenderCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.threadParentSenderName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.threadParentText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _messageEntityCollectionSerialize(
  MessageEntityCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<AttachmentEntityCollection>(
    offsets[0],
    allOffsets,
    AttachmentEntityCollectionSchema.serialize,
    object.attachments,
  );
  writer.writeString(offsets[1], object.code);
  writer.writeString(offsets[2], object.conversationCode);
  writer.writeDateTime(offsets[3], object.deletedAt);
  writer.writeString(offsets[4], object.deletedPlaceholder);
  writer.writeDateTime(offsets[5], object.editedAt);
  writer.writeLong(offsets[6], object.id);
  writer.writeBool(offsets[7], object.isDeleted);
  writer.writeBool(offsets[8], object.isEdited);
  writer.writeBool(offsets[9], object.isPrivate);
  writer.writeDateTime(offsets[10], object.lastSyncedAt);
  writer.writeBool(offsets[11], object.localOnly);
  writer.writeString(offsets[12], object.localTempCode);
  writer.writeString(offsets[13], object.messageType);
  writer.writeString(offsets[14], object.organizationCode);
  writer.writeBool(offsets[15], object.pendingDelete);
  writer.writeString(offsets[16], object.privateParentUserCode);
  writer.writeObjectList<MessageReactionEntityCollection>(
    offsets[17],
    allOffsets,
    MessageReactionEntityCollectionSchema.serialize,
    object.reactions,
  );
  writer.writeObjectList<ReadReceiptEntityCollection>(
    offsets[18],
    allOffsets,
    ReadReceiptEntityCollectionSchema.serialize,
    object.readReceipts,
  );
  writer.writeString(offsets[19], object.schoolCode);
  writer.writeString(offsets[20], object.senderAvatarUrl);
  writer.writeString(offsets[21], object.senderCode);
  writer.writeString(offsets[22], object.senderName);
  writer.writeString(offsets[23], object.senderRole);
  writer.writeDateTime(offsets[24], object.sentAt);
  writer.writeString(offsets[25], object.status);
  writer.writeLong(offsets[26], object.syncAttempts);
  writer.writeString(offsets[27], object.text);
  writer.writeString(offsets[28], object.textPlain);
  writer.writeString(offsets[29], object.threadParentCode);
  writer.writeString(offsets[30], object.threadParentSenderCode);
  writer.writeString(offsets[31], object.threadParentSenderName);
  writer.writeString(offsets[32], object.threadParentText);
}

MessageEntityCollection _messageEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageEntityCollection();
  object.attachments = reader.readObjectList<AttachmentEntityCollection>(
    offsets[0],
    AttachmentEntityCollectionSchema.deserialize,
    allOffsets,
    AttachmentEntityCollection(),
  );
  object.code = reader.readString(offsets[1]);
  object.conversationCode = reader.readString(offsets[2]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[3]);
  object.deletedPlaceholder = reader.readStringOrNull(offsets[4]);
  object.editedAt = reader.readDateTimeOrNull(offsets[5]);
  object.id = reader.readLong(offsets[6]);
  object.isDeleted = reader.readBool(offsets[7]);
  object.isEdited = reader.readBool(offsets[8]);
  object.isPrivate = reader.readBool(offsets[9]);
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[10]);
  object.localOnly = reader.readBool(offsets[11]);
  object.localTempCode = reader.readStringOrNull(offsets[12]);
  object.messageType = reader.readString(offsets[13]);
  object.organizationCode = reader.readString(offsets[14]);
  object.pendingDelete = reader.readBool(offsets[15]);
  object.privateParentUserCode = reader.readStringOrNull(offsets[16]);
  object.reactions = reader.readObjectList<MessageReactionEntityCollection>(
    offsets[17],
    MessageReactionEntityCollectionSchema.deserialize,
    allOffsets,
    MessageReactionEntityCollection(),
  );
  object.readReceipts = reader.readObjectList<ReadReceiptEntityCollection>(
    offsets[18],
    ReadReceiptEntityCollectionSchema.deserialize,
    allOffsets,
    ReadReceiptEntityCollection(),
  );
  object.schoolCode = reader.readString(offsets[19]);
  object.senderAvatarUrl = reader.readStringOrNull(offsets[20]);
  object.senderCode = reader.readString(offsets[21]);
  object.senderName = reader.readString(offsets[22]);
  object.senderRole = reader.readString(offsets[23]);
  object.sentAt = reader.readDateTime(offsets[24]);
  object.status = reader.readString(offsets[25]);
  object.syncAttempts = reader.readLong(offsets[26]);
  object.text = reader.readString(offsets[27]);
  object.textPlain = reader.readString(offsets[28]);
  object.threadParentCode = reader.readStringOrNull(offsets[29]);
  object.threadParentSenderCode = reader.readStringOrNull(offsets[30]);
  object.threadParentSenderName = reader.readStringOrNull(offsets[31]);
  object.threadParentText = reader.readStringOrNull(offsets[32]);
  return object;
}

P _messageEntityCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<AttachmentEntityCollection>(
        offset,
        AttachmentEntityCollectionSchema.deserialize,
        allOffsets,
        AttachmentEntityCollection(),
      )) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readObjectList<MessageReactionEntityCollection>(
        offset,
        MessageReactionEntityCollectionSchema.deserialize,
        allOffsets,
        MessageReactionEntityCollection(),
      )) as P;
    case 18:
      return (reader.readObjectList<ReadReceiptEntityCollection>(
        offset,
        ReadReceiptEntityCollectionSchema.deserialize,
        allOffsets,
        ReadReceiptEntityCollection(),
      )) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readString(offset)) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readString(offset)) as P;
    case 26:
      return (reader.readLong(offset)) as P;
    case 27:
      return (reader.readString(offset)) as P;
    case 28:
      return (reader.readString(offset)) as P;
    case 29:
      return (reader.readStringOrNull(offset)) as P;
    case 30:
      return (reader.readStringOrNull(offset)) as P;
    case 31:
      return (reader.readStringOrNull(offset)) as P;
    case 32:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messageEntityCollectionGetId(MessageEntityCollection object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _messageEntityCollectionGetLinks(
    MessageEntityCollection object) {
  return [];
}

void _messageEntityCollectionAttach(
    IsarCollection<dynamic> col, Id id, MessageEntityCollection object) {}

extension MessageEntityCollectionByIndex
    on IsarCollection<MessageEntityCollection> {
  Future<MessageEntityCollection?> getByCode(String code) {
    return getByIndex(r'code', [code]);
  }

  MessageEntityCollection? getByCodeSync(String code) {
    return getByIndexSync(r'code', [code]);
  }

  Future<bool> deleteByCode(String code) {
    return deleteByIndex(r'code', [code]);
  }

  bool deleteByCodeSync(String code) {
    return deleteByIndexSync(r'code', [code]);
  }

  Future<List<MessageEntityCollection?>> getAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndex(r'code', values);
  }

  List<MessageEntityCollection?> getAllByCodeSync(List<String> codeValues) {
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

  Future<Id> putByCode(MessageEntityCollection object) {
    return putByIndex(r'code', object);
  }

  Id putByCodeSync(MessageEntityCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'code', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCode(List<MessageEntityCollection> objects) {
    return putAllByIndex(r'code', objects);
  }

  List<Id> putAllByCodeSync(List<MessageEntityCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'code', objects, saveLinks: saveLinks);
  }
}

extension MessageEntityCollectionQueryWhereSort
    on QueryBuilder<MessageEntityCollection, MessageEntityCollection, QWhere> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterWhere>
      anySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sentAt'),
      );
    });
  }
}

extension MessageEntityCollectionQueryWhere on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QWhereClause> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> codeEqualTo(String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> conversationCodeEqualTo(String conversationCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'conversationCode',
        value: [conversationCode],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> conversationCodeNotEqualTo(String conversationCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'conversationCode',
              lower: [],
              upper: [conversationCode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'conversationCode',
              lower: [conversationCode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'conversationCode',
              lower: [conversationCode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'conversationCode',
              lower: [],
              upper: [conversationCode],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> textPlainEqualTo(String textPlain) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'textPlain',
        value: [textPlain],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> textPlainNotEqualTo(String textPlain) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'textPlain',
              lower: [],
              upper: [textPlain],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'textPlain',
              lower: [textPlain],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'textPlain',
              lower: [textPlain],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'textPlain',
              lower: [],
              upper: [textPlain],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> sentAtEqualTo(DateTime sentAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sentAt',
        value: [sentAt],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> sentAtNotEqualTo(DateTime sentAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sentAt',
              lower: [],
              upper: [sentAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sentAt',
              lower: [sentAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sentAt',
              lower: [sentAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sentAt',
              lower: [],
              upper: [sentAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> sentAtGreaterThan(
    DateTime sentAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sentAt',
        lower: [sentAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> sentAtLessThan(
    DateTime sentAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sentAt',
        lower: [],
        upper: [sentAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> sentAtBetween(
    DateTime lowerSentAt,
    DateTime upperSentAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sentAt',
        lower: [lowerSentAt],
        includeLower: includeLower,
        upper: [upperSentAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> organizationCodeEqualTo(String organizationCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'organizationCode',
        value: [organizationCode],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterWhereClause> schoolCodeEqualTo(String schoolCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'schoolCode',
        value: [schoolCode],
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

extension MessageEntityCollectionQueryFilter on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QFilterCondition> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'attachments',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'attachments',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> attachmentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachments',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'conversationCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      conversationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      conversationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'conversationCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'conversationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> conversationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'conversationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedPlaceholder',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedPlaceholder',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedPlaceholder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedPlaceholder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedPlaceholder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedPlaceholder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deletedPlaceholder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deletedPlaceholder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      deletedPlaceholderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deletedPlaceholder',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      deletedPlaceholderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deletedPlaceholder',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedPlaceholder',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> deletedPlaceholderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deletedPlaceholder',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> editedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'editedAt',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> editedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'editedAt',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> editedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'editedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> editedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'editedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> editedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'editedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> editedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'editedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> isEditedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEdited',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> isPrivateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPrivate',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localOnlyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localOnly',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localTempCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localTempCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localTempCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localTempCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localTempCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localTempCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localTempCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localTempCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      localTempCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localTempCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      localTempCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localTempCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localTempCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> localTempCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localTempCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      messageTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      messageTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageType',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> messageTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageType',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> organizationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'organizationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> organizationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'organizationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> pendingDeleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pendingDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'privateParentUserCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'privateParentUserCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateParentUserCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privateParentUserCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privateParentUserCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privateParentUserCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privateParentUserCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privateParentUserCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      privateParentUserCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privateParentUserCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      privateParentUserCodeMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privateParentUserCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privateParentUserCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> privateParentUserCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privateParentUserCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reactions',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reactions',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reactions',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reactions',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reactions',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reactions',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reactions',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> reactionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'reactions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'readReceipts',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'readReceipts',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readReceipts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readReceipts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readReceipts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readReceipts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readReceipts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> readReceiptsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readReceipts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> schoolCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schoolCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> schoolCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'schoolCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'senderAvatarUrl',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'senderAvatarUrl',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderAvatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderAvatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderAvatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderAvatarUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderAvatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderAvatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderAvatarUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderAvatarUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderAvatarUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderAvatarUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderAvatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderAvatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderAvatarUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderName',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderName',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderRole',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderRole',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderRole',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderRole',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderRole',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderRole',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderRoleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderRole',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      senderRoleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderRole',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderRole',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> senderRoleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderRole',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> sentAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> sentAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> sentAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> sentAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sentAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
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

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> syncAttemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> syncAttemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> syncAttemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> syncAttemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncAttempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textPlain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textPlain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textPlain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textPlain',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textPlain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textPlain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      textPlainContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textPlain',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      textPlainMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textPlain',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textPlain',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> textPlainIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textPlain',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'threadParentCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'threadParentCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'threadParentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'threadParentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'threadParentCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'threadParentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'threadParentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'threadParentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'threadParentCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'threadParentCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'threadParentSenderCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'threadParentSenderCode',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentSenderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'threadParentSenderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'threadParentSenderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'threadParentSenderCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'threadParentSenderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'threadParentSenderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentSenderCodeContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'threadParentSenderCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentSenderCodeMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'threadParentSenderCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentSenderCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'threadParentSenderCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'threadParentSenderName',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'threadParentSenderName',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'threadParentSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'threadParentSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'threadParentSenderName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'threadParentSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'threadParentSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentSenderNameContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'threadParentSenderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentSenderNameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'threadParentSenderName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentSenderName',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentSenderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'threadParentSenderName',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'threadParentText',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'threadParentText',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'threadParentText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'threadParentText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'threadParentText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'threadParentText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'threadParentText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'threadParentText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      threadParentTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'threadParentText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadParentText',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
      QAfterFilterCondition> threadParentTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'threadParentText',
        value: '',
      ));
    });
  }
}

extension MessageEntityCollectionQueryObject on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QFilterCondition> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      attachmentsElement(FilterQuery<AttachmentEntityCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'attachments');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      reactionsElement(FilterQuery<MessageReactionEntityCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'reactions');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection,
          QAfterFilterCondition>
      readReceiptsElement(FilterQuery<ReadReceiptEntityCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'readReceipts');
    });
  }
}

extension MessageEntityCollectionQueryLinks on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QFilterCondition> {}

extension MessageEntityCollectionQuerySortBy
    on QueryBuilder<MessageEntityCollection, MessageEntityCollection, QSortBy> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByConversationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByConversationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByDeletedPlaceholder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedPlaceholder', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByDeletedPlaceholderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedPlaceholder', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIsEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIsPrivate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrivate', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByIsPrivateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrivate', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByLocalTempCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTempCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByLocalTempCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTempCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByMessageTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByPendingDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByPrivateParentUserCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateParentUserCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByPrivateParentUserCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateParentUserCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderAvatarUrl', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderAvatarUrl', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderRole', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySenderRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderRole', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySyncAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortBySyncAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByTextPlain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPlain', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByTextPlainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPlain', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentSenderCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentSenderCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentSenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderName', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentSenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderName', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentText', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      sortByThreadParentTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentText', Sort.desc);
    });
  }
}

extension MessageEntityCollectionQuerySortThenBy on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QSortThenBy> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByConversationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByConversationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conversationCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByDeletedPlaceholder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedPlaceholder', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByDeletedPlaceholderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedPlaceholder', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByEditedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editedAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsEditedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEdited', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsPrivate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrivate', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsPrivateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPrivate', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByLocalOnlyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localOnly', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByLocalTempCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTempCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByLocalTempCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localTempCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByMessageTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByOrganizationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByOrganizationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'organizationCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByPendingDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByPrivateParentUserCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateParentUserCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByPrivateParentUserCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privateParentUserCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySchoolCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySchoolCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schoolCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderAvatarUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderAvatarUrl', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderAvatarUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderAvatarUrl', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderRole', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySenderRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderRole', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySyncAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenBySyncAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByTextPlain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPlain', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByTextPlainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textPlain', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentSenderCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderCode', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentSenderCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderCode', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentSenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderName', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentSenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentSenderName', Sort.desc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentText', Sort.asc);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QAfterSortBy>
      thenByThreadParentTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadParentText', Sort.desc);
    });
  }
}

extension MessageEntityCollectionQueryWhereDistinct on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QDistinct> {
  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByConversationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'conversationCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByDeletedPlaceholder({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedPlaceholder',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByEditedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editedAt');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctById() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByIsEdited() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEdited');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByIsPrivate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPrivate');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByLocalOnly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localOnly');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByLocalTempCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localTempCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByMessageType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByOrganizationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'organizationCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingDelete');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByPrivateParentUserCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privateParentUserCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySchoolCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schoolCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySenderAvatarUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderAvatarUrl',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySenderCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySenderName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySenderRole({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderRole', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentAt');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctBySyncAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncAttempts');
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByTextPlain({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textPlain', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByThreadParentCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threadParentCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByThreadParentSenderCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threadParentSenderCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByThreadParentSenderName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threadParentSenderName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageEntityCollection, MessageEntityCollection, QDistinct>
      distinctByThreadParentText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threadParentText',
          caseSensitive: caseSensitive);
    });
  }
}

extension MessageEntityCollectionQueryProperty on QueryBuilder<
    MessageEntityCollection, MessageEntityCollection, QQueryProperty> {
  QueryBuilder<MessageEntityCollection, int, QQueryOperations>
      isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<MessageEntityCollection, List<AttachmentEntityCollection>?,
      QQueryOperations> attachmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachments');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      conversationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conversationCode');
    });
  }

  QueryBuilder<MessageEntityCollection, DateTime?, QQueryOperations>
      deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      deletedPlaceholderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedPlaceholder');
    });
  }

  QueryBuilder<MessageEntityCollection, DateTime?, QQueryOperations>
      editedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editedAt');
    });
  }

  QueryBuilder<MessageEntityCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MessageEntityCollection, bool, QQueryOperations>
      isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<MessageEntityCollection, bool, QQueryOperations>
      isEditedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEdited');
    });
  }

  QueryBuilder<MessageEntityCollection, bool, QQueryOperations>
      isPrivateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPrivate');
    });
  }

  QueryBuilder<MessageEntityCollection, DateTime?, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<MessageEntityCollection, bool, QQueryOperations>
      localOnlyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localOnly');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      localTempCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localTempCode');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      messageTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageType');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      organizationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'organizationCode');
    });
  }

  QueryBuilder<MessageEntityCollection, bool, QQueryOperations>
      pendingDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingDelete');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      privateParentUserCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privateParentUserCode');
    });
  }

  QueryBuilder<MessageEntityCollection, List<MessageReactionEntityCollection>?,
      QQueryOperations> reactionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reactions');
    });
  }

  QueryBuilder<MessageEntityCollection, List<ReadReceiptEntityCollection>?,
      QQueryOperations> readReceiptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readReceipts');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      schoolCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schoolCode');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      senderAvatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderAvatarUrl');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      senderCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderCode');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      senderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderName');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      senderRoleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderRole');
    });
  }

  QueryBuilder<MessageEntityCollection, DateTime, QQueryOperations>
      sentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentAt');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<MessageEntityCollection, int, QQueryOperations>
      syncAttemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncAttempts');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<MessageEntityCollection, String, QQueryOperations>
      textPlainProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textPlain');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      threadParentCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threadParentCode');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      threadParentSenderCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threadParentSenderCode');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      threadParentSenderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threadParentSenderName');
    });
  }

  QueryBuilder<MessageEntityCollection, String?, QQueryOperations>
      threadParentTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threadParentText');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const AttachmentEntityCollectionSchema = Schema(
  name: r'AttachmentEntityCollection',
  id: 9093175227671292337,
  properties: {
    r'attachmentId': PropertySchema(
      id: 0,
      name: r'attachmentId',
      type: IsarType.long,
    ),
    r'attachmentType': PropertySchema(
      id: 1,
      name: r'attachmentType',
      type: IsarType.string,
    ),
    r'code': PropertySchema(
      id: 2,
      name: r'code',
      type: IsarType.string,
    ),
    r'conversationCode': PropertySchema(
      id: 3,
      name: r'conversationCode',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 4,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'fileSizeBytes': PropertySchema(
      id: 5,
      name: r'fileSizeBytes',
      type: IsarType.long,
    ),
    r'fileUrl': PropertySchema(
      id: 6,
      name: r'fileUrl',
      type: IsarType.string,
    ),
    r'localFilePath': PropertySchema(
      id: 7,
      name: r'localFilePath',
      type: IsarType.string,
    ),
    r'messageCode': PropertySchema(
      id: 8,
      name: r'messageCode',
      type: IsarType.string,
    ),
    r'mimeType': PropertySchema(
      id: 9,
      name: r'mimeType',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 10,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'uploadedAt': PropertySchema(
      id: 11,
      name: r'uploadedAt',
      type: IsarType.dateTime,
    ),
    r'uploadedBy': PropertySchema(
      id: 12,
      name: r'uploadedBy',
      type: IsarType.string,
    )
  },
  estimateSize: _attachmentEntityCollectionEstimateSize,
  serialize: _attachmentEntityCollectionSerialize,
  deserialize: _attachmentEntityCollectionDeserialize,
  deserializeProp: _attachmentEntityCollectionDeserializeProp,
);

int _attachmentEntityCollectionEstimateSize(
  AttachmentEntityCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.attachmentType.length * 3;
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.conversationCode.length * 3;
  bytesCount += 3 + object.fileName.length * 3;
  bytesCount += 3 + object.fileUrl.length * 3;
  {
    final value = object.localFilePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.messageCode.length * 3;
  bytesCount += 3 + object.mimeType.length * 3;
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uploadedBy.length * 3;
  return bytesCount;
}

void _attachmentEntityCollectionSerialize(
  AttachmentEntityCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attachmentId);
  writer.writeString(offsets[1], object.attachmentType);
  writer.writeString(offsets[2], object.code);
  writer.writeString(offsets[3], object.conversationCode);
  writer.writeString(offsets[4], object.fileName);
  writer.writeLong(offsets[5], object.fileSizeBytes);
  writer.writeString(offsets[6], object.fileUrl);
  writer.writeString(offsets[7], object.localFilePath);
  writer.writeString(offsets[8], object.messageCode);
  writer.writeString(offsets[9], object.mimeType);
  writer.writeString(offsets[10], object.thumbnailUrl);
  writer.writeDateTime(offsets[11], object.uploadedAt);
  writer.writeString(offsets[12], object.uploadedBy);
}

AttachmentEntityCollection _attachmentEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AttachmentEntityCollection();
  object.attachmentId = reader.readLongOrNull(offsets[0]);
  object.attachmentType = reader.readString(offsets[1]);
  object.code = reader.readString(offsets[2]);
  object.conversationCode = reader.readString(offsets[3]);
  object.fileName = reader.readString(offsets[4]);
  object.fileSizeBytes = reader.readLong(offsets[5]);
  object.fileUrl = reader.readString(offsets[6]);
  object.localFilePath = reader.readStringOrNull(offsets[7]);
  object.messageCode = reader.readString(offsets[8]);
  object.mimeType = reader.readString(offsets[9]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[10]);
  object.uploadedAt = reader.readDateTime(offsets[11]);
  object.uploadedBy = reader.readString(offsets[12]);
  return object;
}

P _attachmentEntityCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension AttachmentEntityCollectionQueryFilter on QueryBuilder<
    AttachmentEntityCollection, AttachmentEntityCollection, QFilterCondition> {
  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'attachmentId',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'attachmentId',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentId',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentId',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentId',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      attachmentTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      attachmentTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachmentType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentType',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> attachmentTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachmentType',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
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

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'conversationCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      conversationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'conversationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      conversationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'conversationCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'conversationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> conversationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'conversationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileSizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileSizeBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileSizeBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileSizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileSizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      fileUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      fileUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> fileUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localFilePath',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localFilePath',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localFilePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      localFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      localFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localFilePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> localFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      messageCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      messageCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCode',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> messageCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageCode',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mimeType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      mimeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mimeType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      mimeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mimeType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mimeType',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> mimeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mimeType',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uploadedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uploadedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      uploadedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uploadedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
          QAfterFilterCondition>
      uploadedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uploadedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<AttachmentEntityCollection, AttachmentEntityCollection,
      QAfterFilterCondition> uploadedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uploadedBy',
        value: '',
      ));
    });
  }
}

extension AttachmentEntityCollectionQueryObject on QueryBuilder<
    AttachmentEntityCollection, AttachmentEntityCollection, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ReadReceiptEntityCollectionSchema = Schema(
  name: r'ReadReceiptEntityCollection',
  id: 2359116479779060653,
  properties: {
    r'deliveredAt': PropertySchema(
      id: 0,
      name: r'deliveredAt',
      type: IsarType.dateTime,
    ),
    r'messageCode': PropertySchema(
      id: 1,
      name: r'messageCode',
      type: IsarType.string,
    ),
    r'readAt': PropertySchema(
      id: 2,
      name: r'readAt',
      type: IsarType.dateTime,
    ),
    r'role': PropertySchema(
      id: 3,
      name: r'role',
      type: IsarType.string,
    ),
    r'userCode': PropertySchema(
      id: 4,
      name: r'userCode',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 5,
      name: r'userName',
      type: IsarType.string,
    )
  },
  estimateSize: _readReceiptEntityCollectionEstimateSize,
  serialize: _readReceiptEntityCollectionSerialize,
  deserialize: _readReceiptEntityCollectionDeserialize,
  deserializeProp: _readReceiptEntityCollectionDeserializeProp,
);

int _readReceiptEntityCollectionEstimateSize(
  ReadReceiptEntityCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.messageCode.length * 3;
  {
    final value = object.role;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userCode.length * 3;
  bytesCount += 3 + object.userName.length * 3;
  return bytesCount;
}

void _readReceiptEntityCollectionSerialize(
  ReadReceiptEntityCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.deliveredAt);
  writer.writeString(offsets[1], object.messageCode);
  writer.writeDateTime(offsets[2], object.readAt);
  writer.writeString(offsets[3], object.role);
  writer.writeString(offsets[4], object.userCode);
  writer.writeString(offsets[5], object.userName);
}

ReadReceiptEntityCollection _readReceiptEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadReceiptEntityCollection();
  object.deliveredAt = reader.readDateTimeOrNull(offsets[0]);
  object.messageCode = reader.readString(offsets[1]);
  object.readAt = reader.readDateTimeOrNull(offsets[2]);
  object.role = reader.readStringOrNull(offsets[3]);
  object.userCode = reader.readString(offsets[4]);
  object.userName = reader.readString(offsets[5]);
  return object;
}

P _readReceiptEntityCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ReadReceiptEntityCollectionQueryFilter on QueryBuilder<
    ReadReceiptEntityCollection,
    ReadReceiptEntityCollection,
    QFilterCondition> {
  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> deliveredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveredAt',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> deliveredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveredAt',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> deliveredAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> deliveredAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> deliveredAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> deliveredAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveredAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
          QAfterFilterCondition>
      messageCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'messageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
          QAfterFilterCondition>
      messageCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'messageCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> messageCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'messageCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> readAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'readAt',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> readAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'readAt',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> readAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> readAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> readAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> readAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'role',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'role',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleEqualTo(
    String? value, {
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleGreaterThan(
    String? value, {
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleLessThan(
    String? value, {
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> userCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> userCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
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

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadReceiptEntityCollection, ReadReceiptEntityCollection,
      QAfterFilterCondition> userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }
}

extension ReadReceiptEntityCollectionQueryObject on QueryBuilder<
    ReadReceiptEntityCollection,
    ReadReceiptEntityCollection,
    QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MessageReactionEntityCollectionSchema = Schema(
  name: r'MessageReactionEntityCollection',
  id: 148219316177138462,
  properties: {
    r'emoji': PropertySchema(
      id: 0,
      name: r'emoji',
      type: IsarType.string,
    ),
    r'role': PropertySchema(
      id: 1,
      name: r'role',
      type: IsarType.string,
    ),
    r'userCode': PropertySchema(
      id: 2,
      name: r'userCode',
      type: IsarType.string,
    ),
    r'userName': PropertySchema(
      id: 3,
      name: r'userName',
      type: IsarType.string,
    )
  },
  estimateSize: _messageReactionEntityCollectionEstimateSize,
  serialize: _messageReactionEntityCollectionSerialize,
  deserialize: _messageReactionEntityCollectionDeserialize,
  deserializeProp: _messageReactionEntityCollectionDeserializeProp,
);

int _messageReactionEntityCollectionEstimateSize(
  MessageReactionEntityCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.emoji.length * 3;
  {
    final value = object.role;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userCode.length * 3;
  {
    final value = object.userName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _messageReactionEntityCollectionSerialize(
  MessageReactionEntityCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.emoji);
  writer.writeString(offsets[1], object.role);
  writer.writeString(offsets[2], object.userCode);
  writer.writeString(offsets[3], object.userName);
}

MessageReactionEntityCollection _messageReactionEntityCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageReactionEntityCollection();
  object.emoji = reader.readString(offsets[0]);
  object.role = reader.readStringOrNull(offsets[1]);
  object.userCode = reader.readString(offsets[2]);
  object.userName = reader.readStringOrNull(offsets[3]);
  return object;
}

P _messageReactionEntityCollectionDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MessageReactionEntityCollectionQueryFilter on QueryBuilder<
    MessageReactionEntityCollection,
    MessageReactionEntityCollection,
    QFilterCondition> {
  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
          QAfterFilterCondition>
      emojiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
          QAfterFilterCondition>
      emojiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emoji',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> emojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emoji',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'role',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'role',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleEqualTo(
    String? value, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleGreaterThan(
    String? value, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleLessThan(
    String? value, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userCode',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameEqualTo(
    String? value, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameGreaterThan(
    String? value, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameLessThan(
    String? value, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
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

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageReactionEntityCollection, MessageReactionEntityCollection,
      QAfterFilterCondition> userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }
}

extension MessageReactionEntityCollectionQueryObject on QueryBuilder<
    MessageReactionEntityCollection,
    MessageReactionEntityCollection,
    QFilterCondition> {}
