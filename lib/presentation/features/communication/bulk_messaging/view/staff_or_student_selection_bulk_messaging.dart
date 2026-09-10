import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/presentation/features/communication/model/messaging_recipient.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/cubit/recipient_selection_cubit.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/cubit/recipient_selection_state.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/selection_list_item.dart';
import 'package:wowcare/shared/common/widgets/messaging_filter_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/safe_state_mixin.dart';
import 'package:wowcare/app/di/messaging_resolvers.dart';
import 'package:wowcare/presentation/features/classroom/view/filters/designation_display_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/widgets/selection_shimmer.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

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

  /// Selection + filter state (Mandate 2/5, Bucket A → cubit). The "select all"
  /// checkbox value is derived from these selections against the filtered
  /// roster (see [_computeSelectAll]), not stored.
  final RecipientSelectionCubit _selection = RecipientSelectionCubit();

  Future<void> _loadCurrentStaffCode() async {
    final code = (await resolveStoredStaffCode() ?? '').trim();
    if (!mounted || code.isEmpty) return;
    _selection.setCurrentStaffCode(code);
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
          AppStrings.showingFirstStaff(cubit.state.items.length),
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
          AppStrings.showingFirstStudents(cubit.state.items.length),
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

  List<MessagingRecipient> get staffList {
    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    final Map<String, String> classroomMap = {
      for (var c in classrooms) c.code: c.name,
    };
    final staffMembers = context
        .read<StaffCubit>()
        .state
        .items
        .where((s) => s.code != _selection.state.currentStaffCode)
        .where(
          (s) =>
              widget.restrictToDesignationCodes == null ||
              widget.restrictToDesignationCodes!.contains(s.designation),
        );
    return staffMembers
        .map(
          (s) => MessagingRecipient(
            code: s.code,
            userCode: s.userCode,
            name: '${s.name}',
            // `profileImage` is never populated by the data layer for
            // StaffMember (always null) — `profilePhotoAssetCode` is the
            // field that's actually set.
            avatar: s.profilePhotoAssetCode ?? '',
            classroom: classroomMap[s.primaryClassroomOrFirstAllowed] ?? '',
            designation: s.designation,
            status: s.status,
          ),
        )
        .toList();
  }

  List<MessagingRecipient> get parentList {
    final students = context.read<StudentCubit>().state.items;
    return students
        // Show ALL students matching the filter — including those that already
        // have a conversation of this type. The create path is get-or-open
        // (ROOM_CHAT/ADMIN_CHAT are unique per school+student), so selecting one
        // reuses the existing conversation rather than duplicating it. Mirrors
        // the web New Message picker.
        .map(
          (s) => MessagingRecipient(
            code: s.code,
            name: '${s.firstName} ${s.lastName}',
            // Use the asset code (consistent with the rest of the avatar
            // resolution chain) rather than the separately-cached resolved
            // URL in `profileImage`.
            avatar: s.profilePhotoAssetCode ?? '',
            classroom: s.primaryClassroomName ?? '',
            classroomCode: s.classroomCode,
            status: s.status,
            tags: s.tags,
            hasGuardian: s.hasGuardian,
          ),
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
  late final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase =
      resolveGetTagNamesForSchoolUseCase();
  late final GetTagNameCodeMapForSchoolUseCase
  _getTagNameCodeMapForSchoolUseCase =
      resolveGetTagNameCodeMapForSchoolUseCase();

  Future<void> _loadTags() async {
    try {
      final schoolCode = await resolveStoredSchoolCode() ?? '';
      if (schoolCode.isEmpty) return;

      final names = await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      final nameToCode = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (!mounted) return;

      _selection.setTagData(names, nameToCode);
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
    final classroomCodes = _selection.state.selectedClassrooms
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final tagCodes = _selection.state.selectedTags
        .map((name) => _selection.state.tagNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    context.read<StudentCubit>().updateFilters(
      status: _selection.state.selectedStatus,
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
    final classCodes = _selection.state.selectedClassrooms
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final designation = _selection.state.selectedDesignations.isEmpty
        ? null
        : _designationLabelToCode[_selection.state.selectedDesignations.first];

    context.read<StaffCubit>().updateFilters(
      status: _selection.state.selectedStatus?.toUpperCase(),
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

  List<MapEntry<String, MessagingRecipient>> get _filteredList {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = widget.isStaffSelection
        ? List<MessagingRecipient>.from(staffList)
        : List<MessagingRecipient>.from(parentList);

    if (_selection.state.selectedStatus != null) {
      filtered = filtered.where((person) {
        final status = person.status.toLowerCase();
        return _selection.state.selectedStatus!.toLowerCase() == status;
      }).toList();
    }
    // Classroom isn't re-filtered here: `person['classroom']` for students
    // comes from `Student.primaryClassroomName`, which the data layer never
    // populates (always null/empty) — re-applying it client-side as a name
    // match against `_selection.state.selectedClassrooms` silently emptied the whole grid
    // the moment any classroom (single or "select all") was selected, since
    // `''` never matches a real classroom name. StudentCubit/StaffCubit
    // already filter by classroom server-side via `_applyStudentFiltersToCubit`
    // / `_applyStaffFiltersToCubit`, so `parentList`/`staffList` are already
    // pre-filtered correctly by the time they reach here.
    // Designation isn't filtered here: `person['designation']` is the raw
    // backend code (e.g. "LEAD_TEACHER") while `_selection.state.selectedDesignations` holds
    // display labels (e.g. "Lead Teacher"), so a direct match always misses.
    // StaffCubit already filters by designation server-side via
    // `_applyStaffFiltersToCubit`, so `staffList` is pre-filtered correctly.
    if (_selection.state.selectedTags.isNotEmpty && !widget.isStaffSelection) {
      filtered = filtered.where((person) {
        final tags = person.tags;
        return tags.any((tag) => _selection.state.selectedTags.contains(tag));
      }).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((person) {
        final name = person.name.toLowerCase();
        final message = person.message.toLowerCase();
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    return filtered.asMap().entries.map((entry) {
      return MapEntry(entry.key.toString(), entry.value);
    }).toList();
  }

  /// The "Select All" checkbox value, derived from the current [selection]
  /// against the filtered roster (was the stored `_selectAll` +
  /// `_updateSelectAllState`).
  bool _computeSelectAll(RecipientSelectionState selection) {
    final list = _filteredList;
    if (list.isEmpty) return false;
    if (widget.isStaffSelection) {
      return list.every(
        (entry) => selection.selectedStaffCodes.contains(entry.value.code),
      );
    }
    // Students with no guardian linked are disabled and can never be
    // selected — "Select All" only needs every SELECTABLE student picked to
    // count as fully checked, or it could never show as checked at all
    // whenever such a student is present in the filtered list.
    final selectable = list.where((entry) => entry.value.hasGuardian);
    return selectable.isNotEmpty &&
        selectable.every(
          (entry) => selection.selectedStudentCodes.contains(entry.value.code),
        );
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

    final primaryCode = await resolveStaffPrimaryClassroom();
    if (!mounted || (primaryCode ?? '').trim().isEmpty) return;
    final primaryName = classrooms
        .where((c) => c.code.trim() == primaryCode!.trim())
        .map((c) => c.name)
        .firstOrNull;
    if (primaryName == null || primaryName.trim().isEmpty) return;

    _selection.setClassrooms([primaryName]);
    unawaited(_applyContactFiltersToCubit());
  }

  void _applyFilters() {
    // The list rebuilds via the search-controller ListenableBuilder in build();
    // this listener no longer needs to force a setState.
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    unawaited(_selection.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackgroundColor,
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
                      // Rebuild on the selection cubit + search text alongside
                      // the roster cubits above.
                      return BlocBuilder<
                        RecipientSelectionCubit,
                        RecipientSelectionState
                      >(
                        bloc: _selection,
                        builder: (context, _) => ListenableBuilder(
                          listenable: _searchController,
                          builder: (context, __) {
                            final bool isDataEmpty = widget.isStaffSelection
                                ? staffState.items.isEmpty
                                : studentState.items.isEmpty;

                            final bool isLoading =
                                classroomState.isLoading ||
                                (widget.isStaffSelection &&
                                    staffState.isLoading) ||
                                (!widget.isStaffSelection &&
                                    studentState.isLoading);

                            // Show full screen loader only if no cached data exists at all
                            if (isLoading && isDataEmpty) {
                              return SelectionShimmer(
                                isTablet: responsive.isTablet,
                              );
                            }
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    color: AppColors.pageBackgroundColor,
                                  ),
                                ),
                                Column(
                                  children: [
                                    const SizedBox(height: AppSizes.md),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            responsive.horizontalSpacing,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          AppStrings.newMessage,
                                          style: AppTextStyles.size14.copyWith(
                                            fontSize: responsive.titleFontSize,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                AppColors.messagingHeadingPlum,
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
                                          bottom: AppSizes.xsPlus,
                                        ),
                                        padding: EdgeInsets.all(
                                          responsive.isTablet ? 32.0 : 16.0,
                                        ),
                                        decoration: AppSurfaces.card(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(
                                              responsive.isTablet ? 30.0 : 20.0,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: AppSizes.xsPlus,
                                                ),
                                                child: Text(
                                                  widget.isStaffSelection
                                                      ? AppStrings.selectStaff
                                                      : AppStrings
                                                            .selectStudents,
                                                  style: AppTextStyles.size14
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .messagingHeadingPlum,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSizes.xsPlus,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CustomSearchBar(
                                                    controller:
                                                        _searchController,
                                                    hintText:
                                                        widget.isStaffSelection
                                                        ? AppStrings.searchStaff
                                                        : AppStrings
                                                              .searchStudents,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSizes.xs,
                                                ),
                                                SizedBox(
                                                  height: 38,
                                                  child: CustomClearAllChip(
                                                    onTap: () {
                                                      // clearAll resets classroom/
                                                      // designation/tag filters + the
                                                      // Active-only default status,
                                                      // and drops every pick.
                                                      _selection.clearAll();
                                                      _searchController.clear();
                                                      unawaited(
                                                        _applyContactFiltersToCubit(),
                                                      );
                                                    },
                                                    label: AppStrings.clearAll,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!widget.hideFilters) ...[
                                              const SizedBox(
                                                height: AppSizes.xsPlus,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomMultiSelectDropdown(
                                                      showSelectAll: true,
                                                      hintText: AppStrings
                                                          .selectClassroom,
                                                      items: _classroomOptions,
                                                      selectedItems: _selection
                                                          .state
                                                          .selectedClassrooms,
                                                      gapHeight: 40,
                                                      onChanged: (selectedItems) {
                                                        _selection
                                                            .setClassrooms(
                                                              selectedItems,
                                                            );
                                                        unawaited(
                                                          _applyContactFiltersToCubit(),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSizes.xs,
                                                  ),
                                                  if (widget.isStaffSelection)
                                                    Expanded(
                                                      child: CustomMultiSelectDropdown(
                                                        showSelectAll: true,
                                                        hintText: AppStrings
                                                            .selectDesignation,
                                                        items:
                                                            _designationOptions,
                                                        selectedItems: _selection
                                                            .state
                                                            .selectedDesignations,
                                                        gapHeight: 40,
                                                        onChanged: (selectedItems) {
                                                          _selection
                                                              .setDesignations(
                                                                selectedItems,
                                                              );
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
                                                        hintText: AppStrings
                                                            .selectTags,
                                                        items: _selection
                                                            .state
                                                            .tagOptions,
                                                        selectedItems:
                                                            _selection
                                                                .state
                                                                .selectedTags,
                                                        gapHeight: 40,
                                                        onChanged: (selectedItems) {
                                                          _selection.setTags(
                                                            selectedItems,
                                                          );
                                                          unawaited(
                                                            _applyContactFiltersToCubit(),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: AppSizes.sm,
                                              ),
                                              MessagingFilterDropdown(
                                                hintText: AppStrings.status,
                                                items: _statusOptions,
                                                selectedItem: _selection
                                                    .state
                                                    .selectedStatus,
                                                onSelect: (v) {
                                                  // Clears picks (roster changes).
                                                  _selection.setStatus(v);
                                                  unawaited(
                                                    _applyContactFiltersToCubit(),
                                                  );
                                                },
                                              ),
                                              const SizedBox(
                                                height: AppSizes.sm,
                                              ),
                                            ],
                                            // Select All
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CustomCheckbox(
                                                    label: AppStrings.selectAll,
                                                    value: _computeSelectAll(
                                                      _selection.state,
                                                    ),
                                                    borderColor:
                                                        AppColors.themeColor,
                                                    onChanged:
                                                        _selection
                                                            .state
                                                            .isSelectingAll
                                                        ? null
                                                        : (v) async {
                                                            final newVal =
                                                                v ?? false;
                                                            if (newVal) {
                                                              _selection
                                                                  .setSelectingAll(
                                                                    true,
                                                                  );
                                                              await _ensureAllMatchingPagesLoaded();
                                                              if (!mounted)
                                                                return;
                                                            }
                                                            if (newVal) {
                                                              if (widget
                                                                  .isStaffSelection) {
                                                                _selection.setStaffSelection({
                                                                  ..._selection
                                                                      .state
                                                                      .selectedStaffCodes,
                                                                  ..._filteredList
                                                                      .map(
                                                                        (e) => e
                                                                            .value
                                                                            .code,
                                                                      ),
                                                                });
                                                              } else {
                                                                // Skip students with
                                                                // no guardian linked —
                                                                // disabled/unselectable
                                                                // individually, so
                                                                // "Select All" must
                                                                // not select them.
                                                                _selection.setStudentSelection({
                                                                  ..._selection
                                                                      .state
                                                                      .selectedStudentCodes,
                                                                  ..._filteredList
                                                                      .where(
                                                                        (e) => e
                                                                            .value
                                                                            .hasGuardian,
                                                                      )
                                                                      .map(
                                                                        (e) => e
                                                                            .value
                                                                            .code,
                                                                      ),
                                                                });
                                                              }
                                                            } else {
                                                              if (widget
                                                                  .isStaffSelection) {
                                                                _selection
                                                                    .setStaffSelection(
                                                                      const {},
                                                                    );
                                                              } else {
                                                                _selection
                                                                    .setStudentSelection(
                                                                      const {},
                                                                    );
                                                              }
                                                            }
                                                            _selection
                                                                .setSelectingAll(
                                                                  false,
                                                                );
                                                          },
                                                  ),
                                                  if (_selection
                                                      .state
                                                      .isSelectingAll) ...[
                                                    const SizedBox(
                                                      width: AppSizes.xs,
                                                    ),
                                                    const PrimaryCircularLoader(
                                                      size: 14,
                                                      strokeWidth: 2,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: AppSizes.lg),
                                            Expanded(
                                              child: _filteredList.isEmpty
                                                  ? Center(
                                                      child: Text(
                                                        widget.isStaffSelection
                                                            ? AppStrings
                                                                  .noStaffMatchFilters
                                                            : AppStrings
                                                                  .noStudentMatchFilters,
                                                        style: AppTextStyles
                                                            .size14
                                                            .copyWith(
                                                              color: AppColors
                                                                  .messagingTextMeta,
                                                            ),
                                                      ),
                                                    )
                                                  : GridView.builder(
                                                      itemCount:
                                                          _filteredList.length,
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                            crossAxisCount:
                                                                responsive
                                                                    .isTablet
                                                                ? 3
                                                                : 2,
                                                            crossAxisSpacing:
                                                                12,
                                                            mainAxisSpacing: 12,
                                                            mainAxisExtent: 72,
                                                          ),
                                                      itemBuilder: (context, index) {
                                                        final entry =
                                                            _filteredList[index];
                                                        final person =
                                                            entry.value;

                                                        final bool isSelected =
                                                            widget
                                                                .isStaffSelection
                                                            ? _selection
                                                                  .state
                                                                  .selectedStaffCodes
                                                                  .contains(
                                                                    person.code,
                                                                  )
                                                            : _selection
                                                                  .state
                                                                  .selectedStudentCodes
                                                                  .contains(
                                                                    person.code,
                                                                  );

                                                        // A student with no
                                                        // guardian linked can't be
                                                        // messaged (no one to
                                                        // receive it) — disable
                                                        // selecting them, matching
                                                        // web. Staff rows have no
                                                        // such concept.
                                                        final bool isEnabled =
                                                            widget
                                                                .isStaffSelection ||
                                                            person.hasGuardian;

                                                        return CommonSelectionItem(
                                                          key: ValueKey(
                                                            person.code,
                                                          ),
                                                          name: person.name,
                                                          avatarUuid:
                                                              person.avatar,
                                                          isSelected:
                                                              isSelected,
                                                          isEnabled: isEnabled,
                                                          disabledReason:
                                                              isEnabled
                                                              ? null
                                                              : AppStrings
                                                                    .noParentLinked,
                                                          onSelectionChanged:
                                                              (bool? selected) {
                                                                final code =
                                                                    person.code;
                                                                final on =
                                                                    selected ==
                                                                    true;
                                                                if (widget
                                                                    .isStaffSelection) {
                                                                  _selection
                                                                      .toggleStaff(
                                                                        code,
                                                                        on,
                                                                      );
                                                                } else {
                                                                  _selection
                                                                      .toggleStudent(
                                                                        code,
                                                                        on,
                                                                      );
                                                                }
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
                        ),
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: AppSizes.md,
        right: AppSizes.md,
        top: AppSizes.md,
      ),
      decoration: AppSurfaces.card(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: SkeuKeyBox(
              variant: KeyVariant.secondary,
              radius: responsive.isTablet ? 16.0 : 8.0,
              height: responsive.buttonHeight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  overlayColor: AppColors.transparentColor,
                ),
                child: Text(
                  AppStrings.cancel,
                  style: AppTextStyles.size14.copyWith(
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppSurfaces.keyInk(KeyVariant.secondary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.xsPlus),
          Expanded(
            child: SkeuKeyBox(
              variant: KeyVariant.primary,
              radius: responsive.isTablet ? 16.0 : 8.0,
              height: responsive.buttonHeight,
              child: TextButton(
                onPressed: () {
                  if (widget.isStaffSelection) {
                    if (_selection.state.selectedStaffCodes.isNotEmpty) {
                      final selectedStaffMaps = staffList
                          .where(
                            (s) => _selection.state.selectedStaffCodes.contains(
                              s.code,
                            ),
                          )
                          .toList();
                      context.push(
                        CommunicationRoutes.bulkCompose,
                        extra: MessageCompositionArgs(
                          selectedRecipients: selectedStaffMaps,
                          isStaff: true,
                          conversationType: widget.conversationType,
                        ),
                      );
                    } else {
                      _showWarningMessage(AppStrings.selectAtLeastOneStaff);
                    }
                  } else {
                    if (_selection.state.selectedStudentCodes.isNotEmpty) {
                      final selectedStudentMaps = parentList
                          .where(
                            (s) => _selection.state.selectedStudentCodes
                                .contains(s.code),
                          )
                          .toList();
                      context.push(
                        CommunicationRoutes.bulkCompose,
                        extra: MessageCompositionArgs(
                          selectedRecipients: selectedStudentMaps,
                          isStaff: false,
                          conversationType: widget.conversationType,
                        ),
                      );
                    } else {
                      _showWarningMessage(AppStrings.selectAtLeastOneStudent);
                    }
                  }
                },
                style: TextButton.styleFrom(
                  overlayColor: AppColors.transparentColor,
                ),
                child: Text(
                  AppStrings.next,
                  style: AppTextStyles.size14.copyWith(
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.messagingOnAccent,
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
