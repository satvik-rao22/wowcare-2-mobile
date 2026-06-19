import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/assessments/models/assessment_models.dart';
import 'package:wowcare/data/features/assessments/models/assessment_parameter_models.dart';
import 'package:wowcare/data/features/assessments/models/assessment_reference_models.dart';

/// Development stand-in for the future Assessments remote datasource: returns
/// the bundled `mock-data.json` payload in the same shape the API is expected
/// to use, so swapping in a Dio-backed implementation later (PRD §18) only
/// changes where the JSON comes from.
abstract class AssessmentSeedDataSource {
  Future<List<DomainModel>> fetchDomains();
  Future<List<AssessmentModel>> fetchAssessments();
  Future<List<AssessmentClassroomModel>> fetchClassrooms();
  Future<List<AssessmentStudentModel>> fetchStudents();
}

class AssessmentSeedDataSourceImpl implements AssessmentSeedDataSource {
  static const String _assetPath = 'assets/data/assessments/mock-data.json';

  @override
  Future<List<DomainModel>> fetchDomains() async {
    final raw = await _loadSection('domains');
    return raw
        .whereType<Map>()
        .map((m) => DomainModel.fromJson(m.map((k, v) => MapEntry(k.toString(), v))))
        .where((d) => d.id.isNotEmpty && d.name.isNotEmpty)
        .toList();
  }

  @override
  Future<List<AssessmentModel>> fetchAssessments() async {
    final raw = await _loadSection('assessments');
    return raw
        .whereType<Map>()
        .map((m) =>
            AssessmentModel.fromJson(m.map((k, v) => MapEntry(k.toString(), v))))
        .where((a) => a.studentId.isNotEmpty && a.milestoneId.isNotEmpty)
        .toList();
  }

  @override
  Future<List<AssessmentClassroomModel>> fetchClassrooms() async {
    final raw = await _loadSection('classrooms');
    return raw
        .whereType<Map>()
        .map((m) => AssessmentClassroomModel.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v))))
        .where((c) => c.code.isNotEmpty && c.name.isNotEmpty)
        .toList();
  }

  @override
  Future<List<AssessmentStudentModel>> fetchStudents() async {
    final raw = await _loadSection('students');
    return raw
        .whereType<Map>()
        .map((m) => AssessmentStudentModel.fromJson(
            m.map((k, v) => MapEntry(k.toString(), v))))
        .where((s) => s.code.isNotEmpty && s.name.isNotEmpty)
        .toList();
  }

  Future<List<dynamic>> _loadSection(String key) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      final section = decoded is Map ? decoded[key] : null;
      return section is List ? section : const [];
    } catch (e) {
      AppLogger.e('[Assessments] Failed to load mock seed data ($key): $e');
      return const [];
    }
  }
}
