import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';

class ParentChildRef {
  const ParentChildRef({
    required this.code,
    required this.name,
    required this.classroom,
    this.tags = const <String>[],
    this.schedule = const <String>[],
  });

  final String code;
  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;

  factory ParentChildRef.fromStudent(Student student) {
    return ParentChildRef(
      code: student.code,
      name: student.fullName.trim().isNotEmpty ? student.fullName.trim() : student.code,
      classroom: student.classroom,
      tags: student.tags,
      schedule: student.schedule,
    );
  }
}

class ParentChildProvider extends ChangeNotifier {
  ParentChildRef? _selectedChild;
  List<ParentChildRef> _children = const <ParentChildRef>[];
  bool _isLoading = false;
  bool _isLoaded = false;
  /// Last session we successfully loaded for (user|org|school). Drives reload on context change.
  String _lastLoadedContextKey = '';

  ParentChildRef? get selectedChild => _selectedChild;
  List<ParentChildRef> get children => _children;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  List<String> get childNames => _children.map((e) => e.name).toList(growable: false);

  static String _contextKey(String userCode, String orgCode, String schoolCode) =>
      '${userCode.toLowerCase()}|${orgCode.toLowerCase()}|${schoolCode.toLowerCase()}';

  /// Clears cached children so the next [ensureLoaded] runs a full fetch (e.g. logout, manual refresh).
  void invalidate() {
    _isLoaded = false;
    _isLoading = false;
    _lastLoadedContextKey = '';
    _children = const <ParentChildRef>[];
    _selectedChild = null;
    notifyListeners();
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (_isLoading) return;

    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();

    if (userCode.isEmpty) {
      _children = const <ParentChildRef>[];
      _selectedChild = null;
      _isLoaded = false;
      _lastLoadedContextKey = '';
      _isLoading = false;
      notifyListeners();
      return;
    }

    final contextKey = _contextKey(userCode, orgCode, schoolCode);
    final contextChanged = contextKey != _lastLoadedContextKey;

    if (_isLoaded && !force && !contextChanged) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final remote = serviceLocator<StudentRemoteDataSource>();
      final studentPage = serviceLocator<GetStudentPageUseCase>();
      final guardianCode = (await resolveGuardianCodeForLoggedInUser()).trim();

      if (guardianCode.isEmpty ||
          schoolCode.isEmpty ||
          orgCode.isEmpty ||
          userCode.isEmpty) {
        _children = const <ParentChildRef>[];
        _selectedChild = null;
        _isLoaded = true;
        _lastLoadedContextKey = '';
        return;
      }

      final rawChildren = await remote.getGuardianChildren(
        guardianCode: guardianCode,
        schoolCode: schoolCode,
        userCode: userCode,
      );
      final byCode = <String, ParentChildRef>{};
      for (final row in rawChildren) {
        final code = (row['code'] ?? row['studentCode'] ?? '').toString().trim();
        if (code.isEmpty) continue;
        final firstName = (row['firstName'] ?? '').toString().trim();
        final lastName = (row['lastName'] ?? '').toString().trim();
        final fullName = '$firstName $lastName'.trim();
        byCode[code] = ParentChildRef(
          code: code,
          name: fullName.isNotEmpty ? fullName : code,
          classroom: '',
        );
      }

      if (byCode.isNotEmpty) {
        try {
          final page = await studentPage(
            schoolCode: schoolCode,
            guardianCodes: <String>[guardianCode],
            page: 0,
            size: 500,
          );

          for (final student in page.items) {
            final code = student.code.trim();
            if (!byCode.containsKey(code)) continue;
            byCode[code] = ParentChildRef.fromStudent(student);
          }
        } catch (_) {
          // Keep API children as source-of-truth even if enrichment fails.
        }
      }

      final loadedChildren = byCode.values.toList(growable: false);

      _children = loadedChildren;
      if (_children.isEmpty) {
        _selectedChild = null;
      } else {
        final selectedCode = _selectedChild?.code.trim();
        ParentChildRef? matching;
        if (selectedCode != null && selectedCode.isNotEmpty) {
          for (final child in _children) {
            if (child.code.trim() == selectedCode) {
              matching = child;
              break;
            }
          }
        }
        _selectedChild = matching ?? _children.first;
      }
      _isLoaded = true;
      _lastLoadedContextKey = contextKey;
    } catch (_) {
      _children = const <ParentChildRef>[];
      _selectedChild = null;
      _isLoaded = true;
      _lastLoadedContextKey = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectByName(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return;
    ParentChildRef? next;
    for (final child in _children) {
      if (child.name == trimmed) {
        next = child;
        break;
      }
    }
    if (next == null) return;
    if (_selectedChild?.code == next.code) return;
    _selectedChild = next;
    notifyListeners();
  }
}
