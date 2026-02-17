import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/shared/common/views/filter_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_filters.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';

class StudentAttendanceDailyViewScreen extends StatefulWidget {
  const StudentAttendanceDailyViewScreen({
    super.key,
    this.incomingFilter,
    this.contentOnly = false,
    this.classroomFilter,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
  });

  final String? incomingFilter;
  final bool contentOnly;
  final FilterData? classroomFilter;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;

  @override
  State<StudentAttendanceDailyViewScreen> createState() => _StudentAttendanceDailyViewScreenState();
}

class _StudentAttendanceDailyViewScreenState extends State<StudentAttendanceDailyViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _showAbsentOnly = false;
  String? _statusLegendFilter;
  FilterData? _studentFilters;
  int? _expandedStudentIndex;

  // Summary data (dummy data for now)
  int enrolled = 120;
  int active = 100;
  int upcoming = 20;
  int expected = 95;
  int present = 85;
  int absent = 10;
  int signedOut = 5;
  int notMarked = 5;
  
  // Filter state
  List<String> _selectedClassrooms = [];
  List<String> _selectedTags = [];
  String? _sortColumn;
  bool _sortAscending = true;
  String? _errorMessage;
  bool _hasError = false;

  // Dummy student data
  final List<StudentAttendanceCardData> _students = [];
  final List<StudentAbsentCardData> _absentStudents = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Handle incoming filter
    if (widget.incomingFilter != null) {
      _statusLegendFilter = widget.incomingFilter;
      if (widget.incomingFilter == 'Absent') {
        _showAbsentOnly = true;
      }
    }

    // Handle classroom filter
    if (widget.classroomFilter != null) {
      _studentFilters = widget.classroomFilter;
    }

    // Load dummy data
    _loadDummyData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadDummyData();
  }

  void _loadDummyData() {
    // Simulate loading
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    // Simulate API call with potential error (for UI testing)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Simulate error 10% of the time for testing
        final shouldError = DateTime.now().millisecond % 10 == 0;
        
        if (shouldError) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Unable to load attendance. Retry.';
          });
          return;
        }
        
        setState(() {
          _isLoading = false;
          
          // Generate dummy attendance data
          _students.clear();
          for (int i = 1; i <= 15; i++) {
            _students.add(StudentAttendanceCardData(
              id: 'student_$i',
              studentName: 'Student $i',
              studentPhotoUuid: null,
              roomName: 'Room ${(i % 3) + 1}',
              expectedToday: i <= 12,
              hasSignIn: i <= 10,
              signInTime: i <= 10 ? '08:${30 + i}:00 AM' : null,
              signOutTime: i <= 8 ? '05:${10 + i}:00 PM' : null,
              signInBy: i <= 10 ? 'Staff Member' : null,
              signOutBy: i <= 8 ? 'Staff Member' : null,
              signInMethod: i <= 10 ? (i % 4 == 0 ? SignMethod.gps : (i % 4 == 1 ? SignMethod.qr : (i % 4 == 2 ? SignMethod.kiosk : SignMethod.direct))) : null,
              signOutMethod: i <= 8 ? (i % 4 == 0 ? SignMethod.gps : (i % 4 == 1 ? SignMethod.qr : (i % 4 == 2 ? SignMethod.kiosk : SignMethod.direct))) : null,
              tags: i % 2 == 0 ? ['Full Day'] : ['Half Day'],
              studentId: i,
              roomId: (i % 3) + 1,
              schoolId: 1,
            ));
          }

          // Generate dummy absent data
          _absentStudents.clear();
          for (int i = 1; i <= 5; i++) {
            _absentStudents.add(StudentAbsentCardData(
              id: 'absent_$i',
              name: 'Absent Student $i',
              photoUuid: null,
              roomName: 'Room ${(i % 3) + 1}',
              absentTime: '09:00:00 AM',
              absentBy: 'Staff Member',
              note: 'Student is absent today',
              studentId: 100 + i,
              roomId: (i % 3) + 1,
              schoolId: 1,
              startDate: DateTime.now().toIso8601String(),
              endDate: DateTime.now().toIso8601String(),
              hasSignIn: false,
              expectedToday: true,
            ));
          }
        });
      }
    });
  }

  // Method to load attendance data (backend implementation removed)
  void _loadAttendanceData(BuildContext context, {bool reset = false}) {
    _loadDummyData();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return _buildContent();
    }

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    
    return CustomRefreshIndicator(
      onRefresh: () async {
        _loadAttendanceData(context, reset: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: contentPadding.left,
          vertical: responsive.verticalSpacing / 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.verticalSpacing),
            // Summary cards (only show for admin/director - for now show for all)
            StudentAttendanceSummary(
              enrolled: enrolled,
              active: active,
              upcoming: upcoming,
              expected: expected,
              present: present,
              absent: absent,
              signedOut: signedOut,
              notMarked: notMarked,
              isLoading: _isLoading,
              onLegendTap: (status) {
                setState(() {
                  if (_statusLegendFilter == status) {
                    _statusLegendFilter = null;
                  } else {
                    _statusLegendFilter = status;
                    if (status == 'Absent') {
                      _showAbsentOnly = true;
                    } else {
                      _showAbsentOnly = false;
                    }
                  }
                });
                _loadDummyData();
              },
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Filters row
            StudentAttendanceFilters(
              searchController: _searchController,
              selectedDate: _selectedDate,
              showAbsentOnly: _showAbsentOnly,
              selectedClassrooms: _selectedClassrooms,
              selectedTags: _selectedTags,
              availableClassrooms: ['Room 1', 'Room 2', 'Room 3', 'Room 4', 'Room 5'],
              availableTags: ['Full Day', 'Half Day', '5 Days', 'Photo Permission'],
              hasActiveFilters: _statusLegendFilter != null || 
                  _studentFilters != null || 
                  _selectedClassrooms.isNotEmpty || 
                  _selectedTags.isNotEmpty,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _loadDummyData();
              },
              onToggleChanged: (value) {
                setState(() {
                  _showAbsentOnly = value;
                  if (value) {
                    _statusLegendFilter = null;
                  }
                });
                _loadDummyData();
              },
              onClassroomsChanged: (classrooms) {
                setState(() {
                  _selectedClassrooms = classrooms;
                });
                _loadDummyData();
              },
              onTagsChanged: (tags) {
                setState(() {
                  _selectedTags = tags;
                });
                _loadDummyData();
              },
              onFilterTap: () {
                _navigateToFilterScreen();
              },
              onCreateAttendance: () {
                _showCreateAttendanceModal();
              },
              onClearAll: () {
                setState(() {
                  _statusLegendFilter = null;
                  _studentFilters = null;
                  _selectedClassrooms = [];
                  _selectedTags = [];
                });
                _loadDummyData();
              },
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Error handling
            if (_hasError)
              CustomSectionCard(
                margin: EdgeInsets.only(bottom: responsive.verticalSpacing),
                padding: EdgeInsets.all(responsive.horizontalSpacing),
                backgroundColor: AppColors.errorColor.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.errorColor, size: 24),
                    SizedBox(width: responsive.horizontalSpacing / 2),
                    Expanded(
                      child: AppText.body(
                        _errorMessage ?? 'Unable to load attendance. Retry.',
                        style: TextStyle(color: AppColors.errorColor),
                      ),
                    ),
                    SizedBox(width: responsive.horizontalSpacing / 2),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = null;
                        });
                        _loadDummyData();
                      },
                      child: AppText.body('Retry'),
                    ),
                  ],
                ),
              ),
            // Content based on toggle state
            if (_showAbsentOnly) ...[
              // Show absent students
              if (_isLoading && _absentStudents.isEmpty)
                ...List.generate(6, (index) => const StudentAbsentCardShimmer())
              else if (_absentStudents.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(responsive.verticalSpacing),
                    child: AppText.body(
                      'No absent students found for the selected date',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._absentStudents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = entry.value;
                  return StudentAbsentCard(
                    student: student,
                    index: index,
                    isExpanded: _expandedStudentIndex == index,
                    onTap: () {
                      setState(() {
                        if (_expandedStudentIndex == index) {
                          _expandedStudentIndex = null;
                        } else {
                          _expandedStudentIndex = index;
                        }
                      });
                    },
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentAttendanceProfile(
                            studentId: student.studentId,
                            studentName: student.name,
                            studentPhotoUuid: student.photoUuid,
                            roomName: student.roomName,
                            isSignedIn: false,
                            isAbsent: true,
                            isExpectedToday: student.expectedToday,
                            isPresentToday: false,
                            profileStatus: 'A',
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
            ] else ...[
              // Show regular attendance data
              if (_isLoading && _students.isEmpty)
                ...List.generate(6, (index) => const StudentAttendanceCardShimmer())
              else if (_students.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(responsive.verticalSpacing),
                    child: AppText.body(
                      'No attendance records found for the selected date',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._getFilteredStudents().asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = entry.value;
                  return StudentAttendanceCard(
                    student: student,
                    index: index,
                    isExpanded: _expandedStudentIndex == index,
                    onTap: () {
                      setState(() {
                        if (_expandedStudentIndex == index) {
                          _expandedStudentIndex = null;
                        } else {
                          _expandedStudentIndex = index;
                        }
                      });
                    },
                    onEdit: () {
                      // TODO: Navigate to edit attendance
                    },
                    onDelete: () {
                      // TODO: Show delete confirmation
                    },
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentAttendanceProfile(
                            studentId: student.studentId,
                            studentName: student.studentName,
                            studentPhotoUuid: student.studentPhotoUuid,
                            roomName: student.roomName,
                            isSignedIn: student.hasSignIn,
                            isAbsent: !student.hasSignIn && student.expectedToday,
                            isExpectedToday: student.expectedToday,
                            isPresentToday: student.hasSignIn,
                            profileStatus: 'A',
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  List<StudentAttendanceCardData> _getFilteredStudents() {
    var filtered = _students;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((student) =>
              student.studentName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              student.roomName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply classroom filter
    if (_selectedClassrooms.isNotEmpty) {
      filtered = filtered
          .where((student) => _selectedClassrooms.contains(student.roomName))
          .toList();
    }

    // Apply tags filter
    if (_selectedTags.isNotEmpty) {
      filtered = filtered
          .where((student) => 
              student.tags != null && 
              student.tags!.any((tag) => _selectedTags.contains(tag)))
          .toList();
    }

    // Apply legend filter
    if (_statusLegendFilter != null) {
      if (_statusLegendFilter == 'Present') {
        filtered = filtered
            .where((student) =>
                student.expectedToday && student.hasSignIn)
            .toList();
      } else if (_statusLegendFilter == 'Absent') {
        filtered = filtered
            .where((student) =>
                student.expectedToday && !student.hasSignIn)
            .toList();
      } else if (_statusLegendFilter == 'Signed Out') {
        filtered = filtered
            .where((student) =>
                student.signOutTime != null && student.signOutTime!.isNotEmpty)
            .toList();
      } else if (_statusLegendFilter == 'Not Marked') {
        filtered = filtered
            .where((student) =>
                !student.hasSignIn && student.signInTime == null)
            .toList();
      }
    }

    // Apply sorting
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'name':
            comparison = a.studentName.compareTo(b.studentName);
            break;
          case 'classroom':
            comparison = a.roomName.compareTo(b.roomName);
            break;
          case 'expected':
            comparison = a.expectedToday.toString().compareTo(b.expectedToday.toString());
            break;
          case 'signIn':
            comparison = (a.signInTime ?? '').compareTo(b.signInTime ?? '');
            break;
          case 'signOut':
            comparison = (a.signOutTime ?? '').compareTo(b.signOutTime ?? '');
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    return filtered;
  }

  void _navigateToFilterScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          title: 'Filter Students',
          sections: [
            FilerSection(
              label: 'Classroom',
              hintText: 'Select classroom',
              items: ['Room 1', 'Room 2', 'Room 3', 'Room 4', 'Room 5'],
              initialSelected: _selectedClassrooms,
              isMultiSelectDropDown: true,
            ),
            FilerSection(
              label: 'Tags',
              hintText: 'Select tags',
              items: ['Full Day', 'Half Day', '5 Days', 'Photo Permission'],
              initialSelected: _selectedTags,
              isMultiSelectDropDown: true,
            ),
          ],
          onApply: (appliedFilters) {
            setState(() {
              _selectedClassrooms = appliedFilters['Classroom'] ?? [];
              _selectedTags = appliedFilters['Tags'] ?? [];
            });
            _loadDummyData();
          },
        ),
      ),
    );
  }

  void _showCreateAttendanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateAttendanceModal(
        onSave: (data) {
          // TODO: Save attendance data
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance created successfully')),
          );
          _loadDummyData();
        },
      ),
    );
  }
}

class _CreateAttendanceModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _CreateAttendanceModal({required this.onSave});

  @override
  State<_CreateAttendanceModal> createState() => _CreateAttendanceModalState();
}

class _CreateAttendanceModalState extends State<_CreateAttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  final _studentController = TextEditingController();
  final _classroomController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedMethod;
  final List<String> _methods = ['GPS', 'QR Code', 'Kiosk', 'Direct from App'];

  @override
  void dispose() {
    _studentController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: EdgeInsets.all(responsive.horizontalSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.title(
                'Create Attendance',
                style: TextStyle(
                  fontSize: responsive.isTablet ? 22 : 20,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.verticalSpacing),
              // Student field
              TextFormField(
                controller: _studentController,
                decoration: InputDecoration(
                  labelText: 'Student',
                  hintText: 'Select student',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a student';
                  }
                  return null;
                },
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              // Classroom field
              TextFormField(
                controller: _classroomController,
                decoration: InputDecoration(
                  labelText: 'Classroom',
                  hintText: 'Select classroom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a classroom';
                  }
                  return null;
                },
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              // Date picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: _selectedDate == null
                        ? 'Select date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              // Method dropdown
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Sign-in Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _methods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a method';
                  }
                  return null;
                },
              ),
              SizedBox(height: responsive.verticalSpacing),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: responsive.verticalSpacing / 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: AppText.body('Cancel'),
                    ),
                  ),
                  SizedBox(width: responsive.horizontalSpacing / 2),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() && _selectedDate != null) {
                            widget.onSave({
                              'student': _studentController.text,
                              'classroom': _classroomController.text,
                              'date': _selectedDate,
                              'method': _selectedMethod,
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: responsive.verticalSpacing / 2),
                        ),
                        child: AppText.body(
                          'Create',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
