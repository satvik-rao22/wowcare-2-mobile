import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/message_composition_bulk_messaging.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/selection_list_item.dart';
import 'package:wowcare/shared/common/widgets/messaging_filter_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/media_res.dart';
import '../../../../../../core/util/safe_state_mixin.dart';
import '../../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../../../shared/common/widgets/custom_search_bar.dart';
import '../../../../student/cubit/student_cubit.dart';
import '../widgets/selection_shimmer.dart';

class StaffOrStudentSelectionBulkMessaging extends StatefulWidget {
  const StaffOrStudentSelectionBulkMessaging({
    super.key,
    this.isStaffSelection = true,
    this.conversationType = 'ROOM_CHAT',
  });
  final bool showLoading = false;
  final bool isStaffSelection;
  final String conversationType;

  @override
  State<StaffOrStudentSelectionBulkMessaging> createState() =>
      _StaffOrStudentSelectionBulkMessagingState();
}

class _StaffOrStudentSelectionBulkMessagingState
    extends State<StaffOrStudentSelectionBulkMessaging>
    with SafeStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedClassrooms = [];
  String? _selectedStatus;
  bool _selectAll = false;
  List<String> _selectedDesignations = [];
  List<String> _selectedTags = [];

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
    final staffMembers = context.read<StaffCubit>().state.items;
    return staffMembers
        .map(
          (s) => {
            'code': s.code,
            'name': '${s.name}',
            'avatar': s.profileImage, // fileUuid
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
        .map(
          (s) => {
            'code': s.code,
            'name': '${s.firstName} ${s.lastName}',
            'avatar': s.profileImage, // fileUuid
            'dateTime': null,
            'message': '',
            'isSigned': false,
            'isFavorite': false,
            'unreadCount': 0,
            'classroom': s.primaryClassroomName ?? '',
            'status': s.status,
            'tags': s.tags,
          },
        )
        .toList();
  }

  final List<String> _designationOptions = [
    'Kiosk',
    'Director',
    'Assistant Director',
    'Admin',
    'Lead Teacher',
    'Associate Teacher',
    'Assistant Teacher',
    'Owner',
    'Floater',
  ];
  final List<String> _tagOptions = [
    '5 Days',
    'Full Day',
    'Photo Permission',
    'Vegetarian',
    'First Aid',
    'Allergy',
    'Pickup Authorized',
    'Medication',
    'Half Day',
    'Boy',
    'Girl',
  ];
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
    if (_selectedClassrooms.isNotEmpty) {
      filtered = filtered.where((person) {
        final classroom = person['classroom'] as String?;
        return classroom != null && _selectedClassrooms.contains(classroom);
      }).toList();
    }
    if (_selectedDesignations.isNotEmpty && widget.isStaffSelection) {
      filtered = filtered.where((person) {
        final designation = person['designation'] as String?;
        return designation != null &&
            _selectedDesignations.contains(designation);
      }).toList();
    }
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
    } else {
      if (widget.isStaffSelection) {
        _selectAll = _filteredList.every(
          (entry) => _selectedStaffCodes.contains(entry.value['code']),
        );
      } else {
        _selectAll = _filteredList.every(
          (entry) => _selectedStudentCodes.contains(entry.value['code']),
        );
      }
    }
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade50,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.orange.shade100),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final classroomCubit = context.read<ClassroomCubit>();
        classroomCubit.loadActiveClassrooms();
        context.read<StudentCubit>().loadInitial();
        if (widget.isStaffSelection) {
          context.read<StaffCubit>().loadInitial();
        }

        // Auto-select first classroom if already available
        final classrooms = classroomCubit.state.classrooms;
        if (classrooms.isNotEmpty && _selectedClassrooms.isEmpty) {
          setState(() {
            _selectedClassrooms = [classrooms.first.name];
          });
        }
      }
    });
    _searchController.addListener(_applyFilters);
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
            if (state.classrooms.isNotEmpty && _selectedClassrooms.isEmpty) {
              setState(() {
                _selectedClassrooms = [state.classrooms.first.name];
              });
            }
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
                              Expanded(
                                child: CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  responsive.horizontalSpacing,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'New Message',
                                                style: TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize:
                                                      responsive.titleFontSize,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xff573353,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: responsive.isTablet
                                                ? 32.0
                                                : 20.0,
                                          ),
                                          Container(
                                            width: responsive.containerWidth,
                                            margin: EdgeInsets.symmetric(
                                              horizontal:
                                                  responsive.horizontalSpacing,
                                            ),
                                            padding: EdgeInsets.all(
                                              responsive.isTablet ? 32.0 : 16.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                  responsive.isTablet
                                                      ? 30.0
                                                      : 20.0,
                                                ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 10,
                                                        ),
                                                    child: Text(
                                                      widget.isStaffSelection
                                                          ? 'Select Staff'
                                                          : 'Select Students',
                                                      style: TextStyle(
                                                        fontFamily: 'Manrope',
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xff573353,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: CustomSearchBar(
                                                        controller:
                                                            _searchController,
                                                        hintText:
                                                            widget
                                                                .isStaffSelection
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
                                                            _selectedClassrooms =
                                                                [];
                                                            _selectedStaffCodes
                                                                .clear();
                                                            _selectedStudentCodes
                                                                .clear();
                                                            _selectedTags = [];
                                                            _searchController
                                                                .clear();
                                                            _selectedDesignations =
                                                                [];
                                                            _selectedStatus =
                                                                null;
                                                            _updateSelectAllState();
                                                          });
                                                        },
                                                        label: 'Clear All',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: MessagingFilterDropdown(
                                                        hintText: 'Status',
                                                        items: _statusOptions,
                                                        selectedItem:
                                                            _selectedStatus,
                                                        onSelect: (v) =>
                                                            setState(() {
                                                              _selectedStatus =
                                                                  v;
                                                              _selectedStaffCodes
                                                                  .clear();
                                                              _selectAll =
                                                                  false;
                                                            }),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (widget.isStaffSelection)
                                                      Expanded(
                                                        child: CustomMultiSelectDropdown(
                                                          showSelectAll: true,
                                                          hintText:
                                                              'Select Designation',
                                                          items:
                                                              _designationOptions,
                                                          selectedItems:
                                                              _selectedDesignations,
                                                          gapHeight: 40,
                                                          onChanged: (selectedItems) {
                                                            setState(() {
                                                              _selectedDesignations =
                                                                  selectedItems;
                                                              _updateSelectAllState();
                                                            });
                                                          },
                                                        ),
                                                      )
                                                    else
                                                      Expanded(
                                                        child: CustomMultiSelectDropdown(
                                                          showSelectAll: true,
                                                          hintText:
                                                              'Select Tags',
                                                          items: _tagOptions,
                                                          selectedItems:
                                                              _selectedTags,
                                                          gapHeight: 40,
                                                          onChanged: (selectedItems) {
                                                            setState(() {
                                                              _selectedTags =
                                                                  selectedItems;
                                                              _updateSelectAllState();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                CustomMultiSelectDropdown(
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
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                // Select All
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: CustomCheckbox(
                                                    label: 'Select All',
                                                    value: _selectAll,
                                                    borderColor:
                                                        AppColors.themeColor,
                                                    onChanged: (v) {
                                                      final newVal = v ?? false;
                                                      setState(() {
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
                                                            _selectedStudentCodes.addAll(
                                                              _filteredList.map(
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
                                                ),
                                                const SizedBox(height: 20),
                                                SizedBox(
                                                  height:
                                                      300, // or responsive height
                                                  child: _filteredList.isEmpty
                                                      ? Center(
                                                          child: Text(
                                                            widget.isStaffSelection
                                                                ? 'No staff match the selected filters'
                                                                : 'No student match the selected filters',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        )
                                                      : GridView.builder(
                                                          itemCount:
                                                              _filteredList
                                                                  .length,
                                                          gridDelegate:
                                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                                crossAxisCount:
                                                                    responsive
                                                                        .isTablet
                                                                    ? 3
                                                                    : 2,
                                                                crossAxisSpacing:
                                                                    12,
                                                                mainAxisSpacing:
                                                                    12,
                                                                mainAxisExtent:
                                                                    52,
                                                              ),
                                                          itemBuilder: (context, index) {
                                                            final entry =
                                                                _filteredList[index];
                                                            final person =
                                                                entry.value;

                                                            final bool
                                                            isSelected =
                                                                widget
                                                                    .isStaffSelection
                                                                ? _selectedStaffCodes
                                                                      .contains(
                                                                        person['code'],
                                                                      )
                                                                : _selectedStudentCodes
                                                                      .contains(
                                                                        person['code'],
                                                                      );

                                                            return CommonSelectionItem(
                                                              name:
                                                                  person['name'],
                                                              avatarUuid:
                                                                  person['avatar'] ??
                                                                  '',
                                                              isSelected:
                                                                  isSelected,
                                                              onSelectionChanged: (bool? selected) {
                                                                setState(() {
                                                                  final code =
                                                                      person['code'];
                                                                  if (selected ==
                                                                      true) {
                                                                    (widget.isStaffSelection
                                                                            ? _selectedStaffCodes
                                                                            : _selectedStudentCodes)
                                                                        .add(
                                                                          code,
                                                                        );
                                                                  } else {
                                                                    (widget.isStaffSelection
                                                                            ? _selectedStaffCodes
                                                                            : _selectedStudentCodes)
                                                                        .remove(
                                                                          code,
                                                                        );
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
                                        ],
                                      ),
                                    ),
                                  ],
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
