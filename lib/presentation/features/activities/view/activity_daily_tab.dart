import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/activities/view/edit_create_activity_screens/nap_activity.dart';
import 'package:wowcare/presentation/features/activities/widgets/avtivity_media_preview.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/guardian_code_resolver.dart';
import '../../../../core/util/activity_feed_invalidation.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/activity/entities/activity_detail.dart';
import '../../../../domain/features/activity/entities/activity_feed_row.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../../../domain/features/activity/usecases/get_daily_activity_feed_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../util/activity_filter_metadata_cache.dart';
import 'activity_filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';
import '../util/activity_feed_page_cache_codec.dart';
import '../util/activity_parent_feed_merge.dart';

class ActivityDailyTab extends StatefulWidget {
  const ActivityDailyTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.studentProfile,
    this.isNotParent = true,
    this.allowActivityWrite = true,
  });

  final bool fromStudentProfile;
  /// Display name when opened from student profile.
  final String? studentName;
  /// Optional map (e.g. `name`, `studentCode`) when opened from student profile.
  final Map<String, dynamic>? studentProfile;
  final bool isNotParent;
  /// Edit / delete / add; false when [DAILY_ACTIVITY] has `write: false`.
  final bool allowActivityWrite;

  static const String routeName = '/activityDailyTab';

  @override
  State<ActivityDailyTab> createState() => _ActivityDailyTabState();
}

class _ActivityDailyTabState extends State<ActivityDailyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  //final TextEditingController _searchController = TextEditingController();
  late bool isNotParent;
  bool get _parentHome => !isNotParent && !widget.fromStudentProfile;

  DateTime? _selectedDate = DateTime.now();
  String? _selectdClassroom;
  String? _selectedStudent;
  List<String> _availableStudents = [];
  List<String> _filterTags = [];
  List<String> _filterActivityTypes = [];
  String? _selectedActivityType;
  final List<String> activityType = [
    'Nap Start',
    'Nap End',
    'Bathroom',
    'Bottle',
    'Meal',
    'Incident',
    'Photo',
    'Outdoor',
    'Medication',
    'Notes',
    'Learning',
    'Sign-in',
    'Sign-out',
    'Absent',
  ];
  List<String> _classroomOptions = [];
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _studentCodeByName = {};
  List<ActivityItem> _activities = [];
  static const int _feedPageSize = 10;
  final ScrollController _feedScrollController = ScrollController();
  bool _feedHasMore = false;
  bool _loadingMoreFeed = false;
  int _feedNextPage = 0;
  bool _loadingFeed = false;
  bool _isFeedRequestInFlight = false;
  String? _lastFeedRequestKey;
  DateTime? _lastFeedCompletedAt;
  bool _lastFeedCompletedWithError = false;
  String? _feedError;
  String? _schoolCode;
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  Map<String, String> _tagNameToCode = {};
  final Set<String> _studentCodesForTagFilter = {};

  /// Guardian home: children we may show activities for.
  final Set<String> _parentAllowedStudentCodes = {};
  final Map<String, String> _parentStudentClassroomByCode = {};
  bool _loadingParentContext = false;

  late final GetDailyActivityFeedUseCase _getDailyActivityFeedUseCase;
  late final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  late final GetClassroomActivitySettingsUseCase
      _getClassroomActivitySettingsUseCase;
  late final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  late final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  late final GetStudentPageUseCase _getStudentPageUseCase;
  late final DeleteActivityUseCase _deleteActivityUseCase;
  late final StorageService _storageService;
  late final CacheManager _cacheManager;
  StreamSubscription<void>? _feedInvalidationSub;

  final List<Color> _colorPalette = [
    const Color(0xFFB3E5FC),
    const Color(0xFFFFCCBC),
    const Color(0xFFC8E6C9),
    const Color(0xFFFFE0B2),
    //const Color(0xFFFFF9C4),
    const Color(0xFFE1BEE7),
    //const Color(0xFFCCFF90),
    const Color(0xFF80DEEA),
    const Color(0xFFD1C4E9),
    const Color(0xFFFFAB91),
  ];
  // final List<String> _allStudents = [
  //   'Raghave Gupta',
  //   'Rohan Gupta',
  //   'Ruhi Gupta',
  //   'Anya Mehta',
  //   'Kabir Mehta',
  //   'Sara Khan',
  // ];
  // Map activity label to the destination edit activity screen
  static final Map<String, Widget Function(ActivityItem)> editActivityRoutes = {
    'Nap Start': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Nap End': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Bathroom': (activity) =>
        BathroomActivityScreen(activityData: activity, isEdit: true),
    'Bottle': (activity) =>
        BottleActivityScreen(activityData: activity, isEdit: true),
    'Meal': (activity) =>
        MealActivityScreen(activityData: activity, isEdit: true),
    'Incident': (activity) =>
        IncidentActivityScreen(activityData: activity, isEdit: true),
    'Photo': (activity) =>
        PhotoVideoActivityScreen(activityData: activity, isEdit: true, isPhoto: true,),
    'Video': (activity) =>
        PhotoVideoActivityScreen(activityData: activity, isEdit: true, isPhoto: false,),
    'Medication': (activity) =>
        MedicationActivityScreen(activityData: activity, isEdit: true),
    'Notes': (activity) =>
        NotesActivityScreen(activityData: activity, isEdit: true),
    'Outdoor': (activity) =>
        OutdoorActivityScreen(activityData: activity, isEdit: true),
    'Learning': (activity) =>
        LearningActivityScreen(activityData: activity, isEdit: true),
  };

  /// View: same screens as edit, read-only.
  static final Map<String, Widget Function(ActivityItem)> activityRoutes = {
    'Nap Start': (activity) => NapActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Nap End': (activity) => NapActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Bathroom': (activity) => BathroomActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Bottle': (activity) => BottleActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Meal': (activity) => MealActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Incident': (activity) => IncidentActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Photo': (activity) => PhotoVideoActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
          isPhoto: true,
        ),
    'Video': (activity) => PhotoVideoActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
          isPhoto: false,
        ),
    'Medication': (activity) => MedicationActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Notes': (activity) => NotesActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Outdoor': (activity) => OutdoorActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
    'Learning': (activity) => LearningActivityScreen(
          activityData: activity,
          isEdit: true,
          readOnly: true,
        ),
  };

  static final Map<String, dynamic> activityIcons = {
    'Nap Start': MediaRes.napActivityIcon,
    'Nap End': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
  };

  Future<void> _onRefresh() async {
    await _loadDailyFeed(refresh: true);
  }

  String _dateQueryParam(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String? _activityTypeCodeForLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    for (final s in _classroomActivitySettings) {
      if (_filterLabelMatchesSetting(label, s.activityTypeName)) {
        return s.activityTypeCode;
      }
    }
    return null;
  }

  /// Single type for API: one filter-sheet selection, else parent "Activity Type" dropdown.
  String? _activityTypeCodeForApiFilter() {
    if (_filterActivityTypes.length == 1) {
      return _activityTypeCodeForLabel(_filterActivityTypes.first);
    }
    if (_filterActivityTypes.isEmpty) {
      return _activityTypeCodeForLabel(_selectedActivityType);
    }
    return null;
  }

  List<ActivityItem> _withClientFilters(List<ActivityItem> items) {
    var list = items;
    if (_filterActivityTypes.length > 1) {
      final codes = _filterActivityTypes
          .map(_activityTypeCodeForLabel)
          .whereType<String>()
          .toSet();
      final names =
          _filterActivityTypes.map((e) => e.trim().toLowerCase()).toSet();
      list = list.where((a) {
        final c = a.activityTypeCode?.trim();
        if (c != null && c.isNotEmpty && codes.contains(c)) return true;
        return names.contains(a.name.trim().toLowerCase());
      }).toList();
    }
    if (_filterTags.isNotEmpty && _studentCodesForTagFilter.isNotEmpty) {
      list = list
          .where((a) =>
              a.studentCode != null &&
              _studentCodesForTagFilter.contains(a.studentCode))
          .toList();
    }
    return list;
  }

  Future<void> _rebuildStudentCodesForTagFilter() async {
    _studentCodesForTagFilter.clear();
    if (_filterTags.isEmpty || !mounted) return;
    final school = _schoolCode;
    final classroomName = _selectdClassroom;
    if (school == null ||
        school.isEmpty ||
        classroomName == null ||
        !_classroomCodeByName.containsKey(classroomName)) {
      return;
    }
    final cc = _classroomCodeByName[classroomName]!;
    try {
      for (final tagName in _filterTags) {
        final tagCode = _tagNameToCode[tagName];
        if (tagCode == null || tagCode.trim().isEmpty) continue;
        var page = 0;
        while (true) {
          final sp = await _getStudentPageUseCase(
            schoolCode: school,
            classroomCodes: [cc],
            tagCodes: [tagCode.trim()],
            page: page,
            size: 100,
          );
          if (!mounted) return;
          for (final s in sp.items) {
            _studentCodesForTagFilter.add(s.code);
          }
          if (!sp.hasMore) break;
          page++;
          if (page > 100) break;
        }
      }
    } catch (_) {
      if (mounted) _studentCodesForTagFilter.clear();
    }
  }

  bool _filterLabelMatchesSetting(String uiLabel, String settingName) {
    final u = uiLabel.toLowerCase().trim();
    final n = settingName.toLowerCase().trim();
    if (u.isEmpty || n.isEmpty) return false;
    if (u == n) return true;
    if (n.contains(u) || u.contains(n)) return true;
    final ua = u.split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
    final na = n.split(RegExp(r'\s+')).where((e) => e.length > 2).toSet();
    return ua.intersection(na).isNotEmpty;
  }

  Future<void> _bootstrap() async {
    final school =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (!mounted) return;
    if (school.isEmpty) {
      const msg = 'School is not selected.';
      setState(() {
        _feedError = msg;
        _classroomOptions = [];
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      return;
    }
    _schoolCode = school;

    if (_parentHome) {
      await _bootstrapParentHome();
      return;
    }

    final classroomCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'classrooms',
      identifier: school,
    );
    try {
      final cached = await _cacheManager.loadCache(classroomCacheKey);
      if (cached != null && cached['classrooms'] is List) {
        final list = (cached['classrooms'] as List)
            .whereType<Map>()
            .map((e) => <String, String>{
                  'name': (e['name'] ?? '').toString(),
                  'code': (e['code'] ?? '').toString(),
                })
            .where((e) => e['name']!.isNotEmpty && e['code']!.isNotEmpty)
            .toList();
        if (list.isNotEmpty && mounted) {
          _classroomCodeByName
            ..clear()
            ..addEntries(list.map((c) => MapEntry(c['name']!, c['code']!)));
          setState(() {
            _classroomOptions = list.map((c) => c['name']!).toList()..sort();
            _feedError = null;
            if (_classroomOptions.isNotEmpty) {
              final keep = _selectdClassroom != null &&
                  _classroomOptions.contains(_selectdClassroom);
              _selectdClassroom = keep ? _selectdClassroom : _classroomOptions.first;
            } else {
              _selectdClassroom = null;
            }
          });
        }
      }
    } catch (_) {}

    try {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: school,
        onlyTypeClassroom: true,
      );
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      _classroomCodeByName
        ..clear()
        ..addEntries(classrooms.map((c) => MapEntry(c.name, c.code)));
      setState(() {
        _classroomOptions = classrooms.map((c) => c.name).toList()..sort();
        _feedError = null;
        if (_classroomOptions.isNotEmpty) {
          final keep = _selectdClassroom != null &&
              _classroomOptions.contains(_selectdClassroom);
          _selectdClassroom =
              keep ? _selectdClassroom : _classroomOptions.first;
        } else {
          _selectdClassroom = null;
        }
      });
      await _cacheManager.saveCache(classroomCacheKey, {
        'classrooms': classrooms
            .map((c) => {'name': c.name, 'code': c.code})
            .toList(),
      });
      await Future.wait<void>([
        _loadDailyFeed(refresh: true),
        _reloadStudentsAndSettings(),
        _loadTagFilterOptions(),
      ]);
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
    }
  }

  Future<void> _bootstrapParentHome() async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;

    if (mounted) {
      setState(() {
        _loadingParentContext = true;
        _feedError = null;
      });
    }

    try {
      final guardianCode = await resolveGuardianCodeForLoggedInUser();
      if (guardianCode.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'Could not load guardian profile.';
            _parentAllowedStudentCodes.clear();
            _parentStudentClassroomByCode.clear();
            _loadingParentContext = false;
            _activities = [];
            _loadingFeed = false;
            _feedHasMore = false;
          });
        }
        return;
      }

      final page = await _getStudentPageUseCase(
        schoolCode: school,
        guardianCodes: [guardianCode],
        page: 0,
        size: 500,
      );
      if (!mounted) return;

      _parentAllowedStudentCodes.clear();
      _parentStudentClassroomByCode.clear();
      for (final s in page.items) {
        final code = s.code.trim();
        if (code.isEmpty) continue;
        final cc = s.classroom.trim();
        if (cc.isEmpty) continue;
        _parentAllowedStudentCodes.add(code);
        _parentStudentClassroomByCode[code] = cc;
      }

      if (_parentAllowedStudentCodes.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'No linked children with a classroom.';
            _loadingParentContext = false;
            _activities = [];
            _loadingFeed = false;
            _feedHasMore = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _loadingParentContext = false;
        });
      }
      await _loadDailyFeed(refresh: true);
    } catch (e) {
      if (!mounted) return;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
        _loadingParentContext = false;
        _parentAllowedStudentCodes.clear();
        _parentStudentClassroomByCode.clear();
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
    }
  }

  Future<void> _reloadStudentsAndSettings() async {
    _studentCodeByName.clear();
    _availableStudents = [];
    _classroomActivitySettings = [];

    final classroomName = _selectdClassroom;
    final school = _schoolCode;
    if (classroomName == null ||
        school == null ||
        school.isEmpty ||
        !_classroomCodeByName.containsKey(classroomName)) {
      if (mounted) {
        setState(() {
          _activities = [];
        });
      }
      return;
    }

    final code = _classroomCodeByName[classroomName]!;
    final studentsCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'students',
      identifier: code,
    );

    try {
      final settings = await ActivityFilterMetadataCache.loadClassroomActivitySettings(
        cacheManager: _cacheManager,
        useCase: _getClassroomActivitySettingsUseCase,
        classroomCode: code,
      );
      if (!mounted) return;
      setState(() {
        _classroomActivitySettings = settings;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _classroomActivitySettings = [];
        });
      }
    }

    try {
      final cachedStudents = await _cacheManager.loadCache(studentsCacheKey);
      if (cachedStudents != null && cachedStudents['students'] is List && mounted) {
        final list = (cachedStudents['students'] as List)
            .whereType<Map>()
            .map((e) => <String, String>{
                  'fullName': (e['fullName'] ?? '').toString(),
                  'studentCode': (e['studentCode'] ?? '').toString(),
                })
            .where((e) => e['fullName']!.isNotEmpty && e['studentCode']!.isNotEmpty)
            .toList();
        _studentCodeByName
          ..clear()
          ..addEntries(list.map((e) => MapEntry(e['fullName']!, e['studentCode']!)));
        setState(() {
          _availableStudents = list.map((e) => e['fullName']!).toList()..sort();
          if (_selectedStudent != null &&
              !_availableStudents.contains(_selectedStudent)) {
            _selectedStudent = null;
          }
        });
      }
    } catch (_) {}

    try {
      final students = await _getStudentClassroomListUseCase(
        schoolCode: school,
        classroomCode: code,
        status: const ['ACTIVE'],
        refresh: false,
      );
      if (!mounted) return;
      _studentCodeByName.addEntries(
        students.map((s) => MapEntry(s.fullName, s.studentCode)),
      );
      setState(() {
        _availableStudents = students.map((s) => s.fullName).toList()..sort();
        if (_selectedStudent != null &&
            !_availableStudents.contains(_selectedStudent)) {
          _selectedStudent = null;
        }
      });
      await _cacheManager.saveCache(studentsCacheKey, {
        'students': students
            .map((s) => {
                  'fullName': s.fullName,
                  'studentCode': s.studentCode,
                })
            .toList(),
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableStudents = [];
        });
      }
    }
  }

  Future<void> _reloadStudentsAndSettingsThenFeed() async {
    await _reloadStudentsAndSettings();
    await _loadDailyFeed();
  }

  List<ActivityItem> _mapDailyFeedPageToItems(ActivityFeedPage page) {
    final raw =
        page.content.map((row) => activityItemFromFeedRow(row)).toList();
    return _withClientFilters(raw);
  }

  void _onFeedScroll() {
    _maybeLoadNextDailyFeedPage();
  }

  void _maybeLoadNextDailyFeedPage() {
    if (!_feedScrollController.hasClients) return;
    if (_loadingMoreFeed ||
        !_feedHasMore ||
        _loadingFeed ||
        _isFeedRequestInFlight) {
      return;
    }
    final position = _feedScrollController.position;
    if (position.maxScrollExtent <= 0) {
      _loadNextDailyFeedPage();
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextDailyFeedPage();
    }
  }

  Future<void> _loadNextDailyFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _loadingFeed) return;

    if (_parentHome) {
      return _loadNextParentHomeDailyFeedPage();
    }

    final classroomName = _selectdClassroom;
    final school = _schoolCode;
    final date = _selectedDate;
    if (classroomName == null ||
        school == null ||
        school.isEmpty ||
        date == null ||
        !_classroomCodeByName.containsKey(classroomName)) {
      return;
    }

    final classroomCode = _classroomCodeByName[classroomName]!;
    final dateStr = _dateQueryParam(date);

    String? studentCode;
    if (widget.fromStudentProfile && widget.studentProfile != null) {
      final sc = widget.studentProfile!['studentCode'];
      if (sc is String && sc.trim().isNotEmpty) {
        studentCode = sc.trim();
      }
    } else if (_selectedStudent != null) {
      studentCode = _studentCodeByName[_selectedStudent!];
    }

    final typeCode = _activityTypeCodeForApiFilter();

    _loadingMoreFeed = true;
    if (mounted) setState(() {});

    try {
      final page = await _getDailyActivityFeedUseCase(
        classroomCode: classroomCode,
        date: dateStr,
        studentCode: studentCode,
        activityTypeCode: typeCode,
        page: _feedNextPage,
        size: _feedPageSize,
      );

      final items = _mapDailyFeedPageToItems(page);

      if (!mounted) return;
      setState(() {
        _activities.addAll(items);
        _feedHasMore = !page.last;
        _feedNextPage = page.last ? 0 : page.pageNumber + 1;
      });
    } catch (e) {
      if (mounted) {
        CoreUtils.logApiError(
          ApiErrorHandler.extractErrorMessage(e),
          showOnScreen: true,
          context: context,
        );
        setState(() => _feedHasMore = false);
      }
    } finally {
      _loadingMoreFeed = false;
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeLoadNextDailyFeedPage());
      }
    }
  }

  Future<void> _loadParentHomeDailyFeed({bool refresh = false}) async {
    final school = _schoolCode;
    final date = _selectedDate;
    if (school == null ||
        school.isEmpty ||
        date == null ||
        _parentAllowedStudentCodes.isEmpty) {
      if (mounted) {
        setState(() {
          _activities = [];
          _loadingFeed = false;
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }

    final codes = _parentAllowedStudentCodes.toList()..sort();
    final dateStr = _dateQueryParam(date);
    final typeCode = _activityTypeCodeForApiFilter();
    final requestKey = [
      'parentDaily',
      school,
      codes.join(','),
      dateStr,
      typeCode ?? '',
      _filterActivityTypes.join(','),
      _filterTags.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      if (_isFeedRequestInFlight) return;
      if (!_lastFeedCompletedWithError) return;
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          DateTime.now().difference(completedAt) < const Duration(seconds: 3)) {
        return;
      }
    }

    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    if (mounted) {
      setState(() {
        _loadingFeed = true;
        _feedError = null;
        _feedHasMore = true;
        _loadingMoreFeed = false;
      });
    }

    try {
      final pages = await Future.wait(
        _parentAllowedStudentCodes.map((sc) async {
          final cc = _parentStudentClassroomByCode[sc]?.trim() ?? '';
          if (cc.isEmpty) {
            return const ActivityFeedPage(
              content: [],
              totalElements: 0,
              totalPages: 0,
              pageNumber: 0,
              last: true,
            );
          }
          return _getDailyActivityFeedUseCase(
            classroomCode: cc,
            date: dateStr,
            studentCode: sc,
            activityTypeCode: typeCode,
            page: 0,
            size: _feedPageSize,
          );
        }),
      );

      final merged = mergeActivityFeedPages(pages);
      final items = _mapDailyFeedPageToItems(merged);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        _activities = items;
        _loadingFeed = false;
        _feedError = null;
        _feedHasMore = !merged.last;
        _feedNextPage = merged.last ? 0 : merged.pageNumber + 1;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeLoadNextDailyFeedPage());
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _loadingFeed = false;
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = true;
    }
  }

  Future<void> _loadNextParentHomeDailyFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _loadingFeed) return;

    final school = _schoolCode;
    final date = _selectedDate;
    if (school == null ||
        school.isEmpty ||
        date == null ||
        _parentAllowedStudentCodes.isEmpty) {
      return;
    }

    final dateStr = _dateQueryParam(date);
    final typeCode = _activityTypeCodeForApiFilter();
    final pageIndex = _feedNextPage;

    _loadingMoreFeed = true;
    if (mounted) setState(() {});

    try {
      final pages = await Future.wait(
        _parentAllowedStudentCodes.map((sc) async {
          final cc = _parentStudentClassroomByCode[sc]?.trim() ?? '';
          if (cc.isEmpty) {
            return ActivityFeedPage(
              content: const [],
              totalElements: 0,
              totalPages: 0,
              pageNumber: pageIndex,
              last: true,
            );
          }
          return _getDailyActivityFeedUseCase(
            classroomCode: cc,
            date: dateStr,
            studentCode: sc,
            activityTypeCode: typeCode,
            page: pageIndex,
            size: _feedPageSize,
          );
        }),
      );

      final merged = mergeActivityFeedPages(pages);
      final items = _mapDailyFeedPageToItems(merged);

      if (!mounted) return;
      setState(() {
        _activities.addAll(items);
        _feedHasMore = !merged.last;
        _feedNextPage = merged.last ? 0 : merged.pageNumber + 1;
      });
    } catch (e) {
      if (mounted) {
        CoreUtils.logApiError(
          ApiErrorHandler.extractErrorMessage(e),
          showOnScreen: true,
          context: context,
        );
        setState(() => _feedHasMore = false);
      }
    } finally {
      _loadingMoreFeed = false;
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeLoadNextDailyFeedPage());
      }
    }
  }

  Future<void> _loadDailyFeed({bool refresh = false}) async {
    if (_parentHome) {
      return _loadParentHomeDailyFeed(refresh: refresh);
    }

    final classroomName = _selectdClassroom;
    final school = _schoolCode;
    final date = _selectedDate;
    if (classroomName == null ||
        school == null ||
        school.isEmpty ||
        date == null ||
        !_classroomCodeByName.containsKey(classroomName)) {
      if (mounted) {
        setState(() {
          _activities = [];
          _loadingFeed = false;
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }

    final classroomCode = _classroomCodeByName[classroomName]!;
    final dateStr = _dateQueryParam(date);

    String? studentCode;
    if (widget.fromStudentProfile && widget.studentProfile != null) {
      final sc = widget.studentProfile!['studentCode'];
      if (sc is String && sc.trim().isNotEmpty) {
        studentCode = sc.trim();
      }
    } else if (_selectedStudent != null) {
      studentCode = _studentCodeByName[_selectedStudent!];
    }

    final typeCode = _activityTypeCodeForApiFilter();
    final requestKey = [
      classroomCode,
      dateStr,
      studentCode ?? '',
      typeCode ?? '',
      _filterActivityTypes.join(','),
      _filterTags.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      if (_isFeedRequestInFlight) {
        // Same request is already running; skip duplicate calls.
        return;
      }
      if (!_lastFeedCompletedWithError) {
        // Last identical request already completed successfully
        // (including empty-result success). No need to refetch.
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          DateTime.now().difference(completedAt) < const Duration(seconds: 3)) {
        // Throttle repeated failed requests for same filters.
        return;
      }
    }

    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    if (!refresh) {
      try {
        final cached = await _cacheManager.loadCache(
          ActivityFeedPageCacheCodec.dailyCacheKey(requestKey),
          validFor: StorageKeys.activityFeedCacheDuration,
        );
        final rev =
            await ActivityFeedInvalidation.currentRevision(_storageService);
        final cachedPage =
            ActivityFeedPageCacheCodec.decode(cached, currentRevision: rev);
        if (cachedPage != null && mounted) {
          final items = _mapDailyFeedPageToItems(cachedPage);
          setState(() {
            _activities = items;
            _loadingFeed = false;
            _feedError = null;
            _feedHasMore = !cachedPage.last;
            _feedNextPage =
                cachedPage.last ? 0 : cachedPage.pageNumber + 1;
            _loadingMoreFeed = false;
          });
          _lastFeedRequestKey = requestKey;
          _isFeedRequestInFlight = false;
          _lastFeedCompletedAt = DateTime.now();
          _lastFeedCompletedWithError = false;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _maybeLoadNextDailyFeedPage());
          return;
        }
      } catch (_) {}
    }

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    if (mounted) {
      setState(() {
        _loadingFeed = true;
        _feedError = null;
        _feedHasMore = true;
        _loadingMoreFeed = false;
      });
    }

    try {
      final page = await _getDailyActivityFeedUseCase(
        classroomCode: classroomCode,
        date: dateStr,
        studentCode: studentCode,
        activityTypeCode: typeCode,
        page: 0,
        size: _feedPageSize,
      );

      final items = _mapDailyFeedPageToItems(page);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      try {
        final rev =
            await ActivityFeedInvalidation.currentRevision(_storageService);
        await _cacheManager.saveCache(
          ActivityFeedPageCacheCodec.dailyCacheKey(requestKey),
          ActivityFeedPageCacheCodec.wrapPage(page, rev),
        );
      } catch (_) {}
      setState(() {
        _activities = items;
        _loadingFeed = false;
        _feedError = null;
        _feedHasMore = !page.last;
        _feedNextPage = page.last ? 0 : page.pageNumber + 1;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeLoadNextDailyFeedPage());
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _loadingFeed = false;
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _getDailyActivityFeedUseCase = serviceLocator<GetDailyActivityFeedUseCase>();
    _getActiveClassroomsUseCase = serviceLocator<GetActiveClassroomsUseCase>();
    _getClassroomActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getStudentClassroomListUseCase =
        serviceLocator<GetStudentClassroomListUseCase>();
    _getTagNameCodeMapForSchoolUseCase =
        serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    _getStudentPageUseCase = serviceLocator<GetStudentPageUseCase>();
    _deleteActivityUseCase = serviceLocator<DeleteActivityUseCase>();
    _storageService = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storageService);

    isNotParent = widget.isNotParent;
    if (widget.fromStudentProfile) {
      final n = widget.studentName;
      if (n != null && n.trim().isNotEmpty) {
        _selectedStudent = n.trim();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    _feedScrollController.addListener(_onFeedScroll);
    _feedInvalidationSub =
        ActivityFeedInvalidation.onInvalidated.listen((_) {
      if (mounted) {
        _loadDailyFeed(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _feedInvalidationSub?.cancel();
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    super.dispose();
  }

  void _updateAvailableStudents() {
    if (_selectdClassroom != null) {
      if (_selectedStudent != null &&
          !_availableStudents.contains(_selectedStudent)) {
        _selectedStudent = null;
      }
    } else {
      _availableStudents = [];
      _selectedStudent = null;
    }
  }

  Future<void> _openActivityFilter() async {
    final school = _schoolCode;
    final classroomName = _selectdClassroom;
    if (school == null ||
        school.isEmpty ||
        classroomName == null ||
        !_classroomCodeByName.containsKey(classroomName)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select a classroom first',
        isWarning: true,
      );
      return;
    }
    final classroomCode = _classroomCodeByName[classroomName]!;
    final result = await Navigator.push<Map<String, List<String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityFilterScreen(
          schoolCode: school,
          classroomCode: classroomCode,
          initialFilters: {
            'Tags': List<String>.from(_filterTags),
            'Activity Type': List<String>.from(_filterActivityTypes),
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _filterTags = List<String>.from(result['Tags'] ?? const []);
      _filterActivityTypes =
          List<String>.from(result['Activity Type'] ?? const []);
    });
    await _loadDailyFeed(refresh: true);
  }

  Future<void> _deleteActivityFromSheet(
    BuildContext sheetContext,
    ActivityItem activity,
  ) async {
    final code = activity.activityCode?.trim();
    if (code == null || code.isEmpty) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot delete: missing activity reference.',
        isError: true,
      );
      return;
    }
    try {
      final message = await _deleteActivityUseCase(code: code);
      if (!mounted) return;
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      CoreUtils.logApiError(
        ApiErrorHandler.extractErrorMessage(e),
        showOnScreen: true,
        context: context,
      );
    }
  }

  Future<void> _loadTagFilterOptions() async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;
    try {
      final map = await ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _getTagNameCodeMapForSchoolUseCase,
        schoolCode: school,
      );
      if (!mounted) return;
      setState(() {
        _tagNameToCode = Map<String, String>.from(map);
        _tagFilterOptions = map.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _filterTags.removeWhere((t) => !_tagFilterOptions.contains(t));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _tagFilterOptions = []);
        CoreUtils.logApiError(
          ApiErrorHandler.extractErrorMessage(e),
          showOnScreen: true,
          context: context,
        );
      }
    }
  }

  /// Same card styling as the empty state; shows [PrimaryCircularLoader] on white.
  Widget _dailyFeedLoadingSheet(
    BuildContext context, {
    bool expandToParentHeight = false,
  }) {
    final sheet = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: const PrimaryCircularLoader(size: 40, strokeWidth: 3.5),
    );

    return Padding(
      padding: ResponsiveSizing.contentPadding(context),
      child: expandToParentHeight ? SizedBox.expand(child: sheet) : sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return OrientationBuilder(
        builder: (context, orientation){
          if(orientation == Orientation.landscape){
            return CustomRefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _feedScrollController,
                slivers: [
                SliverToBoxAdapter(child: Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: widget.fromStudentProfile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 40,
                          child: AbsorbPointer(
                            child: _buildCustomDropdown(
                              'Select Student',
                              widget.studentName != null
                                  ? [widget.studentName!]
                                  : <String>[],
                              widget.studentName,
                              (v) => setState(() {
                                _selectedStudent = v;
                              }),
                              height: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: _datePickerFilter(
                            selectedDate: _selectedDate,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadDailyFeed();
                            },
                          ),
                        ),
                      ],
                    )
                        : isNotParent
                        ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCustomDropdown(
                                'Select Classroom',
                                _classroomOptions,
                                _selectdClassroom,
                                (v) {
                                  setState(() {
                                    _selectdClassroom = v;
                                    _updateAvailableStudents();
                                  });
                                  _reloadStudentsAndSettingsThenFeed();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // child: _buildCustomDropdown(
                              //   'Select Student',
                              //   _allStudents,
                              //   _selectedStudent,
                              //   (v) => setState(() {
                              //     _selectedStudent = v;
                              //   }),
                              // ),
                              child: _buildCustomDropdown(
                                _selectdClassroom == null
                                    ? 'Select Classroom First'
                                    : 'Select Student',
                                _availableStudents,
                                _selectedStudent,
                                (value) {
                                  if (_selectdClassroom != null) {
                                    setState(() {
                                      _selectedStudent = value;
                                    });
                                    _loadDailyFeed();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: _openActivityFilter,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    MediaRes.filterIcon,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _datePickerFilter(
                                selectedDate: _selectedDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                  _loadDailyFeed();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  if (_classroomOptions.isNotEmpty) {
                                    _selectdClassroom = _classroomOptions.first;
                                  }
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                                _reloadStudentsAndSettingsThenFeed();
                              },
                              label: 'Clear All',
                            ),
                          ],
                        ),
                      ],
                    )
                        : SizedBox(
                            height: 40,
                            child: _datePickerFilter(
                              selectedDate: _selectedDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                                _loadDailyFeed();
                              },
                            ),
                          ),
                  ),
                ),),
                SliverToBoxAdapter(child: SizedBox(height: 12,),),
                if ((_loadingFeed || _loadingParentContext) &&
                    _activities.isEmpty)
                  SliverToBoxAdapter(child: _dailyFeedLoadingSheet(context)),
                if (!_loadingFeed &&
                    !_loadingParentContext &&
                    _activities.isEmpty)
                  SliverToBoxAdapter(child: Padding(
                    padding: ResponsiveSizing.contentPadding(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: AppText.title(
                          _feedError ?? 'No Activities found',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),),
                // if (activities.isNotEmpty)
                //   SliverPadding(
                //     padding: EdgeInsets.all(16),
                //     sliver: SliverList(
                //       delegate: SliverChildBuilderDelegate(
                //             (context, index) => Container(
                //           height: 100,
                //           margin: EdgeInsets.only(bottom: 16),
                //           color: Colors.blue[100 * (index % 9 + 1)],
                //           child: Center(child: Text('Test Item $index')),
                //         ),
                //         childCount: _activities.length,
                //       ),
                //     ),
                //   ),

                if (_activities.isNotEmpty)
                  SliverPadding(
                      padding: ResponsiveSizing.activityFeedListPadding(context),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                          (context, index){
                            if (index == _activities.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: PrimaryCircularLoader(
                                    size: 28,
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            }
                            final activity = _activities[index];
                            final students = activity.studentList;
                            final Color activityColor =
                            _colorPalette[index % _colorPalette.length];

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            //color: activity.color,
                                            color: activityColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Container(
                                          width: 4,
                                          height: 2,
                                          //color: activity.color,
                                          color: activityColor,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 100,
                                      height: 4,
                                      //color: activity.color,
                                      color: activityColor,
                                    ),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        //color: activity.color,
                                        color: activityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    SizedBox(
                                      height: 20,
                                      child: AppText.small(
                                        activity.time,
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 7),
                                    Container(
                                      width: 4,
                                      height: 220,
                                      //color: activity.color,
                                      color: activityColor,
                                    ),

                                    const SizedBox(width: 16),

                                    // Activity Card
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                          right: 0,
                                        ),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 15),
                                            InkWell(
                                              onTap: () async {
                                                final destinationBuilder =
                                                activityRoutes[activity
                                                    .name];
                                                if (destinationBuilder !=
                                                    null) {
                                                  final nextScreen =
                                                  destinationBuilder(
                                                    activity,
                                                  );
                                                  await Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                      nextScreen,
                                                    ),
                                                  );
                                                  if (mounted) {
                                                    await _loadDailyFeed(refresh: true);
                                                  }
                                                }
                                              },
                                              child: Container(
                                                constraints: const BoxConstraints(
                                                  minHeight: 180,
                                                ),
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: activityColor.withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius: BorderRadius.circular(
                                                    16,
                                                  ),
                                                  border: Border.all(
                                                    color: activityColor.withOpacity(
                                                      0.4,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                      BorderRadius.circular(12),
                                                      child: SizedBox(
                                                        width: 140,
                                                        height: 120,
                                                        child:
                                                        activity.photoUrl != null ||
                                                            activity.videoUrl !=
                                                                null
                                                            ? ActivityMediaPreview(
                                                          activity: activity,
                                                          activityColor:
                                                          activityColor,
                                                        )
                                                        // ? Image.network(
                                                        //     activity.photoUrl!,
                                                        //     fit: BoxFit.cover,
                                                        //     loadingBuilder:
                                                        //         (
                                                        //           context,
                                                        //           child,
                                                        //           loadingProgress,
                                                        //         ) {
                                                        //           if (loadingProgress ==
                                                        //               null)
                                                        //             return child;
                                                        //           return Container(
                                                        //             color: Colors
                                                        //                 .transparent,
                                                        //             child: const Center(
                                                        //               child: CircularProgressIndicator(
                                                        //                 strokeWidth:
                                                        //                     2,
                                                        //               ),
                                                        //             ),
                                                        //           );
                                                        //         },
                                                        //     errorBuilder:
                                                        //         (
                                                        //           context,
                                                        //           error,
                                                        //           stackTrace,
                                                        //         ) {
                                                        //           return Container(
                                                        //             width: 122,
                                                        //             height: 76,
                                                        //             color: activity
                                                        //                 .color
                                                        //                 .withOpacity(
                                                        //                   0.25,
                                                        //                 ),
                                                        //             child: Center(
                                                        //               child: Image.asset(
                                                        //                 activityIcons[activity
                                                        //                     .name],
                                                        //                 //'assets/icons/activity-nap-icon.png',
                                                        //                 fit: BoxFit
                                                        //                     .fill,
                                                        //               ),
                                                        //             ),
                                                        //           );
                                                        //         },
                                                        //   )
                                                            : Container(
                                                          width: 122,
                                                          height: 76,
                                                          color: Colors.white,
                                                          // color: activityColor
                                                          //     .withOpacity(0.25),
                                                          child: Center(
                                                            child: Image.asset(
                                                              activityIcons[activity
                                                                  .name],
                                                              //'assets/icons/activity-nap-icon.png',
                                                              fit: BoxFit.fill,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment.centerLeft,
                                                                  child: Container(
                                                                    padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal: 12,
                                                                      vertical: 6,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          activityColor
                                                                              .withOpacity(
                                                                                0.5,
                                                                              ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      activity.name,
                                                                      maxLines: 1,
                                                                      overflow:
                                                                          TextOverflow.ellipsis,
                                                                      style:
                                                                      const TextStyle(
                                                                        color: AppColors
                                                                            .primaryColor,
                                                                        fontSize: 12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              PopupMenuButton<String>(
                                                                icon: const Icon(
                                                                  Icons.more_horiz,
                                                                  size: 20,
                                                                ),
                                                                onSelected: null,
                                                                itemBuilder: (context) => [
                                                                  PopupMenuItem<String>(
                                                                    value: 'view',
                                                                    child: PopupItem(
                                                                      title: 'View',
                                                                      icon: Icon(
                                                                        Icons
                                                                            .visibility_outlined,
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                    onTap: () async {
                                                                      final destinationBuilder =
                                                                      activityRoutes[activity
                                                                          .name];
                                                                      if (destinationBuilder !=
                                                                          null) {
                                                                        final nextScreen =
                                                                        destinationBuilder(
                                                                          activity,
                                                                        );
                                                                        await Navigator.of(
                                                                          context,
                                                                        ).push(
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                            nextScreen,
                                                                          ),
                                                                        );
                                                                        if (mounted) {
                                                                          await _loadDailyFeed(refresh: true);
                                                                        }
                                                                      }
                                                                    },
                                                                  ),
                                                                  if (widget.allowActivityWrite) ...[
                                                                    PopupMenuItem<String>(
                                                                      value: 'edit',
                                                                      child: PopupItem(
                                                                        title: 'Edit',
                                                                        icon: Icon(
                                                                          Icons.edit,
                                                                          color: AppColors
                                                                              .themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        final destinationBuilder =
                                                                        editActivityRoutes[activity
                                                                            .name];
                                                                        if (destinationBuilder !=
                                                                            null) {
                                                                          final nextScreen =
                                                                          destinationBuilder(
                                                                            activity,
                                                                          );
                                                                          await Navigator.of(
                                                                            context,
                                                                          ).push(
                                                                            MaterialPageRoute(
                                                                              builder: (_) =>
                                                                              nextScreen,
                                                                            ),
                                                                          );
                                                                          if (mounted) {
                                                                            await _loadDailyFeed(refresh: true);
                                                                          }
                                                                        }
                                                                      },
                                                                    ),
                                                                    PopupMenuItem<String>(
                                                                      value: 'delete',
                                                                      child: PopupItem(
                                                                        title: 'Delete',
                                                                        icon: Icon(
                                                                          Icons.delete,
                                                                          color: AppColors
                                                                              .themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: ()  {
                                                                        showModalBottomSheet(
                                                                          context: context,
                                                                          isScrollControlled: true,
                                                                          backgroundColor: Colors.transparent,
                                                                          builder: (ctx) {
                                                                            return DeleteConfirmationBottomSheet(
                                                                              name: activity.name,
                                                                              type: 'Activity',
                                                                              onDelete: () =>
                                                                                  _deleteActivityFromSheet(ctx, activity),
                                                                              onCancel: () {
                                                                                Navigator.of(ctx).pop();
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 10),

                                                          SizedBox(
                                                            height: 32,
                                                            child: Stack(
                                                              children: [
                                                                for (
                                                                int i = 0;
                                                                i < students.length &&
                                                                    i < 4;
                                                                i++
                                                                )
                                                                  Positioned(
                                                                    left: i * 20,
                                                                    child:
                                                                    DocumentImageWidget(
                                                                      fileUuid: '',
                                                                      name:
                                                                      students[i],
                                                                      size: 28,
                                                                      fontSize: 10,
                                                                    ),
                                                                  ),

                                                                // Extra count tooltip
                                                                if (students.length > 4)
                                                                  Positioned(
                                                                    left:
                                                                    4 *
                                                                        20, // after 4 avatars
                                                                    child: Tooltip(
                                                                      message: students
                                                                          .skip(4)
                                                                          .join(', '),
                                                                      child: DocumentImageWidget(
                                                                        fileUuid: '',
                                                                        name:
                                                                        '+${students.length - 4}',
                                                                        size: 28,
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),

                                                          Text(
                                                            activityFeedCardBodyLine(activity),
                                                            style: AppTextStyles.body.copyWith(
                                                              color: AppColors.primaryColor,
                                                              fontWeight: FontWeight.w600,
                                                              height: 1.0,
                                                            ),
                                                            strutStyle: StrutStyle(
                                                              fontFamily: Fonts.manrope,
                                                              fontSize: 14,
                                                              height: 1.0,
                                                              leading: 0,
                                                              fontWeight: FontWeight.w600,
                                                              forceStrutHeight: true,
                                                            ),
                                                            textHeightBehavior:
                                                                const TextHeightBehavior(
                                                              applyHeightToFirstAscent: false,
                                                              applyHeightToLastDescent: false,
                                                            ),
                                                            maxLines:
                                                                activityFeedCardBodyMaxLines(
                                                                    activity),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 10),
                                                          AppText.small(
                                                            'Created By - ${activity.createdBy}',
                                                            style: AppTextStyles.small.copyWith(
                                                              color: AppColors.primaryColor,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                          childCount: _activities.length +
                              (_loadingMoreFeed ? 1 : 0),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
            ),);
            // return SingleChildScrollView(
            //   child: Column(
            //     children: [
            //       Padding(
            //         padding: ResponsiveSizing.contentPadding(context),
            //         child: Container(
            //           padding: const EdgeInsets.all(12),
            //           decoration: BoxDecoration(
            //             border: Border.all(color: AppColors.cardBorderColor),
            //             borderRadius: BorderRadius.circular(12),
            //             color: AppColors.cardColor,
            //           ),
            //           child: widget.fromStudentProfile
            //               ? Column(
            //             crossAxisAlignment: CrossAxisAlignment.stretch,
            //             children: [
            //               SizedBox(
            //                 height: 40,
            //                 child: AbsorbPointer(
            //                   child: _buildCustomDropdown(
            //                     'Select Student',
            //                     [?widget.studentName],
            //                     widget.studentName,
            //                         (v) => setState(() {
            //                       _selectedStudent = v;
            //                     }),
            //                     height: 40,
            //                   ),
            //                 ),
            //               ),
            //               const SizedBox(height: 8),
            //               SizedBox(
            //                 height: 40,
            //                 child: _datePickerFilter(
            //                   selectedDate: _selectedDate,
            //                   onDateSelected: (date) {
            //                     setState(() {
            //                       _selectedDate = date;
            //                     });
            //                   },
            //                 ),
            //               ),
            //             ],
            //           )
            //               : isNotParent
            //               ? Column(
            //             children: [
            //               Row(
            //                 children: [
            //                   Expanded(
            //                     child: _buildCustomDropdown(
            //                       'Select Classroom',
            //                       _classroomOptions,
            //                       _selectdClassroom,
            //                           (v) => setState(() {
            //                         _selectdClassroom = v;
            //                         _updateAvailableStudents();
            //                       }),
            //                     ),
            //                   ),
            //                   const SizedBox(width: 8),
            //                   Expanded(
            //                     // child: _buildCustomDropdown(
            //                     //   'Select Student',
            //                     //   _allStudents,
            //                     //   _selectedStudent,
            //                     //   (v) => setState(() {
            //                     //     _selectedStudent = v;
            //                     //   }),
            //                     // ),
            //                     child: _buildCustomDropdown(
            //                       _selectdClassroom == null
            //                           ? 'Select Classroom First'
            //                           : 'Select Student',
            //                       _availableStudents,
            //                       _selectedStudent,
            //                           (value) {
            //                         if (_selectdClassroom != null) {
            //                           setState(() {
            //                             _selectedStudent = value;
            //                           });
            //                         }
            //                       },
            //                     ),
            //                   ),
            //                   const SizedBox(width: 8),
            //                   Material(
            //                     color: Colors.transparent,
            //                     child: InkWell(
            //                       borderRadius: BorderRadius.circular(100),
            //                       onTap: () async {
            //                         final result = await Navigator.push(
            //                           context,
            //                           MaterialPageRoute(
            //                             builder: (_) => FilterScreen(
            //                               sections: [
            //                                 FilerSection(
            //                                   label: 'Tags',
            //                                   hintText: 'Select tags',
            //                                   items: [
            //                                     '5 Days',
            //                                     'Full Day',
            //                                     'Photo Permission',
            //                                     'Vegetarian',
            //                                     'First Aid',
            //                                     'Allergy',
            //                                     'Pickup Authorized',
            //                                     'Medication',
            //                                     'Half Day',
            //                                     'Boy',
            //                                     'Girl',
            //                                   ],
            //                                   initialSelected: _filterTags,
            //                                   isMultiSelectDropDown: false,
            //                                 ),
            //                                 FilerSection(
            //                                   label: 'Activity Type',
            //                                   hintText: 'Select Activity',
            //                                   items: [
            //                                     'Nap Start',
            //                                     'Nap End',
            //                                     'Bathroom',
            //                                     'Bottle',
            //                                     'Meal',
            //                                     'Incident',
            //                                     'Photo',
            //                                     'Outdoor',
            //                                     'Medication',
            //                                     'Notes',
            //                                     'Learning',
            //                                     'Sign-in',
            //                                     'Sign-out',
            //                                     'Absent',
            //                                   ],
            //                                   initialSelected: _filterActivityTypes,
            //                                   isMultiSelectDropDown: false,
            //                                 ),
            //                               ],
            //                               onApply: (filters) {
            //                                 setState(() {
            //                                   _filterTags = filters['Tags']!;
            //                                   _filterActivityTypes =
            //                                   filters['Activity Type']!;
            //                                 });
            //                                 //print(_filterTags);
            //                                 //print(_filterActivityTypes);
            //                               },
            //                             ),
            //                           ),
            //                         );
            //                         if (!mounted) return;
            //                         if (result is Map) {
            //                           // TODO: apply filters to list
            //                           setState(() {});
            //                         }
            //                       },
            //                       child: Padding(
            //                         padding: const EdgeInsets.all(8),
            //                         child: SvgPicture.asset(
            //                           MediaRes.filterIcon,
            //                           height: 20,
            //                         ),
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //               const SizedBox(height: 16),
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   Expanded(
            //                     child: _datePickerFilter(
            //                       selectedDate: _selectedDate,
            //                       onDateSelected: (date) {
            //                         setState(() {
            //                           _selectedDate = date;
            //                         });
            //                       },
            //                     ),
            //                   ),
            //                   const SizedBox(width: 8),
            //                   CustomClearAllChip(
            //                     onTap: () {
            //                       setState(() {
            //                         _selectdClassroom = _classroomOptions[0];
            //                         _selectedStudent = null;
            //                         _filterActivityTypes.clear();
            //                         _filterTags.clear();
            //                       });
            //                       //print(_filterTags);
            //                     },
            //                     label: 'Clear All',
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           )
            //               : Row(
            //             children: [
            //               Expanded(
            //                 child: SizedBox(
            //                   height: 40,
            //                   child: _datePickerFilter(
            //                     selectedDate: _selectedDate,
            //                     onDateSelected: (date) {
            //                       setState(() {
            //                         _selectedDate = date;
            //                       });
            //                     },
            //                   ),
            //                 ),
            //               ),
            //               const SizedBox(width: 8),
            //               Expanded(
            //                 child: SizedBox(
            //                   height: 40,
            //                   child: _buildCustomDropdown(
            //                     'Activity Type',
            //                     activityType,
            //                     _selectedActivityType,
            //                         (v) => setState(() {
            //                       _selectedActivityType = v;
            //                     }),
            //                     height: 40,
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //
            //       const SizedBox(height: 12),
            //
            //       if (activities.length == 0)
            //         Padding(
            //           padding: ResponsiveSizing.contentPadding(context),
            //           child: Container(
            //             padding: const EdgeInsets.all(12),
            //             decoration: BoxDecoration(
            //               border: Border.all(color: AppColors.cardBorderColor),
            //               borderRadius: BorderRadius.circular(12),
            //               color: AppColors.cardColor,
            //             ),
            //             child: Center(
            //               child: Text(
            //                 'No Activities found',
            //                 style: TextStyle(
            //                   color: Colors.black,
            //                   fontFamily: 'Manrope',
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //
            //       if (activities.length != 0)
            //         Padding(
            //           padding: ResponsiveSizing.contentPadding(context),
            //           child: Column(
            //             children: [
            //               const SizedBox(height: 10),
            //               ListView.builder(
            //                 padding: const EdgeInsets.only(right: 16),
            //                 itemCount: activities.length,
            //                 itemBuilder: (context, index) {
            //                   final activity = _activities[index];
            //                   final students = activity.studentList;
            //                   final Color activityColor =
            //                   _colorPalette[index % _colorPalette.length];
            //
            //                   return Column(
            //                     children: [
            //                       Row(
            //                         children: [
            //                           Column(
            //                             children: [
            //                               Container(
            //                                 width: 18,
            //                                 height: 18,
            //                                 decoration: BoxDecoration(
            //                                   //color: activity.color,
            //                                   color: activityColor,
            //                                   shape: BoxShape.circle,
            //                                 ),
            //                               ),
            //                               Container(
            //                                 width: 4,
            //                                 height: 2,
            //                                 //color: activity.color,
            //                                 color: activityColor,
            //                               ),
            //                             ],
            //                           ),
            //                           Container(
            //                             width: 100,
            //                             height: 4,
            //                             //color: activity.color,
            //                             color: activityColor,
            //                           ),
            //                           Container(
            //                             width: 18,
            //                             height: 18,
            //                             decoration: BoxDecoration(
            //                               //color: activity.color,
            //                               color: activityColor,
            //                               shape: BoxShape.circle,
            //                             ),
            //                           ),
            //                           const SizedBox(width: 20),
            //                           SizedBox(
            //                             height: 20,
            //                             child: Text(
            //                               activity.time,
            //                               style: TextStyle(
            //                                 fontSize: 14,
            //                                 color: AppColors.primaryColor,
            //                                 fontWeight: FontWeight.w500,
            //                               ),
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                       Row(
            //                         crossAxisAlignment: CrossAxisAlignment.start,
            //                         children: [
            //                           const SizedBox(width: 7),
            //                           Container(
            //                             width: 4,
            //                             height: 220,
            //                             //color: activity.color,
            //                             color: activityColor,
            //                           ),
            //
            //                           const SizedBox(width: 16),
            //
            //                           // Activity Card
            //                           Column(
            //                             children: [
            //                               const SizedBox(height: 15),
            //                               InkWell(
            //                                 onTap: () {
            //                                   final destinationBuilder =
            //                                   activityRoutes[activity
            //                                       .name];
            //                                   if (destinationBuilder !=
            //                                       null) {
            //                                     final nextScreen =
            //                                     destinationBuilder(
            //                                       activity,
            //                                     );
            //                                     Navigator.of(
            //                                       context,
            //                                     ).push(
            //                                       MaterialPageRoute(
            //                                         builder: (_) =>
            //                                         nextScreen,
            //                                       ),
            //                                     );
            //                                   }
            //                                 },
            //                                 child: Container(
            //                                   height: 180,
            //                                   margin: const EdgeInsets.only(
            //                                     bottom: 24,
            //                                   ),
            //                                   padding: const EdgeInsets.all(12),
            //                                   decoration: BoxDecoration(
            //                                     color: activityColor.withOpacity(
            //                                       0.15,
            //                                     ),
            //                                     borderRadius: BorderRadius.circular(
            //                                       16,
            //                                     ),
            //                                     border: Border.all(
            //                                       color: activityColor.withOpacity(
            //                                         0.4,
            //                                       ),
            //                                     ),
            //                                   ),
            //                                   child: Row(
            //                                     // crossAxisAlignment:
            //                                     //     CrossAxisAlignment.center,
            //                                     children: [
            //                                       ClipRRect(
            //                                         borderRadius:
            //                                         BorderRadius.circular(12),
            //                                         child: SizedBox(
            //                                           width: 140,
            //                                           height: 120,
            //                                           child:
            //                                           activity.photoUrl != null ||
            //                                               activity.videoUrl !=
            //                                                   null
            //                                               ? ActivityMediaPreview(
            //                                             activity: activity,
            //                                             activityColor:
            //                                             activityColor,
            //                                           )
            //                                           // ? Image.network(
            //                                           //     activity.photoUrl!,
            //                                           //     fit: BoxFit.cover,
            //                                           //     loadingBuilder:
            //                                           //         (
            //                                           //           context,
            //                                           //           child,
            //                                           //           loadingProgress,
            //                                           //         ) {
            //                                           //           if (loadingProgress ==
            //                                           //               null)
            //                                           //             return child;
            //                                           //           return Container(
            //                                           //             color: Colors
            //                                           //                 .transparent,
            //                                           //             child: const Center(
            //                                           //               child: CircularProgressIndicator(
            //                                           //                 strokeWidth:
            //                                           //                     2,
            //                                           //               ),
            //                                           //             ),
            //                                           //           );
            //                                           //         },
            //                                           //     errorBuilder:
            //                                           //         (
            //                                           //           context,
            //                                           //           error,
            //                                           //           stackTrace,
            //                                           //         ) {
            //                                           //           return Container(
            //                                           //             width: 122,
            //                                           //             height: 76,
            //                                           //             color: activity
            //                                           //                 .color
            //                                           //                 .withOpacity(
            //                                           //                   0.25,
            //                                           //                 ),
            //                                           //             child: Center(
            //                                           //               child: Image.asset(
            //                                           //                 activityIcons[activity
            //                                           //                     .name],
            //                                           //                 //'assets/icons/activity-nap-icon.png',
            //                                           //                 fit: BoxFit
            //                                           //                     .fill,
            //                                           //               ),
            //                                           //             ),
            //                                           //           );
            //                                           //         },
            //                                           //   )
            //                                               : Container(
            //                                             width: 122,
            //                                             height: 76,
            //                                             color: Colors.white,
            //                                             // color: activityColor
            //                                             //     .withOpacity(0.25),
            //                                             child: Center(
            //                                               child: Image.asset(
            //                                                 activityIcons[activity
            //                                                     .name],
            //                                                 //'assets/icons/activity-nap-icon.png',
            //                                                 fit: BoxFit.fill,
            //                                               ),
            //                                             ),
            //                                           ),
            //                                         ),
            //                                       ),
            //                                       const SizedBox(width: 12),
            //                                       Expanded(
            //                                         child: Column(
            //                                           crossAxisAlignment:
            //                                           CrossAxisAlignment.start,
            //                                           mainAxisAlignment:
            //                                           MainAxisAlignment
            //                                               .spaceEvenly,
            //                                           children: [
            //                                             Row(
            //                                               mainAxisAlignment:
            //                                               MainAxisAlignment
            //                                                   .spaceBetween,
            //                                               children: [
            //                                                 Container(
            //                                                   padding:
            //                                                   const EdgeInsets.symmetric(
            //                                                     horizontal: 12,
            //                                                     vertical: 6,
            //                                                   ),
            //                                                   decoration: BoxDecoration(
            //                                                     color: activityColor,
            //                                                     borderRadius:
            //                                                     BorderRadius.circular(
            //                                                       20,
            //                                                     ),
            //                                                   ),
            //                                                   child: Text(
            //                                                     activity.name,
            //                                                     style:
            //                                                     const TextStyle(
            //                                                       color: Colors
            //                                                           .white,
            //                                                       fontSize: 11,
            //                                                       fontWeight:
            //                                                       FontWeight
            //                                                           .bold,
            //                                                     ),
            //                                                   ),
            //                                                 ),
            //                                                 PopupMenuButton<String>(
            //                                                   icon: const Icon(
            //                                                     Icons.more_horiz,
            //                                                     size: 20,
            //                                                   ),
            //                                                   onSelected: null,
            //                                                   itemBuilder: (context) => [
            //                                                     PopupMenuItem<String>(
            //                                                       value: 'view',
            //                                                       child: PopupItem(
            //                                                         title: 'View',
            //                                                         icon: Icon(
            //                                                           Icons
            //                                                               .visibility_outlined,
            //                                                           color: AppColors
            //                                                               .themeColor,
            //                                                         ),
            //                                                       ),
            //                                                       onTap: () {
            //                                                         final destinationBuilder =
            //                                                         activityRoutes[activity
            //                                                             .name];
            //                                                         if (destinationBuilder !=
            //                                                             null) {
            //                                                           final nextScreen =
            //                                                           destinationBuilder(
            //                                                             activity,
            //                                                           );
            //                                                           Navigator.of(
            //                                                             context,
            //                                                           ).push(
            //                                                             MaterialPageRoute(
            //                                                               builder: (_) =>
            //                                                               nextScreen,
            //                                                             ),
            //                                                           );
            //                                                         }
            //                                                       },
            //                                                     ),
            //                                                     PopupMenuItem<String>(
            //                                                       value: 'edit',
            //                                                       child: PopupItem(
            //                                                         title: 'Edit',
            //                                                         icon: Icon(
            //                                                           Icons.edit,
            //                                                           color: AppColors
            //                                                               .themeColor,
            //                                                         ),
            //                                                       ),
            //                                                       onTap: () {
            //                                                         final destinationBuilder =
            //                                                         editActivityRoutes[activity
            //                                                             .name];
            //                                                         if (destinationBuilder !=
            //                                                             null) {
            //                                                           final nextScreen =
            //                                                           destinationBuilder(
            //                                                             activity,
            //                                                           );
            //                                                           Navigator.of(
            //                                                             context,
            //                                                           ).push(
            //                                                             MaterialPageRoute(
            //                                                               builder: (_) =>
            //                                                               nextScreen,
            //                                                             ),
            //                                                           );
            //                                                         }
            //                                                       },
            //                                                     ),
            //                                                     PopupMenuItem<String>(
            //                                                       value: 'delete',
            //                                                       child: PopupItem(
            //                                                         title: 'Delete',
            //                                                         icon: Icon(
            //                                                           Icons.delete,
            //                                                           color: AppColors
            //                                                               .themeColor,
            //                                                         ),
            //                                                       ),
            //                                                     ),
            //                                                   ],
            //                                                 ),
            //                                               ],
            //                                             ),
            //                                             const SizedBox(height: 10),
            //
            //                                             SizedBox(
            //                                               height: 32,
            //                                               child: Stack(
            //                                                 children: [
            //                                                   for (
            //                                                   int i = 0;
            //                                                   i < students.length &&
            //                                                       i < 4;
            //                                                   i++
            //                                                   )
            //                                                     Positioned(
            //                                                       left: i * 20,
            //                                                       child:
            //                                                       DocumentImageWidget(
            //                                                         fileUuid: '',
            //                                                         name:
            //                                                         students[i],
            //                                                         size: 28,
            //                                                         fontSize: 10,
            //                                                       ),
            //                                                     ),
            //
            //                                                   // Extra count tooltip
            //                                                   if (students.length > 4)
            //                                                     Positioned(
            //                                                       left:
            //                                                       4 *
            //                                                           20, // after 4 avatars
            //                                                       child: Tooltip(
            //                                                         message: students
            //                                                             .skip(4)
            //                                                             .join(', '),
            //                                                         child: DocumentImageWidget(
            //                                                           fileUuid: '',
            //                                                           name:
            //                                                           '+${students.length - 4}',
            //                                                           size: 28,
            //                                                           fontSize: 10,
            //                                                         ),
            //                                                       ),
            //                                                     ),
            //                                                 ],
            //                                               ),
            //                                             ),
            //                                             const SizedBox(height: 10),
            //
            //                                             Text(
            //                                               activity.description!,
            //
            //                                               style: TextStyle(
            //                                                 color: AppColors
            //                                                     .primaryColor,
            //                                                 fontSize: 14,
            //                                                 fontWeight:
            //                                                 FontWeight.w600,
            //                                               ),
            //                                               maxLines: 1,
            //                                               overflow:
            //                                               TextOverflow.ellipsis,
            //                                             ),
            //                                             const SizedBox(height: 10),
            //                                             Text(
            //                                               'Created By - ${activity.createdBy}',
            //
            //                                               style: TextStyle(
            //                                                 color: AppColors
            //                                                     .primaryColor,
            //                                                 fontSize: 12,
            //                                                 fontWeight:
            //                                                 FontWeight.w500,
            //                                               ),
            //                                               maxLines: 1,
            //                                               overflow:
            //                                               TextOverflow.ellipsis,
            //                                             ),
            //                                           ],
            //                                         ),
            //                                       ),
            //                                     ],
            //                                   ),
            //                                 ),
            //                               ),
            //                             ],
            //                           ),
            //                         ],
            //                       ),
            //                     ],
            //                   );
            //                 },
            //               ),
            //             ],
            //           ),
            //         ),
            //     ],
            //   ),
            // );
          } else {
            return CustomRefreshIndicator(
              onRefresh: _onRefresh,
              child: Column(
                children: [
                Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: widget.fromStudentProfile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 40,
                          child: AbsorbPointer(
                            child: _buildCustomDropdown(
                              'Select Student',
                              widget.studentName != null
                                  ? [widget.studentName!]
                                  : <String>[],
                              widget.studentName,
                              (v) => setState(() {
                                _selectedStudent = v;
                              }),
                              height: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: _datePickerFilter(
                            selectedDate: _selectedDate,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadDailyFeed();
                            },
                          ),
                        ),
                      ],
                    )
                        : isNotParent
                        ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCustomDropdown(
                                'Select Classroom',
                                _classroomOptions,
                                _selectdClassroom,
                                (v) {
                                  setState(() {
                                    _selectdClassroom = v;
                                    _updateAvailableStudents();
                                  });
                                  _reloadStudentsAndSettingsThenFeed();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // child: _buildCustomDropdown(
                              //   'Select Student',
                              //   _allStudents,
                              //   _selectedStudent,
                              //   (v) => setState(() {
                              //     _selectedStudent = v;
                              //   }),
                              // ),
                              child: _buildCustomDropdown(
                                _selectdClassroom == null
                                    ? 'Select Classroom First'
                                    : 'Select Student',
                                _availableStudents,
                                _selectedStudent,
                                (value) {
                                  if (_selectdClassroom != null) {
                                    setState(() {
                                      _selectedStudent = value;
                                    });
                                    _loadDailyFeed();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: _openActivityFilter,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    MediaRes.filterIcon,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _datePickerFilter(
                                selectedDate: _selectedDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                  _loadDailyFeed();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  if (_classroomOptions.isNotEmpty) {
                                    _selectdClassroom = _classroomOptions.first;
                                  }
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                                _reloadStudentsAndSettingsThenFeed();
                              },
                              label: 'Clear All',
                            ),
                          ],
                        ),
                      ],
                    )
                        : SizedBox(
                            height: 40,
                            child: _datePickerFilter(
                              selectedDate: _selectedDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                                _loadDailyFeed();
                              },
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                if ((_loadingFeed || _loadingParentContext) &&
                    _activities.isEmpty)
                  Expanded(
                    child: _dailyFeedLoadingSheet(
                      context,
                      expandToParentHeight: true,
                    ),
                  ),

                if (!_loadingFeed &&
                    !_loadingParentContext &&
                    _activities.length == 0)
                  Expanded(
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: AppText.title(
                            _feedError ?? 'No Activities found',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_activities.length != 0)
                  Expanded(
                    child: Padding(
                      padding: ResponsiveSizing.activityFeedListPadding(context),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              controller: _feedScrollController,
                              padding: EdgeInsets.zero,
                              itemCount: _activities.length +
                                  (_loadingMoreFeed ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _activities.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: PrimaryCircularLoader(
                                        size: 28,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  );
                                }
                                final activity = _activities[index];
                                final students = activity.studentList;
                                final Color activityColor =
                                _colorPalette[index % _colorPalette.length];

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                //color: activity.color,
                                                color: activityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 2,
                                              //color: activity.color,
                                              color: activityColor,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 100,
                                          height: 4,
                                          //color: activity.color,
                                          color: activityColor,
                                        ),
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                                //color: activity.color,
                                                color: activityColor,
                                                shape: BoxShape.circle,
                                              ),
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          height: 20,
                                          child: AppText.small(
                                            activity.time,
                                            style: AppTextStyles.small.copyWith(
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(width: 7),
                                        Container(
                                          width: 4,
                                          height: 220,
                                          //color: activity.color,
                                          color: activityColor,
                                        ),

                                        const SizedBox(width: 16),

                                        // Activity Card
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 15),
                                              InkWell(
                                                onTap: () async {
                                                  final destinationBuilder =
                                                  activityRoutes[activity
                                                      .name];
                                                  if (destinationBuilder !=
                                                      null) {
                                                    final nextScreen =
                                                    destinationBuilder(
                                                      activity,
                                                    );
                                                    await Navigator.of(
                                                      context,
                                                    ).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                        nextScreen,
                                                      ),
                                                    );
                                                    if (mounted) {
                                                      await _loadDailyFeed(refresh: true);
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  constraints: const BoxConstraints(
                                                    minHeight: 180,
                                                  ),
                                                    margin: const EdgeInsets.only(
                                                    bottom: 10,
                                                  ),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: activityColor.withOpacity(
                                                      0.15,
                                                    ),
                                                    borderRadius: BorderRadius.circular(
                                                      16,
                                                    ),
                                                    border: Border.all(
                                                      color: activityColor.withOpacity(
                                                        0.4,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                        BorderRadius.circular(12),
                                                        child: SizedBox(
                                                          width: 140,
                                                          height: 120,
                                                          child:
                                                          activity.photoUrl != null ||
                                                              activity.videoUrl !=
                                                                  null
                                                              ? ActivityMediaPreview(
                                                            activity: activity,
                                                            activityColor:
                                                            activityColor,
                                                          )
                                                          // ? Image.network(
                                                          //     activity.photoUrl!,
                                                          //     fit: BoxFit.cover,
                                                          //     loadingBuilder:
                                                          //         (
                                                          //           context,
                                                          //           child,
                                                          //           loadingProgress,
                                                          //         ) {
                                                          //           if (loadingProgress ==
                                                          //               null)
                                                          //             return child;
                                                          //           return Container(
                                                          //             color: Colors
                                                          //                 .transparent,
                                                          //             child: const Center(
                                                          //               child: CircularProgressIndicator(
                                                          //                 strokeWidth:
                                                          //                     2,
                                                          //               ),
                                                          //             ),
                                                          //           );
                                                          //         },
                                                          //     errorBuilder:
                                                          //         (
                                                          //           context,
                                                          //           error,
                                                          //           stackTrace,
                                                          //         ) {
                                                          //           return Container(
                                                          //             width: 122,
                                                          //             height: 76,
                                                          //             color: activity
                                                          //                 .color
                                                          //                 .withOpacity(
                                                          //                   0.25,
                                                          //                 ),
                                                          //             child: Center(
                                                          //               child: Image.asset(
                                                          //                 activityIcons[activity
                                                          //                     .name],
                                                          //                 //'assets/icons/activity-nap-icon.png',
                                                          //                 fit: BoxFit
                                                          //                     .fill,
                                                          //               ),
                                                          //             ),
                                                          //           );
                                                          //         },
                                                          //   )
                                                              : Container(
                                                            width: 122,
                                                            height: 76,
                                                            color: Colors.white,
                                                            // color: activityColor
                                                            //     .withOpacity(0.25),
                                                            child: Center(
                                                              child: Image.asset(
                                                                activityIcons[activity
                                                                    .name],
                                                                //'assets/icons/activity-nap-icon.png',
                                                                fit: BoxFit.fill,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Align(
                                                                    alignment:
                                                                        Alignment.centerLeft,
                                                                    child: Container(
                                                                      padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal: 12,
                                                                        vertical: 6,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            activityColor
                                                                                .withOpacity(
                                                                                  0.5,
                                                                                ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                      ),
                                                                      child: Text(
                                                                        activity.name,
                                                                        maxLines: 1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style:
                                                                        const TextStyle(
                                                                          color: AppColors
                                                                              .primaryColor,
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                PopupMenuButton<String>(
                                                                  icon: const Icon(
                                                                    Icons.more_horiz,
                                                                    size: 20,
                                                                  ),
                                                                  onSelected: null,
                                                                  itemBuilder: (context) => [
                                                                    PopupMenuItem<String>(
                                                                      value: 'view',
                                                                      child: PopupItem(
                                                                        title: 'View',
                                                                        icon: Icon(
                                                                          Icons
                                                                              .visibility_outlined,
                                                                          color: AppColors
                                                                              .themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () async {
                                                                        final destinationBuilder =
                                                                        activityRoutes[activity
                                                                            .name];
                                                                        if (destinationBuilder !=
                                                                            null) {
                                                                          final nextScreen =
                                                                          destinationBuilder(
                                                                            activity,
                                                                          );
                                                                          await Navigator.of(
                                                                            context,
                                                                          ).push(
                                                                            MaterialPageRoute(
                                                                              builder: (_) =>
                                                                              nextScreen,
                                                                            ),
                                                                          );
                                                                          if (mounted) {
                                                                            await _loadDailyFeed(refresh: true);
                                                                          }
                                                                        }
                                                                      },
                                                                    ),
                                                                    if (widget.allowActivityWrite) ...[
                                                                      PopupMenuItem<String>(
                                                                        value: 'edit',
                                                                        child: PopupItem(
                                                                          title: 'Edit',
                                                                          icon: Icon(
                                                                            Icons.edit,
                                                                            color: AppColors
                                                                                .themeColor,
                                                                          ),
                                                                        ),
                                                                        onTap: () async {
                                                                          final destinationBuilder =
                                                                          editActivityRoutes[activity
                                                                              .name];
                                                                          if (destinationBuilder !=
                                                                              null) {
                                                                            final nextScreen =
                                                                            destinationBuilder(
                                                                              activity,
                                                                            );
                                                                            await Navigator.of(
                                                                              context,
                                                                            ).push(
                                                                              MaterialPageRoute(
                                                                                builder: (_) =>
                                                                                nextScreen,
                                                                              ),
                                                                            );
                                                                            if (mounted) {
                                                                              await _loadDailyFeed(refresh: true);
                                                                            }
                                                                          }
                                                                        },
                                                                      ),
                                                                      PopupMenuItem<String>(
                                                                        value: 'delete',
                                                                        onTap: ()  {
                                                                          showModalBottomSheet(
                                                                            context: context,
                                                                            isScrollControlled: true,
                                                                            backgroundColor: Colors.transparent,
                                                                            builder: (ctx) {
                                                                              return DeleteConfirmationBottomSheet(
                                                                                name: activity.name,
                                                                                type: 'Activity',
                                                                                onDelete: () =>
                                                                                    _deleteActivityFromSheet(ctx, activity),
                                                                                onCancel: () {
                                                                                  Navigator.of(ctx).pop();
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        child: PopupItem(
                                                                          title: 'Delete',
                                                                          icon: Icon(
                                                                            Icons.delete,
                                                                            color: AppColors
                                                                                .themeColor,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 10),

                                                            SizedBox(
                                                              height: 32,
                                                              child: Stack(
                                                                children: [
                                                                  for (
                                                                  int i = 0;
                                                                  i < students.length &&
                                                                      i < 4;
                                                                  i++
                                                                  )
                                                                    Positioned(
                                                                      left: i * 20,
                                                                      child:
                                                                      DocumentImageWidget(
                                                                        fileUuid: '',
                                                                        name:
                                                                        students[i],
                                                                        size: 28,
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),

                                                                  // Extra count tooltip
                                                                  if (students.length > 4)
                                                                    Positioned(
                                                                      left:
                                                                      4 *
                                                                          20, // after 4 avatars
                                                                      child: Tooltip(
                                                                        message: students
                                                                            .skip(4)
                                                                            .join(', '),
                                                                        child: DocumentImageWidget(
                                                                          fileUuid: '',
                                                                          name:
                                                                          '+${students.length - 4}',
                                                                          size: 28,
                                                                          fontSize: 10,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(height: 10),

                                                            Text(
                                                              activityFeedCardBodyLine(activity),
                                                              style: AppTextStyles.body.copyWith(
                                                                color: AppColors.primaryColor,
                                                                fontWeight: FontWeight.w600,
                                                                height: 1.0,
                                                              ),
                                                              strutStyle: StrutStyle(
                                                                fontFamily: Fonts.manrope,
                                                                fontSize: 14,
                                                                height: 1.0,
                                                                leading: 0,
                                                                fontWeight: FontWeight.w600,
                                                                forceStrutHeight: true,
                                                              ),
                                                              textHeightBehavior:
                                                                  const TextHeightBehavior(
                                                                applyHeightToFirstAscent: false,
                                                                applyHeightToLastDescent: false,
                                                              ),
                                                              maxLines:
                                                                  activityFeedCardBodyMaxLines(
                                                                      activity),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 10),
                                                            AppText.small(
                                                              'Created By - ${activity.createdBy}',
                                                              style: AppTextStyles.small.copyWith(
                                                                color: AppColors.primaryColor,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),);
          }
        }
    );
  }

  Widget _datePickerFilter({
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => CalendarDialog(
            isTimePicker: false,
            initialDate: selectedDate,
            whiteBgColor: true,
          ),
        );

        if (result != null && result['date'] != null) {
          onDateSelected(result['date'] as DateTime);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFB1AFE9).withOpacity(0.102),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(selectedDate)
                      : 'Select Date',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: selectedDate == null
                        ? Colors.grey[600]
                        : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                MediaRes.calender_icon,
                height: 20.0,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
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
    double? height,
  }) {
    return CustomDropdown(
      label: null,
      hintText: hintText,
      height: height ?? 40,
      items: items,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: selectedItem != null && selectedItem.trim().isNotEmpty
            ? Colors.black87
            : Colors.grey[600],
      ),
      popupItemTextStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}

class PopupItem extends StatelessWidget {
  final String title;
  final Icon icon;

  const PopupItem({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Feed card line under student avatars (Meal / Bottle / Nap / Learning / Bathroom + description).
String activityFeedCardBodyLine(ActivityItem activity) {
  if (activity.name == 'Meal') {
    final mt = activity.mealType?.trim();
    final mq = activity.mealQuantity?.trim();
    final desc = activity.description?.trim();

    String? firstLine;
    if (mt != null &&
        mt.isNotEmpty &&
        mq != null &&
        mq.isNotEmpty) {
      firstLine = '$mt Quantity: $mq';
    } else if (mt != null && mt.isNotEmpty) {
      firstLine = mt;
    } else if (mq != null && mq.isNotEmpty) {
      firstLine = 'Quantity: $mq';
    }

    if (firstLine != null && firstLine.isNotEmpty) {
      if (desc != null && desc.isNotEmpty) {
        return '$firstLine\n$desc';
      }
      return firstLine;
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Bottle') {
    final desc = activity.description?.trim();
    final oz = _formatBottleOzCompact(activity.amountConsumed);
    final st = activity.bottleConsumptionStatus?.trim();
    final stClean = (st == null || st.isEmpty)
        ? null
        : st.replaceAll(RegExp(r'[\s,;]+$'), '').trim();

    String? primary;
    if (stClean != null && stClean.isNotEmpty && oz != null) {
      primary = '$stClean: $oz';
    } else if (oz != null && oz.isNotEmpty) {
      primary = oz;
    } else if (stClean != null && stClean.isNotEmpty) {
      primary = stClean;
    }

    if (primary != null && primary.isNotEmpty) {
      if (desc != null && desc.isNotEmpty) {
        return '$primary · $desc';
      }
      return primary;
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Nap Start' || activity.name == 'Nap End') {
    final desc = activity.description?.trim();
    final isStart = activity.name == 'Nap Start';
    final at = isStart
        ? (activity.napStartTime?.trim().isNotEmpty == true
            ? activity.napStartTime!.trim()
            : activity.time.trim())
        : (activity.napEndTime?.trim().isNotEmpty == true
            ? activity.napEndTime!.trim()
            : (activity.napStartTime?.trim().isNotEmpty == true
                ? activity.napStartTime!.trim()
                : activity.time.trim()));
    final firstLine =
        at.isNotEmpty ? 'Nap ${isStart ? 'started' : 'ended'} at $at' : 'Nap';
    if (desc != null && desc.isNotEmpty) {
      return '$firstLine\n$desc';
    }
    return firstLine;
  }
  if (activity.name == 'Learning') {
    final at = activity.activityType?.trim();
    final cats = activity.categoryType;
    final desc = activity.description?.trim();
    final parts = <String>[];
    if (at != null && at.isNotEmpty) parts.add(at);
    if (cats != null && cats.isNotEmpty) {
      final c = cats
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
      if (c.isNotEmpty) parts.add(c);
    }
    if (parts.isNotEmpty) {
      final first = parts.join(' · ');
      if (desc != null && desc.isNotEmpty) {
        return '$first\n$desc';
      }
      return first;
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  if (activity.name == 'Bathroom') {
    final t = activity.bathroomType?.trim();
    final st = activity.bathroomSubType?.trim();
    final desc = activity.description?.trim();
    final parts = <String>[];
    if (t != null && t.isNotEmpty) parts.add(t);
    if (st != null && st.isNotEmpty) parts.add(st);
    if (parts.isNotEmpty) {
      final first = parts.join(' · ');
      if (desc != null && desc.isNotEmpty) {
        return '$first\n$desc';
      }
      return first;
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return 'No description';
  }
  final d = activity.description?.trim();
  return (d != null && d.isNotEmpty) ? d : 'No description';
}

int activityFeedCardBodyMaxLines(ActivityItem activity) {
  if (activity.name == 'Bottle') return 2;
  if (activity.name == 'Meal') return 3;
  if (activity.name == 'Nap Start' || activity.name == 'Nap End') return 4;
  if (activity.name == 'Learning') return 3;
  if (activity.name == 'Bathroom') return 3;
  return 1;
}

String? _formatBottleOzCompact(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  var t = raw.trim();
  final upper = t.toUpperCase();
  if (upper.contains('OZ')) {
    final numPart = t.replaceAll(RegExp(r'[^0-9.]'), '');
    final n = double.tryParse(numPart);
    if (n != null) {
      final s = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
      return '${s}OZ';
    }
    return t.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }
  final n = double.tryParse(t.replaceAll(',', ''));
  if (n != null) {
    final s = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
    return '${s} OZ';
  }
  return t;
}

/// Public for bottle detail view; same rules as the daily feed card (`6OZ`).
String? formatBottleAmountForDisplay(String? raw) => _formatBottleOzCompact(raw);

class ActivityItem {
  final String time;
  final String date;
  final String name;
  final String? description;
  //final Color color;
  final String? photoUrl;
  final String? videoUrl;
  final List<String> studentList;
  final String createdBy;
  final String? activityType; // for learning activity
  final List<String>? categoryType; // for learning activity
  final String? mealType; // for meal activity
  final String? mealQuantity; // also for meal activity
  final String? amountConsumed; // for bottle activity (volume, e.g. 6 OZ)
  /// Consumption / intake status from feed (e.g. "Consumed"), not the free-text description.
  final String? bottleConsumptionStatus;
  final String? napStartTime; // for nap activity
  final bool? remainderOn; // for nap start activity
  final String? napEndTime; // for nap end activity
  final String? whatHappened; // for incident activity
  final bool? firstAidAdministered; // for incident activity
  final String? staffPresent; // can be equal to createdBy
  final String? additionalNotes; // for incident activity
  final String? bathroomType; // for bathroom activity
  final String? bathroomSubType; // also for bathroom activity
  /// From feed row; used to load activity-type parameter definitions in edit flows.
  final String? activityTypeCode;
  /// `GET /api/v1/activities/code/{code}` / `PATCH /api/v1/activities/{code}`
  final String? activityCode;
  final String? studentCode;
  final String? classroomCode;
  /// Raw ISO from API (edit / prefetch).
  final String? activityDateIso;
  /// Attachment rows from feed (or detail) snapshot; used by edit screens without GET-by-code.
  final List<Map<String, dynamic>>? snapshotAttachments;

  const ActivityItem({
    required this.time,
    required this.date,
    required this.name,
    this.description,
    //required this.color,
    this.photoUrl,
    this.videoUrl,
    required this.studentList,
    required this.createdBy,
    this.activityType,
    this.categoryType,
    this.mealType,
    this.mealQuantity,
    this.amountConsumed,
    this.bottleConsumptionStatus,
    this.napStartTime,
    this.remainderOn,
    this.napEndTime,
    this.whatHappened,
    this.firstAidAdministered,
    this.staffPresent,
    this.additionalNotes,
    this.bathroomType,
    this.bathroomSubType,
    this.activityTypeCode,
    this.activityCode,
    this.studentCode,
    this.classroomCode,
    this.activityDateIso,
    this.snapshotAttachments,
  });
}

/// Rebuilds UI model from `GET /api/v1/activities/code/{code}` for edit prefetch.
ActivityItem activityItemFromActivityDetail(ActivityDetail detail) {
  return activityItemFromFeedRow(ActivityFeedRow.fromActivityDetail(detail));
}

/// Maps [ActivityItem] to student maps used by create/edit activity screens.
List<Map<String, dynamic>> studentDataMapsForActivityEdit(ActivityItem activity) {
  final code = activity.studentCode?.trim();
  final room = activity.classroomCode?.trim();
  final maps = <Map<String, dynamic>>[];
  for (final name in activity.studentList) {
    maps.add({
      'name': name,
      if (code != null && code.isNotEmpty) 'studentCode': code,
      if (room != null && room.isNotEmpty) 'classroomCode': room,
    });
  }
  if (maps.isEmpty && activity.studentList.isEmpty) {
    maps.add({'name': 'Student'});
  }
  return maps;
}

/// Maps backend [ActivityFeedRow.activityTypeName] to UI keys used in [activityRoutes].
String mapApiActivityTypeNameToUiLabel(String apiName) {
  final s = apiName.toLowerCase().trim();
  if (s.isEmpty) return 'Notes';
  if (s.contains('nap')) {
    if (s.contains('start')) return 'Nap Start';
    if (s.contains('end') ||
        s.contains('stop') ||
        s.contains('wake')) {
      return 'Nap End';
    }
    return 'Nap Start';
  }
  if (s.contains('bathroom') ||
      s.contains('potty') ||
      s.contains('diaper')) {
    return 'Bathroom';
  }
  if (s.contains('bottle')) return 'Bottle';
  if (s.contains('meal') ||
      s.contains('lunch') ||
      s.contains('breakfast') ||
      s.contains('snack')) {
    return 'Meal';
  }
  if (s.contains('incident')) return 'Incident';
  if (s.contains('medication') || s.contains('medicine')) {
    return 'Medication';
  }
  if (s.contains('outdoor') || s.contains('outside')) return 'Outdoor';
  if (s.contains('learning')) return 'Learning';
  if (s.contains('photo') && !s.contains('video')) return 'Photo';
  if (s.contains('video')) return 'Video';
  if (s.contains('note')) return 'Notes';
  if (s.contains('sign') && s.contains('in')) return 'Sign-in';
  if (s.contains('sign') && s.contains('out')) return 'Sign-out';
  if (s.contains('absent')) return 'Absent';
  return apiName.trim();
}

ActivityItem activityItemFromFeedRow(ActivityFeedRow row) {
  DateTime dt;
  try {
    dt = DateTime.parse(row.activityDateIso).toLocal();
  } catch (_) {
    dt = DateTime.now();
  }
  final time = DateFormat.jm().format(dt);
  final date = DateFormat('MMMM d, yyyy').format(dt);
  final name = mapApiActivityTypeNameToUiLabel(row.activityTypeName);

  String? photoUrl;
  String? videoUrl;
  for (final a in row.attachments) {
    final mt = (a['mediaType'] ?? '').toString().toLowerCase();
    final u =
        (a['deliveryUrl'] ?? a['thumbnailUrl'] ?? '').toString().trim();
    if (u.isEmpty) continue;
    if (mt.contains('video') ||
        u.toLowerCase().endsWith('.mp4') ||
        u.toLowerCase().endsWith('.mov')) {
      videoUrl ??= u;
    } else {
      photoUrl ??= u;
    }
  }

  String? pickParam(bool Function(String n) match) {
    for (final p in row.parameterValues) {
      final n = (p['parameterName'] ?? '').toString().toLowerCase();
      if (!match(n)) continue;
      // Prefer human-readable labels (dropdowns) before option codes in valueText.
      for (final key in <String>[
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
        'valueNumber',
        'valueTime',
        'valueDatetime',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  String? paramDisplay(Map<String, dynamic> p) {
    for (final key in <String>[
      'selectedOptionLabel',
      'valueText',
      'valueNumber',
      'valueTime',
      'valueDatetime',
    ]) {
      final v = (p[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  String? bottleVolumeFromParams;
  String? bottleStatusFromParams;
  if (name == 'Bottle') {
    for (final p in row.parameterValues) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      final dt = (p['dataType'] ?? '').toString().toUpperCase();
      if (pn.contains('staff')) continue;
      if (dt == 'DATE' || dt == 'TIME') continue;
      if (pn == 'description' ||
          (pn.contains('description') && dt == 'TEXT')) continue;
      final val = paramDisplay(p);
      if (val == null || val.isEmpty) continue;
      final isConsumptionDropdown = dt == 'DROPDOWN' &&
          (pn.contains('consum') ||
              pn.contains('intake') ||
              pn.contains('status') ||
              pn.contains('left'));
      final isConsumptionText = !pn.contains('amount') &&
          !pn.contains('ounce') &&
          !pn.contains('volume') &&
          (pn.contains('consum') || pn.contains('intake'));
      if (isConsumptionDropdown || isConsumptionText) {
        bottleStatusFromParams ??= val;
        continue;
      }
      final isVolume = pn.contains('amount') ||
          pn.contains('ounce') ||
          pn.contains('volume') ||
          pn.contains(' ml') ||
          RegExp(r'\boz\b').hasMatch(pn);
      if (isVolume) {
        bottleVolumeFromParams ??= val;
      }
    }
  }

  final amountConsumed = name == 'Bottle'
      ? (bottleVolumeFromParams ??
          pickParam(
            (n) =>
                (n.contains('amount') ||
                    n.contains('ounce') ||
                    n.contains('oz')) &&
                !n.contains('consumption'),
          ))
      : pickParam(
          (n) =>
              n.contains('amount') ||
              n.contains('ounce') ||
              n.contains('oz') ||
              n.contains('consumed'),
        );
  final mealType = pickParam((n) => n.contains('meal') && n.contains('type')) ??
      pickParam((n) => n.contains('meal') && !n.contains('quantity'));
  final mealQuantity = name == 'Meal'
      ? pickParam(
          (n) =>
              (n.contains('quant') || n.contains('portion')) &&
              !n.contains('meal type'),
        )
      : pickParam(
          (n) => n.contains('quantity') || n.contains('portion'),
        );
  final napStartTime = pickParam((n) => n.contains('nap') && n.contains('start')) ??
      pickParam((n) => n.contains('start') && n.contains('nap'));
  final napEndTime = pickParam(
        (n) =>
            n.contains('nap') &&
            (n.contains('end') || n.contains('stop'))) ??
      pickParam(
        (n) =>
            n.contains('end') &&
            n.contains('nap') &&
            (n.contains('time') || n.contains('stop')),
      );
  /// Single "Time" param (e.g. PM_027) when nap start/end params are absent.
  final napTimeParam = pickParam((n) => n.trim().toLowerCase() == 'time');
  final bathroomType = pickParam(
          (n) => n.contains('bathroom') && n.contains('type')) ??
      pickParam((n) => n.contains('potty') || n.contains('diaper'));
  final bathroomSubType = pickParam((n) => n.contains('sub') && n.contains('type')) ??
      pickParam((n) => n.contains('subtype'));

  final desc = row.description.trim();
  final studentName =
      row.studentDisplayName.isEmpty ? 'Student' : row.studentDisplayName;
  final by = row.createdBy.trim().isEmpty ? 'Staff' : row.createdBy.trim();

  /// Learning: API stores these in [parameterValues] (e.g. PM_054 Activity Name, PM_055 Categories).
  final String? learningActivityName = name == 'Learning'
      ? (pickParam(
              (n) =>
                  n.contains('activity') &&
                  (n.contains('name') || n.contains('type')),
            ) ??
            pickParam(
              (n) => n.contains('learning') && !n.contains('categor'),
            ))
      : null;
  final String? learningCategory =
      name == 'Learning' ? pickParam((n) => n.contains('categor')) : null;

  return ActivityItem(
    time: time,
    date: date,
    name: name,
    description: desc.isEmpty ? null : desc,
    photoUrl: photoUrl,
    videoUrl: videoUrl,
    studentList: [studentName],
    createdBy: by,
    activityType: learningActivityName,
    categoryType: learningCategory != null && learningCategory.isNotEmpty
        ? [learningCategory]
        : null,
    mealType: name == 'Meal' ? mealType : null,
    mealQuantity: name == 'Meal' ? mealQuantity : null,
    amountConsumed: name == 'Bottle' ? amountConsumed : null,
    bottleConsumptionStatus:
        name == 'Bottle' ? bottleStatusFromParams : null,
    napStartTime: (name == 'Nap Start' || name == 'Nap End')
        ? (napStartTime ?? napTimeParam)
        : null,
    napEndTime: name == 'Nap End'
        ? (napEndTime ?? napTimeParam)
        : null,
    whatHappened:
        (name == 'Incident' || name == 'Notes') && desc.isNotEmpty
            ? desc
            : null,
    staffPresent: by,
    bathroomType: name == 'Bathroom' ? bathroomType : null,
    bathroomSubType: name == 'Bathroom' ? bathroomSubType : null,
    activityTypeCode: row.activityTypeCode.trim().isEmpty
        ? null
        : row.activityTypeCode.trim(),
    activityCode: (row.activityCode ?? '').trim().isEmpty
        ? null
        : row.activityCode!.trim(),
    studentCode: (row.studentCode ?? '').trim().isEmpty
        ? null
        : row.studentCode!.trim(),
    classroomCode: (row.classroomCode ?? '').trim().isEmpty
        ? null
        : row.classroomCode!.trim(),
    activityDateIso:
        row.activityDateIso.trim().isEmpty ? null : row.activityDateIso.trim(),
    snapshotAttachments: row.attachments.isEmpty
        ? null
        : row.attachments
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
  );
}
