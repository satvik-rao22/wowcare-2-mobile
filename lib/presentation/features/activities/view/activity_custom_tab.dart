import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

import '../../../../core/util/core_utils.dart';
import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/guardian_code_resolver.dart';
import '../../../../core/util/activity_feed_invalidation.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/activity/entities/activity_feed_row.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../domain/features/activity/usecases/get_range_activity_feed_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_codes_for_activity_tag_filter_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../util/activity_filter_metadata_cache.dart';
import '../widgets/activity_feed_student_avatar.dart';
import 'activity_filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import '../widgets/avtivity_media_preview.dart';
import 'activity_daily_tab.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/nap_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';
import '../util/activity_feed_page_cache_codec.dart';
import '../util/activity_parent_feed_merge.dart';

class ActivityCustomTab extends StatefulWidget {
  const ActivityCustomTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.isNotParent = true,
    this.allowActivityWrite = true,
  });

  final bool fromStudentProfile;
  final String? studentName;
  final bool isNotParent;
  /// Edit / delete; false when [DAILY_ACTIVITY] has `write: false`.
  final bool allowActivityWrite;

  static const String routeName = '/activityCustomTab';

  @override
  State<ActivityCustomTab> createState() => _ActivityCustomTabState();
}

class _ActivityCustomTabState extends State<ActivityCustomTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late bool isNotParent;
  bool get _parentHome => !isNotParent && !widget.fromStudentProfile;

  DateTime? _selectedStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _selectedEndDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  String? _selectdClassroom;
  String? _selectedStudent;
  List<String> _availableStudents = [];
  List<String> _filterTags = [];
  List<String> _filterActivityTypes = [];
  String? _selectedActivityType;
  String? _feedError;
  String? _schoolCode;
  String _viewerStaffDisplayName = '';
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _studentCodeByName = {};
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  Map<String, String> _tagNameToCode = {};
  final Set<String> _studentCodesForTagFilter = {};
  final Set<String> _parentAllowedStudentCodes = {};
  final Map<String, String> _parentStudentClassroomByCode = {};
  bool _loadingParentContext = false;
  bool _isFeedRequestInFlight = false;
  String? _lastFeedRequestKey;
  String? _lastGlobalSelectedStudentCode;
  DateTime? _lastFeedCompletedAt;
  bool _lastFeedCompletedWithError = false;
  String? _lastResolvedClassroomCode;
  static const int _feedPageSize = 10;
  final ScrollController _feedScrollController = ScrollController();
  bool _feedHasMore = false;
  bool _loadingMoreFeed = false;
  int _feedNextPage = 0;

  late final GetRangeActivityFeedUseCase _getRangeActivityFeedUseCase;
  late final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  late final GetClassroomActivitySettingsUseCase
      _getClassroomActivitySettingsUseCase;
  late final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  late final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  late final GetStudentCodesForActivityTagFilterUseCase
      _getStudentCodesForActivityTagFilterUseCase;
  late final GetStudentPageUseCase _getStudentPageUseCase;
  late final DeleteActivityUseCase _deleteActivityUseCase;
  late final StorageService _storageService;
  late final CacheManager _cacheManager;
  StreamSubscription<void>? _feedInvalidationSub;

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
  final Map<String, List<String>> classroomStudents = {};
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
  final List<String> _classroomOptions = [];
  final List<ActivityItem> activities = [];

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

  @override
  void initState() {
    super.initState();
    _getRangeActivityFeedUseCase = serviceLocator<GetRangeActivityFeedUseCase>();
    _getActiveClassroomsUseCase = serviceLocator<GetActiveClassroomsUseCase>();
    _getClassroomActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getStudentClassroomListUseCase =
        serviceLocator<GetStudentClassroomListUseCase>();
    _getTagNameCodeMapForSchoolUseCase =
        serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    _getStudentCodesForActivityTagFilterUseCase =
        serviceLocator<GetStudentCodesForActivityTagFilterUseCase>();
    _getStudentPageUseCase = serviceLocator<GetStudentPageUseCase>();
    _deleteActivityUseCase = serviceLocator<DeleteActivityUseCase>();
    _storageService = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storageService);

    _updateAvailableStudents();
    isNotParent = widget.isNotParent;
    //_selectedStudent = _allStudents[0];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapRangeFeed();
    });
    _feedScrollController.addListener(_onFeedScroll);
    _feedInvalidationSub =
        ActivityFeedInvalidation.onInvalidated.listen((_) {
      if (mounted) {
        _loadRangeFeed(refresh: true);
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

  void _onFeedScroll() {
    _maybeLoadNextRangeFeedPage();
  }

  void _maybeLoadNextRangeFeedPage() {
    if (!_feedScrollController.hasClients) return;
    if (_loadingMoreFeed || !_feedHasMore || _isFeedRequestInFlight) {
      return;
    }
    final position = _feedScrollController.position;
    if (position.maxScrollExtent <= 0) {
      _loadNextRangeFeedPage();
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextRangeFeedPage();
    }
  }

  List<ActivityItem> _itemsFromRangeFeedPage(ActivityFeedPage page) {
    final raw = page.content
        .map(
          (row) => activityItemFromFeedRow(
            row,
            viewerDisplayName: _viewerStaffDisplayName,
          ),
        )
        .toList();
    return mergeAdjacentMultiStudentFeedItems(_withClientFilters(raw));
  }

  Future<void> _loadNextRangeFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _isFeedRequestInFlight) return;

    if (_parentHome) {
      return _loadNextParentHomeRangeFeedPage();
    }

    final classroomName = _selectdClassroom;
    if (classroomName == null) return;

    final classroomCode = _classroomCodeByName[classroomName];
    if (classroomCode == null || classroomCode.trim().isEmpty) return;

    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (start == null || end == null) return;

    final selectedStudent = _selectedStudent;
    final studentCodeForRequest = selectedStudent == null
        ? null
        : _studentCodeByName[selectedStudent];
    final typeCode = _activityTypeCodeForApiFilter();

    _loadingMoreFeed = true;
    if (mounted) setState(() {});

    try {
      final page = await _getRangeActivityFeedUseCase(
        classroomCode: classroomCode,
        startDate: _dateQueryParam(start),
        endDate: _dateQueryParam(end),
        studentCode: studentCodeForRequest,
        activityTypeCode: typeCode,
        page: _feedNextPage,
        size: _feedPageSize,
      );

      final items = _itemsFromRangeFeedPage(page);

      if (!mounted) return;
      setState(() {
        activities.addAll(items);
        final merged = mergeAdjacentMultiStudentFeedItems(
          List<ActivityItem>.from(activities),
        );
        activities
          ..clear()
          ..addAll(merged);
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
            .addPostFrameCallback((_) => _maybeLoadNextRangeFeedPage());
      }
    }
  }

  Future<void> _loadParentHomeRangeFeed({bool refresh = false}) async {
    final school = _schoolCode;
    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (school == null ||
        school.isEmpty ||
        start == null ||
        end == null ||
        _parentAllowedStudentCodes.isEmpty) {
      if (mounted) {
        setState(() {
          activities.clear();
          _feedHasMore = false;
          _loadingMoreFeed = false;
        });
      }
      return;
    }

    final codes = _parentAllowedStudentCodes.toList()..sort();
    final typeCode = _activityTypeCodeForApiFilter();
    final requestKey = [
      'parentRange',
      school,
      codes.join(','),
      _dateQueryParam(start),
      _dateQueryParam(end),
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
          return _getRangeActivityFeedUseCase(
            classroomCode: cc,
            startDate: _dateQueryParam(start),
            endDate: _dateQueryParam(end),
            studentCode: sc,
            activityTypeCode: typeCode,
            page: 0,
            size: _feedPageSize,
          );
        }),
      );

      final merged = mergeActivityFeedPages(pages);
      final items = _itemsFromRangeFeedPage(merged);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        activities
          ..clear()
          ..addAll(items);
        _feedError = null;
        _feedHasMore = !merged.last;
        _feedNextPage = merged.last ? 0 : merged.pageNumber + 1;
        _loadingMoreFeed = false;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeLoadNextRangeFeedPage());
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = true;
    }
  }

  Future<void> _loadNextParentHomeRangeFeedPage() async {
    if (_loadingMoreFeed || !_feedHasMore || _isFeedRequestInFlight) return;

    final school = _schoolCode;
    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (school == null ||
        school.isEmpty ||
        start == null ||
        end == null ||
        _parentAllowedStudentCodes.isEmpty) {
      return;
    }

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
          return _getRangeActivityFeedUseCase(
            classroomCode: cc,
            startDate: _dateQueryParam(start),
            endDate: _dateQueryParam(end),
            studentCode: sc,
            activityTypeCode: typeCode,
            page: pageIndex,
            size: _feedPageSize,
          );
        }),
      );

      final merged = mergeActivityFeedPages(pages);
      final items = _itemsFromRangeFeedPage(merged);

      if (!mounted) return;
      setState(() {
        activities.addAll(items);
        final combined = mergeAdjacentMultiStudentFeedItems(
          List<ActivityItem>.from(activities),
        );
        activities
          ..clear()
          ..addAll(combined);
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
            .addPostFrameCallback((_) => _maybeLoadNextRangeFeedPage());
      }
    }
  }

  void _updateAvailableStudents() {
    if (_selectdClassroom != null) {
      _availableStudents = classroomStudents[_selectdClassroom] ?? [];
      // If current selected student is not in the new list, clear it
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
    await _loadRangeFeed(refresh: true);
  }

  /// Refreshes tag map from the network, then reloads the range feed (bypassing caches).
  Future<void> _refreshApisAfterClearAll() async {
    await _loadTagFilterOptions(forceRefresh: true);
    await _loadRangeFeed(refresh: true);
  }

  Future<void> _loadTagFilterOptions({bool forceRefresh = false}) async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;
    try {
      final map = await ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _getTagNameCodeMapForSchoolUseCase,
        schoolCode: school,
        forceRefresh: forceRefresh,
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

  String _dateQueryParam(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
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

  String? _activityTypeCodeForLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    for (final s in _classroomActivitySettings) {
      if (_filterLabelMatchesSetting(label, s.activityTypeName)) {
        return s.activityTypeCode;
      }
    }
    return null;
  }

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
    if (_filterTags.isNotEmpty) {
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
    if (school == null || school.isEmpty) return;

    final tagCodes = _filterTags
        .map((name) => _tagNameToCode[name]?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();
    if (tagCodes.isEmpty) return;

    try {
      if (_parentHome) {
        final classroomCodes = _parentStudentClassroomByCode.values
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        for (final cc in classroomCodes) {
          final students = await _getStudentCodesForActivityTagFilterUseCase(
            schoolCode: school,
            classroomCode: cc,
            tagCodes: tagCodes,
          );
          if (!mounted) return;
          _studentCodesForTagFilter.addAll(students);
        }
        return;
      }

      final classroomName = _selectdClassroom;
      if (classroomName == null ||
          !_classroomCodeByName.containsKey(classroomName)) {
        return;
      }
      final cc = _classroomCodeByName[classroomName]!;
      final students = await _getStudentCodesForActivityTagFilterUseCase(
        schoolCode: school,
        classroomCode: cc,
        tagCodes: tagCodes,
      );
      if (!mounted) return;
      _studentCodesForTagFilter.addAll(students);
    } catch (_) {
      if (mounted) _studentCodesForTagFilter.clear();
    }
  }

  Future<void> _bootstrapRangeFeed() async {
    final viewerName =
        (await _storageService.getString(StorageKeys.displayName) ?? '').trim();
    if (mounted) {
      setState(() {
        _viewerStaffDisplayName = viewerName;
      });
    }

    _schoolCode = (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

    if ((_schoolCode ?? '').isEmpty) {
      if (!mounted) return;
      const msg = 'School is not selected.';
      setState(() {
        _feedError = msg;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      return;
    }

    if (_parentHome) {
      await _bootstrapParentHome();
      return;
    }

    final school = _schoolCode ?? '';
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
            .where((e) => (e['name'] ?? '').isNotEmpty && (e['code'] ?? '').isNotEmpty)
            .toList();
        if (list.isNotEmpty && mounted) {
          _classroomCodeByName
            ..clear()
            ..addEntries(
              list
                  .map((c) => MapEntry(c['name'] ?? '', c['code'] ?? ''))
                  .where((e) => e.key.isNotEmpty && e.value.isNotEmpty),
            );
        }
      }
    } catch (_) {}

    try {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: school,
        onlyTypeClassroom: true,
      );

      _classroomCodeByName
        ..clear()
        ..addEntries(classrooms.map((c) => MapEntry(c.name, c.code)));
      _classroomOptions
        ..clear()
        ..addAll(classrooms.map((c) => c.name));
      if (_classroomOptions.isNotEmpty &&
          (_selectdClassroom == null || !_classroomOptions.contains(_selectdClassroom))) {
        _selectdClassroom = _classroomOptions.first;
      }
      await _cacheManager.saveCache(classroomCacheKey, {
        'classrooms': classrooms
            .map((c) => {'name': c.name, 'code': c.code})
            .toList(),
      });

      await Future.wait<void>([
        _loadRangeFeed(),
        _loadTagFilterOptions(),
      ]);
    } catch (e) {
      if (!mounted) return;
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
            activities.clear();
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

      // Parent UX: use the child currently selected in the global dropdown.
      final globalSelectedCode =
          (context.read<ParentChildProvider>().selectedChild?.code ?? '').trim();
      if (globalSelectedCode.isNotEmpty) {
        final selectedClassroom =
            _parentStudentClassroomByCode[globalSelectedCode];
        _parentAllowedStudentCodes
          ..clear()
          ..add(globalSelectedCode);
        _parentStudentClassroomByCode..clear();
        if (selectedClassroom != null && selectedClassroom.trim().isNotEmpty) {
          _parentStudentClassroomByCode[globalSelectedCode] =
              selectedClassroom.trim();
        }
        _lastGlobalSelectedStudentCode = globalSelectedCode;
      }

      if (_parentAllowedStudentCodes.isEmpty) {
        if (mounted) {
          setState(() {
            _feedError = 'No linked children with a classroom.';
            _loadingParentContext = false;
            activities.clear();
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _loadingParentContext = false;
        });
      }
      await _loadRangeFeed(refresh: true);
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

  Future<void> _loadRangeFeed({bool refresh = false}) async {
    if (_parentHome) {
      return _loadParentHomeRangeFeed(refresh: refresh);
    }

    final classroomName = _selectdClassroom;
    if (classroomName == null) return;

    final classroomCode = _classroomCodeByName[classroomName];
    if (classroomCode == null || classroomCode.trim().isEmpty) {
      if (!mounted) return;
      const msg = 'Classroom is not mapped to a valid code.';
      setState(() {
        _feedError = msg;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      return;
    }

    final start = _selectedStartDate;
    final end = _selectedEndDate ?? _selectedStartDate;
    if (start == null || end == null) return;
    final selectedStudent = _selectedStudent;
    final studentCodeForRequest = selectedStudent == null
        ? null
        : _studentCodeByName[selectedStudent];
    final typeCode = _activityTypeCodeForApiFilter();
    final requestKey = [
      classroomCode,
      _dateQueryParam(start),
      _dateQueryParam(end),
      studentCodeForRequest ?? '',
      typeCode ?? '',
      _filterActivityTypes.join(','),
      _filterTags.join(','),
    ].join('|');

    if (!refresh && _lastFeedRequestKey == requestKey) {
      if (_isFeedRequestInFlight) return;
      if (!_lastFeedCompletedWithError) {
        return;
      }
      final completedAt = _lastFeedCompletedAt;
      if (completedAt != null &&
          DateTime.now().difference(completedAt) < const Duration(seconds: 3)) {
        return;
      }
    }

    await _rebuildStudentCodesForTagFilter();
    if (!mounted) return;

    if (!refresh) {
      try {
        final cached = await _cacheManager.loadCache(
          ActivityFeedPageCacheCodec.rangeCacheKey(requestKey),
          validFor: StorageKeys.activityFeedCacheDuration,
        );
        final rev =
            await ActivityFeedInvalidation.currentRevision(_storageService);
        final cachedPage =
            ActivityFeedPageCacheCodec.decode(cached, currentRevision: rev);
        if (cachedPage != null && mounted) {
          final items = _itemsFromRangeFeedPage(cachedPage);
          setState(() {
            activities
              ..clear()
              ..addAll(items);
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
              .addPostFrameCallback((_) => _maybeLoadNextRangeFeedPage());
          return;
        }
      } catch (_) {}
    }

    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

    try {
      final page = await _getRangeActivityFeedUseCase(
        classroomCode: classroomCode,
        startDate: _dateQueryParam(start),
        endDate: _dateQueryParam(end),
        studentCode: studentCodeForRequest,
        activityTypeCode: typeCode,
        page: 0,
        size: _feedPageSize,
      );

      final items = _itemsFromRangeFeedPage(page);

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      try {
        final rev =
            await ActivityFeedInvalidation.currentRevision(_storageService);
        await _cacheManager.saveCache(
          ActivityFeedPageCacheCodec.rangeCacheKey(requestKey),
          ActivityFeedPageCacheCodec.wrapPage(page, rev),
        );
      } catch (_) {}
      setState(() {
        activities
          ..clear()
          ..addAll(items);
        _feedError = null;
        _feedHasMore = !page.last;
        _feedNextPage = page.last ? 0 : page.pageNumber + 1;
        _loadingMoreFeed = false;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeLoadNextRangeFeedPage());

      try {
        final school = _schoolCode;
        final shouldReloadClassroomDependencies =
            refresh ||
            _lastResolvedClassroomCode != classroomCode ||
            !classroomStudents.containsKey(classroomName) ||
            _classroomActivitySettings.isEmpty;

        if (shouldReloadClassroomDependencies) {
          if (school != null && school.isNotEmpty) {
            final studentsCacheKey = CacheManager.buildCacheKey(
              feature: 'activity',
              resource: 'students',
              identifier: '$school|$classroomCode',
            );
            if (!refresh) {
              try {
                final cachedStudents =
                    await _cacheManager.loadCache(studentsCacheKey);
                if (cachedStudents != null &&
                    cachedStudents['students'] is List) {
                  final cachedList = (cachedStudents['students'] as List)
                      .whereType<Map>()
                      .map((e) => <String, String>{
                            'name': (e['name'] ?? '').toString(),
                            'code': (e['code'] ?? '').toString(),
                          })
                      .where((e) =>
                          (e['name'] ?? '').isNotEmpty &&
                          (e['code'] ?? '').isNotEmpty)
                      .toList();
                  if (cachedList.isNotEmpty) {
                    _studentCodeByName
                      ..clear()
                      ..addEntries(cachedList.map(
                          (s) => MapEntry(s['name'] ?? '', s['code'] ?? '')));
                    classroomStudents[classroomName] =
                        cachedList.map((s) => s['name'] ?? '').toList();
                    _updateAvailableStudents();
                  }
                }
              } catch (_) {}
            }

            final students = await _getStudentClassroomListUseCase(
              schoolCode: school,
              classroomCode: classroomCode,
              status: const ['ACTIVE'],
              refresh: refresh,
            );
            _studentCodeByName
              ..clear()
              ..addEntries(
                  students.map((s) => MapEntry(s.fullName, s.studentCode)));
            classroomStudents[classroomName] =
                students.map((s) => s.fullName).toList();
            _updateAvailableStudents();
            await _cacheManager.saveCache(studentsCacheKey, {
              'students': students
                  .map((s) => {'name': s.fullName, 'code': s.studentCode})
                  .toList(),
            });
          }

          final settingsCacheKey = CacheManager.buildCacheKey(
            feature: 'activity',
            resource: 'settings',
            identifier: classroomCode,
          );
          if (!refresh) {
            try {
              final cachedSettings =
                  await _cacheManager.loadCache(settingsCacheKey);
              if (cachedSettings != null && cachedSettings['settings'] is List) {
                final list = (cachedSettings['settings'] as List)
                    .whereType<Map>()
                    .map(
                      (e) => ActivitySetting(
                        activityTypeCode:
                            (e['activityTypeCode'] ?? '').toString(),
                        activityTypeName:
                            (e['activityTypeName'] ?? '').toString(),
                        description: (e['description'] ?? '').toString(),
                        category: (e['category'] ?? '').toString(),
                        icon: (e['icon'] ?? '').toString(),
                        color: (e['color'] ?? '').toString(),
                        isSystem: (e['isSystem'] as bool?) ?? false,
                        isMultiStudent: (e['isMultiStudent'] as bool?) ?? false,
                        requiresStaff: (e['requiresStaff'] as bool?) ?? false,
                        requiresPhoto: (e['requiresPhoto'] as bool?) ?? false,
                        requiresVideo: (e['requiresVideo'] as bool?) ?? false,
                        allowsAttachments:
                            (e['allowsAttachments'] as bool?) ?? false,
                        maxAttachments: (e['maxAttachments'] as int?) ?? 0,
                        isEnabled: (e['isEnabled'] as bool?) ?? true,
                        isFavorite: (e['isFavorite'] as bool?) ?? false,
                        displayOrder: (e['displayOrder'] as int?) ?? 0,
                      ),
                    )
                    .where((e) =>
                        e.activityTypeCode.isNotEmpty &&
                        e.activityTypeName.isNotEmpty)
                    .toList();
                if (list.isNotEmpty) {
                  _classroomActivitySettings = list;
                }
              }
            } catch (_) {}
          }

          try {
            _classroomActivitySettings =
                await _getClassroomActivitySettingsUseCase(
              classroomCode: classroomCode,
              refresh: refresh,
            );
            await _cacheManager.saveCache(settingsCacheKey, {
              'settings': _classroomActivitySettings
                  .map((s) => {
                        'activityTypeCode': s.activityTypeCode,
                        'activityTypeName': s.activityTypeName,
                        'description': s.description,
                        'category': s.category,
                        'icon': s.icon,
                        'color': s.color,
                        'isSystem': s.isSystem,
                        'isMultiStudent': s.isMultiStudent,
                        'requiresStaff': s.requiresStaff,
                        'requiresPhoto': s.requiresPhoto,
                        'requiresVideo': s.requiresVideo,
                        'allowsAttachments': s.allowsAttachments,
                        'maxAttachments': s.maxAttachments,
                        'isEnabled': s.isEnabled,
                        'isFavorite': s.isFavorite,
                        'displayOrder': s.displayOrder,
                      })
                  .toList(),
            });
          } catch (_) {
            // Keep existing in-memory/cached settings on fetch failure.
          }
          _lastResolvedClassroomCode = classroomCode;
          if (mounted) setState(() {});
        }
      } catch (_) {
        // Students/settings are non-blocking after the feed is shown.
      }
    } catch (e) {
      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
        _feedHasMore = false;
      });
      CoreUtils.logApiError(msg, showOnScreen: true, context: context);
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = true;
    }
  }

  Future<void> _onRefresh() async {
    await _loadRangeFeed(refresh: true);
  }

  /// Minimum viewport height + [AlwaysScrollableScrollPhysics] so pull-to-refresh
  /// works when the feed is empty or loading (portrait [Column] layout).
  Widget _portraitOverscrollFeedWrapper({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _feedScrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  void _syncWithGlobalChildSelection() {
    if (!_parentHome) return;
    final globalSelectedCode =
        (context.read<ParentChildProvider>().selectedChild?.code ?? '').trim();
    if (globalSelectedCode.isEmpty) return;
    if (_lastGlobalSelectedStudentCode == globalSelectedCode) return;

    _lastGlobalSelectedStudentCode = globalSelectedCode;

    // If we don't yet have classroom mapping for this child, bootstrap first.
    if (_parentStudentClassroomByCode[globalSelectedCode] == null) {
      _bootstrapParentHome();
      return;
    }

    _parentAllowedStudentCodes
      ..clear()
      ..add(globalSelectedCode);

    _loadRangeFeed(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Listen to global child dropdown. When ParentChildProvider notifies,
    // this widget rebuilds and we can refresh the feed for the selected child.
    if (_parentHome) {
      context.watch<ParentChildProvider>().selectedChild?.code;
    }
    if (_parentHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncWithGlobalChildSelection();
      });
    }
    return OrientationBuilder(
        builder: (context, orientation){
          if(orientation == Orientation.landscape){
            return CustomRefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _feedScrollController,
              slivers: [
                SliverToBoxAdapter(child:  Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  // filter card
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
                            selectedStartDate: _selectedStartDate,
                            selectedEndDate: _selectedEndDate,
                            // onDateRangeSelected: (date) {
                            //   List<String>? dates = date?.split('-\n');
                            //   setState(() {
                            //     _selectedStartDate = dates?[0].trim() as DateTime?;
                            //     _selectedEndDate = dates?[1].trim() as DateTime;
                            //
                            //   });
                            // },
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
                                  _loadRangeFeed(refresh: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // child: _buildCustomDropdown(
                              //   'Select Student',
                              //   _allStudents,
                              //   _selectedStudent,
                              //       (v) => setState(() {
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
                                selectedStartDate: _selectedStartDate,
                                selectedEndDate: _selectedEndDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  final now = DateTime.now();
                                  _selectedStartDate =
                                      DateTime(now.year, now.month, 1);
                                  _selectedEndDate =
                                      DateTime(now.year, now.month + 1, 0);
                                  if (_classroomOptions.isNotEmpty) {
                                    _selectdClassroom = _classroomOptions.first;
                                  }
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                                _refreshApisAfterClearAll();
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
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                  ),
                ),),
                SliverToBoxAdapter(
                  child: SizedBox(height: _parentHome ? 0 : 12),
                ),
                if (_loadingParentContext && activities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 48,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: const PrimaryCircularLoader(
                          size: 40,
                          strokeWidth: 3.5,
                        ),
                      ),
                    ),
                  ),
                if (!_loadingParentContext && activities.isEmpty)
                  SliverToBoxAdapter(
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
                            style: AppTextStyles.title
                                .copyWith(color: AppColors.primaryColor.withValues(alpha: 0.55)),
                          ),
                        ),
                      ),
                    ),
                  ),
                if(activities.isNotEmpty)
                  SliverPadding(
                    padding: ResponsiveSizing.activityFeedListPadding(context),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                              (context, index){
                            if (index == activities.length) {
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
                            final activity = activities[index];
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
                                                    await _loadRangeFeed(refresh: true);
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
                                                              if (isNotParent)
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
                                                                          await _loadRangeFeed(refresh: true);
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
                                                                            await _loadRangeFeed(refresh: true);
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
                                                                      onTap: () {
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

                                                          activityFeedStudentAvatarStack(
                                                            students,
                                                            onOpenStudentList: () =>
                                                                showActivityStudentListSheet(
                                                              context,
                                                              students,
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
                          childCount: activities.length +
                              (_loadingMoreFeed ? 1 : 0),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 10))
              ],
            ),
            );
          } else {
            return CustomRefreshIndicator(
              onRefresh: _onRefresh,
              child: Column(
              children: [
                Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  // filter card
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
                            selectedStartDate: _selectedStartDate,
                            selectedEndDate: _selectedEndDate,
                            // onDateRangeSelected: (date) {
                            //   List<String>? dates = date?.split('-\n');
                            //   setState(() {
                            //     _selectedStartDate = dates?[0].trim() as DateTime?;
                            //     _selectedEndDate = dates?[1].trim() as DateTime;
                            //
                            //   });
                            // },
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
                                  _loadRangeFeed(refresh: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // child: _buildCustomDropdown(
                              //   'Select Student',
                              //   _allStudents,
                              //   _selectedStudent,
                              //       (v) => setState(() {
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
                                selectedStartDate: _selectedStartDate,
                                selectedEndDate: _selectedEndDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  final now = DateTime.now();
                                  _selectedStartDate =
                                      DateTime(now.year, now.month, 1);
                                  _selectedEndDate =
                                      DateTime(now.year, now.month + 1, 0);
                                  if (_classroomOptions.isNotEmpty) {
                                    _selectdClassroom = _classroomOptions.first;
                                  }
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                                _refreshApisAfterClearAll();
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
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_loadingParentContext && activities.isEmpty)
                  Expanded(
                    child: _portraitOverscrollFeedWrapper(
                      child: Padding(
                        padding: ResponsiveSizing.contentPadding(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 48,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: const PrimaryCircularLoader(
                            size: 40,
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!_loadingParentContext && activities.length == 0)
                  Expanded(
                    child: _portraitOverscrollFeedWrapper(
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
                            child: Text(
                              _feedError ?? 'No Activities found',
                              style: TextStyle(
                                color: AppColors.primaryColor.withValues(alpha: 0.55),
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (activities.length != 0)
                  Expanded(
                    child: Padding(
                      padding: ResponsiveSizing.activityFeedListPadding(context),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _feedScrollController,
                              padding: EdgeInsets.zero,
                              itemCount: activities.length +
                                  (_loadingMoreFeed ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == activities.length) {
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
                                final activity = activities[index];
                                final students = activity.studentList;
                                final Color activityColor = _colorPalette[index % _colorPalette.length];

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
                                                color: activityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 2,
                                              color: activityColor,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 100,
                                          height: 4,
                                          color: activityColor,
                                        ),
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: activityColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          height: 20,
                                          child: Text(
                                            activity.time,
                                            style: TextStyle(
                                              fontSize: 14,
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
                                          color: activityColor,
                                        ),

                                        const SizedBox(width: 16),

                                        // Activity Card
                                        Expanded(
                                          child: InkWell(
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
                                                  await _loadRangeFeed(refresh: true);
                                                }
                                              }
                                            },
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 15),
                                                Container(
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
                                                          activity.photoUrl != null || activity.videoUrl != null
                                                              ? ActivityMediaPreview(activity: activity, activityColor: activityColor,)
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
                                                          //             color: activityColor
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
                                                                Container(
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
                                                                    style:
                                                                    const TextStyle(
                                                                      color: AppColors
                                                                          .primaryColor,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (isNotParent)
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
                                                                            await _loadRangeFeed(refresh: true);
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
                                                                              await _loadRangeFeed(refresh: true);
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
                                                                        onTap: () {
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

                                                            activityFeedStudentAvatarStack(
                                                            students,
                                                            onOpenStudentList: () =>
                                                                showActivityStudentListSheet(
                                                              context,
                                                              students,
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
                                                            Text(
                                                              'Created By - ${activity.createdBy}',

                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                FontWeight.w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                              TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
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
            ),
            );
          }
        }
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: ResponsiveSizing.contentPadding(context),
  //         // filter card
  //         child: Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: AppColors.cardBorderColor),
  //             borderRadius: BorderRadius.circular(12),
  //             color: AppColors.cardColor,
  //           ),
  //           child: widget.fromStudentProfile
  //               ? Column(
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: [
  //                     SizedBox(
  //                       height: 40,
  //                       child: AbsorbPointer(
  //                         child: _buildCustomDropdown(
  //                           'Select Student',
  //                           [?widget.studentName],
  //                           widget.studentName,
  //                           (v) => setState(() {
  //                             _selectedStudent = v;
  //                           }),
  //                           height: 40,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 8),
  //                     SizedBox(
  //                       height: 40,
  //                       child: _datePickerFilter(
  //                         selectedStartDate: _selectedStartDate,
  //                         selectedEndDate: _selectedEndDate,
  //                         // onDateRangeSelected: (date) {
  //                         //   List<String>? dates = date?.split('-\n');
  //                         //   setState(() {
  //                         //     _selectedStartDate = dates?[0].trim() as DateTime?;
  //                         //     _selectedEndDate = dates?[1].trim() as DateTime;
  //                         //
  //                         //   });
  //                         // },
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               : isNotParent
  //               ? Column(
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: _buildCustomDropdown(
  //                             'Select Classroom',
  //                             _classroomOptions,
  //                             _selectdClassroom,
  //                             (v) => setState(() {
  //                               _selectdClassroom = v;
  //                               _updateAvailableStudents();
  //                             }),
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           // child: _buildCustomDropdown(
  //                           //   'Select Student',
  //                           //   _allStudents,
  //                           //   _selectedStudent,
  //                           //       (v) => setState(() {
  //                           //     _selectedStudent = v;
  //                           //   }),
  //                           // ),
  //                           child: _buildCustomDropdown(
  //                             _selectdClassroom == null
  //                                 ? 'Select Classroom First'
  //                                 : 'Select Student',
  //                             _availableStudents,
  //                             _selectedStudent,
  //                             (value) {
  //                               if (_selectdClassroom != null) {
  //                                 setState(() {
  //                                   _selectedStudent = value;
  //                                 });
  //                               }
  //                             },
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Material(
  //                           color: Colors.transparent,
  //                           child: InkWell(
  //                             borderRadius: BorderRadius.circular(100),
  //                             onTap: () async {
  //                               final result = await Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (_) => FilterScreen(
  //                                     sections: [
  //                                       FilerSection(
  //                                         label: 'Tags',
  //                                         hintText: 'Select tags',
  //                                         items: [
  //                                           '5 Days',
  //                                           'Full Day',
  //                                           'Photo Permission',
  //                                           'Vegetarian',
  //                                           'First Aid',
  //                                           'Allergy',
  //                                           'Pickup Authorized',
  //                                           'Medication',
  //                                           'Half Day',
  //                                           'Boy',
  //                                           'Girl',
  //                                         ],
  //                                         initialSelected: _filterTags,
  //                                         isMultiSelectDropDown: false,
  //                                       ),
  //                                       FilerSection(
  //                                         label: 'Activity Type',
  //                                         hintText: 'Select Activity',
  //                                         items: [
  //                                           'Nap Start',
  //                                           'Nap End',
  //                                           'Bathroom',
  //                                           'Bottle',
  //                                           'Meal',
  //                                           'Incident',
  //                                           'Photo',
  //                                           'Outdoor',
  //                                           'Medication',
  //                                           'Notes',
  //                                           'Learning',
  //                                           'Sign-in',
  //                                           'Sign-out',
  //                                           'Absent',
  //                                         ],
  //                                         initialSelected: _filterActivityTypes,
  //                                         isMultiSelectDropDown: false,
  //                                       ),
  //                                     ],
  //                                     onApply: (filters) {
  //                                       setState(() {
  //                                         _filterTags = filters['Tags']!;
  //                                         _filterActivityTypes =
  //                                             filters['Activity Type']!;
  //                                       });
  //                                     },
  //                                   ),
  //                                 ),
  //                               );
  //                               if (!mounted) return;
  //                               if (result is Map) {
  //                                 // TODO: apply filters to list
  //                                 setState(() {});
  //                               }
  //                             },
  //                             child: Padding(
  //                               padding: const EdgeInsets.all(8),
  //                               child: SvgPicture.asset(
  //                                 MediaRes.filterIcon,
  //                                 height: 20,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 16),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Expanded(
  //                           child: _datePickerFilter(
  //                             selectedStartDate: _selectedStartDate,
  //                             selectedEndDate: _selectedEndDate,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         CustomClearAllChip(
  //                           onTap: () {
  //                             setState(() {
  //                               _selectdClassroom = _classroomOptions[0];
  //                               _selectedStudent = null;
  //                               _filterActivityTypes.clear();
  //                               _filterTags.clear();
  //                             });
  //                           },
  //                           label: 'Clear All',
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 )
  //               : Row(
  //                   children: [
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 40,
  //                         child: _datePickerFilter(
  //                           selectedStartDate: _selectedStartDate,
  //                           selectedEndDate: _selectedEndDate,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 40,
  //                         child: _buildCustomDropdown(
  //                           'Activity Type',
  //                           activityType,
  //                           _selectedActivityType,
  //                           (v) => setState(() {
  //                             _selectedActivityType = v;
  //                           }),
  //                           height: 40,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //         ),
  //       ),
  //
  //       const SizedBox(height: 12),
  //
  //       if (activities.length == 0)
  //         Expanded(
  //           child: Padding(
  //             padding: ResponsiveSizing.contentPadding(context),
  //             child: Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 border: Border.all(color: AppColors.cardBorderColor),
  //                 borderRadius: BorderRadius.circular(12),
  //                 color: AppColors.cardColor,
  //               ),
  //               child: Center(
  //                 child: Text(
  //                   'No Activities found',
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                     fontFamily: 'Manrope',
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //
  //       if (activities.length != 0)
  //         Expanded(
  //           child: Padding(
  //             padding: ResponsiveSizing.contentPadding(context),
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 10),
  //                 Expanded(
  //                   child: ListView.builder(
  //                     padding: const EdgeInsets.only(right: 16),
  //                     itemCount: activities.length,
  //                     itemBuilder: (context, index) {
  //                       final activity = activities[index];
  //                       final students = activity.studentList;
  //                       final Color activityColor = _colorPalette[index % _colorPalette.length];
  //
  //                       return Column(
  //                         children: [
  //                           Row(
  //                             children: [
  //                               Column(
  //                                 children: [
  //                                   Container(
  //                                     width: 18,
  //                                     height: 18,
  //                                     decoration: BoxDecoration(
  //                                       color: activityColor,
  //                                       shape: BoxShape.circle,
  //                                     ),
  //                                   ),
  //                                   Container(
  //                                     width: 4,
  //                                     height: 2,
  //                                     color: activityColor,
  //                                   ),
  //                                 ],
  //                               ),
  //                               Container(
  //                                 width: 100,
  //                                 height: 4,
  //                                 color: activityColor,
  //                               ),
  //                               Container(
  //                                 width: 18,
  //                                 height: 18,
  //                                 decoration: BoxDecoration(
  //                                   color: activityColor,
  //                                   shape: BoxShape.circle,
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 20),
  //                               SizedBox(
  //                                 height: 20,
  //                                 child: Text(
  //                                   activity.time,
  //                                   style: TextStyle(
  //                                     fontSize: 14,
  //                                     color: AppColors.primaryColor,
  //                                     fontWeight: FontWeight.w500,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                           Row(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               const SizedBox(width: 7),
  //                               Container(
  //                                 width: 4,
  //                                 height: 220,
  //                                 color: activityColor,
  //                               ),
  //
  //                               const SizedBox(width: 16),
  //
  //                               // Activity Card
  //                               Expanded(
  //                                 child: Column(
  //                                   children: [
  //                                     const SizedBox(height: 15),
  //                                     Container(
  //                                       height: 180,
  //                                       margin: const EdgeInsets.only(
  //                                         bottom: 24,
  //                                       ),
  //                                       padding: const EdgeInsets.all(12),
  //                                       decoration: BoxDecoration(
  //                                         color: activityColor.withOpacity(
  //                                           0.15,
  //                                         ),
  //                                         borderRadius: BorderRadius.circular(
  //                                           16,
  //                                         ),
  //                                         border: Border.all(
  //                                           color: activityColor.withOpacity(
  //                                             0.4,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       child: Row(
  //                                         // crossAxisAlignment:
  //                                         //     CrossAxisAlignment.center,
  //                                         children: [
  //                                           ClipRRect(
  //                                             borderRadius:
  //                                                 BorderRadius.circular(12),
  //                                             child: SizedBox(
  //                                               width: 140,
  //                                               height: 120,
  //                                               child:
  //                                               activity.photoUrl != null || activity.videoUrl != null
  //                                                   ? ActivityMediaPreview(activity: activity, activityColor: activityColor,)
  //                                                   // ? Image.network(
  //                                                   //     activity.photoUrl!,
  //                                                   //     fit: BoxFit.cover,
  //                                                   //     loadingBuilder:
  //                                                   //         (
  //                                                   //           context,
  //                                                   //           child,
  //                                                   //           loadingProgress,
  //                                                   //         ) {
  //                                                   //           if (loadingProgress ==
  //                                                   //               null)
  //                                                   //             return child;
  //                                                   //           return Container(
  //                                                   //             color: Colors
  //                                                   //                 .transparent,
  //                                                   //             child: const Center(
  //                                                   //               child: CircularProgressIndicator(
  //                                                   //                 strokeWidth:
  //                                                   //                     2,
  //                                                   //               ),
  //                                                   //             ),
  //                                                   //           );
  //                                                   //         },
  //                                                   //     errorBuilder:
  //                                                   //         (
  //                                                   //           context,
  //                                                   //           error,
  //                                                   //           stackTrace,
  //                                                   //         ) {
  //                                                   //           return Container(
  //                                                   //             width: 122,
  //                                                   //             height: 76,
  //                                                   //             color: activityColor
  //                                                   //                 .withOpacity(
  //                                                   //                   0.25,
  //                                                   //                 ),
  //                                                   //             child: Center(
  //                                                   //               child: Image.asset(
  //                                                   //                 activityIcons[activity
  //                                                   //                     .name],
  //                                                   //                 //'assets/icons/activity-nap-icon.png',
  //                                                   //                 fit: BoxFit
  //                                                   //                     .fill,
  //                                                   //               ),
  //                                                   //             ),
  //                                                   //           );
  //                                                   //         },
  //                                                   //   )
  //                                                   : Container(
  //                                                       width: 122,
  //                                                       height: 76,
  //                                                       color: Colors.white,
  //                                                       // color: activityColor
  //                                                       //     .withOpacity(0.25),
  //                                                       child: Center(
  //                                                         child: Image.asset(
  //                                                           activityIcons[activity
  //                                                               .name],
  //                                                           //'assets/icons/activity-nap-icon.png',
  //                                                           fit: BoxFit.fill,
  //                                                         ),
  //                                                       ),
  //                                                     ),
  //                                             ),
  //                                           ),
  //                                           const SizedBox(width: 12),
  //                                           Expanded(
  //                                             child: Column(
  //                                               crossAxisAlignment:
  //                                                   CrossAxisAlignment.start,
  //                                               mainAxisAlignment:
  //                                                   MainAxisAlignment
  //                                                       .spaceEvenly,
  //                                               children: [
  //                                                 Row(
  //                                                   mainAxisAlignment:
  //                                                       MainAxisAlignment
  //                                                           .spaceBetween,
  //                                                   children: [
  //                                                     Container(
  //                                                       padding:
  //                                                           const EdgeInsets.symmetric(
  //                                                             horizontal: 12,
  //                                                             vertical: 6,
  //                                                           ),
  //                                                       decoration: BoxDecoration(
  //                                                         color: activityColor,
  //                                                         borderRadius:
  //                                                             BorderRadius.circular(
  //                                                               20,
  //                                                             ),
  //                                                       ),
  //                                                       child: Text(
  //                                                         activity.name,
  //                                                         style:
  //                                                             const TextStyle(
  //                                                               color: Colors
  //                                                                   .white,
  //                                                               fontSize: 11,
  //                                                               fontWeight:
  //                                                                   FontWeight
  //                                                                       .bold,
  //                                                             ),
  //                                                       ),
  //                                                     ),
  //                                                     PopupMenuButton<String>(
  //                                                       icon: const Icon(
  //                                                         Icons.more_horiz,
  //                                                         size: 20,
  //                                                       ),
  //                                                       onSelected: null,
  //                                                       itemBuilder: (context) => [
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'view',
  //                                                           child: PopupItem(
  //                                                             title: 'View',
  //                                                             icon: Icon(
  //                                                               Icons
  //                                                                   .visibility_outlined,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                           onTap: () {
  //                                                             final destinationBuilder =
  //                                                                 activityRoutes[activity
  //                                                                     .name];
  //                                                             if (destinationBuilder !=
  //                                                                 null) {
  //                                                               final nextScreen =
  //                                                                   destinationBuilder(
  //                                                                     activity,
  //                                                                   );
  //                                                               Navigator.of(
  //                                                                 context,
  //                                                               ).push(
  //                                                                 MaterialPageRoute(
  //                                                                   builder: (_) =>
  //                                                                       nextScreen,
  //                                                                 ),
  //                                                               );
  //                                                             }
  //                                                           },
  //                                                         ),
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'edit',
  //                                                           child: PopupItem(
  //                                                             title: 'Edit',
  //                                                             icon: Icon(
  //                                                               Icons.edit,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'delete',
  //                                                           child: PopupItem(
  //                                                             title: 'Delete',
  //                                                             icon: Icon(
  //                                                               Icons.delete,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                       ],
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //
  //                                                 SizedBox(
  //                                                   height: 32,
  //                                                   child: Stack(
  //                                                     children: [
  //                                                       for (
  //                                                         int i = 0;
  //                                                         i < students.length &&
  //                                                             i < 4;
  //                                                         i++
  //                                                       )
  //                                                         Positioned(
  //                                                           left: i * 20,
  //                                                           child:
  //                                                               DocumentImageWidget(
  //                                                                 fileUuid: '',
  //                                                                 name:
  //                                                                     students[i],
  //                                                                 size: 28,
  //                                                                 fontSize: 10,
  //                                                               ),
  //                                                         ),
  //
  //                                                       // Extra count tooltip
  //                                                       if (students.length > 4)
  //                                                         Positioned(
  //                                                           left:
  //                                                               4 *
  //                                                               20, // after 4 avatars
  //                                                           child: Tooltip(
  //                                                             message: students
  //                                                                 .skip(4)
  //                                                                 .join(', '),
  //                                                             child: DocumentImageWidget(
  //                                                               fileUuid: '',
  //                                                               name:
  //                                                                   '+${students.length - 4}',
  //                                                               size: 28,
  //                                                               fontSize: 10,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                     ],
  //                                                   ),
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //
  //                                                 Text(
  //                                                   activity.description!,
  //
  //                                                   style: TextStyle(
  //                                                     color: AppColors
  //                                                         .primaryColor,
  //                                                     fontSize: 14,
  //                                                     fontWeight:
  //                                                         FontWeight.w600,
  //                                                   ),
  //                                                   maxLines: 1,
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //                                                 Text(
  //                                                   'Created By - ${activity.createdBy}',
  //
  //                                                   style: TextStyle(
  //                                                     color: AppColors
  //                                                         .primaryColor,
  //                                                     fontSize: 12,
  //                                                     fontWeight:
  //                                                         FontWeight.w500,
  //                                                   ),
  //                                                   maxLines: 1,
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _datePickerFilter({
    required DateTime? selectedStartDate,
    required DateTime? selectedEndDate,
    //required Function(String?) onDateRangeSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => CalendarDialog(
            isRangePicker: true,
            isTimePicker: false,
            initialDate: selectedStartDate,
            initialEndDate: selectedEndDate,
            whiteBgColor: true,
          ),
        );

        if (result != null) {
          setState(() {
            _selectedStartDate = result['startDate'] as DateTime?;
            if (result['endDate'] != null)
              _selectedEndDate = result['endDate'] as DateTime?;
          });
          _loadRangeFeed(refresh: true);
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
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedStartDate != null
                      ? '${DateFormat('MMM dd, yyyy').format(selectedStartDate)} - ${DateFormat('MMM dd, yyyy').format(selectedEndDate ?? selectedStartDate)}'
                      : 'Select Date',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: selectedStartDate == null
                        ? Colors.grey[600]
                        : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Flexible(
              //   child: Text(
              //     selectedEndDate != null
              //         ? DateFormat('MMM dd, yyyy').format(selectedEndDate)
              //         : 'Select Date',
              //     style: TextStyle(
              //       color: selectedEndDate == null
              //           ? AppColors.primaryColor.withOpacity(0.6)
              //           : AppColors.primaryColor,
              //       fontSize: 14,
              //       fontWeight: FontWeight.w500,
              //     ),
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
              // const SizedBox(width: 4),
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
      items: items,
      height: height ?? 40,
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

//
// class ActivityItem {
//   final String time;
//   final String name;
//   final String description;
//   final Color color;
//   final String photoUrl;
//   final List<String> studentList;
//   final String createdBy;
//
//   const ActivityItem({
//     required this.time,
//     required this.name,
//     required this.description,
//     required this.color,
//     required this.photoUrl,
//     required this.studentList,
//     required this.createdBy
//   });
// }
