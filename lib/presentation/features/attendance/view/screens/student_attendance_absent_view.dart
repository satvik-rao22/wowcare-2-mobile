import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/app/theme/colors.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize data if needed
  }

  // Method to load initial data (backend implementation removed)
  void _loadInitialData({bool reset = false}) {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData(reset: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildAbsentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentList() {
    // Placeholder UI - backend implementation removed
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Attendance Absent View',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Absent students data will be displayed here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
