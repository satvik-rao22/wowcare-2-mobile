import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import '../../../../../app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';

// Dummy data model for UI-only implementation
class _AbsentStudentModel {
  final String id;
  final String name;
  final String? photoUuid;
  final String roomName;
  final int absentDays;
  final DateTime startDate;
  final String absentTime;
  final String absentBy;
  final String? note;
  final int studentId;
  final int roomId;
  final int schoolId;

  _AbsentStudentModel({
    required this.id,
    required this.name,
    this.photoUuid,
    required this.roomName,
    required this.absentDays,
    required this.startDate,
    required this.absentTime,
    required this.absentBy,
    this.note,
    required this.studentId,
    required this.roomId,
    required this.schoolId,
  });
}

class StudentAttendanceAbsentView extends StatefulWidget {
  const StudentAttendanceAbsentView({
    super.key,
    this.contentOnly = false,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
    this.refreshNotifier,
  });

  final bool contentOnly;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;
  final ValueNotifier<int>? refreshNotifier;

  @override
  State<StudentAttendanceAbsentView> createState() =>
      _StudentAttendanceAbsentViewState();
}

class _StudentAttendanceAbsentViewState
    extends State<StudentAttendanceAbsentView>
    implements AttendanceTabRefresh {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  List<String> _selectedClassroomNames = <String>[];
  List<String>? _selectedClassroomCodes;
  List<String> _selectedTagNames = <String>[];
  List<String> _availableTagNames = <String>[];
  Map<String, String> _tagNameToCode = <String, String>{};
  bool _isLoadingTagMap = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int? _expandedStudentIndex;
  bool _isClassroomDataReady = false;

  // Pagination & list state
  bool _isInitialLoadingStudents = true;
  bool _isLoadingStudents = false;
  bool _isBackgroundFetchingStudents = false;
  int _studentsPage = 0;
  bool _studentsHasMore = true;
  final int _pageSize = 10;
  final List<_AbsentStudentModel> _absentStudents = [];
  late final CacheManager _cacheManager;
  bool isLoading = false;
  String? errorMessage;

  // Loading state for individual buttons
  final Map<int, bool> _loadingButtons = {};
  late final ClassroomCubit _classroomCubit;
  final GetClassroomByCodeUseCase _getClassroomByCode =
      serviceLocator<GetClassroomByCodeUseCase>();
  final Map<String, String> _classroomNameByCode = {};
  final Set<String> _classroomFetchInFlight = {};

  /// When the school allows teacher cross-class attendance, teachers see every
  /// classroom in the filter (like an admin) instead of just their own.
  bool _allowCrossClass = false;

  @override
  void initState() {
    super.initState();
    _cacheManager = CacheManager(serviceLocator<StorageService>());
    _initializeDefaultRange();
    _searchController.addListener(_onSearchChanged);
    widget.refreshNotifier?.addListener(_onRefreshRequested);
    _classroomCubit = serviceLocator<ClassroomCubit>();
    _resolveCrossClassFlag();
    // Classroom filter must be backed by the classroom(all) API (type=CLASSROOM).
    // We also guard for "data not loaded yet" so name->code resolution is reliable.
    _loadClassroomData();
    _loadTagData();

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    // Resolve the school timezone, then re-seed the default range if it differs.
    _initSchoolTimezone();
  }

  void _onRefreshRequested() => refreshAfterReturningFromAttendanceFlow();

  @override
  void refreshAfterReturningFromAttendanceFlow() {
    if (!mounted) return;
    _loadInitialData(reset: true);
  }

  /// Resolves the school's teacher cross-class flag; when enabled, reloads the
  /// classroom filter unscoped so teachers see every classroom.
  Future<void> _resolveCrossClassFlag() async {
    try {
      final enabled =
          await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
            storage: serviceLocator<StorageService>(),
          );
      if (!mounted || !enabled || _allowCrossClass) return;
      setState(() => _allowCrossClass = true);
      _loadClassroomData();
    } catch (_) {
      // Non-critical: default (scoped) behaviour stays in effect.
    }
  }

  Future<void> _loadClassroomData() async {
    final hadClassroomSelection = _selectedClassroomNames.isNotEmpty;
    _classroomCubit.loadActiveClassrooms(
      force: true,
      // The classroom filter must list only real classrooms (type=CLASSROOM) —
      // Office / Admin locations must not appear as filter options. Names for
      // non-CLASSROOM location codes are still resolved on demand via
      // getClassroomByCode (see _fetchClassroomName).
      onlyTypeClassroom: true,
      // Cross-class teachers see every classroom in the filter, like an admin.
      applyAttendanceStaffScope: !_allowCrossClass,
    );

    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isClassroomDataReady = true);
      if (hadClassroomSelection) {
        _syncClassroomFilterCodes();
        if (_selectedClassroomCodes != null) {
          _loadAbsentStudents(reset: true);
        }
      }
      return;
    }

    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    setState(() {
      _isClassroomDataReady =
          !_classroomCubit.state.isLoading &&
          _classroomCubit.state.classrooms.isNotEmpty;
    });
    if (hadClassroomSelection && _isClassroomDataReady) {
      _syncClassroomFilterCodes();
      if (_selectedClassroomCodes != null) {
        _loadAbsentStudents(reset: true);
      }
    }
  }

  Future<void> _loadTagData() async {
    if (_isLoadingTagMap) return;
    setState(() {
      _isLoadingTagMap = true;
    });
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        setState(() {
          _isLoadingTagMap = false;
        });
        return;
      }

      // Load full name->code map for sending tagCodes to API
      final getMap = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
      final map = await getMap(schoolCode: schoolCode);

      // Load just names for UI dropdown
      final getNames = serviceLocator<GetTagNamesForSchoolUseCase>();
      final names = await getNames(schoolCode: schoolCode);

      if (!mounted) return;
      setState(() {
        _tagNameToCode = map;
        _availableTagNames = names;
        // Remove any previously-selected tags that no longer exist
        _selectedTagNames.removeWhere(
          (name) => !_availableTagNames.contains(name),
        );
        _isLoadingTagMap = false;
      });
    } catch (e) {
      debugPrint('Failed to load tag data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingTagMap = false;
      });
    }
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshRequested);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  String? _resolveClassroomNameByCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    for (final c in _classroomCubit.state.classrooms) {
      if (c.code.trim() == trimmed) return c.name;
    }
    final cached = _classroomNameByCode[trimmed]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<void> _fetchClassroomName(String code) async {
    try {
      final details = await _getClassroomByCode(code: code);
      if (!mounted) return;
      final name = details.name.trim();
      if (name.isNotEmpty) {
        setState(() {
          _classroomNameByCode[code] = name;
        });
      }
    } catch (_) {
      // Keep code when lookup fails.
    } finally {
      _classroomFetchInFlight.remove(code);
    }
  }

  String _classroomDisplay({
    required String classroomCode,
    required String classroomName,
  }) {
    final apiName = classroomName.trim();
    if (apiName.isNotEmpty) return apiName;
    final code = classroomCode.trim();
    if (code.isEmpty) return '';
    final resolved = _resolveClassroomNameByCode(code);
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    if (!_classroomFetchInFlight.contains(code)) {
      _classroomFetchInFlight.add(code);
      // ignore: discarded_futures
      _fetchClassroomName(code);
    }
    return code;
  }

  void _initializeDefaultRange() {
    final now = attendanceSchoolToday();
    _rangeStart ??= DateTime(now.year, now.month, 1);
    _rangeEnd ??= DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _initSchoolTimezone() async {
    final beforeStart = _rangeStart;
    final beforeEnd = _rangeEnd;
    await bootstrapAttendanceSchoolTimezone();
    if (!mounted) return;
    final now = attendanceSchoolToday();
    final schoolStart = DateTime(now.year, now.month, 1);
    final schoolEnd = DateTime(now.year, now.month + 1, 0);
    if (beforeStart == _rangeStart &&
        beforeEnd == _rangeEnd &&
        (_rangeStart != schoolStart || _rangeEnd != schoolEnd)) {
      setState(() {
        _rangeStart = schoolStart;
        _rangeEnd = schoolEnd;
      });
      _loadInitialData();
    }
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text;
    setState(() {
      _searchQuery = newQuery;
    });

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _triggerSearchReload();
    });
  }

  void _triggerSearchReload() {
    _loadAbsentStudents(reset: true);
  }

  void _syncClassroomFilterCodes() {
    _selectedClassroomCodes = resolveClassroomNamesToCodes(
      selectedNamesOrCodes: _selectedClassroomNames,
      classrooms: _classroomCubit.state.classrooms,
    );
  }

  List<String>? _effectiveClassroomCodes() {
    if (_selectedClassroomNames.isEmpty) {
      _selectedClassroomCodes = null;
      return null;
    }
    _syncClassroomFilterCodes();
    return _selectedClassroomCodes;
  }

  void _reloadIfPendingClassroomFilter() {
    if (_selectedClassroomNames.isEmpty) return;
    _syncClassroomFilterCodes();
    if (_selectedClassroomCodes == null) return;
    _loadAbsentStudents(reset: true);
  }

  List<String>? _resolveSelectedTagCodes() {
    if (_selectedTagNames.isEmpty) return null;
    if (_tagNameToCode.isEmpty) return null;
    final codes = _selectedTagNames
        .map((n) => _tagNameToCode[n])
        .whereType<String>() // remove nulls
        .where((c) => c.trim().isNotEmpty)
        .toList();
    return codes.isEmpty ? null : codes;
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingStudents ||
        _isInitialLoadingStudents)
      return;
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent > 200
        ? position.maxScrollExtent - 100
        : position.maxScrollExtent * 0.8;
    if (!_isBackgroundFetchingStudents &&
        _studentsHasMore &&
        position.pixels >= threshold) {
      setState(() => _isBackgroundFetchingStudents = true);
      _loadAbsentStudents(fromBackground: true);
    }
  }

  Future<void> _loadInitialData({
    bool reset = false,
    bool fromBackground = false,
  }) async {
    // Try cache first to mirror cache integration used in student lists — but
    // never for a classroom-scoped staff persona. This cache key isn't keyed
    // per-user/per-scope, so serving it directly could leak another
    // classroom's absent students (or a stale unscoped/admin payload from an
    // earlier session on the same device) straight into a restricted view.
    if (!reset) {
      final scoped = await isStudentAttendanceScopedStaffPersona(
        storage: serviceLocator<StorageService>(),
      );
      if (!mounted) return;

      if (!scoped) {
        final from = _rangeStart ?? attendanceSchoolToday();
        final to = _rangeEnd ?? attendanceSchoolToday();
        final classroomCodes = _effectiveClassroomCodes();
        final tagCodes = _resolveSelectedTagCodes();
        final trimmedSearch = _searchQuery.trim();
        final hasActiveFilters =
            (classroomCodes != null && classroomCodes.isNotEmpty) ||
            (tagCodes != null && tagCodes.isNotEmpty) ||
            trimmedSearch.isNotEmpty;

        if (!hasActiveFilters) {
          final cacheKey = _studentAttendanceAbsentCacheKey(
            from,
            to,
            classroomCodes: classroomCodes,
            tagCodes: tagCodes,
            search: trimmedSearch.isNotEmpty ? trimmedSearch : null,
          );

          final cachedPayload = await _cacheManager.loadCache(cacheKey);
          if (!mounted) return;
          if (cachedPayload != null) {
            _applyPagePayload(cachedPayload, reset: true);
            return;
          }
        }
      }
    }

    await _loadAbsentStudents(reset: reset, fromBackground: fromBackground);
  }

  Future<void> _loadAbsentStudents({
    bool reset = false,
    bool fromBackground = false,
  }) async {
    if (_isLoadingStudents && !reset) return;

    if (_rangeStart == null || _rangeEnd == null) {
      _initializeDefaultRange();
    }

    final from = _rangeStart!;
    final to = _rangeEnd!;

    setState(() {
      _isLoadingStudents = true;
      isLoading = true;
      errorMessage = null;

      if (reset || _studentsPage == 0) {
        if (reset || !fromBackground) {
          _isInitialLoadingStudents = true;
        }
        _isBackgroundFetchingStudents = false;
        if (reset) {
          _absentStudents.clear();
        }
      }

      if (reset) {
        _studentsPage = 0;
        _studentsHasMore = true;
      }
    });

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final classroomCodes = _effectiveClassroomCodes();
    if (_selectedClassroomNames.isNotEmpty && classroomCodes == null) {
      setState(() {
        _isInitialLoadingStudents = false;
        _isLoadingStudents = false;
        isLoading = false;
      });
      return;
    }

    final tagCodes = _resolveSelectedTagCodes();

    final trimmedSearch = _searchQuery.trim();

    try {
      final data = await serviceLocator<AttendanceRepository>()
          .getStudentAttendanceAbsentView(
            fromAbsenceDate: fromStr,
            toAbsenceDate: toStr,
            classroomCodes: classroomCodes,
            tagCodes: tagCodes,
            search: trimmedSearch.isNotEmpty ? trimmedSearch : null,
            page: _studentsPage,
            size: _pageSize,
            sort: const <String>['studentName,asc'],
          );

      if (!mounted) return;

      if (data is! Map<String, dynamic>) {
        setState(() {
          _isInitialLoadingStudents = false;
          _isLoadingStudents = false;
          isLoading = false;
          _isBackgroundFetchingStudents = false;
        });
        return;
      }

      final root = data['data'] as Map<String, dynamic>? ?? {};

      // Cache first page keyed by filters so it can be reused on next load —
      // but only when this persona is unrestricted. A scoped staff member's
      // results must never be persisted to the shared cache: another user
      // (or this same user after their access changes) could otherwise read
      // back a payload that doesn't reflect their current classroom scope.
      if (_studentsPage == 0) {
        final scoped = await isStudentAttendanceScopedStaffPersona(
          storage: serviceLocator<StorageService>(),
        );
        if (!mounted) return;
        if (!scoped) {
          final from = _rangeStart ?? attendanceSchoolToday();
          final to = _rangeEnd ?? attendanceSchoolToday();
          final cacheKey = _studentAttendanceAbsentCacheKey(
            from,
            to,
            classroomCodes: classroomCodes,
            tagCodes: tagCodes,
            search: trimmedSearch.isNotEmpty ? trimmedSearch : null,
          );
          await _cacheManager.saveCache(cacheKey, root);
        }
      }

      _applyPagePayload(root, reset: reset);
    } catch (error) {
      debugPrint('StudentAbsent API error: $error');
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
      setState(() {
        _isInitialLoadingStudents = false;
        _isLoadingStudents = false;
        isLoading = false;
        _isBackgroundFetchingStudents = false;
        errorMessage = message;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAbsentStudents(reset: true);
  }

  /// Builds a cache key for the student absent toggle list,
  /// following the `{feature}_{resource}_cache_{identifier}` pattern.
  String _studentAttendanceAbsentCacheKey(
    DateTime from,
    DateTime to, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final parts = <String>[fromStr, toStr];

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      parts.add('classrooms=${classroomCodes.join(',')}');
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      parts.add('tags=${tagCodes.join(',')}');
    }

    final searchKey = (search ?? '').trim().toLowerCase();
    if (searchKey.isNotEmpty) {
      parts.add('search=$searchKey');
    }

    final identifier = parts.join('|');

    return CacheManager.buildCacheKey(
      feature: 'attendance',
      resource: 'student_absent_toggle',
      identifier: identifier,
    );
  }

  /// Formats 24-hour clock components as 12-hour with AM/PM (e.g. `2:05:03 PM`).
  String _timeComponentsTo12h(int hour, int minute, int second) {
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final mm = minute.toString().padLeft(2, '0');
    final ss = second.toString().padLeft(2, '0');
    return '$h12:$mm:$ss $period';
  }

  /// Applies a paged API/cache payload to local state and list.
  void _applyPagePayload(Map<String, dynamic> root, {required bool reset}) {
    final content = root['content'] as List<dynamic>? ?? const [];
    final last = root['last'] as bool? ?? true;
    final number = root['number'] as int? ?? _studentsPage;

    String parseTime(dynamic value) {
      if (value == null) return '';
      if (value is Map<String, dynamic>) {
        final hour = value['hour'] as int? ?? 0;
        final minute = value['minute'] as int? ?? 0;
        final second = value['second'] as int? ?? 0;
        return _timeComponentsTo12h(hour, minute, second);
      }
      if (value is String) {
        final s = value.trim();
        if (s.isEmpty) return '';
        final parts = s.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final secPart = parts.length >= 3 ? parts[2] : '0';
          final sec = int.tryParse(secPart.split('.').first) ?? 0;
          return _timeComponentsTo12h(h, m, sec);
        }
        final dt = DateTime.tryParse(s);
        if (dt != null) {
          return _timeComponentsTo12h(dt.hour, dt.minute, dt.second);
        }
        return s;
      }
      return value.toString();
    }

    final newData = content.asMap().entries.map<_AbsentStudentModel>((entry) {
      final indexInPage = entry.key;
      final e = entry.value;
      final m = e as Map<String, dynamic>;

      final absenceDateStr = m['absenceDate'] as String? ?? '';
      final absenceDate = absenceDateStr.isNotEmpty
          ? DateTime.tryParse(absenceDateStr) ?? attendanceSchoolToday()
          : attendanceSchoolToday();

      final classroomName = (m['classroomName'] as String?)?.trim() ?? '';
      final classroomCode = (m['classroomCode'] as String?)?.trim() ?? '';
      final roomDisplay = _classroomDisplay(
        classroomCode: classroomCode,
        classroomName: classroomName,
      );

      return _AbsentStudentModel(
        id: (m['studentCode'] as String?) ?? '',
        name: (m['studentName'] as String?) ?? '',
        photoUuid: null,
        roomName: roomDisplay,
        absentDays: (m['absentDays'] as int?) ?? 0,
        startDate: absenceDate,
        absentTime: parseTime(m['markedAbsentTime']),
        absentBy: (m['markedAbsentByName'] as String?) ?? '',
        note: (m['absenceNote'] as String?),
        // No numeric studentId available in this response - use a stable placeholder
        studentId: (number * _pageSize) + indexInPage,
        roomId: 0,
        schoolId: 0,
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      if (reset) {
        _absentStudents.clear();
      }
      _absentStudents.addAll(newData);
      _studentsHasMore = !last;
      _studentsPage = number + (newData.isNotEmpty ? 1 : 0);
      _isInitialLoadingStudents = false;
      _isLoadingStudents = false;
      isLoading = false;
      _isBackgroundFetchingStudents = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return _buildContent();
    }

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    final filtered = _absentStudents;

    return BlocListener<ClassroomCubit, ClassroomState>(
      bloc: _classroomCubit,
      listenWhen: (previous, current) =>
          previous.classrooms.isEmpty && current.classrooms.isNotEmpty,
      listener: (_, __) => _reloadIfPendingClassroomFilter(),
      child: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: contentPadding.left,
            vertical: responsive.verticalSpacing / 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.verticalSpacing / 4),
              // Filter section
              CustomSectionCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Row 1: Full-width Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Search Students',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Date Range (70%) + Clear All (30%)
                    Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: CustomDateTimeField(
                            hasLabel: false,
                            isRangePicker: true,
                            // Let the field compute and DISPLAY a default start–end (current month)
                            // so both dates are visible on first open.
                            fetchInitialTime: true,
                            onRangeSelected: (start, end) {
                              setState(() {
                                _rangeStart = start;
                                _rangeEnd = end;
                              });
                              _loadAbsentStudents(reset: true);
                            },
                          ),
                        ),
                        SizedBox(width: responsive.horizontalSpacing / 2),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedClassroomNames = <String>[];
                                  _selectedClassroomCodes = null;
                                  _selectedTagNames = <String>[];
                                  // Reset to current month
                                  final now = attendanceSchoolToday();
                                  _rangeStart = DateTime(
                                    now.year,
                                    now.month,
                                    1,
                                  );
                                  _rangeEnd = DateTime(
                                    now.year,
                                    now.month + 1,
                                    0,
                                  );
                                });
                                _loadAbsentStudents(reset: true);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 3: Classroom (50%) + Tags (50%)
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<ClassroomCubit, ClassroomState>(
                            bloc: _classroomCubit,
                            builder: (context, state) {
                              final items = state.classrooms
                                  .map((c) => c.name)
                                  .toList();
                              final isLoading =
                                  state.isLoading || !_isClassroomDataReady;
                              if (isLoading && items.isEmpty) {
                                return ShimmerLoader(height: 40);
                              }
                              return CustomMultiSelectDropdown(
                                hintText: 'Classroom',
                                items: items,
                                selectedItems: _selectedClassroomNames,
                                onChanged: (values) {
                                  setState(() {
                                    _selectedClassroomNames = List<String>.from(
                                      values,
                                    );
                                    _syncClassroomFilterCodes();
                                  });
                                  if (_selectedClassroomNames.isNotEmpty &&
                                      _selectedClassroomCodes == null) {
                                    return;
                                  }
                                  _loadAbsentStudents(reset: true);
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(width: responsive.horizontalSpacing / 2),
                        Expanded(
                          child: _isLoadingTagMap && _availableTagNames.isEmpty
                              ? ShimmerLoader(height: 40)
                              : CustomMultiSelectDropdown(
                                  hintText: 'Tags',
                                  items: _availableTagNames,
                                  selectedItems: _selectedTagNames,
                                  onChanged: (values) {
                                    setState(() {
                                      _selectedTagNames = List<String>.from(
                                        values,
                                      );
                                    });
                                    _loadAbsentStudents(reset: true);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.verticalSpacing),
              // Content section
              if (_isInitialLoadingStudents)
                Column(
                  children: List.generate(
                    6,
                    (index) => StudentAbsentCardShimmer(
                      key: ValueKey('shimmer_$index'),
                    ),
                  ),
                )
              else if (errorMessage != null)
                CustomSectionCard(
                  padding: EdgeInsets.all(responsive.horizontalSpacing),
                  backgroundColor: AppColors.errorColor.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.errorColor,
                        size: 48,
                      ),
                      SizedBox(height: responsive.verticalSpacing / 2),
                      AppText.body(
                        errorMessage ?? 'Unable to load absent students.',
                        style: TextStyle(color: AppColors.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: responsive.verticalSpacing / 2),
                      ElevatedButton(
                        onPressed: () => _loadInitialData(reset: true),
                        child: AppText.body(
                          'Retry',
                          style: TextStyle(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(responsive.verticalSpacing),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: AppColors.secondaryColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        SizedBox(height: responsive.verticalSpacing / 2),
                        AppText.body(
                          _absentStudents.isEmpty
                              ? 'No absent students found'
                              : 'No students match your filters',
                          style: TextStyle(color: AppColors.secondaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...filtered.asMap().entries.map((entry) {
                      final index = entry.key;
                      final student = entry.value;
                      return _buildAbsentStudentCard(student, index);
                    }).toList(),
                    // Pagination loader
                    if (_isLoadingStudents &&
                        _studentsHasMore &&
                        _studentsPage > 0 &&
                        !_isInitialLoadingStudents)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.verticalSpacing,
                        ),
                        child: const PrimaryCircularLoader(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbsentStudentCard(_AbsentStudentModel student, int index) {
    final responsive = ResponsiveHelper(context);
    final bool isExpanded = _expandedStudentIndex == index;
    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final spacing = responsive.isTablet ? 16.0 : 14.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedStudentIndex == index) {
            _expandedStudentIndex = null;
          } else {
            _expandedStudentIndex = index;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isTablet ? 16 : 12,
          vertical: responsive.isTablet ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo
                DocumentImageWidget(
                  fileUuid: student.photoUuid ?? '',
                  studentCode: student.id,
                  size: avatarSize,
                  name: student.name,
                  fontSize: responsive.isTablet ? 18 : 16,
                  disableAttendanceStatusLookup: true,
                ),
                SizedBox(width: spacing),
                // Header matches staff_card.dart: name (left) + classroom (right).
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          student.name,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          student.roomName,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildDetailRow(responsive, 'Classroom', student.roomName),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                responsive,
                'Absent Days',
                '${student.absentDays} days',
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                responsive,
                'Absent Date',
                DateFormat('MMM dd, yyyy').format(student.startDate),
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(responsive, 'Absent Time', student.absentTime),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(responsive, 'Marked By', student.absentBy),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                responsive,
                'Absent Note',
                (student.note != null && student.note!.trim().isNotEmpty)
                    ? student.note!.trim()
                    : '-',
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _loadingButtons[student.studentId] == true
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorderColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : CustomCancelButton(
                          cancelButtonLabel: 'View',
                          onPressedCancel: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentAttendanceProfile(
                                  studentCode: student.id,
                                  studentId: student.studentId,
                                  studentName: student.name,
                                  studentPhotoUuid: student.photoUuid,
                                  roomName: student.roomName,
                                  isSignedIn: false,
                                  isAbsent: true,
                                  isExpectedToday: true,
                                  isPresentToday: false,
                                  profileStatus: 'A',
                                  initialShowAbsentDays: true,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ResponsiveHelper responsive,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              height: 16 / 13,
            ),
          ),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff573353),
              height: 19 / 14,
            ),
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
