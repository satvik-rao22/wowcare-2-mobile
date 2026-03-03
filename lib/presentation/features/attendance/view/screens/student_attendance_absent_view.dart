import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';

// Dummy data model for UI-only implementation
class _AbsentStudentModel {
  final String id;
  final String name;
  final String? photoUuid;
  final String roomName;
  final int absentDays;
  final DateTime startDate;
  final String absentTime;
  final String absentBy;
  final String? note;
  final int studentId;
  final int roomId;
  final int schoolId;

  _AbsentStudentModel({
    required this.id,
    required this.name,
    this.photoUuid,
    required this.roomName,
    required this.absentDays,
    required this.startDate,
    required this.absentTime,
    required this.absentBy,
    this.note,
    required this.studentId,
    required this.roomId,
    required this.schoolId,
  });
}

class StudentAttendanceAbsentView extends StatefulWidget {
  const StudentAttendanceAbsentView({
    super.key,
    this.contentOnly = false,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
  });

  final bool contentOnly;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;

  @override
  State<StudentAttendanceAbsentView> createState() => _StudentAttendanceAbsentViewState();
}

class _StudentAttendanceAbsentViewState extends State<StudentAttendanceAbsentView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  String? _selectedClassroom;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int? _expandedStudentIndex;

  // Pagination & list state
  bool _isInitialLoadingStudents = true;
  bool _isLoadingStudents = false;
  bool _isBackgroundFetchingStudents = false;
  int _studentsPage = 0;
  bool _studentsHasMore = true;
  final int _pageSize = 10;
  final List<_AbsentStudentModel> _absentStudents = [];

  List<String> classrooms = ['All'];
  bool isLoading = false;
  String? errorMessage;

  // Loading state for individual buttons
  final Map<int, bool> _loadingButtons = {};

  @override
  void initState() {
    super.initState();
    _initializeClassrooms();
    _initializeDefaultRange();
    _searchController.addListener(_onSearchChanged);
    
    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeClassrooms() {
    final fromWidget = (widget.staffAllowedClassrooms ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final fallback = <String>['Room 1', 'Room 2', 'Room 3'];
    classrooms = <String>[
      'All',
      ...((fromWidget.isNotEmpty) ? fromWidget : fallback),
    ];
  }

  void _initializeDefaultRange() {
    final now = DateTime.now();
    _rangeStart ??= DateTime(now.year, now.month, 1);
    _rangeEnd ??= DateTime(now.year, now.month + 1, 0);
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text;
    setState(() {
      _searchQuery = newQuery;
    });

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _triggerSearchReload();
    });
  }

  void _triggerSearchReload() {
      _loadAbsentStudents(reset: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingStudents ||
        _isInitialLoadingStudents) return;
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent > 200
        ? position.maxScrollExtent - 100
        : position.maxScrollExtent * 0.8;
    if (!_isBackgroundFetchingStudents &&
        _studentsHasMore &&
        position.pixels >= threshold) {
      setState(() => _isBackgroundFetchingStudents = true);
        _loadAbsentStudents(fromBackground: true);
    }
  }

  Future<void> _loadInitialData({bool reset = false, bool fromBackground = false}) async {
    await _loadAbsentStudents(reset: reset, fromBackground: fromBackground);
  }

  Future<void> _loadAbsentStudents({bool reset = false, bool fromBackground = false}) async {
    if (_isLoadingStudents && !reset) return;

    if (_rangeStart == null || _rangeEnd == null) {
      _initializeDefaultRange();
    }

    final from = _rangeStart!;
    final to = _rangeEnd!;

    setState(() {
      _isLoadingStudents = true;
      isLoading = true;
      errorMessage = null;

      if (reset || _studentsPage == 0) {
        if (reset || !fromBackground) {
        _isInitialLoadingStudents = true;
        }
        _isBackgroundFetchingStudents = false;
        if (reset) {
        _absentStudents.clear();
        }
      }

      if (reset) {
        _studentsPage = 0;
        _studentsHasMore = true;
      }
    });

    final apiClient = serviceLocator<ApiClient>().client;
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceAbsentView,
      ApiConstants.attendanceBaseUrl,
    );

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final classroomCodes = (_selectedClassroom != null &&
            _selectedClassroom != 'All' &&
            _selectedClassroom!.trim().isNotEmpty)
        ? <String>[_selectedClassroom!.trim()]
        : null;

    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromStr,
      'toAbsenceDate': toStr,
      'page': _studentsPage,
      'size': _pageSize,
      'sort': <String>['studentName,asc'],
    };

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }

    final trimmedSearch = _searchQuery.trim();
    if (trimmedSearch.isNotEmpty) {
      queryParameters['search'] = trimmedSearch;
      }

    debugPrint(
      'StudentAbsent API → GET $endpoint query=$queryParameters',
    );

    try {
      final response = await apiClient.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
      );

      debugPrint(
        'StudentAbsent API ← status=${response.statusCode} data=${response.data}',
      );

      if (!mounted) return;

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        setState(() {
          _isInitialLoadingStudents = false;
          _isLoadingStudents = false;
          isLoading = false;
          _isBackgroundFetchingStudents = false;
        });
        return;
      }

      final root = data['data'] as Map<String, dynamic>? ?? {};
      final content = root['content'] as List<dynamic>? ?? const [];
      final last = root['last'] as bool? ?? true;
      final number = root['number'] as int? ?? _studentsPage;

      String _parseTime(dynamic value) {
        if (value == null) return '';
        if (value is String) return value;
        if (value is Map<String, dynamic>) {
          final hour = value['hour'] as int? ?? 0;
          final minute = value['minute'] as int? ?? 0;
          final second = value['second'] as int? ?? 0;
          final h = hour.toString().padLeft(2, '0');
          final mStr = minute.toString().padLeft(2, '0');
          final sStr = second.toString().padLeft(2, '0');
          return '$h:$mStr:$sStr';
        }
        return value.toString();
      }

      final newData = content.asMap().entries.map<_AbsentStudentModel>((entry) {
        final indexInPage = entry.key;
        final e = entry.value;
        final m = e as Map<String, dynamic>;

        final absenceDateStr = m['absenceDate'] as String? ?? '';
        final absenceDate = absenceDateStr.isNotEmpty
            ? DateTime.tryParse(absenceDateStr) ?? DateTime.now()
            : DateTime.now();

        final classroomName = (m['classroomName'] as String?)?.trim() ?? '';
        final classroomCode = (m['classroomCode'] as String?)?.trim() ?? '';
        final roomDisplay =
            classroomName.isNotEmpty ? classroomName : classroomCode;

        return _AbsentStudentModel(
          id: (m['studentCode'] as String?) ?? '',
          name: (m['studentName'] as String?) ?? '',
          photoUuid: null,
          roomName: roomDisplay,
          absentDays: (m['absentDays'] as int?) ?? 0,
          startDate: absenceDate,
          absentTime: _parseTime(m['markedAbsentTime']),
          absentBy: (m['markedAbsentByName'] as String?) ?? '',
          note: (m['absenceNote'] as String?),
          // No numeric studentId available in this response - use a stable placeholder
          studentId: (number * _pageSize) + indexInPage,
          roomId: 0,
          schoolId: 0,
        );
      }).toList();

      setState(() {
        if (reset) {
          _absentStudents.clear();
        }
        _absentStudents.addAll(newData);
        _studentsHasMore = !last;
        _studentsPage = number + (newData.isNotEmpty ? 1 : 0);
        _isInitialLoadingStudents = false;
        _isLoadingStudents = false;
        isLoading = false;
        _isBackgroundFetchingStudents = false;
      });

      _updateClassroomsList(_absentStudents);
    } catch (error) {
      debugPrint('StudentAbsent API error: $error');
      if (!mounted) return;
      setState(() {
        _isInitialLoadingStudents = false;
        _isLoadingStudents = false;
        isLoading = false;
        _isBackgroundFetchingStudents = false;
        errorMessage = error.toString();
      });
    }
  }

  void _updateClassroomsList(List<_AbsentStudentModel> students) {
    final Set<String> uniqueClassrooms = {'All'};
    
    for (final student in students) {
      final room = student.roomName.trim();
      if (room.isNotEmpty) {
        uniqueClassrooms.add(room);
      }
    }

    final List<String> sortedClassrooms =
        uniqueClassrooms.where((room) => room != 'All').toList()..sort();
    classrooms = ['All', ...sortedClassrooms];
  }

  Future<void> _handleRefresh() async {
      await _loadAbsentStudents(reset: true);
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
    final filtered = _absentStudents;

    return CustomRefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: contentPadding.left,
          vertical: responsive.verticalSpacing / 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.verticalSpacing),
            // Filter section
            CustomSectionCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomSearchBar(
                          controller: _searchController,
                          hintText: 'Search Students',
                        ),
                      ),
                      SizedBox(width: responsive.horizontalSpacing / 2),
                      Expanded(
                        flex: 2,
                        child: CustomDropdown(
                          hintText: 'Select Classroom',
                          items: classrooms,
                          selectedItem: _selectedClassroom ?? 'All',
                          onSelect: (val) {
                            setState(() {
                              _selectedClassroom = val;
                            });
                              _loadAbsentStudents(reset: true);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomDateTimeField(
                    hasLabel: false,
                    isRangePicker: true,
                    fetchInitialTime: false,
                    initialDate: _rangeStart,
                    onRangeSelected: (start, end) {
                      setState(() {
                        _rangeStart = start;
                        _rangeEnd = end;
                      });
                        _loadAbsentStudents(reset: true);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            // Content section
            if (_isInitialLoadingStudents)
              Column(
                children: List.generate(
                  6,
                  (index) => StudentAbsentCardShimmer(
                    key: ValueKey('shimmer_$index'),
                  ),
                ),
              )
            else if (errorMessage != null)
              CustomSectionCard(
                padding: EdgeInsets.all(responsive.horizontalSpacing),
                backgroundColor: AppColors.errorColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.errorColor, size: 48),
                    SizedBox(height: responsive.verticalSpacing / 2),
                    AppText.body(
                      'Error: $errorMessage',
                      style: TextStyle(color: AppColors.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.verticalSpacing / 2),
                    ElevatedButton(
                      onPressed: () => _loadInitialData(reset: true),
                      child: AppText.body('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(responsive.verticalSpacing),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: AppColors.secondaryColor.withOpacity(0.5),
                      ),
                      SizedBox(height: responsive.verticalSpacing / 2),
                      AppText.body(
                        _absentStudents.isEmpty
                            ? 'No absent students found'
                            : 'No students match your filters',
                        style: TextStyle(color: AppColors.secondaryColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ...filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    return _buildAbsentStudentCard(student, index);
                  }).toList(),
                  // Pagination loader
                  if (_isLoadingStudents &&
                      _studentsHasMore &&
                      _studentsPage > 0 &&
                      !_isInitialLoadingStudents)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: responsive.verticalSpacing),
                      child: const PrimaryCircularLoader(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentStudentCard(_AbsentStudentModel student, int index) {
    final responsive = ResponsiveHelper(context);
    final bool isExpanded = _expandedStudentIndex == index;
    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final spacing = responsive.isTablet ? 16.0 : 14.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedStudentIndex == index) {
            _expandedStudentIndex = null;
          } else {
            _expandedStudentIndex = index;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isTablet ? 16 : 12,
          vertical: responsive.isTablet ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo
                DocumentImageWidget(
                  fileUuid: student.photoUuid ?? '',
                  size: avatarSize,
                  name: student.name,
                  fontSize: responsive.isTablet ? 18 : 16,
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: AppText.body(
                    student.name,
                    style: TextStyle(
                      fontSize: responsive.labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Flexible(
                  child: AppText.body(
                    'Absent: ${student.absentDays} days',
                    style: TextStyle(
                      fontSize: responsive.isTablet ? 15 : 14,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildDetailRow(responsive, 'Classroom', student.roomName),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                responsive,
                'Absent Date',
                DateFormat('MMM dd, yyyy').format(student.startDate),
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(responsive, 'Absent Time', student.absentTime),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(responsive, 'Marked By', student.absentBy),
                SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                responsive,
                'Absent Note',
                (student.note != null && student.note!.trim().isNotEmpty)
                    ? student.note!.trim()
                    : '-',
                      ),
              SizedBox(height: responsive.verticalSpacing / 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _loadingButtons[student.studentId] == true
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : CustomCancelButton(
                          cancelButtonLabel: 'View',
                          onPressedCancel: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentAttendanceProfile(
                                  studentCode: student.id,
                                  studentId: student.studentId,
                                  studentName: student.name,
                                  studentPhotoUuid: student.photoUuid,
                                  roomName: student.roomName,
                                  isSignedIn: false,
                                  isAbsent: true,
                                  isExpectedToday: true,
                                  isPresentToday: false,
                                  profileStatus: 'A',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ResponsiveHelper responsive, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: AppText.small(
            label,
            style: TextStyle(color: AppColors.secondaryColor.withOpacity(0.6)),
          ),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: AppText.value(
            value,
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
