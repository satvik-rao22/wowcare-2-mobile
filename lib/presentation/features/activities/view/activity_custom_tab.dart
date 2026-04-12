import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

import '../../../../core/util/core_utils.dart';
import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../domain/features/activity/usecases/get_range_activity_feed_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../../../../shared/common/views/filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import '../../../../shared/utils/responsive_helper.dart';
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

class ActivityCustomTab extends StatefulWidget {
  const ActivityCustomTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.isNotParent = true,
  });

  final bool fromStudentProfile;
  final String? studentName;
  final bool isNotParent;

  static const String routeName = '/activityCustomTab';

  @override
  State<ActivityCustomTab> createState() => _ActivityCustomTabState();
}

class _ActivityCustomTabState extends State<ActivityCustomTab> {
  late bool isNotParent;

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
  final Map<String, String> _classroomCodeByName = {};
  final Map<String, String> _studentCodeByName = {};
  List<ActivitySetting> _classroomActivitySettings = [];
  List<String> _tagFilterOptions = [];
  bool _isFeedRequestInFlight = false;
  String? _lastFeedRequestKey;
  DateTime? _lastFeedCompletedAt;
  bool _lastFeedCompletedWithError = false;
  String? _lastResolvedClassroomCode;

  late final GetRangeActivityFeedUseCase _getRangeActivityFeedUseCase;
  late final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  late final GetClassroomActivitySettingsUseCase
      _getClassroomActivitySettingsUseCase;
  late final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  late final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  late final DeleteActivityUseCase _deleteActivityUseCase;
  late final StorageService _storageService;
  late final CacheManager _cacheManager;

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
    _deleteActivityUseCase = serviceLocator<DeleteActivityUseCase>();
    _storageService = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storageService);

    _updateAvailableStudents();
    isNotParent = widget.isNotParent;
    //_selectedStudent = _allStudents[0];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapRangeFeed();
    });
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

  List<String> _activityTypeNamesForFilter() {
    final out = _classroomActivitySettings
        .map((s) => s.activityTypeName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  List<FilerSection> _activityFeedFilterSections() {
    return [
      FilerSection(
        label: 'Tags',
        hintText: 'Select tags',
        items: List<String>.from(_tagFilterOptions),
        initialSelected: _filterTags,
        isMultiSelectDropDown: false,
      ),
      FilerSection(
        label: 'Activity Type',
        hintText: 'Select Activity',
        items: _activityTypeNamesForFilter(),
        initialSelected: _filterActivityTypes,
        isMultiSelectDropDown: false,
      ),
    ];
  }

  Future<void> _loadTagFilterOptions() async {
    final school = _schoolCode;
    if (school == null || school.isEmpty) return;
    try {
      final map = await _getTagNameCodeMapForSchoolUseCase(schoolCode: school);
      if (!mounted) return;
      setState(() {
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

  String? _activityTypeCodeForApiFilter() {
    final label = _selectedActivityType;
    if (label == null || label.trim().isEmpty) return null;
    final want = label.toLowerCase().trim();
    for (final s in _classroomActivitySettings) {
      final name = s.activityTypeName.toLowerCase().trim();
      if (name == want) return s.activityTypeCode;
      if (name.contains(want) || want.contains(name)) return s.activityTypeCode;
    }
    return null;
  }

  Future<void> _bootstrapRangeFeed() async {
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

    await _loadTagFilterOptions();

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

      await _loadRangeFeed();
    } catch (e) {
      if (!mounted) return;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      setState(() {
        _feedError = msg;
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
      await _loadRangeFeed(refresh: true);
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
    _isFeedRequestInFlight = true;
    _lastFeedRequestKey = requestKey;

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
              final cachedStudents = await _cacheManager.loadCache(studentsCacheKey);
              if (cachedStudents != null && cachedStudents['students'] is List) {
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
            ..addEntries(students.map((s) => MapEntry(s.fullName, s.studentCode)));
          classroomStudents[classroomName] = students.map((s) => s.fullName).toList();
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
            final cachedSettings = await _cacheManager.loadCache(settingsCacheKey);
            if (cachedSettings != null && cachedSettings['settings'] is List) {
              final list = (cachedSettings['settings'] as List)
                  .whereType<Map>()
                  .map(
                    (e) => ActivitySetting(
                      activityTypeCode: (e['activityTypeCode'] ?? '').toString(),
                      activityTypeName: (e['activityTypeName'] ?? '').toString(),
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
          _classroomActivitySettings = await _getClassroomActivitySettingsUseCase(
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
      }

      final page = await _getRangeActivityFeedUseCase(
        classroomCode: classroomCode,
        startDate: _dateQueryParam(start),
        endDate: _dateQueryParam(end),
        studentCode: studentCodeForRequest,
        activityTypeCode: typeCode,
        page: 0,
        size: 200,
      );

      var items = page.content
          .map((row) => activityItemFromFeedRow(row))
          .toList();

      // Do not apply additional client-side student filtering here.
      // Server-side `studentCode` filter is already applied in API request.

      if (!mounted) {
        _isFeedRequestInFlight = false;
        return;
      }
      setState(() {
        activities
          ..clear()
          ..addAll(items);
        _feedError = null;
      });
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = false;
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
      _isFeedRequestInFlight = false;
      _lastFeedCompletedAt = DateTime.now();
      _lastFeedCompletedWithError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (context, orientation){
          if(orientation == Orientation.landscape){
            return CustomScrollView(
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
                          height: 65,
                          child: AbsorbPointer(
                            child: _buildCustomDropdown(
                              'Select Student',
                              [?widget.studentName],
                              widget.studentName,
                                  (v) => setState(() {
                                _selectedStudent = v;
                              }),
                              height: 65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 65,
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
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterScreen(
                                        sections: _activityFeedFilterSections(),
                                        onApply: (filters) {
                                          setState(() {
                                            _filterTags = List<String>.from(
                                              filters['Tags'] ?? const [],
                                            );
                                            _filterActivityTypes =
                                                List<String>.from(
                                              filters['Activity Type'] ??
                                                  const [],
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result is Map) {
                                    // TODO: apply filters to list
                                    setState(() {});
                                  }
                                },
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
                                  _selectdClassroom = _classroomOptions[0];
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                              },
                              label: 'Clear All',
                            ),
                          ],
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _datePickerFilter(
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _buildCustomDropdown(
                              'Activity Type',
                              activityType,
                              _selectedActivityType,
                                  (v) {
                                setState(() {
                                  _selectedActivityType = v;
                                });
                                _loadRangeFeed(refresh: true);
                              },
                              height: 65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),),
                SliverToBoxAdapter(child: SizedBox(height: 12,),),
                if(activities.isEmpty)
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

                                                          AppText.body(
                                                            activityFeedCardBodyLine(activity),
                                                            style: AppTextStyles.body.copyWith(
                                                              color: AppColors.primaryColor,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                            maxLines: activityFeedCardBodyMaxLines(activity),
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
                          childCount: activities.length
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 10))
              ],
            );
            // ignore: dead_code
            return SingleChildScrollView(
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
                            height: 65,
                            child: AbsorbPointer(
                              child: _buildCustomDropdown(
                                'Select Student',
                                [?widget.studentName],
                                widget.studentName,
                                    (v) => setState(() {
                                  _selectedStudent = v;
                                }),
                                height: 65,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 65,
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
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FilterScreen(
                                          sections: _activityFeedFilterSections(),
                                          onApply: (filters) {
                                            setState(() {
                                              _filterTags = List<String>.from(
                                                filters['Tags'] ?? const [],
                                              );
                                              _filterActivityTypes =
                                                  List<String>.from(
                                                filters['Activity Type'] ??
                                                    const [],
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (result is Map) {
                                      // TODO: apply filters to list
                                      setState(() {});
                                    }
                                  },
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
                                    _selectdClassroom = _classroomOptions[0];
                                    _selectedStudent = null;
                                    _filterActivityTypes.clear();
                                    _filterTags.clear();
                                  });
                                },
                                label: 'Clear All',
                              ),
                            ],
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 65,
                              child: _datePickerFilter(
                                selectedStartDate: _selectedStartDate,
                                selectedEndDate: _selectedEndDate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 65,
                              child: _buildCustomDropdown(
                                'Activity Type',
                                activityType,
                                _selectedActivityType,
                                  (v) {
                                setState(() {
                                  _selectedActivityType = v;
                                });
                                _loadRangeFeed(refresh: true);
                              },
                                height: 65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (activities.length == 0)
                    Padding(
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

                  if (activities.length != 0)
                    Padding(
                      padding: ResponsiveSizing.activityFeedListPadding(context),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: activities.length,
                            itemBuilder: (context, index) {
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
                                                                  color: activityColor,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  activity.name,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow.ellipsis,
                                                                  style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: 11,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold,
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
                                                                      await _loadRangeFeed(refresh: true);
                                                                    }
                                                                  }
                                                                },
                                                              ),
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
                                                              ),
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

                                                      AppText.body(
                                                        activityFeedCardBodyLine(activity),
                                                        style: AppTextStyles.body.copyWith(
                                                          color: AppColors.primaryColor,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: activityFeedCardBodyMaxLines(activity),
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
                        ],
                      ),
                    ),
                ],
              ),
            );
          } else {
            return Column(
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
                          height: 65,
                          child: AbsorbPointer(
                            child: _buildCustomDropdown(
                              'Select Student',
                              [?widget.studentName],
                              widget.studentName,
                                  (v) => setState(() {
                                _selectedStudent = v;
                              }),
                              height: 65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 65,
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
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterScreen(
                                        sections: _activityFeedFilterSections(),
                                        onApply: (filters) {
                                          setState(() {
                                            _filterTags = List<String>.from(
                                              filters['Tags'] ?? const [],
                                            );
                                            _filterActivityTypes =
                                                List<String>.from(
                                              filters['Activity Type'] ??
                                                  const [],
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result is Map) {
                                    // TODO: apply filters to list
                                    setState(() {});
                                  }
                                },
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
                                  _selectdClassroom = _classroomOptions[0];
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                              },
                              label: 'Clear All',
                            ),
                          ],
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _datePickerFilter(
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _buildCustomDropdown(
                              'Activity Type',
                              activityType,
                              _selectedActivityType,
                                  (v) {
                                setState(() {
                                  _selectedActivityType = v;
                                });
                                _loadRangeFeed(refresh: true);
                              },
                              height: 65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (activities.length == 0)
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
                          child: Text(
                            _feedError ?? 'No Activities found',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                              padding: EdgeInsets.zero,
                              itemCount: activities.length,
                              itemBuilder: (context, index) {
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
                                                                    ),
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
                                                              activity.description!,

                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                FontWeight.w600,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                              TextOverflow.ellipsis,
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
  //                       height: 65,
  //                       child: AbsorbPointer(
  //                         child: _buildCustomDropdown(
  //                           'Select Student',
  //                           [?widget.studentName],
  //                           widget.studentName,
  //                           (v) => setState(() {
  //                             _selectedStudent = v;
  //                           }),
  //                           height: 65,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 8),
  //                     SizedBox(
  //                       height: 65,
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
  //                         height: 65,
  //                         child: _datePickerFilter(
  //                           selectedStartDate: _selectedStartDate,
  //                           selectedEndDate: _selectedEndDate,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 65,
  //                         child: _buildCustomDropdown(
  //                           'Activity Type',
  //                           activityType,
  //                           _selectedActivityType,
  //                           (v) => setState(() {
  //                             _selectedActivityType = v;
  //                           }),
  //                           height: 65,
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
          //color: const Color(0xFFF8F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedStartDate != null
                      ? '${DateFormat('MMM dd, yyyy').format(selectedStartDate)} - ${DateFormat('MMM dd, yyyy').format(selectedEndDate ?? selectedStartDate)}'
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedStartDate == null
                        ? AppColors.primaryColor.withOpacity(0.6)
                        : AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      ),
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
