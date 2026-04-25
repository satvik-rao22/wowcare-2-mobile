import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/school_timezone_resolver.dart';
import '../../../../core/util/school_zone_datetime.dart';
import '../../../../core/util/staff_code_resolver.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../data/features/attendance/datasources/attendance_remote_datasource.dart';
import '../../../../data/features/attendance/repositories/attendance_repository_impl.dart';
import '../../../../domain/features/attendance/entities/student_attendance_custom.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../shared/common/widgets/custom_date_time_field.dart';
import '../../../../shared/common/widgets/ellipsis_tooltip_text.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import '../util/activity_filter_metadata_cache.dart';

class ActivityStudentSelection extends StatefulWidget {
  const ActivityStudentSelection({super.key});
  final bool showLoading = false;

  @override
  State<ActivityStudentSelection> createState() =>
      _ActivityStudentSelectionState();
}

class _ActivityStudentSelectionState extends State<ActivityStudentSelection> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Map<String, dynamic>> _selectedStudents = <Map<String, dynamic>>{};

  // Filters & options
  String? _selectedClassroom;
  bool _selectAll = false;
  List<String> _selectedTags = [];

  // Staff persona scoping
  List<String> _allowedClassroomCodes = const [];
  String? _primaryClassroomCode;

  // Options loaded from backend
  List<String> _classroomOptions = [];
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _classroomNameByCode = {};

  List<String> _tagOptions = [];
  final Map<String, String> _tagCodeByName = {};

  // API + storage
  late final StorageService _storageService;
  late final CacheManager _cacheManager;
  late final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  late final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  late final GetStudentAttendanceCustomUseCase _getStudentAttendanceCustomUseCase;
  String? _schoolCode;
  String _schoolTimeZone = SchoolTimezoneResolver.fallbackTimeZone;
  DateTime _selectedAttendanceDate = DateTime.now();

  // Students from /api/v1/student-attendance/view/custom for selected date
  List<StudentAttendanceCustomItem> _studentsForCurrentFilters = [];
  bool _isLoadingFilters = false;
  bool _isLoadingStudents = false;
  String? _studentsError;

  List<StudentAttendanceCustomItem> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _studentsForCurrentFilters;

    return _studentsForCurrentFilters.where((student) {
      final fullName = student.studentName.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  // List<MapEntry<String, List<String>>> get _filteredStudents {
  //   // 1. Start with all students
  //   Map<String, List<String>> allStudents = {};
  //
  //   // If no classroom selected → show all
  //   if (_selectedClassroom == null) {
  //     return [];
  //   } else {
  //     // Only selected classroom
  //     final selected = _studentsInSelectedClassroom[_selectedClassroom];
  //     if (selected != null) {
  //       allStudents = Map<String, List<String>>.from(selected);
  //     } else {
  //       return [];
  //     }
  //   }
  //
  //   // 2. Apply tag filtering if any tags selected
  //   if (_selectedTags.isNotEmpty) {
  //     allStudents.removeWhere((name, tags) {
  //       // Keep student only if they have ALL selected tags
  //       return !_selectedTags.every((tag) => tags.contains(tag));
  //     });
  //   }
  //
  //   // 3. Apply search filter
  //   final query = _searchController.text.trim().toLowerCase();
  //   if (query.isNotEmpty) {
  //     allStudents.removeWhere((name, tags) =>
  //     !name.toLowerCase().contains(query));
  //   }
  //
  //   return allStudents.entries.toList();
  // }

  void _updateSelectAllState() {
    final students = _filteredStudents;
    if (students.isEmpty) {
      _selectAll = false;
      return;
    }

    _selectAll = students.every((student) {
      final code = student.studentCode;
      return _selectedStudents.any((s) => s['studentCode'] == code);
    });
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isWarning: true,
      );
    });
  }


  @override
  void initState() {
    super.initState();
    _storageService = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storageService);
    _getActiveClassroomsUseCase = serviceLocator<GetActiveClassroomsUseCase>();
    _getTagNameCodeMapForSchoolUseCase =
        serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    if (serviceLocator.isRegistered<GetStudentAttendanceCustomUseCase>()) {
      _getStudentAttendanceCustomUseCase =
          serviceLocator<GetStudentAttendanceCustomUseCase>();
    } else {
      final apiClient = serviceLocator<ApiClient>();
      final remote = AttendanceRemoteDataSourceImpl(apiClient.client);
      final repo = AttendanceRepositoryImpl(remote, _storageService, apiClient);
      _getStudentAttendanceCustomUseCase = GetStudentAttendanceCustomUseCase(repo);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFiltersAndLoad();
    });
  }

  Future<void> _initFiltersAndLoad() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      _schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      if (_schoolCode == null || _schoolCode!.trim().isEmpty) {
        _showWarningMessage(
          'School code is not set. Please ensure you are logged in and a school is selected.',
        );
        setState(() {
          _isLoadingFilters = false;
        });
        return;
      }
      _schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: serviceLocator<ApiClient>(),
      );
      final schoolNow =
          SchoolZoneDateTime.schoolCalendarDateAndTimeNow(_schoolTimeZone).$1;
      _selectedAttendanceDate =
          DateTime(schoolNow.year, schoolNow.month, schoolNow.day);

      await _loadStaffClassroomScope();

      await Future.wait([
        _loadClassrooms(),
        _loadTags(),
      ]);

      if (_selectedClassroom != null) {
        await _loadStudentsForCurrentFilters();
      }
    } catch (error) {
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.logApiError('Failed to load activity filters: $message');
      _showWarningMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
        });
      }
    }
  }

  Future<void> _loadClassrooms({bool forceRefresh = false}) async {
    if (_schoolCode == null || _schoolCode!.trim().isEmpty) return;

    final classroomCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'classrooms',
      identifier: _schoolCode!.trim(),
    );

    // Fast path: show cached classrooms first (if available).
    var hydratedFromCache = false;
    if (!forceRefresh) {
      try {
        final cached = await _cacheManager.loadCache(classroomCacheKey);
        if (cached != null && cached['classrooms'] is List && mounted) {
          final list = (cached['classrooms'] as List)
              .whereType<Map>()
              .map((e) => <String, String>{
                    'name': (e['name'] ?? '').toString(),
                    'code': (e['code'] ?? '').toString(),
                  })
              .where((e) => e['name']!.trim().isNotEmpty && e['code']!.trim().isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            final scoped = _allowedClassroomCodes.isEmpty
                ? list
                : list
                    .where((c) => _allowedClassroomCodes.contains((c['code'] ?? '').trim()))
                    .toList();
            setState(() {
              _classroomOptions = scoped.map((c) => c['name']!).toList();
              _classroomCodeByName
                ..clear()
                ..addEntries(scoped.map((c) => MapEntry(c['name']!, c['code']!)));
              _classroomNameByCode
                ..clear()
                ..addEntries(scoped.map((c) => MapEntry(c['code']!, c['name']!)));

              if (_selectedClassroom == null || !_classroomOptions.contains(_selectedClassroom)) {
                final primaryCode = (_primaryClassroomCode ?? '').trim();
                final primaryName = primaryCode.isNotEmpty ? _classroomNameByCode[primaryCode] : null;
                _selectedClassroom = primaryName ?? (_classroomOptions.isNotEmpty ? _classroomOptions.first : null);
              }
            });
            hydratedFromCache = true;
          }
        }
      } catch (_) {}
    }

    if (hydratedFromCache && !forceRefresh) {
      return;
    }

    try {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: _schoolCode!,
        onlyTypeClassroom: true,
      );

      if (!mounted) return;

      setState(() {
        final scoped = _allowedClassroomCodes.isEmpty
            ? classrooms
            : classrooms
                .where((c) => _allowedClassroomCodes.contains(c.code.trim()))
                .toList();

        _classroomOptions = scoped.map((c) => c.name).toList();
        _classroomCodeByName
          ..clear()
          ..addEntries(scoped.map((c) => MapEntry(c.name, c.code)));
        _classroomNameByCode
          ..clear()
          ..addEntries(scoped.map((c) => MapEntry(c.code, c.name)));

        // Default: primary classroom (if allowed), else first allowed.
        if (_selectedClassroom == null || !_classroomOptions.contains(_selectedClassroom)) {
          final primaryCode = (_primaryClassroomCode ?? '').trim();
          final primaryName = primaryCode.isNotEmpty ? _classroomNameByCode[primaryCode] : null;
          _selectedClassroom = primaryName ?? (_classroomOptions.isNotEmpty ? _classroomOptions.first : null);
        }
      });

      await _cacheManager.saveCache(classroomCacheKey, {
        'classrooms': classrooms.map((c) => {'name': c.name, 'code': c.code}).toList(),
      });
    } catch (error) {
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.logApiError('Failed to load classrooms: $message');
      _showWarningMessage(message);
    }
  }

  Future<void> _loadStaffClassroomScope() async {
    // Scope only applies to staff/teacher personas (not parent/guardian; not admins).
    final roles = (await _storageService.getString(StorageKeys.roles) ?? '').toUpperCase();
    if (roles.contains('GUARDIAN') || roles.contains('PARENT')) {
      _allowedClassroomCodes = const [];
      _primaryClassroomCode = null;
      return;
    }

    final staffType =
        (await _storageService.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      _allowedClassroomCodes = const [];
      _primaryClassroomCode = null;
      return;
    }

    List<String> decodeCodes(String raw) {
      if (raw.trim().isEmpty) return <String>[];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return <String>[];
    }

    final cached = (await _storageService.getString(StorageKeys.staffAllowedClassroomCodes) ?? '').trim();
    var allowed = decodeCodes(cached);

    try {
      final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      if (staffCode.isNotEmpty) {
        final repo = serviceLocator<StaffRepository>();
        final profile = await repo.getStaffProfile(
          staffCode: staffCode,
          forEditStaff: true,
        );
        final primary = profile.primaryClassroomCode.trim();
        final profileAllowed = profile.allowedClassroomCodes
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (profileAllowed.isNotEmpty) {
          allowed = profileAllowed;
          // Keep cache warm for subsequent screens.
          await _storageService.saveString(
            StorageKeys.staffAllowedClassroomCodes,
            jsonEncode(profileAllowed),
          );
        }

        _primaryClassroomCode = primary.isNotEmpty ? primary : null;
      }
    } catch (_) {
      // Non-blocking: fall back to cached allowed codes.
    }

    _allowedClassroomCodes = allowed;
  }

  Future<void> _loadTags({bool forceRefresh = false}) async {
    if (_schoolCode == null || _schoolCode!.trim().isEmpty) return;

    try {
      final nameCodeMap = await ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _getTagNameCodeMapForSchoolUseCase,
        schoolCode: _schoolCode!.trim(),
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _tagCodeByName
          ..clear()
          ..addAll(nameCodeMap);
        _tagOptions = nameCodeMap.keys.toList()..sort();
      });
    } catch (error) {
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.logApiError('Failed to load tags: $message');
      // Tags are non-critical, but still show backend message once.
      _showWarningMessage(message);
    }
  }

  Future<void> _loadStudentsForCurrentFilters({bool refresh = false}) async {
    if (_schoolCode == null || _schoolCode!.trim().isEmpty) {
      return;
    }

    final selectedClassroomCode =
        (_classroomCodeByName[_selectedClassroom]?.trim() ?? '');
    final classroomCodes = selectedClassroomCode.isEmpty
        ? (_primaryClassroomCode?.trim().isNotEmpty == true
            ? <String>[_primaryClassroomCode!.trim()]
            : null)
        : <String>[selectedClassroomCode];

    final tagCodes = _selectedTags
        .map((name) => _tagCodeByName[name])
        .whereType<String>()
        .toList();

    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final selectedDate = _formatAttendanceDate(_selectedAttendanceDate);
      final page = await _getStudentAttendanceCustomUseCase(
        fromAttendanceDate: selectedDate,
        toAttendanceDate: selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes.isEmpty ? null : tagCodes,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        page: 0,
        size: 200,
      );
      final students =
          page.items.where((item) => item.hasSignIn).toList(growable: false);

      if (!mounted) return;

      setState(() {
        _studentsForCurrentFilters = students;
        _isLoadingStudents = false;
        _studentsError = null;
      });
      _updateSelectAllState();
    } catch (error) {
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.logApiError('Failed to load students: $message');
      setState(() {
        _isLoadingStudents = false;
        _studentsError = message;
      });
      _showWarningMessage(message);
    }
  }

  void _applyFilters() => setState(() {});

  String _classroomLabelForStudent(StudentAttendanceCustomItem student) {
    final fromApi = student.classroomName.trim();
    if (fromApi.isNotEmpty) return fromApi;
    final mapped = _classroomNameByCode[student.classroomCode.trim()] ?? '';
    return mapped.trim().isEmpty ? 'Classroom' : mapped.trim();
  }

  String _formatAttendanceDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final yyyy = normalized.year.toString().padLeft(4, '0');
    final mm = normalized.month.toString().padLeft(2, '0');
    final dd = normalized.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _onPullRefresh() async {
    if (_schoolCode == null || _schoolCode!.trim().isEmpty) {
      _showWarningMessage(
        'School code is not set. Please ensure you are logged in and a school is selected.',
      );
      return;
    }
    await Future.wait([
      _loadClassrooms(forceRefresh: true),
      _loadTags(forceRefresh: true),
    ]);
    if (!mounted) return;
    if (_selectedClassroom != null) {
      await _loadStudentsForCurrentFilters(refresh: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return StaffFormLayout(
      title: 'Add Activity',
                  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Text(
                                  'Select Students',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff573353),
                                  ),
                                ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
            child: TextField(
                                    controller: _searchController,
              decoration: InputDecoration(
                                    hintText: 'Search Students',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                                          _searchController.clear();
                          _applyFilters();
                          _updateSelectAllState();
                        },
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
              ),
              onChanged: (_) {
                _applyFilters();
                                          _updateSelectAllState();
                                      },
                                ),
                            ),
          const SizedBox(height: 12),
          CustomDateTimeField(
            hasLabel: false,
            initialDate: _selectedAttendanceDate,
            fetchInitialTime: false,
            onDateSelected: (date) {
              setState(() {
                _selectedAttendanceDate = DateTime(date.year, date.month, date.day);
                _selectedStudents.clear();
                _selectAll = false;
              });
              _loadStudentsForCurrentFilters(refresh: true);
            },
          ),
          const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomDropdown(
                                    'Classroom',
                                    _classroomOptions,
                                    _selectedClassroom,
                  (v) {
                    setState(() {
                                      _selectedClassroom = v;
                      // Students across classrooms cannot be selected together
                      _selectedStudents.clear();
                                      _selectAll = false;
                    });
                    _loadStudentsForCurrentFilters();
                  },
                                  ),
                                ),
              const SizedBox(width: 12),
                                Expanded(
                                  child: CustomMultiSelectDropdown(
                                    hintText: 'Tags',
                                    items: _tagOptions,
                                    selectedItems: _selectedTags,
                                    gapHeight: 6,
                                    onChanged: (selectedItems) {
                                      setState(() {
                                        _selectedTags = selectedItems;
                                      });
                    _loadStudentsForCurrentFilters();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: CustomCheckbox(
                                value: _selectAll,
                                onChanged: (v) {
                                  final newVal = v ?? false;
                                  setState(() {
                                    _selectAll = newVal;
                                    if (newVal) {
                        for (final student in _filteredStudents) {
                                        _selectedStudents.add({
                            'name': student.studentName,
                                          'classroom': _classroomLabelForStudent(student),
                            'classroomCode': student.classroomCode,
                            'studentCode': student.studentCode,
                            'profilePictureUrl': '',
                            'status': '',
                            'expectedToday': student.isExpectedToday,
                            'signedIn': student.hasSignIn,
                            'absent': false,
                            'notMarked': false,
                            'nappingStatus': false,
                            'photoPermission': true,
                            'notes': '',
                            'medication': '',
                            'allergies': '',
                            'dietaryRestriction': '',
                            'signedInBy': student.signedInBy,
                            'signedInTime': student.signedInTime,
                            'signedOutBy': student.signedOutBy,
                            'signedOutTime': student.signedOutTime,
                            'attendanceDate': _formatAttendanceDate(_selectedAttendanceDate),
                                        });
                                      }
                                    } else {
                                      _selectedStudents.removeWhere((s) =>
                                          _filteredStudents.any((st) =>
                                              st.studentCode == s['studentCode']));
                                    }
                                  });
                  },
                  borderColor: AppColors.themeColor,
                ),
              ),
              Text(
                'Select All',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff573353),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_classroomOptions.isNotEmpty) {
                      final primaryCode = (_primaryClassroomCode ?? '').trim();
                      final primaryName = primaryCode.isNotEmpty ? _classroomNameByCode[primaryCode] : null;
                      _selectedClassroom = primaryName ?? _classroomOptions.first;
                    }
                    _selectedStudents.clear();
                    _searchController.clear();
                    _selectedTags = [];
                    final schoolNow =
                        SchoolZoneDateTime.schoolCalendarDateAndTimeNow(_schoolTimeZone).$1;
                    _selectedAttendanceDate =
                        DateTime(schoolNow.year, schoolNow.month, schoolNow.day);
                    _selectAll = false;
                  });
                  _loadStudentsForCurrentFilters();
                },
                child: const Text('Clear'),
                              ),
            ],
                            ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomRefreshIndicator(
              onRefresh: _onPullRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_isLoadingFilters || _isLoadingStudents)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else if (_filteredStudents.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _selectedClassroom == null
                              ? 'Select a classroom to view students or use the search bar'
                              : (_studentsError ??
                                  'No students match the selected filters'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'Manrope',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: responsive.isTablet ? 3 : 2,
                        crossAxisSpacing: responsive.isTablet ? 16 : 12,
                        mainAxisSpacing: responsive.isTablet ? 16 : 12,
                        mainAxisExtent: 72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final student = _filteredStudents[index];
                          final String name = student.studentName;
                          final String studentCode = student.studentCode;
                          const bool isNapping = false;

                          final bool isSelected = _selectedStudents.any(
                            (s) => s['studentCode'] == studentCode,
                          );

                          return _ActivityStudentListItem(
                            name: name,
                            isNapping: isNapping,
                            isSelected: isSelected,
                            onSelectionChanged: (selected) {
                              ScaffoldMessenger.of(context)
                                  .removeCurrentSnackBar();
                              setState(() {
                                if (selected == true) {
                                  _selectedStudents.add({
                                    'name': name,
                                    'classroom': _classroomLabelForStudent(student),
                                    'classroomCode': student.classroomCode,
                                    'studentCode': student.studentCode,
                                    'profilePictureUrl': '',
                                    'status': '',
                                    'expectedToday': student.isExpectedToday,
                                    'signedIn': student.hasSignIn,
                                    'absent': false,
                                    'notMarked': false,
                                    'nappingStatus': isNapping,
                                    'photoPermission': true,
                                    'notes': '',
                                    'medication': '',
                                    'allergies': '',
                                    'dietaryRestriction': '',
                                    'signedInBy': student.signedInBy,
                                    'signedInTime': student.signedInTime,
                                    'signedOutBy': student.signedOutBy,
                                    'signedOutTime': student.signedOutTime,
                                    'attendanceDate': _formatAttendanceDate(
                                      _selectedAttendanceDate,
                                    ),
                                  });
                                } else {
                                  _selectedStudents.removeWhere(
                                    (s) =>
                                        s['studentCode'] == studentCode,
                                  );
                                }
                                _updateSelectAllState();
                              });
                            },
                          );
                        },
                        childCount: _filteredStudents.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
            ],
          ),
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          cancelButtonLabel: 'Cancel',
          onPressedCancel: () => Navigator.of(context).pop(),
          onPressedConfirm: () {
            if (_selectedStudents.isNotEmpty) {
              final selectedDate = _formatAttendanceDate(_selectedAttendanceDate);
              final normalizedSelectedStudents = _selectedStudents
                  .map((student) {
                    final next = Map<String, dynamic>.from(student);
                    next['attendanceDate'] = selectedDate;
                    return next;
                  })
                  .toList(growable: false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChooseActivity(
                    selectedStudents: normalizedSelectedStudents,
                  ),
                ),
              );
            } else {
              _showWarningMessage('Select at least one student.');
            }
          },
        ),
      ),
    );
  }

  Widget _buildCustomDropdown(
    String hintText,
    List<String> items,
    String? selectedItem,
    ValueChanged<String?> onSelect, {
    bool isRequired = false,
    double? height = null,
  }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      //fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      fieldHeight: 40,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xff573353),
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      // contentPadding: EdgeInsets.symmetric(
      //   horizontal: responsive.isTablet ? 16.0 : 12.0,
      //   vertical: responsive.isTablet ? 16.0 : 12.0,
      // ),
    );
  }

  // Widget _buildShimmer() {
  //   return GridView.builder(
  //       padding: EdgeInsets.zero,
  //       physics: const NeverScrollableScrollPhysics(),
  //       shrinkWrap: true,
  //       itemCount: widget.sections.length,
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6),
  //       itemBuilder: (context, index) {
  //         return Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(widget.sections[index].label, style: TextStyle(color: AppColors.primaryColor, fontSize: 13),),
  //             const SizedBox(height: 8,),
  //             const ShimmerLoader(height: 40,)
  //           ],
  //         );
  //       }
  //   );
  // }

}

class _ActivityStudentListItem extends StatelessWidget {
  final String name;
  final bool isNapping;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const _ActivityStudentListItem({
    required this.name,
    required this.isNapping,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelectionChanged(!isSelected),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.themeColor,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color.fromARGB(255, 249, 245, 250)
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
              ),
              DocumentImageWidget(
                fileUuid: '',
                name: name,
                size: 32,
                fontSize: 14,
              ),
              if (isNapping) ...[
                const SizedBox(width: 4),
                Image.asset(
                  MediaRes.sleepStatusIcon,
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: EllipsisTooltipText(
                  text: name.trim().isEmpty ? 'Student' : name.trim(),
                  maxLines: 2,
                  preferLongPress: true,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
