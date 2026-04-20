import 'dart:async';
import 'dart:typed_data';

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
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_page_usecase.dart';
import 'package:wowcare/domain/features/staff_classroom/usecases/assign_staff_to_classroom_usecase.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // UI-only
// import 'package:wowcare/core/extentions/context_extentions.dart'; // UI-only
// import 'package:wowcare/core/services/injection_container.dart'; // UI-only
// import 'package:wowcare/core/util/color_utils.dart'; // UI-only
// import 'package:wowcare/core/util/core_utils.dart'; // UI-only
// import 'package:wowcare/core/util/string_utils.dart'; // UI-only
// import 'package:wowcare/core/util/typedefs.dart'; // UI-only
// import 'package:wowcare/features/...'; // UI-only
import 'package:shimmer/shimmer.dart';

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
  final String photoUuid;
  final List<RoomDTO> rooms;
  const Staff({
    required this.id,
    required this.code,
    required this.name,
    required this.designation,
    this.photoUuid = '',
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
  static const int _pageSize = 100;

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

  @override
  void initState() {
    super.initState();
    _loadStaffsFromApi();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffsFromApi() async {
    setState(() {
      _isLoadingStaffs = true;
      _staffsError = null;
    });

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      final organizationCode =
          await storage.getString(StorageKeys.organizationCode) ?? '';
      if (schoolCode.trim().isEmpty || organizationCode.trim().isEmpty) {
        throw 'Missing school/organization code. Please sign in again.';
      }

      final getClassrooms = serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      final classroomNameByCode = <String, String>{
        for (final c in classrooms) c.code: c.name,
      };

      final getStaffPageUseCase = serviceLocator<GetStaffPageUseCase>();
      final fetchedStaffs = <Staff>[];
      final uniqueRoomNames = <String>{};
      final uniqueDesignations = <String>{};

      int page = 0;
      bool hasMore = true;
      while (hasMore) {
        final staffPage = await getStaffPageUseCase(
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          page: page,
          size: _pageSize,
          status: 'ACTIVE',
        );

        for (final s in staffPage.items) {
          final roomCodes = <String>{
            if (s.primaryClassroomCode.trim().isNotEmpty)
              s.primaryClassroomCode.trim(),
            ...s.allowedClassroomCodes
                .where((code) => code.trim().isNotEmpty)
                .map((code) => code.trim()),
          };
          final rooms = roomCodes
              .map(
                (code) => RoomDTO(
                  code: code,
                  name: classroomNameByCode[code] ?? code,
                ),
              )
              .toList();

          fetchedStaffs.add(
            Staff(
              id: fetchedStaffs.length + 1,
              code: s.code,
              name: s.name,
              designation: s.designation,
              photoUuid: '',
              rooms: rooms,
            ),
          );
          if (s.designation.trim().isNotEmpty) {
            uniqueDesignations.add(s.designation.trim());
          }
          for (final r in rooms) {
            if (r.name.trim().isNotEmpty) {
              uniqueRoomNames.add(r.name.trim());
            }
          }
        }

        hasMore = staffPage.hasMore;
        page += 1;
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
    _filterStaffs();
  }

  void _filterStaffs() {
    final allStaffs = _allStaffs;
    _filteredStaffs = allStaffs.where((staff) {
      // Exclude staff who are already associated with the selected classroom
      final excludeDueToSelectedClassroom = staff.rooms.any((room) {
        final byCode = room.code.trim() == (widget.classroomCode.trim());
        final byName = room.name.trim() == (widget.selectedRoomName.trim());
        return byCode || byName;
      });
      if (excludeDueToSelectedClassroom) return false;

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Staffs',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.grey[700],
                ),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
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
                child: CustomMultiSelectDropdownAssignStaff(
                  hintText: 'Designations',
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
                ? const Center(child: CircularProgressIndicator())
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select at least one staff member'),
                  ),
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
                        StaffProfileImage(
                          imageUrl: staff.photoUuid,
                          staffId: staff.id,
                          name: staff.name,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select at least one staff member',
                          ),
                        ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            message.isEmpty ? 'Assigned successfully' : message,
                          ),
                        ),
                      );

                      widget.onStaffsAssigned();
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
              StaffProfileImage(
                imageUrl: staff.photoUuid,
                staffId: staff.id,
                name: staff.name,
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

class StaffProfileImage extends StatefulWidget {
  final String imageUrl;
  final int staffId;
  final double radius;
  final String? name;
  final double? fontSize;

  const StaffProfileImage({
    Key? key,
    required this.imageUrl,
    required this.staffId,
    this.fontSize,
    this.name,
    this.radius = 16,
  }) : super(key: key);

  @override
  State<StaffProfileImage> createState() => _StaffProfileImageState();
}

class _StaffProfileImageState extends State<StaffProfileImage> {
  // UI-only: remove backend image fetching; keep shimmer interface if needed
  StreamSubscription? _subscription; // not used in UI-only
  Uint8List? _currentImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(StaffProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.staffId != widget.staffId) {
      _loadImage();
    }
  }

  void _loadImage() {
    // UI-only: skip downloading; always use placeholder/asset
    setState(() {
      _currentImage = null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    if (_currentImage == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: const AssetImage(MediaRes.userImageMale),
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: MemoryImage(_currentImage!),
    );
  }
}

class CustomMultiSelectDropdownAssignStaff extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;

  const CustomMultiSelectDropdownAssignStaff({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.isField = false,
    this.width,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdownAssignStaff> createState() =>
      _CustomMultiSelectDropdownAssignStaffState();
}

class _CustomMultiSelectDropdownAssignStaffState
    extends State<CustomMultiSelectDropdownAssignStaff> {
  bool isDropdownOpen = false;
  String get displaySuffix {
    if (widget.hintText.toLowerCase() == 'status') {
      return 'status';
    } else if (widget.hintText.toLowerCase() == 'tags') {
      return 'tag${widget.selectedItems.length > 1 ? 's' : ''}';
    }
    return 'items';
  }

  @override
  Widget build(BuildContext context) {
    String displayText = widget.selectedItems.isEmpty
        ? widget.hintText
        : '${widget.selectedItems.length} $displaySuffix';

    return Container(
      height: 40,
      width: widget.width,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
        iconSize: 24,
        elevation: 2,
        style: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xff573353),
          fontSize: 16,
        ),
        dropdownColor: Colors.white,
        items: widget.items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            enabled: false,
            child: InkWell(
              onTap: () {
                List<String> newSelectedItems = List.from(widget.selectedItems);
                if (newSelectedItems.contains(item)) {
                  newSelectedItems.remove(item);
                } else {
                  newSelectedItems.add(item);
                }
                widget.onChanged(newSelectedItems);
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Checkbox(
                      value: widget.selectedItems.contains(item),
                      onChanged: (_) {
                        List<String> newSelectedItems = List.from(
                          widget.selectedItems,
                        );
                        if (newSelectedItems.contains(item)) {
                          newSelectedItems.remove(item);
                        } else {
                          newSelectedItems.add(item);
                        }
                        widget.onChanged(newSelectedItems);
                      },
                      activeColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: Color(0xff573353),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (_) {},
        isExpanded: true,
        hint: Text(
          displayText,
          style: TextStyle(
            fontFamily: 'Manrope',
            color: widget.selectedItems.isEmpty
                ? Colors.grey[600]
                : const Color(0xff573353),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
