import 'dart:convert';
import 'package:equatable/equatable.dart';
import '../../../../core/util/typedefs.dart';
import '../../../../domain/features/Student-Module/entities/Student-Entity.dart';

class TagModel extends Tag {
  const TagModel({
    required super.id,
    required super.name,
    required super.schoolId,
    required super.status,
    required super.lastModified,
    required super.lastModifiedBy,
  });

  TagModel copyWith({
    int? id,
    String? name,
    int? schoolId,
    String? status,
    String? lastModified,
    String? lastModifiedBy,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'schoolId': schoolId,
      'status': status,
      'lastModified': lastModified,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  factory TagModel.fromMap(DataMap map) {
    return TagModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      schoolId: map['schoolId'] as int?,
      status: map['status'] as String?,
      lastModified: map['lastModified'] as String?,
      lastModifiedBy: map['lastModifiedBy'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TagModel.fromJson(String source) =>
      TagModel.fromMap(json.decode(source) as DataMap);

  @override
  bool get stringify => true;

  static const empty = TagModel(
    id: 0,
    name: '',
    schoolId: null,
    status: null,
    lastModified: null,
    lastModifiedBy: null,
  );

  static const demo = TagModel(
    id: 1,
    name: 'Creative',
    schoolId: 1,
    status: 'Active',
    lastModified: '2025-09-18',
    lastModifiedBy: 'Admin',
  );

  static const demoList = [demo];
}
