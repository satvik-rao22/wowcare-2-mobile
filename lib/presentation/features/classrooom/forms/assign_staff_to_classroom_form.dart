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
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/staff_classroom/models/staff_classroom_models.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // UI-only
// import 'package:wowcare/core/extentions/context_extentions.dart'; // UI-only
// import 'package:wowcare/core/services/injection_container.dart'; // UI-only
// import 'package:wowcare/core/util/color_utils.dart'; // UI-only
// import 'package:wowcare/core/util/core_utils.dart'; // UI-only
// import 'package:wowcare/core/util/string_utils.dart'; // UI-only
// import 'package:wowcare/core/util/typedefs.dart'; // UI-only
// import 'package:wowcare/features/...'; // UI-only
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

class RoomDTO {
  final String code;
  final String name;
  const RoomDTO({required this.code, required this.name});
}

class Staff {
  final int id;
  final String code;
  final String name;
  final String designation;
  final String? profileImageUrl;
  final String? profilePhotoAssetCode;
  final List<RoomDTO> rooms;
  const Staff({
    required this.id,
    required this.code,
    required this.name,
    required this.designation,
    this.profileImageUrl,
    this.profilePhotoAssetCode,
    this.rooms = const [],
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
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedDesignations = [];
  List<Staff> _filteredStaffs = [];
  final List<Staff> _allStaffs = [];
  final List<String> _allRooms = [];
  final List<String> _allDesignations = [];
  bool _isLoadingStaffs = false;
  String? _staffsError;
  Set<Staff> selectedStaffs = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadStaffsFromApi();
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
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffClassroomsManageStaffList,
      ApiConstants.staffBaseUrl,
    );

    final dio = serviceLocator<ApiClient>().client;
    final response = await dio.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'excludeClassroomCode': excludeClassroomCode,
        'status': const ['ACTIVE'],
      },
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected manage-staff-list API response format');
    }

    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StaffClassroomItemModel.fromJson)
        .map(
          (m) => StaffClassroomItem(
            classroomCode: m.classroomCode,
            staffCode: m.staffCode,
            firstName: m.firstName,
            lastName: m.lastName,
            profilePictureUrl: m.profilePictureUrl,
            status: m.status,
            designation: m.designation,
            expectedToday: m.expectedToday,
            signedIn: m.signedIn,
            absent: m.absent,
            notMarked: m.notMarked,
          ),
        )
        .toList();
  }

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

      final getClassrooms = serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      final classroomNameByCode = <String, String>{
        for (final c in classrooms) c.code: c.name,
      };

      final roster = await _fetchManageStaffList(
        schoolCode: schoolCode,
        excludeClassroomCode: excludeClassroomCode,
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
      final uniqueRoomNames = <String>{};
      final uniqueDesignations = <String>{};
      var id = 0;
      for (final s in rows) {
        final cc = s.classroomCode.trim();
        final rooms = <RoomDTO>[];
        if (cc.isNotEmpty) {
          final name = classroomNameByCode[cc] ?? cc;
          rooms.add(RoomDTO(code: cc, name: name));
          if (name.trim().isNotEmpty) uniqueRoomNames.add(name.trim());
        }

        final rawPhoto = (s.profilePictureUrl ?? '').trim();
        final looksLikeUrl = rawPhoto.startsWith('http://') ||
            rawPhoto.startsWith('https://');

        fetchedStaffs.add(
          Staff(
            id: ++id,
            code: s.staffCode,
            name: s.fullName,
            designation: s.designation,
            profileImageUrl: looksLikeUrl ? rawPhoto : null,
            profilePhotoAssetCode:
                (!looksLikeUrl && rawPhoto.isNotEmpty) ? rawPhoto : null,
            rooms: rooms,
          ),
        );
        if (s.designation.trim().isNotEmpty) {
          uniqueDesignations.add(s.designation.trim());
        }
      }

      if (!mounted) return;
      setState(() {
        _allStaffs
          ..clear()
          ..addAll(fetchedStaffs);
        _allRooms
          ..clear()
          ..addAll(uniqueRoomNames.toList()..sort());
        _allDesignations
          ..clear()
          ..addAll(uniqueDesignations.toList()..sort());
        _filterStaffs();
      });
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

  void _onSearchChanged() {
    // Debounce so the list filters once the user pauses typing.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _filterStaffs();
    });
  }

  void _filterStaffs() {
    final allStaffs = _allStaffs;
    _filteredStaffs = allStaffs.where((staff) {
      bool matchesSearch = true;
      bool matchesRoom = true;
      bool matchesDesignation = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = staff.name.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }

      if (_selectedClassroom != null && _selectedClassroom != '') {
        matchesRoom = staff.rooms.any(
          (room) => _selectedClassroom!.contains(room.name),
        );
      }

      if (_selectedDesignations.isNotEmpty) {
        matchesDesignation = _selectedDesignations.contains(staff.designation);
      }

      return matchesSearch && matchesRoom && matchesDesignation;
    }).toList();
    setState(() {});
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      final List<Staff> visibleStaffs = _getVisibleStaffs();

      if (value) {
        selectedStaffs.addAll(visibleStaffs);
      } else {
        selectedStaffs.removeAll(visibleStaffs);
      }
    });
  }

  void _toggleStaffSelection(Staff staff, bool? value) {
    if (value == null) return;

    setState(() {
      if (value) {
        selectedStaffs.add(staff);
      } else {
        selectedStaffs.remove(staff);
      }

      final visibleStaffs = _getVisibleStaffs();
      isSelectAllChecked = visibleStaffs.every(
        (staff) => selectedStaffs.contains(staff),
      );
    });
  }

  List<Staff> _getVisibleStaffs() {
    return _filteredStaffs.isEmpty &&
            _searchController.text.isEmpty &&
            (_selectedClassroom?.isEmpty ?? true) &&
            _selectedDesignations.isEmpty
        ? _allStaffs
        : _filteredStaffs;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assign to ${widget.selectedRoomName}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
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
          SearchBar(
            controller: _searchController,
            constraints: const BoxConstraints(minHeight: 44),
            hintText: 'Search Staffs',
            hintStyle: WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Manrope',
                color: Colors.grey[700],
              ),
            ),
            backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
            surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
            elevation: const WidgetStatePropertyAll<double>(0),
            side: const WidgetStatePropertyAll(
              BorderSide(
                width: 1,
                color: Color.fromARGB(255, 188, 173, 186),
              ),
            ),
            leading: const Icon(Icons.search, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: CustomDropdown(
                  onSelect: (value) {
                    setState(() {
                      _selectedClassroom = value;
                      _filterStaffs();
                    });
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
                    setState(() {
                      _selectedDesignations = selectedItems;
                      _filterStaffs();
                    });
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
                  borderColor: AppColors.themeColor,
                  value: isSelectAllChecked,
                  onChanged: _toggleSelectAll,
                ),
              ),
              const Text('Select All', style: TextStyle(fontFamily: 'Manrope')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingStaffs
                ? const Center(child: PrimaryCircularLoader())
                : _staffsError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _staffsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _loadStaffsFromApi,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 52,
                        ),
                    itemCount: _getVisibleStaffs().length,
                    itemBuilder: (context, index) {
                      final staff = _getVisibleStaffs()[index];
                      final isSelected = selectedStaffs.contains(staff);
                      return StaffListItem(
                        staff: staff,
                        isSelected: isSelected,
                        onSelectionChanged: (value) {
                          _toggleStaffSelection(staff, value);
                        },
                      );
                    },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Assign to ${widget.selectedRoomName}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentSelectedStaffs.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No staff selected',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: const Color(0xff573353),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 52,
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
                          child: Text(
                            staff.name,
                            overflow: TextOverflow.ellipsis,
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
                : () async {
                    if (currentSelectedStaffs.isEmpty) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Please select at least one staff member',
                        isWarning: true,
                      );
                      return;
                    }
                    setState(() => _isSubmitting = true);
                    try {
                      final storage = serviceLocator<StorageService>();
                      final schoolCode = await storage.getString(
                        StorageKeys.schoolCode,
                      );
                      if (schoolCode == null || schoolCode.trim().isEmpty) {
                        throw 'Missing schoolCode. Please sign in / select a school again.';
                      }

                      final staffCodes = currentSelectedStaffs
                          .map((s) => s.code.trim())
                          .where((code) => code.isNotEmpty)
                          .toList();

                      final message =
                          await serviceLocator<AssignStaffToClassroomUseCase>()(
                            schoolCode: schoolCode,
                            classroomCode: widget.classroomCode,
                            staffCodes: staffCodes,
                          );

                      if (!mounted) return;
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message:
                            message.isEmpty ? 'Assigned successfully' : message,
                        isSuccess: true,
                      );

                      widget.onStaffsAssigned();
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: e.toString(),
                        isError: true,
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class StaffListItem extends StatelessWidget {
  final Staff staff;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const StaffListItem({
    Key? key,
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onSelectionChanged(!isSelected);
      },
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
                  onChanged: onSelectionChanged,
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
                disableAttendanceStatusLookup: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  staff.name,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}

// NOTE: Designation multi-select uses the shared `CustomMultiSelectDropdown`
// (`lib/shared/common/widgets/custom_multi_select_dropdown.dart`).
