# PRODUCTION-READY REPORTS API INTEGRATION PLAN
**Date**: 2026-06-05  
**Status**: Architecture Review + Planning Phase  
**Total Estimated Effort**: 40-50 hours across 8 phases  

---

## EXECUTIVE SUMMARY

### Current State
✅ **Foundation Ready**:
- BLoC/Cubit state management architecture established
- 14 report screens with format selector & error handling (Phase 3.3 ✅)
- Repository pattern with caching implemented
- Remote datasource layer with API routing
- DTO/Model pattern standardized
- Environment switching (UAT/Local) infrastructure in place

❌ **Outstanding Requirements**:
- API URL refactoring (hardcoded endpoints need centralization)
- Student Attendance Report Generate API integration
- Recent reports APIs (4 distinct endpoints) not fully implemented
- Tab auto-switch on successful generation not implemented
- Tab performance optimizations (AutomaticKeepAliveClientMixin, IndexedStack) missing
- Download flow not integrated with recent reports
- Staff Attendance API issue investigation needed (possible backend data mismatch)

### Architecture Decision
**NO NEW ARCHITECTURE** — All changes follow existing patterns:
- Clean Architecture (Domain/Data/Presentation layers)
- Repository pattern for data access
- Cubit for state management
- Dependency injection via GetIt service locator
- DTOs for API serialization, Entities for domain logic
- Provider pattern for UI-layer state when needed

---

## PHASE 1: ARCHITECTURE REVIEW & ANALYSIS

### 1.1 Current API Path Organization

**Status**: ✅ Analyzed

**Key Findings**:
- `ApiPaths` class in `lib/core/util/api_paths.dart` is the single source of truth
- Paths use microservice segmentation: `/api/v1/{resource-segment}/...`
- `ApiMicroservices` enum routes paths to correct base URLs
- `ApiPathsUat` provides UAT-specific routing overrides
- Attendance endpoints map to `ApiMicroservices.attendance`

**Current Hardcoded Issues** (to refactor):
```dart
// In reports_remote_datasource_impl.dart - line 21, 28, 33, 36
// Using inline string paths instead of ApiPaths constants
'/api/v1/attendance/student-attendance/reports/generate'
'/api/v1/attendance/staff-attendance/reports/generate'
'/api/v1/staff/staff/reports/generate'
'/api/v1/student/student/reports/generate'
```

**Refactoring Solution**:
Move to `ApiPaths` class with proper pattern:
```dart
// In ApiPaths class
static const String studentAttendanceReportsGenerate = 
    '/api/v1/attendance/student-attendance/reports/generate';
static const String staffAttendanceReportsGenerate = 
    '/api/v1/attendance/staff-attendance/reports/generate';
static const String studentReportsGenerate = 
    '/api/v1/student/student/reports/generate';
static const String staffReportsGenerate = 
    '/api/v1/staff/staff/reports/generate';
```

### 1.2 Provider/State Management Pattern

**Status**: ✅ Analyzed

**Architecture**:
- **Cubit** (ReportsCubit) owns business logic and state
- **Repository** (ReportsRepository/ReportsRepositoryImpl) owns caching & data orchestration
- **RemoteDataSource** (ReportsRemoteDataSourceImpl) handles raw API calls
- **UseCase** (GenerateReportUseCase, GetRecentReportsUseCase) bridges Cubit to Repository

**Flow**:
```
Screen -> BlocListener/BlocSelector -> 
  ReportsCubit.generateReport() -> 
    GenerateReportUseCase -> 
      ReportsRepository -> 
        ReportsRemoteDataSource (Dio)
```

**State Fields** (ReportsState):
- `isGenerating`: bool (generation in progress)
- `generatedReport`: ReportEntity? (last generated)
- `recentReports`: List<ReportMetadataEntity> (merged from all 4 sources)
- `generationError`: String? (error message for snackbar)
- `isLoadingRecent`: bool (recent reports loading)
- `recentError`: String? (fetch error)

### 1.3 DTO/Model Patterns

**Status**: ✅ Analyzed

**Pattern**:
```
Remote API Response (JSON)
        ↓
    DTO/Model (fromJson, toJson)
        ↓
    Entity (domain logic, no serialization)
```

**Examples**:
- `ReportResponseModel` (DTO) → `ReportEntity` (domain)
- `RecentReportModel` (DTO) → `ReportMetadataEntity` (domain)

**Standardization**:
- All models use `fromJson()` factory with null coalescing
- All models have `toJson()` for caching
- All models have conversion method to entity: `toEntity()`
- All entities are `Equatable` for state comparison

### 1.4 Report Type Handling

**Status**: ✅ Analyzed

**Enum Definition** (`report_type.dart`):
```dart
enum ReportType {
  studentDailyAttendance,      // STUDENT_DAILY_ATTENDANCE
  studentAbsent,               // STUDENT_ABSENT
  studentAttendancePerStudent, // STUDENT_ATTENDANCE_PER_STUDENT
  studentsAndFamily,           // STUDENTS_AND_FAMILY
  schoolImmunization,          // IMMUNIZATION
  studentEmergencyContact,     // EMERGENCY_CONTACTS
  
  staffAbsent,                 // STAFF_ABSENT
  staffAttendancePerWeek,      // STAFF_ATTENDANCE_PER_WEEK
  staffDetails,                // STAFF_DETAILS
  
  annualStateImmunization,     // ANNUAL_STATE_IMMUNIZATION
  billingPlan,                 // BILLING_PLAN
  billingTransaction,          // BILLING_TRANSACTION
}
```

### 1.5 Caching Strategy

**Status**: ✅ Analyzed

**Implementation**:
- CacheManager in `core/util/cache_manager.dart`
- Cache keys follow pattern: `{feature}:{resource}:{identifier}`
- Duration: 30 minutes for generated/recent reports
- Hit: Return cached JSON, miss: Fetch API

**Applied To**:
- Generated reports (30 min cache, per params)
- Recent reports (30 min cache, per source type)
- Tags (30 min cache)

---

## PHASE 2: API URL REFACTORING

### 2.1 New ApiPaths Constants

**Files to Modify**:
- `lib/core/util/api_paths.dart`

**New Constants** (after line 612, in Attendance section):
```dart
// —— Reports (Attendance MS) ——

/// POST generate student attendance report
static const String studentAttendanceReportsGenerate = 
    '/api/v1/attendance/student-attendance/reports/generate';

/// GET recent student attendance reports
static const String studentAttendanceReportsRecent = 
    '/api/v1/attendance/student-attendance/reports/recent';

/// POST generate staff attendance report
static const String staffAttendanceReportsGenerate = 
    '/api/v1/attendance/staff-attendance/reports/generate';

/// GET recent staff attendance reports
static const String staffAttendanceReportsRecent = 
    '/api/v1/attendance/staff-attendance/reports/recent';

// —— Reports (Student MS) ——

/// GET recent student reports (students & family, incident, etc.)
static const String studentReportsRecent = 
    '/api/v1/student/student/reports/recent';

/// POST generate student reports (students & family, incident, etc.)
static const String studentReportsGenerate = 
    '/api/v1/student/student/reports/generate';

// —— Reports (Staff MS) ——

/// GET recent staff reports (staff directory, schedule, etc.)
static const String staffReportsRecent = 
    '/api/v1/staff/staff/reports/recent';

/// POST generate staff reports (staff directory, schedule, etc.)
static const String staffReportsGenerate = 
    '/api/v1/staff/staff/reports/generate';
```

**UAT Override Check** (`lib/core/util/api_paths_uat.dart`):
- Verify all 8 endpoints map to correct microservices
- Confirm `attendance` segment → `ApiMicroservices.attendance`
- Confirm `student` segment → `ApiMicroservices.student`
- Confirm `staff` segment → `ApiMicroservices.staff`
- No hardcoded differences needed; UAT routing automatic

### 2.2 RemoteDataSource Update

**File**: `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart`

**Changes**:
```dart
// BEFORE (hardcoded)
'/api/v1/attendance/student-attendance/reports/generate'

// AFTER (use ApiPaths)
ApiPaths.studentAttendanceReportsGenerate
ApiPaths.url(ApiPaths.studentAttendanceReportsGenerate)
```

**Pattern**:
```dart
// Use ApiPaths.url() to get full URL with microservice routing
final response = await _dio.post<Map<String, dynamic>>(
  ApiPaths.url(ApiPaths.studentAttendanceReportsGenerate),
  data: requestBody,
);
```

---

## PHASE 3: STUDENT ATTENDANCE REPORT GENERATE API

### 3.1 Requirements Analysis

**Endpoint**: `POST /api/v1/attendance/student-attendance/reports/generate`

**Request Payload**:
```json
{
  "reportType": "STUDENT_DAILY_ATTENDANCE",
  "schoolCode": "SCH001",
  "organizationCode": "ORG001",
  "generatedBy": "USER001",
  "roomCodes": ["ROOM1", "ROOM2"],
  "date": "2026-06-05",
  "format": "PDF"  // or "XLSX"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "reportId": "RPT123",
    "assetCode": "AST456",
    "fileName": "student_attendance_2026-06-05.pdf",
    "reportType": "STUDENT_DAILY_ATTENDANCE",
    "generatedAt": "2026-06-05T10:30:00Z"
  }
}
```

### 3.2 Current Implementation Status

**✅ Already Implemented**:
- ReportRequestParams with format field
- RemoteDataSource method: `generateReport()`
- Repository method: `generateReport()`
- Cubit method: `generateReport()`
- UseCase: `GenerateReportUseCase`
- All 14 screens with format selector & error handling (Phase 3.3)

**Verification Required**:
1. Confirm all report screens pass correct `reportType` enum
2. Verify `toRequestBody()` converts enum to backend string
3. Test date/roomCodes serialization
4. Validate payload includes all required fields from storage

### 3.3 Integration Validation Checklist

**Domain Layer** (`report_request_params.dart`):
- [ ] ReportRequestParams has `format` getter → returns format value
- [ ] toRequestBody() includes `format` field
- [ ] Example: `{'format': _format, ...}`

**Data Layer**:
- [ ] RemoteDataSource.generateReport() uses ApiPaths constant
- [ ] Request body includes schoolCode, organizationCode, generatedBy from storage
- [ ] Response model correctly maps to ReportResponseModel

**Presentation Layer**:
- [ ] StudentDailyAttendanceReportScreen passes format to params
- [ ] All report screens call `cubit.generateReport(reportParams)`
- [ ] Cubit emits loading state before API call
- [ ] On success: emit report + call `loadRecentReports()`
- [ ] On error: emit error message for snackbar

---

## PHASE 4: RECENT REPORTS APIs (4 Sources)

### 4.1 API Structure Analysis

**Four Distinct Endpoints**:

#### A. Student Attendance Reports
- **Endpoint**: `GET /api/v1/attendance/student-attendance/reports/recent`
- **Query Params**: `?schoolCode=...`
- **Report Types**: 
  - STUDENT_DAILY_ATTENDANCE
  - STUDENT_ATTENDANCE_PER_STUDENT
  - STUDENT_ABSENT
- **Response**:
```json
{
  "reports": [
    {
      "reportId": "RPT123",
      "reportType": "STUDENT_DAILY_ATTENDANCE",
      "generatedAt": "2026-06-05T10:30:00Z",
      "assetCode": "AST456",
      "fileName": "..."
    }
  ]
}
```

#### B. Staff Attendance Reports  
- **Endpoint**: `GET /api/v1/attendance/staff-attendance/reports/recent`
- **Query Params**: `?schoolCode=...`
- **Report Types**:
  - STAFF_ATTENDANCE_PER_WEEK
  - STAFF_ABSENT
  - STAFF_SCHEDULE (if available)
- **Response**: Same structure as above

#### C. Staff Reports (Directory)
- **Endpoint**: `GET /api/v1/staff/staff/reports/recent`
- **Query Params**: `?schoolCode=...`
- **Report Types**:
  - STAFF_DETAILS
- **Response**: Same structure

#### D. Student Reports (Management)
- **Endpoint**: `GET /api/v1/student/student/reports/recent`
- **Query Params**: `?schoolCode=...`
- **Report Types**:
  - STUDENTS_AND_FAMILY
  - EMERGENCY_CONTACTS
  - SCHOOL_IMMUNIZATION
- **Response**: Same structure

### 4.2 Current Implementation Status

**✅ Already In Place**:
- RemoteDataSource has all 4 methods (implemented but hardcoded URLs)
- Repository orchestrates all 4 in `getRecentReports()`
- Models: RecentReportModel (DTO) → ReportMetadataEntity
- Cubit: `loadRecentReports()` method exists
- Caching: 30-minute cache per source type

**❌ Issues to Fix**:
1. Hardcoded URLs in datasource (use ApiPaths)
2. No individual endpoints in ApiPaths (add 8 constants)
3. Staff Attendance API may return wrong data (INVESTIGATION NEEDED)

### 4.3 Staff Attendance Reports Data Issue

**Investigation Required**:

**Symptom**: 
- Staff Attendance Reports tab possibly showing student attendance data
- Need to determine root cause

**Possible Causes**:
1. Backend `/api/v1/attendance/staff-attendance/reports/recent` returns student data
2. Frontend calls wrong endpoint
3. Request payload has wrong parameters
4. Response mapping incorrectly interprets report type

**Investigation Steps**:
1. Check network logs: actual endpoint called?
2. Verify response from backend has correct `reportType` values
3. Confirm FilterRecentReportsByType logic separates correctly
4. Test with mock data to isolate issue

**Diagnosis Method**:
```dart
// In generated_reports_list.dart, add debug logging
final staffAttendanceReports = recentReports
    .where((r) => r.reportType == ReportType.staffAttendancePerWeek ||
                  r.reportType == ReportType.staffAbsent)
    .toList();

debugPrint('Staff Attendance Reports Found: ${staffAttendanceReports.length}');
for (final report in staffAttendanceReports) {
  debugPrint('Report: ${report.reportType.backendValue} - ${report.fileName}');
}
```

---

## PHASE 5: GENERATED REPORTS TAB AUTO-SWITCH

### 5.1 Current Behavior (Broken)

**Issue**:
```
User Generates Report → Success Snackbar → Manual switch to Generated tab required
```

**Expected Behavior**:
```
User Generates Report 
    ↓
Success (report.reportId generated)
    ↓
Auto-switch to Generated Reports tab
    ↓
Auto-load recent reports
    ↓
Show newly generated report at top
    ↓
No manual refresh needed
```

### 5.2 Implementation Strategy

**Architecture**:
The ReportsScreen is the tab container; individual screens are tab bodies.

**Key Insight**:
- Generate button exists in report form screens (nested)
- Tab switching controlled by ReportsScreen (parent)
- Need to communicate "generation success" from child to parent

**Solution**:
Use TabController and ReportsCubit state to coordinate.

### 5.3 Technical Implementation

**File**: `lib/presentation/features/reports/view/reports_screen.dart`

**Modifications**:
```dart
class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _setupGenerationListener();
  }
  
  void _setupGenerationListener() {
    // Listen to cubit for successful generation
    // Switch to Generated Reports tab (index 1)
    // Trigger recent reports refresh
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

**Pattern** (adapted from existing code):
```dart
@override
Widget build(BuildContext context) {
  return BlocListener<ReportsCubit, ReportsState>(
    // Only trigger when a new report is generated (not null after being null)
    listenWhen: (prev, curr) => 
        curr.generatedReport != null && prev.generatedReport == null,
    listener: (ctx, state) {
      // Show success snackbar (already done in form screen)
      
      // Switch to Generated Reports tab
      _tabController.animateTo(1); // Generated Reports is index 1
      
      // Recent reports refresh already triggered by cubit
      // (loadRecentReports() called after generation)
    },
    child: // ... rest of UI
  );
}
```

### 5.4 Implementation Checklist

**ReportsScreen Changes**:
- [ ] Add TabController field
- [ ] Initialize with 5 tabs
- [ ] Add BlocListener for generatedReport state
- [ ] Switch tab on success: `_tabController.animateTo(1)`
- [ ] Preserve tab scroll position when switching back

**Recent Reports Screen Changes**:
- [ ] Load recent reports on initState
- [ ] Listen to cubit recentReports state
- [ ] Display newly generated report at top (sort by date desc)
- [ ] No manual refresh button needed (auto-loads after generation)

**Performance Consideration**:
- Avoid rebuilding entire screen on tab switch
- Use `AutomaticKeepAliveClientMixin` (see Phase 6)

---

## PHASE 6: TAB PERFORMANCE OPTIMIZATIONS

### 6.1 Current Issues

**Problem**:
- Switching tabs reloads all data (API calls on every switch)
- Loses scroll position
- Loses filter state
- Poor perceived performance

**Desired Behavior**:
- Switch tabs instantly (cached state preserved)
- Scroll position maintained
- Filters preserved
- Form state preserved
- No duplicate API calls

### 6.2 Solution Architecture

**Use `IndexedStack` + `AutomaticKeepAliveClientMixin`**:

```dart
// In ReportsScreen, replace TabBarView with IndexedStack
IndexedStack(
  index: _tabController.index,
  children: [
    GenerateTab(),      // Wrapped with AutomaticKeepAliveClientMixin
    GeneratedReportsTab(),
    StudentReportsTab(),
    StaffReportsTab(),
    ComplianceTab(),
  ],
)
```

### 6.3 Implementation Details

**File**: `lib/presentation/features/reports/view/reports_screen.dart`

**Pattern for Each Tab Screen**:
```dart
class GenerateTabScreen extends StatefulWidget {
  const GenerateTabScreen({super.key});
  
  @override
  State<GenerateTabScreen> createState() => _GenerateTabScreenState();
}

class _GenerateTabScreenState extends State<GenerateTabScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;  // Keep alive when switched away
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required when using AutomaticKeepAliveClientMixin
    return // ... UI
  }
}
```

**Apply to All Tab Bodies**:
- [ ] GenerateTab (form fields preserved)
- [ ] GeneratedReportsTab (scroll position preserved)
- [ ] StudentReportsTab (filter state preserved)
- [ ] StaffReportsTab (filter state preserved)
- [ ] ComplianceTab (form data preserved)

### 6.4 Horizontal Swipe Support

**Implementation**:
Use GestureDetector or custom PageView wrapper to detect swipes.

```dart
GestureDetector(
  onHorizontalDragEnd: (details) {
    if (details.primaryVelocity! < 0) {
      // Swipe left → next tab
      _tabController.animateTo(_tabController.index + 1);
    } else {
      // Swipe right → previous tab
      _tabController.animateTo(_tabController.index - 1);
    }
  },
  child: TabBar(
    controller: _tabController,
    tabs: [/* ... */],
  ),
)
```

**Checklist**:
- [ ] Detect left swipe → next tab
- [ ] Detect right swipe → previous tab
- [ ] Boundary check (first/last tab)
- [ ] Test on both iOS and Android

---

## PHASE 7: DOWNLOAD IMPLEMENTATION

### 7.1 Current Download Infrastructure

**Existing Implementation** (`shared/common/views/pdf_view.dart`):
- ✅ Request storage permissions (Android 13+ compatible)
- ✅ Download to device (Android: /storage/emulated/0/Download, fallback to app docs)
- ✅ Handle permission denied
- ✅ Show snackbar on success/failure

### 7.2 Integration with Recent Reports

**Flow**:
```
Recent Reports List
    ↓
Download Button (in generated_report_card.dart)
    ↓
Get assetCode from ReportMetadataEntity
    ↓
Fetch File (asset service or API)
    ↓
Show Downloading state
    ↓
Save to device
    ↓
Show Download Complete
```

### 7.3 New Components Needed

**A. Download Service** (`lib/data/services/report_download_service.dart`):
```dart
class ReportDownloadService {
  Future<Uint8List> downloadReportFile({
    required String assetCode,
    required String fileName,
  }) async {
    // Fetch from asset service or document API
    // Return bytes
  }
}
```

**B. Download Cubit** (optional, for download state):
```dart
class ReportDownloadCubit extends Cubit<ReportDownloadState> {
  Future<void> downloadReport({
    required String assetCode,
    required String fileName,
  }) async {
    // Show downloading state
    // Fetch bytes
    // Save file
    // Show completed/error
  }
}
```

**C. Updated Report Card Widget** (`generated_report_card.dart`):
```dart
class GeneratedReportCard extends StatelessWidget {
  final ReportMetadataEntity report;
  
  void _onDownloadTap() {
    // Call service or cubit to download
    // Show loading overlay
    // Save when complete
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(report.fileName ?? 'Report'),
          Text(report.reportType.displayName),
          Text(DateFormatter.format(report.generatedAt)),
          Row(
            children: [
              ElevatedButton(
                onPressed: _onDownloadTap,
                child: const Text('Download'),
              ),
              // View button hidden for now (requirement #4)
            ],
          ),
        ],
      ),
    );
  }
}
```

### 7.4 File Format Handling

**Supported Formats**:
- PDF: Use existing pdf_view.dart download logic
- XLSX: Similar logic, different MIME type

**Mapping**:
```dart
String getMimeType(String format) => switch(format) {
  'PDF' => 'application/pdf',
  'XLSX' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  _ => 'application/octet-stream',
};

String getFileExtension(String format) => switch(format) {
  'PDF' => 'pdf',
  'XLSX' => 'xlsx',
  _ => 'bin',
};
```

### 7.5 Integration Checklist

**Data Layer**:
- [ ] Create ReportDownloadService
- [ ] Implement fetchReportFile() using asset API or document API
- [ ] Handle different MIME types
- [ ] Return Uint8List

**Presentation Layer**:
- [ ] Add Download button to GeneratedReportCard
- [ ] Show downloading state (spinner/progress)
- [ ] Call service on download tap
- [ ] Save file using existing permission logic
- [ ] Show success/error snackbar

**Files to Modify/Create**:
- [ ] Create: `lib/data/services/report_download_service.dart`
- [ ] Modify: `lib/presentation/features/reports/widgets/generated_report_card.dart`
- [ ] Modify: `lib/data/features/reports/datasources/reports_remote_datasource.dart` (add fetchReportFile method)

---

## PHASE 8: ERROR HANDLING & VALIDATION

### 8.1 API Error Mapping

**Implementation** (`core/util/api_error_handler.dart`):

**Existing Pattern**:
```dart
class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    // Map Dio errors to user-friendly messages
  }
}
```

**HTTP Status Codes**:
| Code | Meaning | User Message |
|------|---------|--------------|
| 400 | Invalid request | "Invalid report parameters" |
| 401 | Unauthorized | "Session expired, please log in again" |
| 403 | Forbidden | "You don't have permission to generate this report" |
| 404 | Not found | "Report endpoint not found" |
| 500 | Server error | "Server error, please try again" |
| 503 | Service unavailable | "Service temporarily unavailable" |

### 8.2 Validation Rules

**Report Form Validation**:

| Field | Rule | Error Message |
|-------|------|---------------|
| Format | Required, must be PDF or XLSX | "Please select an export format" |
| Date | Required for date-based reports | "Date is required" |
| Date Range | fromDate <= toDate | "End date must be after start date" |
| Rooms/Students | At least one required | "Please select at least one {item}" |
| Frequency | Required for per-X reports | "Please select a frequency" |

**Implementation**:
```dart
bool _isFormValid() {
  return _selectedFormat != null &&  // Format required
         _selectedDate != null &&    // Date required
         _selectedRooms.isNotEmpty;   // At least one room
}
```

### 8.3 Empty States & Loading States

**Loading State**:
- [ ] Show shimmer/skeleton while loading recent reports
- [ ] Use existing ShimmerLoading widget
- [ ] Show "Loading reports..." message

**Empty State**:
- [ ] No recent reports: "No reports generated yet"
- [ ] Button: "Generate first report"

**Error State**:
- [ ] Network error: Show retry button
- [ ] Display error message from backend
- [ ] Log error for debugging

**Implementation**:
```dart
BlocSelector<ReportsCubit, ReportsState, (bool, List<ReportMetadataEntity>)>(
  selector: (state) => (state.isLoadingRecent, state.recentReports),
  builder: (context, data) {
    final (isLoading, reports) = data;
    
    if (isLoading) return _buildLoadingShimmer();
    if (reports.isEmpty) return _buildEmptyState();
    return _buildReportsList(reports);
  },
)
```

### 8.4 Error Handling Checklist

**Data Layer**:
- [ ] Catch Dio exceptions in datasource
- [ ] Map to domain Failure type
- [ ] Return fold result from usecase

**Repository Layer**:
- [ ] Catch datasource exceptions
- [ ] Propagate via Result/Either
- [ ] Invalidate cache on 401/403

**Cubit Layer**:
- [ ] Emit error state on failure
- [ ] Preserve error message
- [ ] Don't emit loading state on cached hits

**Presentation Layer**:
- [ ] Listen to error changes
- [ ] Show snackbar with message
- [ ] Allow retry action
- [ ] Don't crash on unexpected errors

---

## DELIVERABLES BY PHASE

### Phase 1: Architecture Review ✅
- [x] API path organization analysis
- [x] Provider/state management review
- [x] DTO/Model pattern validation
- [x] Report type enum verification
- [x] Caching strategy assessment

**Deliverable**: This document

---

### Phase 2: API URL Refactoring
**Deliverable**: 
- Updated `ApiPaths` class with 8 new constants
- Updated `ApiPathsUat` validation
- Updated `ReportsRemoteDataSourceImpl` to use constants

**Files**:
- `lib/core/util/api_paths.dart` (add 8 constants)
- `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart` (replace hardcoded)

**Time**: 1-2 hours

---

### Phase 3: Student Attendance Report Generate API
**Deliverable**:
- Validate full integration (should already work from Phase 3.3)
- Create unit tests for payload generation
- Document expected responses
- Add network request logging

**Files**:
- `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart` (verification)
- Test files (new unit tests)

**Time**: 2-3 hours

---

### Phase 4: Recent Reports APIs
**Deliverable**:
- 8 new ApiPaths constants integrated
- All 4 datasource methods updated to use constants
- Staff Attendance API issue diagnosed
- Comprehensive debug logging added

**Files**:
- `lib/core/util/api_paths.dart` (add 4 more recent endpoints)
- `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart` (update all methods)
- `lib/presentation/features/reports/widgets/generated_reports_list.dart` (add filtering)

**Time**: 3-4 hours

---

### Phase 5: Generated Reports Tab Auto-Switch
**Deliverable**:
- TabController integrated in ReportsScreen
- BlocListener auto-switches tab on generation success
- GeneratedReportsScreen auto-loads recent reports
- No manual refresh needed

**Files**:
- `lib/presentation/features/reports/view/reports_screen.dart` (add TabController, BlocListener)
- `lib/presentation/features/reports/view/generated_reports_screen.dart` (ensure auto-load)
- `lib/presentation/features/reports/cubit/reports_cubit.dart` (verify loadRecentReports call)

**Time**: 3-4 hours

---

### Phase 6: Tab Performance Optimizations
**Deliverable**:
- IndexedStack replaces TabBarView
- AutomaticKeepAliveClientMixin on all tab screens
- Horizontal swipe support working
- Zero data reload on tab switch

**Files**:
- `lib/presentation/features/reports/view/reports_screen.dart` (IndexedStack, swipe)
- All tab screen files (add AutomaticKeepAliveClientMixin)

**Time**: 4-5 hours

---

### Phase 7: Download Implementation
**Deliverable**:
- Download Service created
- Report Card widgets have Download button
- File saved to device correctly
- Loading/complete states shown
- Both PDF and XLSX formats supported

**Files**:
- Create: `lib/data/services/report_download_service.dart`
- Modify: `lib/presentation/features/reports/widgets/generated_report_card.dart`
- Modify: `lib/data/features/reports/datasources/reports_remote_datasource.dart`

**Time**: 5-6 hours

---

### Phase 8: Error Handling & Validation
**Deliverable**:
- All API errors mapped to user messages
- Form validation on all 14 screens
- Empty/Loading/Error states implemented
- Network error retry support
- Comprehensive error logging

**Files**:
- `lib/core/util/api_error_handler.dart` (update error mapping)
- All report screen files (add validation)
- `lib/presentation/features/reports/widgets/generated_reports_list.dart` (empty/loading states)

**Time**: 4-5 hours

---

## CRITICAL ISSUES & RISKS

### Issue 1: Staff Attendance Reports Data Mismatch
**Status**: 🔍 Investigation Required

**Symptom**: Staff Attendance tab possibly showing student data

**Root Cause** (To Determine):
- Backend bug (returns wrong report type)
- Frontend routing bug (calls wrong endpoint)
- Filtering bug (mixes report types)

**Resolution**:
1. Add network logging to see actual endpoint + response
2. Check report type values returned in response
3. Verify filtering logic in generated_reports_list.dart
4. Coordinate with backend team if needed

**Timeline**: Phase 4

---

### Issue 2: UAT Environment Switching
**Status**: ✅ Analysis Complete

**Concern**: Will API URLs work in UAT?

**Verification**:
- ApiPathsUat.microserviceKeyFromPath() correctly identifies `attendance`, `student`, `staff`
- Each microservice maps to correct UAT gateway segment
- No hardcoded URLs survive refactoring

**Assurance**: 
- Existing attendance endpoints already use this pattern (attendance-settings)
- Student/Staff endpoints already in ApiPaths
- No new path pattern needed

**Timeline**: Automatic once Phase 2 complete

---

### Issue 3: Recent Reports Deduplication
**Status**: ✅ Already Handled

**Concern**: Same report shown twice from multiple sources?

**Current Solution** (in repository):
```dart
// Deduplicate by reportId (keep last occurrence)
final unique = <String, ReportMetadataEntity>{};
for (final report in allReports) {
  final entity = _mapRecentModelToEntity(report);
  unique[entity.reportId] = entity;
}
```

**Validation**: 
- Test with reports in multiple sources
- Confirm only one copy shown
- Most recent shown first

---

### Issue 4: Tab Index Out of Bounds
**Status**: ✅ Mitigated

**Concern**: TabController.animateTo(1) if tabs not initialized?

**Solution**:
- Ensure TabController created in initState
- Check bounds before animating: `if (_tabController.index != 1)`
- Use SafeTabSwitch helper function

---

## TESTING STRATEGY

### Unit Tests
**Files**:
- Test all report parameter classes (format field inclusion)
- Test error mapping (ApiErrorHandler)
- Test DTO serialization/deserialization
- Test cache key generation

**Coverage**: 80%+ per file

### Integration Tests
**Scenarios**:
1. Generate report → Recent reports auto-refresh → Tab switch successful
2. Download report → File saved → Success shown
3. Network error → Error message shown → Retry works
4. Empty state → No recent reports → Button enabled

**Coverage**: Happy path + error paths

### Manual Testing Checklist

**Environment**:
- [ ] Test on LOCAL environment
- [ ] Test on UAT environment
- [ ] Test on both iOS and Android

**Generate Flow**:
- [ ] Select report type
- [ ] Fill form fields
- [ ] Select format (PDF/XLSX)
- [ ] Tap Generate
- [ ] Loading state shown
- [ ] Success snackbar
- [ ] Tab auto-switch to Generated
- [ ] Recent reports loaded
- [ ] Generated report visible at top

**Download Flow**:
- [ ] Recent report visible
- [ ] Download button responsive
- [ ] Downloading state shown
- [ ] File saved to device
- [ ] Can open file
- [ ] Supports both PDF and XLSX

**Error Flow**:
- [ ] Invalid form → disabled Generate button
- [ ] Network error → error snackbar
- [ ] No permission → retry option
- [ ] Server error (500) → user message

**Tab Performance**:
- [ ] Switch tabs quickly (no lag)
- [ ] Scroll position preserved
- [ ] Filter state preserved
- [ ] Horizontal swipe works

---

## IMPLEMENTATION TIMELINE

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| 1 | Architecture Review | 2 hours | ✅ Complete |
| 2 | API URL Refactoring | 1.5 hours | ⏳ Pending |
| 3 | Student Attendance Generate | 2.5 hours | ⏳ Pending |
| 4 | Recent Reports APIs | 3.5 hours | ⏳ Pending |
| 5 | Tab Auto-Switch | 3.5 hours | ⏳ Pending |
| 6 | Tab Performance | 4.5 hours | ⏳ Pending |
| 7 | Download Implementation | 5.5 hours | ⏳ Pending |
| 8 | Error Handling | 4.5 hours | ⏳ Pending |
| **Integration Testing** | **Validation** | **5 hours** | ⏳ Pending |
| **Documentation** | **Update comments + README** | **2 hours** | ⏳ Pending |
| **TOTAL** | | **34-35 hours** | |

---

## NEXT STEPS

### Immediate Actions
1. ✅ **Architecture Review Complete** (this document)
2. ⏳ **Begin Phase 2: API URL Refactoring**
   - Add 8 constants to ApiPaths
   - Update RemoteDataSourceImpl
   - Verify UAT routing
   - Run existing tests to ensure no breakage

### Decision Points Required
1. **Staff Attendance Data Issue**: 
   - Investigate in Phase 4
   - Decide: Backend fix or frontend filter?
   - Timeline impact?

2. **Download Feature Scope**:
   - Implement in this phase?
   - Or defer to future phase?
   - API available for file fetch?

3. **Tab Swipe Support**:
   - Required for MVP?
   - Nice-to-have?
   - Affects timeline?

---

## APPENDIX: EXISTING CODE PATTERNS

### Repository Pattern (Already Used)
```dart
// ReportsRepositoryImpl
Future<ReportEntity> generateReport(ReportParams params) async {
  // Check cache
  // Fetch from datasource
  // Save cache
  // Return entity
}
```

### Usecase Pattern (Already Used)
```dart
// GenerateReportUseCase
Future<Either<Failure, ReportEntity>> call(ReportParams params) async {
  if (!await _isConnected()) {
    return Left(NetworkFailure());
  }
  try {
    final entity = await _repository.generateReport(params);
    return Right(entity);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### Cubit Pattern (Already Used)
```dart
// ReportsCubit
Future<void> generateReport(ReportParams params) async {
  emit(state.copyWith(isGenerating: true, generationError: null));
  
  final result = await _generateReportUseCase(params);
  
  result.fold(
    (failure) => emit(state.copyWith(
      isGenerating: false,
      generationError: failure.message,
    )),
    (report) => emit(state.copyWith(
      isGenerating: false,
      generatedReport: report,
    )),
  );
}
```

### BlocListener Pattern (Already Used)
```dart
// In UI
BlocListener<ReportsCubit, ReportsState>(
  listenWhen: (prev, curr) => curr.generationError != null,
  listener: (ctx, state) {
    CoreUtils.showTopSnackBar(
      context: ctx,
      message: state.generationError!,
      isError: true,
    );
  },
  child: // ... UI
)
```

---

## DOCUMENT METADATA

| Property | Value |
|----------|-------|
| Created | 2026-06-05 |
| Author | Senior Flutter Engineer (Claude) |
| Status | Architecture Review Phase Complete |
| Next Phase | API URL Refactoring |
| Approvals Required | Technical Lead Review |
| Implementation Start | TBD |

---

**END OF PLAN**
