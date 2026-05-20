// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'staff_shift_collection.dart';

// // **************************************************************************
// // IsarCollectionGenerator
// // **************************************************************************

// // coverage:ignore-file
// // ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

// extension GetStaffShiftCollectionCollection on Isar {
//   IsarCollection<StaffShiftCollection> get staffShiftCollections =>
//       this.collection();
// }

// const StaffShiftCollectionSchema = CollectionSchema(
//   name: r'StaffShiftCollection',
//   id: 1383217482202801667,
//   properties: {
//     r'breakEndTime': PropertySchema(
//       id: 0,
//       name: r'breakEndTime',
//       type: IsarType.string,
//     ),
//     r'breakStartTime': PropertySchema(
//       id: 1,
//       name: r'breakStartTime',
//       type: IsarType.string,
//     ),
//     r'classroomCode': PropertySchema(
//       id: 2,
//       name: r'classroomCode',
//       type: IsarType.string,
//     ),
//     r'endTime': PropertySchema(
//       id: 3,
//       name: r'endTime',
//       type: IsarType.string,
//     ),
//     r'forceAdd': PropertySchema(
//       id: 4,
//       name: r'forceAdd',
//       type: IsarType.bool,
//     ),
//     r'notes': PropertySchema(
//       id: 5,
//       name: r'notes',
//       type: IsarType.string,
//     ),
//     r'organizationCode': PropertySchema(
//       id: 6,
//       name: r'organizationCode',
//       type: IsarType.string,
//     ),
//     r'overrideConflicts': PropertySchema(
//       id: 7,
//       name: r'overrideConflicts',
//       type: IsarType.bool,
//     ),
//     r'publish': PropertySchema(
//       id: 8,
//       name: r'publish',
//       type: IsarType.bool,
//     ),
//     r'repeat': PropertySchema(
//       id: 9,
//       name: r'repeat',
//       type: IsarType.bool,
//     ),
//     r'schoolCode': PropertySchema(
//       id: 10,
//       name: r'schoolCode',
//       type: IsarType.string,
//     ),
//     r'seriesCode': PropertySchema(
//       id: 11,
//       name: r'seriesCode',
//       type: IsarType.string,
//     ),
//     r'shiftCode': PropertySchema(
//       id: 12,
//       name: r'shiftCode',
//       type: IsarType.string,
//     ),
//     r'shiftDate': PropertySchema(
//       id: 13,
//       name: r'shiftDate',
//       type: IsarType.string,
//     ),
//     r'staffCode': PropertySchema(
//       id: 14,
//       name: r'staffCode',
//       type: IsarType.string,
//     ),
//     r'startTime': PropertySchema(
//       id: 15,
//       name: r'startTime',
//       type: IsarType.string,
//     )
//   },
//   estimateSize: _staffShiftCollectionEstimateSize,
//   serialize: _staffShiftCollectionSerialize,
//   deserialize: _staffShiftCollectionDeserialize,
//   deserializeProp: _staffShiftCollectionDeserializeProp,
//   idName: r'isarId',
//   indexes: {},
//   links: {},
//   embeddedSchemas: {},
//   getId: _staffShiftCollectionGetId,
//   getLinks: _staffShiftCollectionGetLinks,
//   attach: _staffShiftCollectionAttach,
//   version: '3.1.0+1',
// );

// int _staffShiftCollectionEstimateSize(
//   StaffShiftCollection object,
//   List<int> offsets,
//   Map<Type, List<int>> allOffsets,
// ) {
//   var bytesCount = offsets.last;
//   {
//     final value = object.breakEndTime;
//     if (value != null) {
//       bytesCount += 3 + value.length * 3;
//     }
//   }
//   {
//     final value = object.breakStartTime;
//     if (value != null) {
//       bytesCount += 3 + value.length * 3;
//     }
//   }
//   bytesCount += 3 + object.classroomCode.length * 3;
//   bytesCount += 3 + object.endTime.length * 3;
//   {
//     final value = object.notes;
//     if (value != null) {
//       bytesCount += 3 + value.length * 3;
//     }
//   }
//   bytesCount += 3 + object.organizationCode.length * 3;
//   bytesCount += 3 + object.schoolCode.length * 3;
//   {
//     final value = object.seriesCode;
//     if (value != null) {
//       bytesCount += 3 + value.length * 3;
//     }
//   }
//   {
//     final value = object.shiftCode;
//     if (value != null) {
//       bytesCount += 3 + value.length * 3;
//     }
//   }
//   bytesCount += 3 + object.shiftDate.length * 3;
//   bytesCount += 3 + object.staffCode.length * 3;
//   bytesCount += 3 + object.startTime.length * 3;
//   return bytesCount;
// }

// void _staffShiftCollectionSerialize(
//   StaffShiftCollection object,
//   IsarWriter writer,
//   List<int> offsets,
//   Map<Type, List<int>> allOffsets,
// ) {
//   writer.writeString(offsets[0], object.breakEndTime);
//   writer.writeString(offsets[1], object.breakStartTime);
//   writer.writeString(offsets[2], object.classroomCode);
//   writer.writeString(offsets[3], object.endTime);
//   writer.writeBool(offsets[4], object.forceAdd);
//   writer.writeString(offsets[5], object.notes);
//   writer.writeString(offsets[6], object.organizationCode);
//   writer.writeBool(offsets[7], object.overrideConflicts);
//   writer.writeBool(offsets[8], object.publish);
//   writer.writeBool(offsets[9], object.repeat);
//   writer.writeString(offsets[10], object.schoolCode);
//   writer.writeString(offsets[11], object.seriesCode);
//   writer.writeString(offsets[12], object.shiftCode);
//   writer.writeString(offsets[13], object.shiftDate);
//   writer.writeString(offsets[14], object.staffCode);
//   writer.writeString(offsets[15], object.startTime);
// }

// StaffShiftCollection _staffShiftCollectionDeserialize(
//   Id id,
//   IsarReader reader,
//   List<int> offsets,
//   Map<Type, List<int>> allOffsets,
// ) {
//   final object = StaffShiftCollection();
//   object.breakEndTime = reader.readStringOrNull(offsets[0]);
//   object.breakStartTime = reader.readStringOrNull(offsets[1]);
//   object.classroomCode = reader.readString(offsets[2]);
//   object.endTime = reader.readString(offsets[3]);
//   object.forceAdd = reader.readBool(offsets[4]);
//   object.notes = reader.readStringOrNull(offsets[5]);
//   object.organizationCode = reader.readString(offsets[6]);
//   object.overrideConflicts = reader.readBool(offsets[7]);
//   object.publish = reader.readBool(offsets[8]);
//   object.repeat = reader.readBool(offsets[9]);
//   object.schoolCode = reader.readString(offsets[10]);
//   object.seriesCode = reader.readStringOrNull(offsets[11]);
//   object.shiftCode = reader.readStringOrNull(offsets[12]);
//   object.shiftDate = reader.readString(offsets[13]);
//   object.staffCode = reader.readString(offsets[14]);
//   object.startTime = reader.readString(offsets[15]);
//   return object;
// }

// P _staffShiftCollectionDeserializeProp<P>(
//   IsarReader reader,
//   int propertyId,
//   int offset,
//   Map<Type, List<int>> allOffsets,
// ) {
//   switch (propertyId) {
//     case 0:
//       return (reader.readStringOrNull(offset)) as P;
//     case 1:
//       return (reader.readStringOrNull(offset)) as P;
//     case 2:
//       return (reader.readString(offset)) as P;
//     case 3:
//       return (reader.readString(offset)) as P;
//     case 4:
//       return (reader.readBool(offset)) as P;
//     case 5:
//       return (reader.readStringOrNull(offset)) as P;
//     case 6:
//       return (reader.readString(offset)) as P;
//     case 7:
//       return (reader.readBool(offset)) as P;
//     case 8:
//       return (reader.readBool(offset)) as P;
//     case 9:
//       return (reader.readBool(offset)) as P;
//     case 10:
//       return (reader.readString(offset)) as P;
//     case 11:
//       return (reader.readStringOrNull(offset)) as P;
//     case 12:
//       return (reader.readStringOrNull(offset)) as P;
//     case 13:
//       return (reader.readString(offset)) as P;
//     case 14:
//       return (reader.readString(offset)) as P;
//     case 15:
//       return (reader.readString(offset)) as P;
//     default:
//       throw IsarError('Unknown property with id $propertyId');
//   }
// }

// Id _staffShiftCollectionGetId(StaffShiftCollection object) {
//   return object.isarId;
// }

// List<IsarLinkBase<dynamic>> _staffShiftCollectionGetLinks(
//     StaffShiftCollection object) {
//   return [];
// }

// void _staffShiftCollectionAttach(
//     IsarCollection<dynamic> col, Id id, StaffShiftCollection object) {}

// extension StaffShiftCollectionQueryWhereSort
//     on QueryBuilder<StaffShiftCollection, StaffShiftCollection, QWhere> {
//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterWhere>
//       anyIsarId() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addWhereClause(const IdWhereClause.any());
//     });
//   }
// }

// extension StaffShiftCollectionQueryWhere
//     on QueryBuilder<StaffShiftCollection, StaffShiftCollection, QWhereClause> {
//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterWhereClause>
//       isarIdEqualTo(Id isarId) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addWhereClause(IdWhereClause.between(
//         lower: isarId,
//         upper: isarId,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterWhereClause>
//       isarIdNotEqualTo(Id isarId) {
//     return QueryBuilder.apply(this, (query) {
//       if (query.whereSort == Sort.asc) {
//         return query
//             .addWhereClause(
//               IdWhereClause.lessThan(upper: isarId, includeUpper: false),
//             )
//             .addWhereClause(
//               IdWhereClause.greaterThan(lower: isarId, includeLower: false),
//             );
//       } else {
//         return query
//             .addWhereClause(
//               IdWhereClause.greaterThan(lower: isarId, includeLower: false),
//             )
//             .addWhereClause(
//               IdWhereClause.lessThan(upper: isarId, includeUpper: false),
//             );
//       }
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterWhereClause>
//       isarIdGreaterThan(Id isarId, {bool include = false}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addWhereClause(
//         IdWhereClause.greaterThan(lower: isarId, includeLower: include),
//       );
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterWhereClause>
//       isarIdLessThan(Id isarId, {bool include = false}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addWhereClause(
//         IdWhereClause.lessThan(upper: isarId, includeUpper: include),
//       );
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterWhereClause>
//       isarIdBetween(
//     Id lowerIsarId,
//     Id upperIsarId, {
//     bool includeLower = true,
//     bool includeUpper = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addWhereClause(IdWhereClause.between(
//         lower: lowerIsarId,
//         includeLower: includeLower,
//         upper: upperIsarId,
//         includeUpper: includeUpper,
//       ));
//     });
//   }
// }

// extension StaffShiftCollectionQueryFilter on QueryBuilder<StaffShiftCollection,
//     StaffShiftCollection, QFilterCondition> {
//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeIsNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNull(
//         property: r'breakEndTime',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeIsNotNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNotNull(
//         property: r'breakEndTime',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeEqualTo(
//     String? value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'breakEndTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeGreaterThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'breakEndTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeLessThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'breakEndTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeBetween(
//     String? lower,
//     String? upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'breakEndTime',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'breakEndTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'breakEndTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       breakEndTimeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'breakEndTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       breakEndTimeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'breakEndTime',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'breakEndTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakEndTimeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'breakEndTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeIsNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNull(
//         property: r'breakStartTime',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeIsNotNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNotNull(
//         property: r'breakStartTime',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeEqualTo(
//     String? value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'breakStartTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeGreaterThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'breakStartTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeLessThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'breakStartTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeBetween(
//     String? lower,
//     String? upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'breakStartTime',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'breakStartTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'breakStartTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       breakStartTimeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'breakStartTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       breakStartTimeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'breakStartTime',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'breakStartTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> breakStartTimeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'breakStartTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'classroomCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'classroomCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'classroomCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'classroomCode',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'classroomCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'classroomCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       classroomCodeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'classroomCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       classroomCodeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'classroomCode',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'classroomCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> classroomCodeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'classroomCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'endTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'endTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'endTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'endTime',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'endTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'endTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       endTimeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'endTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       endTimeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'endTime',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'endTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> endTimeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'endTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> forceAddEqualTo(bool value) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'forceAdd',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> isarIdEqualTo(Id value) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'isarId',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> isarIdGreaterThan(
//     Id value, {
//     bool include = false,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'isarId',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> isarIdLessThan(
//     Id value, {
//     bool include = false,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'isarId',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> isarIdBetween(
//     Id lower,
//     Id upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'isarId',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesIsNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNull(
//         property: r'notes',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesIsNotNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNotNull(
//         property: r'notes',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesEqualTo(
//     String? value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'notes',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesGreaterThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'notes',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesLessThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'notes',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesBetween(
//     String? lower,
//     String? upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'notes',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'notes',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'notes',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       notesContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'notes',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       notesMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'notes',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'notes',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> notesIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'notes',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'organizationCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'organizationCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'organizationCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'organizationCode',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'organizationCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'organizationCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       organizationCodeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'organizationCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       organizationCodeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'organizationCode',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'organizationCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> organizationCodeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'organizationCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> overrideConflictsEqualTo(bool value) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'overrideConflicts',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> publishEqualTo(bool value) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'publish',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> repeatEqualTo(bool value) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'repeat',
//         value: value,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'schoolCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'schoolCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'schoolCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'schoolCode',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'schoolCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'schoolCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       schoolCodeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'schoolCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       schoolCodeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'schoolCode',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'schoolCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> schoolCodeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'schoolCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeIsNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNull(
//         property: r'seriesCode',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeIsNotNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNotNull(
//         property: r'seriesCode',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeEqualTo(
//     String? value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'seriesCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeGreaterThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'seriesCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeLessThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'seriesCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeBetween(
//     String? lower,
//     String? upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'seriesCode',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'seriesCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'seriesCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       seriesCodeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'seriesCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       seriesCodeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'seriesCode',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'seriesCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> seriesCodeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'seriesCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeIsNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNull(
//         property: r'shiftCode',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeIsNotNull() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(const FilterCondition.isNotNull(
//         property: r'shiftCode',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeEqualTo(
//     String? value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'shiftCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeGreaterThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'shiftCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeLessThan(
//     String? value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'shiftCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeBetween(
//     String? lower,
//     String? upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'shiftCode',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'shiftCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'shiftCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       shiftCodeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'shiftCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       shiftCodeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'shiftCode',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'shiftCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftCodeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'shiftCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'shiftDate',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'shiftDate',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'shiftDate',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'shiftDate',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'shiftDate',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'shiftDate',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       shiftDateContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'shiftDate',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       shiftDateMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'shiftDate',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'shiftDate',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> shiftDateIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'shiftDate',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'staffCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'staffCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'staffCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'staffCode',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'staffCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'staffCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       staffCodeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'staffCode',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       staffCodeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'staffCode',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'staffCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> staffCodeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'staffCode',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeEqualTo(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'startTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeGreaterThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         include: include,
//         property: r'startTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeLessThan(
//     String value, {
//     bool include = false,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.lessThan(
//         include: include,
//         property: r'startTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeBetween(
//     String lower,
//     String upper, {
//     bool includeLower = true,
//     bool includeUpper = true,
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.between(
//         property: r'startTime',
//         lower: lower,
//         includeLower: includeLower,
//         upper: upper,
//         includeUpper: includeUpper,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeStartsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.startsWith(
//         property: r'startTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeEndsWith(
//     String value, {
//     bool caseSensitive = true,
//   }) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.endsWith(
//         property: r'startTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       startTimeContains(String value, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.contains(
//         property: r'startTime',
//         value: value,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//           QAfterFilterCondition>
//       startTimeMatches(String pattern, {bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.matches(
//         property: r'startTime',
//         wildcard: pattern,
//         caseSensitive: caseSensitive,
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeIsEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.equalTo(
//         property: r'startTime',
//         value: '',
//       ));
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection,
//       QAfterFilterCondition> startTimeIsNotEmpty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addFilterCondition(FilterCondition.greaterThan(
//         property: r'startTime',
//         value: '',
//       ));
//     });
//   }
// }

// extension StaffShiftCollectionQueryObject on QueryBuilder<StaffShiftCollection,
//     StaffShiftCollection, QFilterCondition> {}

// extension StaffShiftCollectionQueryLinks on QueryBuilder<StaffShiftCollection,
//     StaffShiftCollection, QFilterCondition> {}

// extension StaffShiftCollectionQuerySortBy
//     on QueryBuilder<StaffShiftCollection, StaffShiftCollection, QSortBy> {
//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByBreakEndTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakEndTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByBreakEndTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakEndTime', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByBreakStartTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakStartTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByBreakStartTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakStartTime', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByClassroomCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'classroomCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByClassroomCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'classroomCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByEndTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'endTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByEndTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'endTime', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByForceAdd() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'forceAdd', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByForceAddDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'forceAdd', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByNotes() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'notes', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByNotesDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'notes', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByOrganizationCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'organizationCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByOrganizationCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'organizationCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByOverrideConflicts() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'overrideConflicts', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByOverrideConflictsDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'overrideConflicts', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByPublish() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'publish', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByPublishDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'publish', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByRepeat() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'repeat', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByRepeatDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'repeat', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortBySchoolCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'schoolCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortBySchoolCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'schoolCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortBySeriesCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'seriesCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortBySeriesCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'seriesCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByShiftCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByShiftCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByShiftDate() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftDate', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByShiftDateDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftDate', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByStaffCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'staffCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByStaffCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'staffCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByStartTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'startTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       sortByStartTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'startTime', Sort.desc);
//     });
//   }
// }

// extension StaffShiftCollectionQuerySortThenBy
//     on QueryBuilder<StaffShiftCollection, StaffShiftCollection, QSortThenBy> {
//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByBreakEndTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakEndTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByBreakEndTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakEndTime', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByBreakStartTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakStartTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByBreakStartTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'breakStartTime', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByClassroomCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'classroomCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByClassroomCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'classroomCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByEndTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'endTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByEndTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'endTime', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByForceAdd() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'forceAdd', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByForceAddDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'forceAdd', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByIsarId() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'isarId', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByIsarIdDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'isarId', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByNotes() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'notes', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByNotesDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'notes', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByOrganizationCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'organizationCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByOrganizationCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'organizationCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByOverrideConflicts() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'overrideConflicts', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByOverrideConflictsDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'overrideConflicts', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByPublish() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'publish', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByPublishDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'publish', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByRepeat() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'repeat', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByRepeatDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'repeat', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenBySchoolCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'schoolCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenBySchoolCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'schoolCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenBySeriesCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'seriesCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenBySeriesCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'seriesCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByShiftCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByShiftCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByShiftDate() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftDate', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByShiftDateDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'shiftDate', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByStaffCode() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'staffCode', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByStaffCodeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'staffCode', Sort.desc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByStartTime() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'startTime', Sort.asc);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QAfterSortBy>
//       thenByStartTimeDesc() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addSortBy(r'startTime', Sort.desc);
//     });
//   }
// }

// extension StaffShiftCollectionQueryWhereDistinct
//     on QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct> {
//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByBreakEndTime({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'breakEndTime', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByBreakStartTime({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'breakStartTime',
//           caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByClassroomCode({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'classroomCode',
//           caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByEndTime({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'endTime', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByForceAdd() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'forceAdd');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByNotes({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByOrganizationCode({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'organizationCode',
//           caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByOverrideConflicts() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'overrideConflicts');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByPublish() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'publish');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByRepeat() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'repeat');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctBySchoolCode({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'schoolCode', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctBySeriesCode({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'seriesCode', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByShiftCode({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'shiftCode', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByShiftDate({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'shiftDate', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByStaffCode({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'staffCode', caseSensitive: caseSensitive);
//     });
//   }

//   QueryBuilder<StaffShiftCollection, StaffShiftCollection, QDistinct>
//       distinctByStartTime({bool caseSensitive = true}) {
//     return QueryBuilder.apply(this, (query) {
//       return query.addDistinctBy(r'startTime', caseSensitive: caseSensitive);
//     });
//   }
// }

// extension StaffShiftCollectionQueryProperty on QueryBuilder<
//     StaffShiftCollection, StaffShiftCollection, QQueryProperty> {
//   QueryBuilder<StaffShiftCollection, int, QQueryOperations> isarIdProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'isarId');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String?, QQueryOperations>
//       breakEndTimeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'breakEndTime');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String?, QQueryOperations>
//       breakStartTimeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'breakStartTime');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       classroomCodeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'classroomCode');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       endTimeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'endTime');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, bool, QQueryOperations>
//       forceAddProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'forceAdd');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String?, QQueryOperations>
//       notesProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'notes');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       organizationCodeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'organizationCode');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, bool, QQueryOperations>
//       overrideConflictsProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'overrideConflicts');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, bool, QQueryOperations> publishProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'publish');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, bool, QQueryOperations> repeatProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'repeat');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       schoolCodeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'schoolCode');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String?, QQueryOperations>
//       seriesCodeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'seriesCode');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String?, QQueryOperations>
//       shiftCodeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'shiftCode');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       shiftDateProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'shiftDate');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       staffCodeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'staffCode');
//     });
//   }

//   QueryBuilder<StaffShiftCollection, String, QQueryOperations>
//       startTimeProperty() {
//     return QueryBuilder.apply(this, (query) {
//       return query.addPropertyName(r'startTime');
//     });
//   }
// }
