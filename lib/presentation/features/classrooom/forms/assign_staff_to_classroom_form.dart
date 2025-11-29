import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// UI-only: use wowcare widgets and theme; backend/bloc imports removed
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // UI-only
// import 'package:wowcare/core/extentions/context_extentions.dart'; // UI-only
// import 'package:wowcare/core/services/injection_container.dart'; // UI-only
// import 'package:wowcare/core/util/color_utils.dart'; // UI-only
// import 'package:wowcare/core/util/core_utils.dart'; // UI-only
// import 'package:wowcare/core/util/string_utils.dart'; // UI-only
// import 'package:wowcare/core/util/typedefs.dart'; // UI-only
// import 'package:wowcare/features/...'; // UI-only
import 'package:shimmer/shimmer.dart';

// UI-only lightweight types
typedef DataMap = Map<String, dynamic>;

class RoomDTO {
  final int id;
  final String name;
  const RoomDTO({required this.id, required this.name});
}

class Staff {
  final int id;
  final String name;
  final String designation;
  final String photoUuid;
  final List<RoomDTO> rooms;
  const Staff({
    required this.id,
    required this.name,
    required this.designation,
    this.photoUuid = '',
    this.rooms = const [],
  });
}

class AssignStaffToClassroomForm extends StatefulWidget {
  const AssignStaffToClassroomForm({
    required this.selectedRoomName,
    required this.onStaffsAssigned,
    super.key,
  });

  final String selectedRoomName;
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
  Set<Staff> selectedStaffs = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAllStaffs();
    getAllDesignationsFromMasterLookup();
    getAllClassrooms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void getAllStaffs() {
    // UI-only: populate with dummy staff
    _allStaffs
      ..clear()
      ..addAll([
        Staff(
          id: 1,
          name: 'Ava Johnson',
          designation: 'Lead Teacher',
          rooms: [const RoomDTO(id: 1, name: 'Room A')],
        ),
        Staff(
          id: 2,
          name: 'Michael Chen',
          designation: 'Assistant Teacher',
          rooms: [const RoomDTO(id: 2, name: 'Room B')],
        ),
        Staff(
          id: 3,
          name: 'Priya Patel',
          designation: 'Floater',
          rooms: [const RoomDTO(id: 1, name: 'Room A'), const RoomDTO(id: 3, name: 'Room C')],
        ),
      ]);
    _filterStaffs();
    setState(() {});
  }

  void getAllClassrooms() {
    // UI-only: static room names
    _allRooms
      ..clear()
      ..addAll(['Room A', 'Room B', 'Room C']);
    setState(() {});
  }

  void getAllDesignationsFromMasterLookup() {
    // UI-only: static designations list
    _allDesignations
      ..clear()
      ..addAll([
        'Director',
        'Assistant Director',
        'Admin',
        'Lead Teacher',
        'Associate Teacher',
        'Assistant Teacher',
        'Owner',
        'Floater',
      ]);
    setState(() {});
  }

  void _onSearchChanged() {
    _filterStaffs();
  }

  void _filterStaffs() {
    final allStaffs = _allStaffs;
    _filteredStaffs = allStaffs.where((staff) {
      bool matchesSearch = true;
      bool matchesRoom = true;
      bool matchesDesignation = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = staff.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }

      if (_selectedClassroom != null && _selectedClassroom != '') {
        matchesRoom = staff.rooms.any((room) => _selectedClassroom!.contains(room.name));
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

  Widget _buildShimmerGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 69,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const ShimmerLoaderCard(
        child: SizedBox(),
      ),
    );
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
                border: Border.all(color: Colors.grey)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Staffs',
                hintStyle: TextStyle(color: Colors.grey[700]),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelectAllChecked,
                  onChanged: _toggleSelectAll,
                ),
              ),
              const Text('Select All'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            onPressedConfirm: () {
              if (selectedStaffs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one staff member')),
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
  final VoidCallback onStaffsAssigned;

  const StaffConfirmationForm({
    Key? key,
    required this.selectedStaffs,
    required this.selectedRoomName,
    required this.onStaffsAssigned,
  }) : super(key: key);

  @override
  State<StaffConfirmationForm> createState() => _StaffConfirmationFormState();
}

class _StaffConfirmationFormState extends State<StaffConfirmationForm> {
  late Set<Staff> currentSelectedStaffs;

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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
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
                    color: Colors.grey,
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
                      border: Border.all(
                        color: AppColors.themeColor,
                      ),
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
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => removeStaff(staff),
                          child: SvgPicture.asset(MediaRes.delete_icon),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Submit',
            onPressedConfirm: () {
              if (currentSelectedStaffs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one staff member')),
                );
                return;
              }
              // UI-only: simulate success and close
              widget.onStaffsAssigned();
              Navigator.pop(context);
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
  static final Map<String, Uint8List?> _imageCache = {};
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
          color: Colors.black87,
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
                        List<String> newSelectedItems =
                            List.from(widget.selectedItems);
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
                        fontSize: 14,
                        color: Colors.black87,
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
            color: widget.selectedItems.isEmpty
                ? Colors.grey[600]
                : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

