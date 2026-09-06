import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// UI-only: use wowcare widgets and theme; backend/bloc imports removed
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/staff_classroom/entities/staff_classroom_item.dart';
import 'package:wowcare/domain/features/staff_classroom/usecases/assign_staff_to_classroom_usecase.dart';
import 'package:wowcare/domain/features/staff_classroom/repositories/staff_classroom_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/presentation/features/classroom/views/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/classroom/forms/widgets/assign_classroom_form_widgets.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // UI-only
// import 'package:wowcare/core/extentions/context_extentions.dart'; // UI-only
// import 'package:wowcare/core/services/injection_container.dart'; // UI-only
// import 'package:wowcare/core/util/color_utils.dart'; // UI-only
// import 'package:wowcare/core/util/core_utils.dart'; // UI-only
// import 'package:wowcare/core/util/string_utils.dart'; // UI-only
// import 'package:wowcare/core/util/typedefs.dart'; // UI-only
// import 'package:wowcare/features/...'; // UI-only
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

class Staff {
  final int id;
  final String code;
  final String name;
  final String designation;
  final String? profileImageUrl;
  final String? profilePhotoAssetCode;
  const Staff({
    required this.id,
    required this.code,
    required this.name,
    required this.designation,
    this.profileImageUrl,
    this.profilePhotoAssetCode,
  });
}

class AssignStaffToClassroomForm extends StatefulWidget {
  const AssignStaffToClassroomForm({
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStaffsAssigned,
    super.key,
  });

  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStaffsAssigned;

  @override
  State<AssignStaffToClassroomForm> createState() =>
      _AssignStaffToClassroomFormState();
}

class _AssignStaffToClassroomFormState
    extends State<AssignStaffToClassroomForm> {
  /// Backend designation codes (API filter values) — same fixed set as
  /// [StaffFilterScreen], not derived from whichever staff happen to be
  /// loaded, so every designation is always selectable regardless of who's
  /// currently in the roster.
  static const List<String> _designationCodes = [
    'OWNER',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
    'FLOATER',
  ];

  Map<String, String> get _labelToDesignationCode => {
    for (final code in _designationCodes)
      formatDesignationForDisplay(code): code,
  };

  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';

  /// Selected designation display labels (dropdown-facing); translated to
  /// codes in [_loadStaffsFromApi] via [_labelToDesignationCode].
  List<String> _selectedDesignations = [];
  List<Staff> _filteredStaffs = [];
  final List<Staff> _allStaffs = [];
  final List<String> _allRooms = [];
  final List<String> _allDesignations = [];

  /// Classroom display name → code, so the (name-based) Classroom dropdown
  /// selection can be sent to the API as `primaryClassroomCodes`.
  Map<String, String> _classroomNameToCode = {};
  bool _isLoadingStaffs = false;
  String? _staffsError;
  Set<Staff> selectedStaffs = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Today's sign-in status per staff code — drives disabling the selection
  // checkbox for staff who are currently signed in (they can't be
  // reassigned to another classroom while signed in). Mirrors the same
  // restriction used by AssignStudentToClassroomForm.
  Map<String, String> _todayStatusByCode = {};

  bool _isStaffSignedIn(String code) {
    final gate = staffAttendanceGateFromTodayStatus(
      isActiveProfile: true,
      todayStatusRaw: _todayStatusByCode[code],
    );
    return gate.isSignedInToday;
  }

  @override
  void initState() {
    super.initState();
    _loadFilterOptionsThenStaffs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Staff roster for this screen only.
  ///
  /// This screen uses a dedicated endpoint instead of the shared
  /// `GetStaffClassroomsUseCase`. The URL is resolved through [ApiPaths] so it
  /// follows the active environment (LOCAL devtunnel or UAT host).
  Future<List<StaffClassroomItem>> _fetchManageStaffList({
    required String schoolCode,
    required String excludeClassroomCode,
    List<String>? primaryClassroomCodes,
    List<String>? designation,
  }) {
    return serviceLocator<StaffClassroomRepository>().getManageStaffList(
      schoolCode: schoolCode,
      excludeClassroomCode: excludeClassroomCode,
      primaryClassroomCodes: primaryClassroomCodes,
      designation: designation,
    );
  }

  /// Loads the full Classroom/Designation option lists once (every active
  /// classroom + the fixed designation set, mirroring StaffFilterScreen —
  /// not derived from a roster that's naturally incomplete, since this
  /// screen excludes staff already in the target classroom), then does the
  /// first staff fetch.
  Future<void> _loadFilterOptionsThenStaffs() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      final getClassrooms = serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      _classroomNameToCode = {
        for (final c in classrooms)
          if (c.name.trim().isNotEmpty) c.name.trim(): c.code.trim(),
      };
      if (mounted) {
        setState(() {
          _allRooms
            ..clear()
            ..addAll(_classroomNameToCode.keys.toList()..sort());
          _allDesignations
            ..clear()
            ..addAll(_labelToDesignationCode.keys.toList()..sort());
        });
      }
    } catch (_) {
      // Filter options failing to load shouldn't block the staff fetch below
      // — the dropdowns just stay empty and the user can retry via search.
    }
    await _loadStaffsFromApi();
  }

  /// Fetches the roster with the current Classroom/Designation selections
  /// applied server-side (`primaryClassroomCodes` / `designation` query
  /// params) — re-run whenever either selection changes. Free-text search
  /// stays client-side over this already-filtered result.
  Future<void> _loadStaffsFromApi() async {
    setState(() {
      _isLoadingStaffs = true;
      _staffsError = null;
    });

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.trim().isEmpty) {
        throw 'Missing school code. Please sign in again.';
      }

      final excludeClassroomCode = widget.classroomCode.trim();
      if (excludeClassroomCode.isEmpty) {
        throw 'Missing classroom code.';
      }

      final selectedClassroomCode =
          (_selectedClassroom != null && _selectedClassroom!.trim().isNotEmpty)
          ? _classroomNameToCode[_selectedClassroom!.trim()]
          : null;
      final designationCodes = _selectedDesignations
          .map((label) => _labelToDesignationCode[label])
          .whereType<String>()
          .toList();

      final roster = await _fetchManageStaffList(
        schoolCode: schoolCode,
        excludeClassroomCode: excludeClassroomCode,
        primaryClassroomCodes: selectedClassroomCode != null
            ? [selectedClassroomCode]
            : null,
        designation: designationCodes.isEmpty ? null : designationCodes,
      );

      final byStaffCode = <String, StaffClassroomItem>{};
      for (final item in roster) {
        final code = item.staffCode.trim();
        if (code.isEmpty) continue;
        byStaffCode[code] = item;
      }

      final rows = byStaffCode.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

      final fetchedStaffs = <Staff>[];
      var id = 0;
      for (final s in rows) {
        final rawPhoto = (s.profilePictureUrl ?? '').trim();
        final looksLikeUrl =
            rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://');

        fetchedStaffs.add(
          Staff(
            id: ++id,
            code: s.staffCode,
            name: s.fullName,
            designation: s.designation,
            profileImageUrl: looksLikeUrl ? rawPhoto : null,
            profilePhotoAssetCode: (!looksLikeUrl && rawPhoto.isNotEmpty)
                ? rawPhoto
                : null,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _allStaffs
          ..clear()
          ..addAll(fetchedStaffs);
        _filterStaffs();
      });
      unawaited(_loadTodaySignInStatuses(fetchedStaffs));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _staffsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStaffs = false;
        });
      }
    }
  }

  /// Fetches today's sign-in status for every loaded staff member in one
  /// batch call, reusing the same use case the staff dashboard/attendance
  /// screens use — staff currently signed in can't be reassigned to
  /// another classroom.
  Future<void> _loadTodaySignInStatuses(List<Staff> staffs) async {
    final codes = staffs
        .map((s) => s.code.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (codes.isEmpty) return;
    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusMapUseCase>();
      final map = await useCase(staffCodes: codes);
      if (!mounted) return;
      setState(() => _todayStatusByCode = map);
    } catch (_) {
      // Non-critical: leave statuses empty so nothing is incorrectly
      // disabled if the status check itself fails.
    }
  }

  void _onSearchChanged() {
    // Debounce so the list filters once the user pauses typing.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _filterStaffs();
    });
  }

  /// Search-text filtering only — Classroom and Designation are applied
  /// server-side by [_loadStaffsFromApi] via `primaryClassroomCodes` /
  /// `designation` query params, so [_allStaffs] is already scoped to them.
  void _filterStaffs() {
    final query = _searchController.text.trim().toLowerCase();
    _filteredStaffs = query.isEmpty
        ? _allStaffs
        : _allStaffs
              .where((staff) => staff.name.toLowerCase().contains(query))
              .toList();
    setState(() {});
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      // Get the current visible staff based on filters, excluding anyone
      // currently signed in — they can't be selected at all.
      final List<Staff> visibleStaffs = _getVisibleStaffs()
          .where((s) => !_isStaffSignedIn(s.code))
          .toList();

      if (value) {
        selectedStaffs.addAll(visibleStaffs);
      } else {
        selectedStaffs.removeAll(visibleStaffs);
      }
    });
  }

  void _toggleStaffSelection(Staff staff, bool? value) {
    if (value == null || _isStaffSignedIn(staff.code)) return;

    setState(() {
      if (value) {
        selectedStaffs.add(staff);
      } else {
        selectedStaffs.remove(staff);
      }

      // Update select all checkbox based on visible, selectable staff.
      final visibleStaffs = _getVisibleStaffs().where(
        (s) => !_isStaffSignedIn(s.code),
      );
      isSelectAllChecked = visibleStaffs.every(
        (staff) => selectedStaffs.contains(staff),
      );
    });
  }

  /// [_filterStaffs] keeps this in sync with the search box on every change,
  /// so it's always safe to read directly.
  List<Staff> _getVisibleStaffs() => _filteredStaffs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssignFormHeader(title: 'Assign to ${widget.selectedRoomName}'),
          const SizedBox(height: 16),
          const Text(
            'Select Staffs',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          AssignFormSearchBar(
            controller: _searchController,
            hintText: 'Search Staff',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: CustomDropdown(
                  onSelect: (value) {
                    setState(() => _selectedClassroom = value);
                    _loadStaffsFromApi();
                  },
                  hintText: 'Classroom',
                  items: _allRooms,
                  isField: true,
                  isEnabled: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: CustomMultiSelectDropdown(
                  hintText: 'Designations',
                  showSelectAll: true,
                  items: _allDesignations,
                  selectedItems: _selectedDesignations,
                  onChanged: (selectedItems) {
                    setState(() => _selectedDesignations = selectedItems);
                    _loadStaffsFromApi();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectAllCheckboxRow(
            value: isSelectAllChecked,
            onChanged: _toggleSelectAll,
            checkboxBuilder: (value, onChanged) => CustomCheckbox(
              borderColor: AppColors.themeColor,
              value: value,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AssignFormResultsArea(
              isLoading: _isLoadingStaffs,
              errorMessage: _staffsError,
              onRetry: _loadStaffsFromApi,
              content: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 72,
                ),
                itemCount: _getVisibleStaffs().length,
                itemBuilder: (context, index) {
                  final staff = _getVisibleStaffs()[index];
                  final isSelected = selectedStaffs.contains(staff);
                  return StaffListItem(
                    staff: staff,
                    isSelected: isSelected,
                    isSignedIn: _isStaffSignedIn(staff.code),
                    todayStatusRaw: _todayStatusByCode[staff.code],
                    onSelectionChanged: (value) {
                      _toggleStaffSelection(staff, value);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Next',
            cancelButtonLabel: 'Cancel',
            onPressedCancel: () => Navigator.pop(context),
            onPressedConfirm: () {
              if (selectedStaffs.isEmpty) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Please select at least one staff member',
                  isWarning: true,
                );
                return;
              } else {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    maxChildSize: 0.95,
                    builder: (_, controller) => StaffConfirmationForm(
                      selectedStaffs: selectedStaffs,
                      selectedRoomName: widget.selectedRoomName,
                      classroomCode: widget.classroomCode,
                      onStaffsAssigned: widget.onStaffsAssigned,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class StaffConfirmationForm extends StatefulWidget {
  final Set<Staff> selectedStaffs;
  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStaffsAssigned;

  const StaffConfirmationForm({
    Key? key,
    required this.selectedStaffs,
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStaffsAssigned,
  }) : super(key: key);

  @override
  State<StaffConfirmationForm> createState() => _StaffConfirmationFormState();
}

class _StaffConfirmationFormState extends State<StaffConfirmationForm> {
  late Set<Staff> currentSelectedStaffs;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    currentSelectedStaffs = Set.from(widget.selectedStaffs);
  }

  void removeStaff(Staff staff) {
    setState(() {
      currentSelectedStaffs.remove(staff);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssignFormHeader(title: 'Assign to ${widget.selectedRoomName}'),
          const SizedBox(height: 16),
          if (currentSelectedStaffs.isEmpty)
            const AssignFormEmptySelection(message: 'No staff selected')
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 72,
                ),
                itemCount: currentSelectedStaffs.length,
                itemBuilder: (context, index) {
                  final staff = currentSelectedStaffs.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.themeColor),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromRGBO(249, 245, 250, 1),
                    ),
                    child: Row(
                      children: [
                        DocumentImageWidget(
                          fileUuid: '',
                          imageUrl: staff.profileImageUrl,
                          mediaAssetCode: staff.profilePhotoAssetCode,
                          name: staff.name,
                          staffCode: staff.code,
                          size: 32,
                          fontSize: 12,
                          disableAttendanceStatusLookup: true,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: EllipsisTooltipText(
                            text: staff.name.trim().isEmpty
                                ? 'Staff'
                                : staff.name.trim(),
                            maxLines: 2,
                            preferLongPress: true,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => removeStaff(staff),
                          child: SvgPicture.asset(MediaRes.delete_icon),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Submit',
            cancelButtonLabel: 'Cancel',
            onPressedCancel: () => Navigator.pop(context),
            onPressedConfirm: _isSubmitting
                ? () {}
                : () => submitClassroomAssignment(
                    context: context,
                    isSelectionEmpty: currentSelectedStaffs.isEmpty,
                    emptySelectionMessage:
                        'Please select at least one staff member',
                    setSubmitting: (submitting) {
                      if (mounted) {
                        setState(() => _isSubmitting = submitting);
                      }
                    },
                    submit: (schoolCode) {
                      final staffCodes = currentSelectedStaffs
                          .map((s) => s.code.trim())
                          .where((code) => code.isNotEmpty)
                          .toList();
                      return serviceLocator<AssignStaffToClassroomUseCase>()(
                        schoolCode: schoolCode,
                        classroomCode: widget.classroomCode,
                        staffCodes: staffCodes,
                      );
                    },
                    onSuccess: widget.onStaffsAssigned,
                  ),
          ),
        ],
      ),
    );
  }
}

class StaffListItem extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final bool isSignedIn;
  final String? todayStatusRaw;
  final ValueChanged<bool?> onSelectionChanged;

  const StaffListItem({
    Key? key,
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
    this.isSignedIn = false,
    this.todayStatusRaw,
  }) : super(key: key);

  String get _disabledReason =>
      "${staff.name.trim().isEmpty ? 'This staff member' : staff.name.trim()} is already signed in. Please sign out before assigning to another classroom.";

  // Same green (signed in) / red (absent) attendance dot shown on the
  // classroom roster (classroom_staff_tab_card.dart) — passed in manually
  // here since the status is already batch-fetched for this whole grid.
  Color? get _attendanceDotColor {
    final normalized = (todayStatusRaw ?? '').trim().toUpperCase();
    if (normalized == 'SIGNED_IN') return Colors.green;
    if (normalized == 'ABSENT') return Colors.red;
    return null;
  }

  String? get _attendanceTooltip {
    final normalized = (todayStatusRaw ?? '').trim().toUpperCase();
    if (normalized == 'SIGNED_IN') return 'Staff is signed in';
    if (normalized == 'ABSENT') return 'Staff is absent';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: () {
        if (isSignedIn) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: _disabledReason,
            isWarning: true,
          );
          return;
        }
        onSelectionChanged(!isSelected);
      },
      child: Opacity(
        opacity: isSignedIn ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.themeColor),
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
                    onChanged: isSignedIn ? null : onSelectionChanged,
                  ),
                ),
                DocumentImageWidget(
                  fileUuid: '',
                  imageUrl: staff.profileImageUrl,
                  mediaAssetCode: staff.profilePhotoAssetCode,
                  name: staff.name,
                  staffCode: staff.code,
                  size: 32,
                  fontSize: 12,
                  statusColor: _attendanceDotColor,
                  statusTooltip: _attendanceTooltip,
                  disableAttendanceStatusLookup: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EllipsisTooltipText(
                    text: staff.name.trim().isEmpty
                        ? 'Staff'
                        : staff.name.trim(),
                    maxLines: 2,
                    preferLongPress: true,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
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
      ),
    );

    if (isSignedIn) {
      return Tooltip(message: _disabledReason, child: content);
    }
    return content;
  }
}

// NOTE: Designation multi-select uses the shared `CustomMultiSelectDropdown`
// (`lib/shared/common/widgets/custom_multi_select_dropdown.dart`).
