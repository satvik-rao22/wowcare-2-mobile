import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/view/message_composition_bulk_messaging.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/selection_list_item.dart';
import 'package:wowcare/shared/common/widgets/messaging_filter_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/attendance_classroom_scope.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/safe_state_mixin.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../app/di/di.dart';
import '../../../classroom/views/filters/designation_display_utils.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../../shared/common/widgets/custom_search_bar.dart';
import '../../../students/cubit/student_cubit.dart';
import '../widgets/selection_shimmer.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class StaffOrStudentSelectionBulkMessaging extends StatefulWidget {
  const StaffOrStudentSelectionBulkMessaging({
    super.key,
    this.isStaffSelection = true,
    this.conversationType = 'ROOM_CHAT',
    this.restrictToDesignationCodes,
    this.hideFilters = false,
  });
  final bool showLoading = false;
  final bool isStaffSelection;
  final String conversationType;

  /// When set, only staff whose designation code is in this list are shown
  /// — used for the Parent/Guardian "Admin Chat" compose flow, where the
  /// only valid recipients are Admins/Directors, not the full staff roster.
  final List<String>? restrictToDesignationCodes;

  /// Hides the Classroom/Status/Designation/Tags filter UI entirely — paired
  /// with [restrictToDesignationCodes] so the Parent/Guardian Admin Chat
  /// compose screen shows a plain grid (search + select), not staff filters
  /// that don't make sense for that flow.
  final bool hideFilters;

  @override
  State<StaffOrStudentSelectionBulkMessaging> createState() =>
      _StaffOrStudentSelectionBulkMessagingState();
}

class _StaffOrStudentSelectionBulkMessagingState
    extends State<StaffOrStudentSelectionBulkMessaging>
    with SafeStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedClassrooms = [];

  // Default to Active-only (per spec); user can switch to Upcoming explicitly.
  String? _selectedStatus = 'Active';
  bool _selectAll = false;
  bool _isSelectingAll = false;
  List<String> _selectedDesignations = [];
  List<String> _selectedTags = [];

  /// The logged-in staff member's own code — excluded from the staff
  /// recipient list so a user can't start a conversation with themselves.
  String? _currentStaffCode;

  Future<void> _loadCurrentStaffCode() async {
    final storageService = serviceLocator<StorageService>();
    final code = (await storageService.getString(StorageKeys.staffCode) ?? '')
        .trim();
    if (!mounted || code.isEmpty) return;
    setState(() => _currentStaffCode = code);
  }

  // Safety cap on how many extra pages "Select All" will fetch before
  // selecting, so a very large filtered result can't trigger unbounded
  // network calls.
  static const int _maxSelectAllPages = 50;

  /// Pages in the remaining filtered set that haven't been loaded into the
  /// cubit yet (StaffCubit/StudentCubit only auto-load the first couple of
  /// pages), so "Select All" would otherwise silently only select what's
  /// already in memory.
  Future<void> _ensureAllMatchingPagesLoaded() async {
    if (widget.isStaffSelection) {
      final cubit = context.read<StaffCubit>();
      var pages = 0;
      while (cubit.state.hasMore && pages < _maxSelectAllPages) {
        await cubit.loadNextPage();
        pages++;
      }
      if (cubit.state.hasMore) {
        _showWarningMessage(
          'Showing first ${cubit.state.items.length} staff matching filters.',
        );
      }
    } else {
      final cubit = context.read<StudentCubit>();
      var pages = 0;
      while (cubit.state.hasMore && pages < _maxSelectAllPages) {
        await cubit.loadNextPage();
        pages++;
      }
      if (cubit.state.hasMore) {
        _showWarningMessage(
          'Showing first ${cubit.state.items.length} students matching filters.',
        );
      }
    }
  }

  final List<String> _statusOptions = ['Active', 'Upcoming'];

  List<String> get _classroomOptions => context
      .read<ClassroomCubit>()
      .state
      .classrooms
      .map((e) => e.name)
      .toList();

  List<Map<String, dynamic>> get staffList {
    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    final Map<String, String> classroomMap = {
      for (var c in classrooms) c.code: c.name,
    };
    final staffMembers = context
        .read<StaffCubit>()
        .state
        .items
        .where((s) => s.code != _currentStaffCode)
        .where(
          (s) =>
              widget.restrictToDesignationCodes == null ||
              widget.restrictToDesignationCodes!.contains(s.designation),
        );
    return staffMembers
        .map(
          (s) => {
            'code': s.code,
            'userCode': s.userCode,
            'name': '${s.name}',
            // `profileImage` is never populated by the data layer for
            // StaffMember (always null) — `profilePhotoAssetCode` is the
            // field that's actually set.
            'avatar': s.profilePhotoAssetCode ?? '',
            'dateTime': null,
            'message': '',
            'isSigned': false,
            'isFavorite': false,
            'unreadCount': 0,
            'classroom': classroomMap[s.primaryClassroomOrFirstAllowed] ?? '',
            'designation': s.designation,
            'status': s.status,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> get parentList {
    final students = context.read<StudentCubit>().state.items;
    return students
        // Show ALL students matching the filter — including those that already
        // have a conversation of this type. The create path is get-or-open
        // (ROOM_CHAT/ADMIN_CHAT are unique per school+student), so selecting one
        // reuses the existing conversation rather than duplicating it. Mirrors
        // the web New Message picker.
        .map(
          (s) => {
            'code': s.code,
            'name': '${s.firstName} ${s.lastName}',
            // Use the asset code (consistent with the rest of the avatar
            // resolution chain) rather than the separately-cached resolved
            // URL in `profileImage`.
            'avatar': s.profilePhotoAssetCode ?? '',
            'dateTime': null,
            'message': '',
            'isSigned': false,
            'isFavorite': false,
            'unreadCount': 0,
            'classroom': s.primaryClassroomName ?? '',
            'classroomCode': s.classroomCode,
            'status': s.status,
            'tags': s.tags,
            'hasGuardian': s.hasGuardian,
          },
        )
        .toList();
  }

  /// Backend designation codes (matches staff_filter_screen.dart /
  /// staff_messaging_tab.dart) used to turn the Designation filter's
  /// human-readable selections back into the API value.
  static const List<String> _designationCodes = [
    'OWNER',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
    'FLOATER',
    'KIOSK_USER',
  ];

  Map<String, String> get _designationLabelToCode => {
    for (final code in _designationCodes)
      formatDesignationForDisplay(code): code,
  };

  List<String> get _designationOptions =>
      _designationLabelToCode.keys.toList()..sort();
  List<String> _tagOptions = [];
  Map<String, String> _tagNameToCode = {};
  late final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase =
      serviceLocator<GetTagNamesForSchoolUseCase>();
  late final GetTagNameCodeMapForSchoolUseCase
  _getTagNameCodeMapForSchoolUseCase =
      serviceLocator<GetTagNameCodeMapForSchoolUseCase>();

  Future<void> _loadTags() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          await storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final names = await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      final nameToCode = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (!mounted) return;

      setState(() {
        _tagOptions = names;
        _tagNameToCode = nameToCode;
        _selectedTags.removeWhere((tag) => !_tagOptions.contains(tag));
      });
    } catch (_) {
      // Non-critical for filters; ignore errors.
    }
  }

  /// Pushes the current classroom/status/tag selections to [StudentCubit] as
  /// server-side filters and refreshes. Without this, the cubit only ever
  /// loads the first couple of unfiltered pages, so selecting a classroom
  /// whose students aren't in that initial page shows an empty list even
  /// though matching students exist on the server.
  Future<void> _applyStudentFiltersToCubit() async {
    if (widget.isStaffSelection) return;

    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    final nameToCode = {for (final c in classrooms) c.name: c.code};
    final classroomCodes = _selectedClassrooms
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final tagCodes = _selectedTags
        .map((name) => _tagNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    context.read<StudentCubit>().updateFilters(
      status: _selectedStatus,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      tagCodes: tagCodes.isEmpty ? null : tagCodes,
    );
    await context.read<StudentCubit>().refreshWithCacheReset();
  }

  /// Pushes the current classroom/status/designation selections to
  /// [StaffCubit] as server-side filters and refreshes — same reasoning as
  /// [_applyStudentFiltersToCubit], but for the Staff selection mode.
  Future<void> _applyStaffFiltersToCubit() async {
    if (!widget.isStaffSelection) return;

    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    final nameToCode = {for (final c in classrooms) c.name: c.code};
    final classCodes = _selectedClassrooms
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final designation = _selectedDesignations.isEmpty
        ? null
        : _designationLabelToCode[_selectedDesignations.first];

    context.read<StaffCubit>().updateFilters(
      status: _selectedStatus?.toUpperCase(),
      designation: designation,
      classCodes: classCodes,
    );
    await context.read<StaffCubit>().refreshWithCacheReset();
  }

  /// Dispatches to whichever cubit backs the currently-shown list.
  Future<void> _applyContactFiltersToCubit() async {
    if (widget.isStaffSelection) {
      await _applyStaffFiltersToCubit();
    } else {
      await _applyStudentFiltersToCubit();
    }
  }

  Set<String> _selectedStaffCodes = <String>{};
  Set<String> _selectedStudentCodes = <String>{};

  List<MapEntry<String, Map<String, dynamic>>> get _filteredList {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = widget.isStaffSelection
        ? List<Map<String, dynamic>>.from(staffList)
        : List<Map<String, dynamic>>.from(parentList);

    if (_selectedStatus != null) {
      filtered = filtered.where((person) {
        final status = (person['status'] as String?)?.toLowerCase();
        return status != null && _selectedStatus!.toLowerCase() == status;
      }).toList();
    }
    // Classroom isn't re-filtered here: `person['classroom']` for students
    // comes from `Student.primaryClassroomName`, which the data layer never
    // populates (always null/empty) — re-applying it client-side as a name
    // match against `_selectedClassrooms` silently emptied the whole grid
    // the moment any classroom (single or "select all") was selected, since
    // `''` never matches a real classroom name. StudentCubit/StaffCubit
    // already filter by classroom server-side via `_applyStudentFiltersToCubit`
    // / `_applyStaffFiltersToCubit`, so `parentList`/`staffList` are already
    // pre-filtered correctly by the time they reach here.
    // Designation isn't filtered here: `person['designation']` is the raw
    // backend code (e.g. "LEAD_TEACHER") while `_selectedDesignations` holds
    // display labels (e.g. "Lead Teacher"), so a direct match always misses.
    // StaffCubit already filters by designation server-side via
    // `_applyStaffFiltersToCubit`, so `staffList` is pre-filtered correctly.
    if (_selectedTags.isNotEmpty && !widget.isStaffSelection) {
      filtered = filtered.where((person) {
        final tags = List<String>.from(person['tags']);
        return tags.any((tag) => _selectedTags.contains(tag));
      }).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((person) {
        final name = (person['name'] as String?)?.toLowerCase() ?? '';
        final message = (person['message'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    return filtered.asMap().entries.map((entry) {
      return MapEntry(entry.key.toString(), entry.value);
    }).toList();
  }

  void _updateSelectAllState() {
    if (_filteredList.isEmpty) {
      _selectAll = false;
    } else if (widget.isStaffSelection) {
      _selectAll = _filteredList.every(
        (entry) => _selectedStaffCodes.contains(entry.value['code']),
      );
    } else {
      // Students with no guardian linked are disabled and can never be
      // selected — "Select All" only needs every SELECTABLE student picked
      // to count as fully checked, or it could never show as checked at
      // all whenever such a student is present in the filtered list.
      final selectable = _filteredList.where(
        (entry) => entry.value['hasGuardian'] as bool? ?? true,
      );
      _selectAll = selectable.isNotEmpty
          ? selectable.every(
              (entry) => _selectedStudentCodes.contains(entry.value['code']),
            )
          : false;
    }
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final classroomCubit = context.read<ClassroomCubit>();
        // Non-admin staff only see the classrooms they're allowed to
        // access when starting a new conversation; admins see all of them.
        // Awaited (unlike before) so the primary-classroom default below can
        // rely on the classroom list actually being loaded — [ClassroomCubit]
        // is shared app-wide, so if another screen already populated it this
        // call returns without emitting a new state, and the BlocListener
        // above would otherwise never fire to apply the default.
        await classroomCubit.loadActiveClassrooms(
          applyAttendanceStaffScope: true,
        );
        if (!mounted) return;
        unawaited(_applyDefaultClassroomSelectionIfNeeded());
        context.read<StudentCubit>().loadInitial();
        if (widget.isStaffSelection) {
          unawaited(
            context.read<StaffCubit>().loadInitial().then((_) {
              // The Admin/Director-only flow needs the full roster client-side
              // since StaffCubit's designation filter only supports one value
              // at a time — loadInitial() alone only fetches the first couple
              // of pages.
              if (widget.restrictToDesignationCodes != null) {
                return _ensureAllMatchingPagesLoaded();
              }
            }),
          );
          unawaited(_loadCurrentStaffCode());
        } else {
          unawaited(_loadTags());
        }
      }
    });
    _searchController.addListener(_applyFilters);
  }

  /// Resolves at most once per screen instance — set before the actual
  /// resolve call (not after it completes) so a second, near-simultaneous
  /// [ClassroomCubit] emission can't race in and kick off a duplicate
  /// resolve/apply while the first is still in flight.
  bool _defaultClassroomResolveStarted = false;

  /// Defaults the Classroom filter to the staff member's own primary
  /// classroom — same "pre-select the home classroom" pattern the
  /// attendance forms use (resolveStaffPrimaryClassroomCode), so this
  /// picker opens already scoped to the classroom the staff member is
  /// actually responsible for instead of the full school roster. Resolves
  /// to null (no default applied) for admin/parent personas or a staff
  /// member with no primary classroom set — same fail-open contract as
  /// attendance. [widget.hideFilters] hides the Classroom UI entirely
  /// (Parent/Guardian Admin Chat compose), so there's nothing to default
  /// there.
  Future<void> _applyDefaultClassroomSelectionIfNeeded() async {
    if (_defaultClassroomResolveStarted || widget.hideFilters) return;
    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    // Classroom list hasn't loaded yet — wait for a later emission so the
    // code→name lookup below has something to match against.
    if (classrooms.isEmpty) return;
    _defaultClassroomResolveStarted = true;

    final primaryCode = await resolveStaffPrimaryClassroomCode(
      storage: serviceLocator<StorageService>(),
    );
    if (!mounted || (primaryCode ?? '').trim().isEmpty) return;
    final primaryName = classrooms
        .where((c) => c.code.trim() == primaryCode!.trim())
        .map((c) => c.name)
        .firstOrNull;
    if (primaryName == null || primaryName.trim().isEmpty) return;

    setState(() {
      _selectedClassrooms = [primaryName];
      _updateSelectAllState();
    });
    unawaited(_applyContactFiltersToCubit());
  }

  void _applyFilters() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(hasBackButton: true),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: BlocListener<ClassroomCubit, ClassroomState>(
          listener: (context, state) {
            unawaited(_applyDefaultClassroomSelectionIfNeeded());
          },
          child: BlocBuilder<ClassroomCubit, ClassroomState>(
            builder: (context, classroomState) {
              return BlocBuilder<StaffCubit, StaffState>(
                builder: (context, staffState) {
                  return BlocBuilder<StudentCubit, StudentState>(
                    builder: (context, studentState) {
                      final bool isDataEmpty = widget.isStaffSelection
                          ? staffState.items.isEmpty
                          : studentState.items.isEmpty;

                      final bool isLoading =
                          classroomState.isLoading ||
                          (widget.isStaffSelection && staffState.isLoading) ||
                          (!widget.isStaffSelection && studentState.isLoading);

                      // Show full screen loader only if no cached data exists at all
                      // if (isLoading && isDataEmpty && classroomState.isLoading) {
                      //   return const Center(child: CircularProgressIndicator());
                      // }
                      if (isLoading && isDataEmpty) {
                        return SelectionShimmer(isTablet: responsive.isTablet);
                      }
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.buildScaffoldGradient(),
                              ),
                              child: Image.asset(
                                MediaRes.wowcareMobileBg,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.horizontalSpacing,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'New Message',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: responsive.titleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff573353),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: responsive.isTablet ? 32.0 : 20.0,
                              ),
                              Expanded(
                                child: Container(
                                  width: responsive.containerWidth,
                                  margin: EdgeInsets.only(
                                    left: responsive.horizontalSpacing,
                                    right: responsive.horizontalSpacing,
                                    bottom: 10,
                                  ),
                                  padding: EdgeInsets.all(
                                    responsive.isTablet ? 32.0 : 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(
                                        responsive.isTablet ? 30.0 : 20.0,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Text(
                                            widget.isStaffSelection
                                                ? 'Select Staff'
                                                : 'Select Students',
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xff573353),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomSearchBar(
                                              controller: _searchController,
                                              hintText: widget.isStaffSelection
                                                  ? 'Search Staff'
                                                  : 'Search Students',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 38,
                                            child: CustomClearAllChip(
                                              onTap: () {
                                                setState(() {
                                                  _selectedClassrooms = [];
                                                  _selectedStaffCodes.clear();
                                                  _selectedStudentCodes.clear();
                                                  _selectedTags = [];
                                                  _searchController.clear();
                                                  _selectedDesignations = [];
                                                  // Reset to the
                                                  // Active-only
                                                  // default, not
                                                  // "show everyone".
                                                  _selectedStatus = 'Active';
                                                  _updateSelectAllState();
                                                });
                                                unawaited(
                                                  _applyContactFiltersToCubit(),
                                                );
                                              },
                                              label: 'Clear All',
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!widget.hideFilters) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomMultiSelectDropdown(
                                                showSelectAll: true,
                                                hintText: 'Select Classroom',
                                                items: _classroomOptions,
                                                selectedItems:
                                                    _selectedClassrooms,
                                                gapHeight: 40,
                                                onChanged: (selectedItems) {
                                                  setState(() {
                                                    _selectedClassrooms =
                                                        selectedItems;
                                                    _updateSelectAllState();
                                                  });
                                                  unawaited(
                                                    _applyContactFiltersToCubit(),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (widget.isStaffSelection)
                                              Expanded(
                                                child: CustomMultiSelectDropdown(
                                                  showSelectAll: true,
                                                  hintText:
                                                      'Select Designation',
                                                  items: _designationOptions,
                                                  selectedItems:
                                                      _selectedDesignations,
                                                  gapHeight: 40,
                                                  onChanged: (selectedItems) {
                                                    setState(() {
                                                      _selectedDesignations =
                                                          selectedItems;
                                                      _updateSelectAllState();
                                                    });
                                                    unawaited(
                                                      _applyContactFiltersToCubit(),
                                                    );
                                                  },
                                                ),
                                              )
                                            else
                                              Expanded(
                                                child: CustomMultiSelectDropdown(
                                                  showSelectAll: true,
                                                  hintText: 'Select Tags',
                                                  items: _tagOptions,
                                                  selectedItems: _selectedTags,
                                                  gapHeight: 40,
                                                  onChanged: (selectedItems) {
                                                    setState(() {
                                                      _selectedTags =
                                                          selectedItems;
                                                      _updateSelectAllState();
                                                    });
                                                    unawaited(
                                                      _applyContactFiltersToCubit(),
                                                    );
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        MessagingFilterDropdown(
                                          hintText: 'Status',
                                          items: _statusOptions,
                                          selectedItem: _selectedStatus,
                                          onSelect: (v) {
                                            setState(() {
                                              _selectedStatus = v;
                                              _selectedStaffCodes.clear();
                                              _selectedStudentCodes.clear();
                                              _selectAll = false;
                                            });
                                            unawaited(
                                              _applyContactFiltersToCubit(),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      // Select All
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomCheckbox(
                                              label: 'Select All',
                                              value: _selectAll,
                                              borderColor: AppColors.themeColor,
                                              onChanged: _isSelectingAll
                                                  ? null
                                                  : (v) async {
                                                      final newVal = v ?? false;
                                                      if (newVal) {
                                                        setState(
                                                          () =>
                                                              _isSelectingAll =
                                                                  true,
                                                        );
                                                        await _ensureAllMatchingPagesLoaded();
                                                        if (!mounted) {
                                                          return;
                                                        }
                                                      }
                                                      setState(() {
                                                        _isSelectingAll = false;
                                                        _selectAll = newVal;
                                                        if (newVal) {
                                                          if (widget
                                                              .isStaffSelection) {
                                                            _selectedStaffCodes.addAll(
                                                              _filteredList.map(
                                                                (e) =>
                                                                    e.value['code']
                                                                        as String,
                                                              ),
                                                            );
                                                          } else {
                                                            // Skip students
                                                            // with no
                                                            // guardian linked
                                                            // — they're
                                                            // disabled/
                                                            // unselectable
                                                            // individually,
                                                            // so "Select All"
                                                            // must not select
                                                            // them either.
                                                            _selectedStudentCodes.addAll(
                                                              _filteredList
                                                                  .where(
                                                                    (e) =>
                                                                        e.value['hasGuardian']
                                                                            as bool? ??
                                                                        true,
                                                                  )
                                                                  .map(
                                                                    (e) =>
                                                                        e.value['code']
                                                                            as String,
                                                                  ),
                                                            );
                                                          }
                                                        } else {
                                                          if (widget
                                                              .isStaffSelection) {
                                                            _selectedStaffCodes
                                                                .clear();
                                                          } else {
                                                            _selectedStudentCodes
                                                                .clear();
                                                          }
                                                        }
                                                      });
                                                    },
                                            ),
                                            if (_isSelectingAll) ...[
                                              const SizedBox(width: 8),
                                              const PrimaryCircularLoader(
                                                size: 14,
                                                strokeWidth: 2,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Expanded(
                                        child: _filteredList.isEmpty
                                            ? Center(
                                                child: Text(
                                                  widget.isStaffSelection
                                                      ? 'No staff match the selected filters'
                                                      : 'No student match the selected filters',
                                                  style: AppTextStyles.body
                                                      .copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              )
                                            : GridView.builder(
                                                itemCount: _filteredList.length,
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount:
                                                          responsive.isTablet
                                                          ? 3
                                                          : 2,
                                                      crossAxisSpacing: 12,
                                                      mainAxisSpacing: 12,
                                                      mainAxisExtent: 72,
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final entry =
                                                      _filteredList[index];
                                                  final person = entry.value;

                                                  final bool isSelected =
                                                      widget.isStaffSelection
                                                      ? _selectedStaffCodes
                                                            .contains(
                                                              person['code'],
                                                            )
                                                      : _selectedStudentCodes
                                                            .contains(
                                                              person['code'],
                                                            );

                                                  // A student with no
                                                  // guardian linked can't be
                                                  // messaged (no one to
                                                  // receive it) — disable
                                                  // selecting them, matching
                                                  // web. Staff rows have no
                                                  // such concept.
                                                  final bool isEnabled =
                                                      widget.isStaffSelection ||
                                                      (person['hasGuardian']
                                                              as bool? ??
                                                          true);

                                                  return CommonSelectionItem(
                                                    key: ValueKey(
                                                      person['code'],
                                                    ),
                                                    name: person['name'],
                                                    avatarUuid:
                                                        person['avatar'] ?? '',
                                                    isSelected: isSelected,
                                                    isEnabled: isEnabled,
                                                    disabledReason: isEnabled
                                                        ? null
                                                        : 'No parent linked',
                                                    onSelectionChanged: (bool? selected) {
                                                      setState(() {
                                                        final code =
                                                            person['code'];
                                                        if (selected == true) {
                                                          (widget.isStaffSelection
                                                                  ? _selectedStaffCodes
                                                                  : _selectedStudentCodes)
                                                              .add(code);
                                                        } else {
                                                          (widget.isStaffSelection
                                                                  ? _selectedStaffCodes
                                                                  : _selectedStudentCodes)
                                                              .remove(code);
                                                        }
                                                        _updateSelectAllState();
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ), // GestureDetector
      bottomNavigationBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(1),
                child: Container(
                  //alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 8.0,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return AppColors.buildPrimaryGradient().createShader(
                          bounds,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  if (widget.isStaffSelection) {
                    if (_selectedStaffCodes.isNotEmpty) {
                      final selectedStaffMaps = staffList
                          .where((s) => _selectedStaffCodes.contains(s['code']))
                          .toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MessageCompositionBulkMessaging(
                            selectedRecipients: selectedStaffMaps,
                            isStaff: true,
                            conversationType: widget.conversationType,
                          ),
                        ),
                      );
                    } else {
                      _showWarningMessage('Select at least one staff.');
                    }
                  } else {
                    if (_selectedStudentCodes.isNotEmpty) {
                      final selectedStudentMaps = parentList
                          .where(
                            (s) => _selectedStudentCodes.contains(s['code']),
                          )
                          .toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MessageCompositionBulkMessaging(
                            selectedRecipients: selectedStudentMaps,
                            isStaff: false,
                            conversationType: widget.conversationType,
                          ),
                        ),
                      );
                    } else {
                      _showWarningMessage('Select at least one student.');
                    }
                  }
                },
                style: TextButton.styleFrom(overlayColor: Colors.transparent),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
