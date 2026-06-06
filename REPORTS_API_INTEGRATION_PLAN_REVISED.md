# PRODUCTION-READY REPORTS API INTEGRATION PLAN (REVISED)
**Date**: 2026-06-05  
**Status**: Architecture Review + Revised Planning Phase  
**Total Estimated Effort**: 20-25 hours across 6 focused phases  
**Major Changes**: Code review corrections applied (see Section 2)

---

## SECTION 1: CODE REVIEW CORRECTIONS

### 1.1 Repository Architecture (CRITICAL CORRECTION)

**❌ WRONG** (Original Plan):
```
Create separate repositories:
  StudentRecentReportRepository
  AttendanceRecentReportRepository  
  StaffRecentReportRepository
```

**✅ CORRECT** (Revised):
```
Keep SINGLE ReportsRepository with multiple methods:

ReportsRepository (interface)
  ├── generateReport(params) → ReportEntity
  ├── getRecentReports() → List<ReportMetadataEntity>
  ├── getStudentReports() → List<RecentReportModel>
  ├── getStudentAttendanceReports() → List<RecentReportModel>
  ├── getStaffReports() → List<RecentReportModel>
  └── getStaffAttendanceReports() → List<RecentReportModel>
```

**Reason**: 
- Existing ReportsRepositoryImpl already orchestrates all 4 sources
- Adding separate repositories = duplicate caching, duplicate error handling
- Breaks single responsibility principle
- Violates existing clean architecture

**Impact**: 
- ⏱️ Saves ~3-4 hours of refactoring
- ✅ Maintains existing patterns
- ✅ Reduces code duplication

---

### 1.2 Tab Auto-Switch (ALREADY 70% DONE)

**Current State (Phase 3.3 ✅)**:
```
generateReport()
    ↓
Success: emit(generatedReport)
    ↓
loadRecentReports() [already called - unawaited()]
    ↓
Recent reports refresh automatically
```

**Missing Piece (Only This)**:
```
Listen to generatedReport state change
    ↓
If (curr.generatedReport != null && prev.generatedReport == null)
    ↓
TabController.animateTo(generatedTabIndex)
```

**Implementation** (reports_screen.dart):
```dart
late TabController _tabController;

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);
}

@override
Widget build(BuildContext context) {
  return BlocListener<ReportsCubit, ReportsState>(
    listenWhen: (prev, curr) => 
        curr.generatedReport != null && prev.generatedReport == null,
    listener: (ctx, state) {
      _tabController.animateTo(1); // Generated Reports tab
    },
    child: // ... rest of build
  );
}
```

**Impact**: 
- ⏱️ Only ~1 hour to implement
- ✅ No complex state management needed
- ✅ Uses existing infrastructure

---

### 1.3 Tab Performance: Keep TabBarView + KeepAlive

**❌ WRONG** (Original Plan):
```
Replace TabBarView with IndexedStack
This requires rewriting entire navigation layer
```

**✅ CORRECT** (Revised):
```
Keep TabBarView as-is
Add AutomaticKeepAliveClientMixin to each tab body screen
```

**Implementation Pattern**:
```dart
class GenerateTabScreen extends StatefulWidget {
  @override
  State<GenerateTabScreen> createState() => _GenerateTabScreenState();
}

class _GenerateTabScreenState extends State<GenerateTabScreen>
    with AutomaticKeepAliveClientMixin {  // ← Add this mixin
  
  @override
  bool get wantKeepAlive => true;  // Preserve state when switched away
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required with mixin
    return // ... existing UI
  }
}
```

**Apply to**:
- [ ] GenerateTabScreen (preserves form field selection)
- [ ] GeneratedReportsScreen (preserves scroll position)
- [ ] StudentReportsScreen (preserves filter state)
- [ ] StaffReportsScreen (preserves filter state)
- [ ] ComplianceScreen (preserves form data)

**Preserved Automatically**:
- ✅ Scroll position
- ✅ Text field values
- ✅ Filter selections
- ✅ Dropdown state
- ✅ Selected dates
- ✅ Checkbox state

**Impact**: 
- ⏱️ Only ~2 hours (add mixin to 5 screens)
- ✅ No navigation rewrite needed
- ✅ Works with existing TabBarView
- ✅ Minimal testing risk

---

### 1.4 Staff Attendance API: Backend Verification REQUIRED

**Critical Issue Identified** ⚠️:

From the code, the endpoint:
```
GET /api/v1/attendance/staff-attendance/reports/recent
```

Returns response with:
```json
{
  "reportType": "STUDENT_DAILY_ATTENDANCE"  // ← WRONG!
}
```

**This is 99% a Backend Bug**, not frontend filtering issue.

**Root Cause Verification** (Do NOT skip):

**Step 1: Test with Postman/Insomnia**
```
GET /api/v1/attendance/staff-attendance/reports/recent?schoolCode=SCH001

Expected Response:
{
  "reports": [
    {
      "reportType": "STAFF_ATTENDANCE_PER_WEEK",  // ← Should be STAFF_*
      ...
    }
  ]
}

Actual Response (if backend bug):
{
  "reports": [
    {
      "reportType": "STUDENT_DAILY_ATTENDANCE",  // ← WRONG!
      ...
    }
  ]
}
```

**Step 2: If backend bug confirmed**:
- File backend ticket immediately
- Do NOT create frontend filtering workarounds
- Block implementation until fixed

**Step 3: If frontend issue found**:
- Check report type mapping in datasource
- Verify filtering logic in generated_reports_list.dart
- Add unit test to prevent regression

**Impact**: 
- ⏱️ 1-2 hours investigation
- 🔴 **May block Phase 4 until backend fixed**
- ✅ Or quick fix if frontend issue

---

### 1.5 Download Feature: Missing Endpoint

**Blocker Identified** 🔴:

Current recent report response has:
```json
{
  "reportId": "RPT123",
  "assetCode": "AST456",     // ← This is available
  "fileName": "report.pdf",
  ...
}
```

**But missing**: Where is the download endpoint?

**Need to Verify Before Implementation**:

```
What API endpoint fetches file bytes by assetCode?

Option A: Asset Service
  GET /api/v1/assets/{assetCode}
  GET /api/v1/assets/{assetCode}/download

Option B: Document API
  GET /api/v1/document/{assetCode}
  GET /document-ms/api/v1/assets/{assetCode}

Option C: Reports API
  GET /api/v1/attendance/reports/{reportId}/download
  GET /api/v1/student/reports/{reportId}/file

Option D: File Service
  GET /api/v1/files/{assetCode}
```

**Action Required**:
1. Check backend API documentation
2. Test endpoint in Postman
3. Verify response is file bytes (Uint8List)
4. Confirm supports PDF and XLSX

**If Endpoint Missing**:
- Cannot implement download feature
- Defer to Phase 2 of next sprint
- File backend request for API

**Impact**: 
- ⏱️ 30 minutes investigation
- 🔴 **May not be implementable in this phase**
- ⏳ Plan as optional deliverable

---

## SECTION 2: REVISED IMPLEMENTATION ROADMAP

### Phase 1: Preparation & Verification (2 hours)

**Tasks**:
1. [ ] Verify Staff Attendance API response
   - Test with Postman
   - Check if backend returns wrong reportType
   - File ticket if backend bug
   
2. [ ] Identify file download endpoint
   - Find API that serves file by assetCode
   - Test with Postman
   - Verify returns bytes for PDF/XLSX

3. [ ] Run existing test suite
   - Ensure Phase 3.3 didn't break anything
   - Check all 14 report screens

**Deliverable**: 
- Verification report
- Decision: proceed or defer download feature
- Backend ticket (if API bug found)

---

### Phase 2: API URL Refactoring (1.5 hours) ⏳

**File**: `lib/core/util/api_paths.dart`

**Add 6 New Constants** (after line 611, Attendance section):
```dart
// —— Reports (Attendance MS) ——

/// POST /api/v1/attendance/student-attendance/reports/generate
static const String studentAttendanceReportsGenerate = 
    '/api/v1/attendance/student-attendance/reports/generate';

/// GET /api/v1/attendance/student-attendance/reports/recent
static const String studentAttendanceReportsRecent = 
    '/api/v1/attendance/student-attendance/reports/recent';

/// POST /api/v1/attendance/staff-attendance/reports/generate
static const String staffAttendanceReportsGenerate = 
    '/api/v1/attendance/staff-attendance/reports/generate';

/// GET /api/v1/attendance/staff-attendance/reports/recent
static const String staffAttendanceReportsRecent = 
    '/api/v1/attendance/staff-attendance/reports/recent';

// —— Reports (Student MS) ——

/// GET /api/v1/student/student/reports/recent
static const String studentReportsRecent = 
    '/api/v1/student/student/reports/recent';

/// GET /api/v1/staff/staff/reports/recent
static const String staffReportsRecent = 
    '/api/v1/staff/staff/reports/recent';
```

**File**: `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart`

**Replace Hardcoded URLs**:
```dart
// BEFORE (line 21)
endpoint = '/api/v1/attendance/student-attendance/reports/generate';

// AFTER
endpoint = ApiPaths.studentAttendanceReportsGenerate;

// BEFORE (line 52)
'/api/v1/attendance/student-attendance/reports/recent'

// AFTER
ApiPaths.url(ApiPaths.studentAttendanceReportsRecent)
```

**Testing**:
- [ ] All existing report generation tests still pass
- [ ] All recent reports loading tests still pass
- [ ] No URL construction errors

**Verification**: 
- [ ] UAT environment: Confirm ApiPathsUat correctly routes attendance/student/staff
- [ ] Local environment: Confirm API calls work

**Deliverable**: 
- Updated ApiPaths with 6 constants
- Updated ReportsRemoteDataSourceImpl
- All tests passing

---

### Phase 3: Tab Auto-Switch Implementation (1-1.5 hours) ⏳

**File**: `lib/presentation/features/reports/view/reports_screen.dart`

**Current State**: 
- ✅ TabBar exists
- ✅ TabBarView with 5 tabs exists
- ❌ No TabController field
- ❌ No BlocListener for generation success

**Changes**:

**A. Add TabController**:
```dart
class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {  // ← Keep existing mixin
  
  late TabController _tabController;  // ← Add this
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // ... rest of initState
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

**B. Update TabBar to use controller**:
```dart
// BEFORE
TabBar(
  tabs: [/* ... */],
)

// AFTER
TabBar(
  controller: _tabController,
  tabs: [/* ... */],
)
```

**C. Update TabBarView to use controller**:
```dart
// BEFORE
TabBarView(
  children: [/* ... */],
)

// AFTER
TabBarView(
  controller: _tabController,
  children: [/* ... */],
)
```

**D. Add BlocListener for auto-switch**:
```dart
@override
Widget build(BuildContext context) {
  return BlocListener<ReportsCubit, ReportsState>(
    listenWhen: (prev, curr) => 
        curr.generatedReport != null && prev.generatedReport == null,
    listener: (ctx, state) {
      // Switch to Generated Reports tab (index 1)
      _tabController.animateTo(1);
    },
    child: // ... existing scaffold/build
  );
}
```

**Testing**:
- [ ] Generate report from any form
- [ ] Verify tab switches to Generated Reports automatically
- [ ] Verify recent reports list shows newly generated report
- [ ] Test all 14 report types

**Deliverable**:
- TabController integrated
- BlocListener triggers auto-switch
- No manual tab navigation needed after generation

**Risk**: Low (TabController standard Flutter pattern)

---

### Phase 4: Tab Performance - Add KeepAlive (2 hours) ⏳

**Why**: Switch tabs instantly without reloading data

**Files to Modify**: All 5 tab screens

**Pattern** (apply to each):

```dart
// Before
class GenerateTabScreen extends StatefulWidget { ... }
class _GenerateTabScreenState extends State<GenerateTabScreen> { ... }

// After
class GenerateTabScreen extends StatefulWidget { ... }
class _GenerateTabScreenState extends State<GenerateTabScreen>
    with AutomaticKeepAliveClientMixin {  // ← Add mixin
  
  @override
  bool get wantKeepAlive => true;  // ← Add this property
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // ← Call super.build() - REQUIRED
    return // ... existing build
  }
}
```

**Apply to**:
- [ ] `GenerateTabScreen` (Form fields preserved)
- [ ] `GeneratedReportsScreen` (Scroll position preserved)
- [ ] `StudentReportsScreen` (Filter state preserved)
- [ ] `StaffReportsScreen` (Filter state preserved)
- [ ] `ComplianceScreen` (Form data preserved)

**What Gets Preserved Automatically**:
- ✅ Scroll position
- ✅ TextField input values
- ✅ Dropdown selections
- ✅ Checkbox states
- ✅ Selected dates
- ✅ Filter selections
- ✅ List selection state

**Testing**:
- [ ] Switch Generate → Student → Generate tab
- [ ] Verify form fields still have old values
- [ ] Verify scroll position preserved
- [ ] Test all 5 tabs

**Deliverable**:
- All 5 tab screens have AutomaticKeepAliveClientMixin
- State preserved on tab switch
- Zero data reload on navigation

**Risk**: Minimal (standard Flutter pattern)

---

### Phase 5: Horizontal Swipe Navigation (1.5 hours) ⏳

**Optional**: Nice-to-have, not critical for MVP

**Implementation** (in reports_screen.dart):

```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onHorizontalDragEnd: (details) {
      // Swipe velocity threshold
      if (details.primaryVelocity == null) return;
      
      if (details.primaryVelocity! < -50) {
        // Swipe left → next tab
        if (_tabController.index < 4) {
          _tabController.animateTo(_tabController.index + 1);
        }
      } else if (details.primaryVelocity! > 50) {
        // Swipe right → previous tab
        if (_tabController.index > 0) {
          _tabController.animateTo(_tabController.index - 1);
        }
      }
    },
    child: Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [/* ... */],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [/* ... */],
      ),
    ),
  );
}
```

**Testing**:
- [ ] Swipe left on each tab
- [ ] Swipe right on each tab
- [ ] Verify boundary checks (first/last tab)
- [ ] Test on iOS and Android

**Deliverable**:
- Horizontal swipe navigation works
- Boundaries protected

**Timeline**: Optional, implement only if time permits

---

### Phase 6: Download Feature (2-3 hours, IF endpoint found) ⏳

**BLOCKER**: Must verify download API endpoint exists first (Phase 1)

**If API Found**: Implement Download Service

**File**: Create `lib/data/services/report_download_service.dart`

```dart
class ReportDownloadService {
  final Dio _dio;
  
  ReportDownloadService(this._dio);
  
  /// Fetch report file bytes by asset code
  Future<Uint8List> downloadReportFile({
    required String assetCode,
  }) async {
    // Use the verified endpoint
    final response = await _dio.get<List<int>>(
      // e.g., ApiPaths.url('/api/v1/assets/$assetCode/download')
      options: Options(responseType: ResponseType.bytes),
    );
    
    return Uint8List.fromList(response.data ?? []);
  }
}
```

**File**: Update `lib/presentation/features/reports/widgets/generated_report_card.dart`

**Add Download Button**:
```dart
class GeneratedReportCard extends StatelessWidget {
  final ReportMetadataEntity report;
  
  void _onDownloadTap(BuildContext context) async {
    try {
      // Show loading overlay
      
      // Fetch file bytes
      final service = getIt<ReportDownloadService>();
      final bytes = await service.downloadReportFile(
        assetCode: report.assetCode ?? '',
      );
      
      // Save to device (use existing pdf_view.dart logic)
      // Show success snackbar
      
    } catch (e) {
      // Show error snackbar
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(report.fileName ?? 'Report'),
          Text(report.reportType.displayName),
          Text(DateFormat('MMM dd, yyyy').format(report.generatedAt)),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _onDownloadTap(context),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Testing**:
- [ ] Download button visible on recent reports
- [ ] File downloads successfully
- [ ] File saved to device
- [ ] Can open file
- [ ] Works with PDF and XLSX

**Deliverable**:
- Download Service created
- Download button integrated
- File saved to device

**Status**: Only if download API endpoint is found

---

## SECTION 3: REVISED PHASE BREAKDOWN

| Phase | Task | Duration | Dependency | Status |
|-------|------|----------|------------|--------|
| 1 | Verification & Investigation | 2 hrs | None | ⏳ Pending |
| 2 | API URL Refactoring | 1.5 hrs | Phase 1 ✓ | ⏳ Pending |
| 3 | Tab Auto-Switch | 1.5 hrs | Phase 2 ✓ | ⏳ Pending |
| 4 | Tab Performance (KeepAlive) | 2 hrs | Phase 3 ✓ | ⏳ Pending |
| 5 | Horizontal Swipe (Optional) | 1.5 hrs | Phase 4 ✓ | ⏳ Pending |
| 6 | Download Feature (If API exists) | 2-3 hrs | Phase 1 ✓ | 🔴 Blocked |
| **Integration Testing** | Validation | 3 hrs | All ✓ | ⏳ Pending |
| **TOTAL** | | **13.5-15 hrs** | | |

**Note**: Original plan was 40-50 hours. Revised plan is 50% smaller due to:
- ✅ Keeping single repository (not 3 separate)
- ✅ Using existing TabBarView (not IndexedStack rewrite)
- ✅ Tab auto-switch already mostly done
- ✅ More focused scope

---

## SECTION 4: IMPLEMENTATION CHECKLIST

### Pre-Implementation
- [ ] Phase 1: Verify Staff Attendance API response
- [ ] Phase 1: Identify download API endpoint
- [ ] Phase 1: Run existing test suite
- [ ] Code review complete

### Phase 2: API URL Refactoring
- [ ] Add 6 constants to ApiPaths
- [ ] Update ReportsRemoteDataSourceImpl (6 endpoints)
- [ ] Run tests to verify no breakage
- [ ] Verify UAT routing

### Phase 3: Tab Auto-Switch
- [ ] Add TabController field to ReportsScreen
- [ ] Update TabBar to use controller
- [ ] Update TabBarView to use controller
- [ ] Add BlocListener for generatedReport state
- [ ] Test: Generate → auto-switch to Generated tab
- [ ] Test: Recent reports load automatically
- [ ] Test: All 14 report types work

### Phase 4: Tab Performance
- [ ] Add AutomaticKeepAliveClientMixin to GenerateTabScreen
- [ ] Add AutomaticKeepAliveClientMixin to GeneratedReportsScreen
- [ ] Add AutomaticKeepAliveClientMixin to StudentReportsScreen
- [ ] Add AutomaticKeepAliveClientMixin to StaffReportsScreen
- [ ] Add AutomaticKeepAliveClientMixin to ComplianceScreen
- [ ] Test: Switch tabs → state preserved
- [ ] Test: Scroll position preserved
- [ ] Test: Form values preserved
- [ ] Test: Filter state preserved

### Phase 5: Swipe Navigation (Optional)
- [ ] Add GestureDetector to ReportsScreen
- [ ] Implement swipe left (next tab)
- [ ] Implement swipe right (previous tab)
- [ ] Test: Swipe left from each tab
- [ ] Test: Swipe right from each tab
- [ ] Test: Boundaries (first/last tab)

### Phase 6: Download (If API Found)
- [ ] Create ReportDownloadService
- [ ] Add download method to datasource
- [ ] Update generated_report_card.dart with Download button
- [ ] Implement file save logic
- [ ] Test: Download PDF file
- [ ] Test: Download XLSX file
- [ ] Test: File permissions (Android 13+)

### Integration Testing
- [ ] Generate student attendance report
- [ ] Verify tab auto-switch works
- [ ] Verify recent reports load
- [ ] Verify newly generated report visible
- [ ] Test all 14 report types
- [ ] Test error cases
- [ ] Test on LOCAL environment
- [ ] Test on UAT environment
- [ ] Test on iOS
- [ ] Test on Android

---

## SECTION 5: CRITICAL DECISION POINTS

### Decision 1: Staff Attendance API Status
**Question**: Is backend returning wrong report type?

**Impact**:
- ✅ If frontend issue: 1-2 hour fix
- 🔴 If backend bug: Blocks Phase 4, file ticket

**Action**: Complete Phase 1 verification before proceeding

---

### Decision 2: Download API Availability
**Question**: What endpoint downloads file by assetCode?

**Options**:
- ✅ Found: Implement in this sprint
- ❌ Not found: Defer to next sprint

**Action**: Complete Phase 1 investigation before Phase 6

---

### Decision 3: Swipe Navigation Priority
**Question**: Is horizontal swipe required for MVP?

**Options**:
- ✅ Required: Implement in Phase 5
- ⏭️ Nice-to-have: Defer to Phase 2

**Current Impact**: 1.5 hours if included

---

## SECTION 6: TESTING STRATEGY

### Unit Tests (Run After Each Phase)
```
Phase 2: API paths resolve correctly
Phase 3: TabController switches tab on generation
Phase 4: AutomaticKeepAliveClientMixin preserves state
Phase 5: Swipe gestures trigger correct navigation
Phase 6: Download service fetches file bytes
```

### Manual Testing (Integration Phase)
```
Scenario 1: Generate Student Daily Attendance
  - Fill form
  - Select format (PDF)
  - Tap Generate
  - ✓ Loading shown
  - ✓ Success snackbar
  - ✓ Tab auto-switches to Generated
  - ✓ Recent reports load
  - ✓ Report visible at top

Scenario 2: Switch Tabs Multiple Times
  - Generate form → switch to Student → back to Generate
  - ✓ Form fields still populated
  - ✓ No API reload

Scenario 3: Swipe Navigation
  - Swipe left → next tab
  - Swipe right → previous tab
  - ✓ Both work smoothly

Scenario 4: Download Report (if implemented)
  - Tap Download on recent report
  - ✓ File downloads
  - ✓ Saved to device
  - ✓ Can open file
```

---

## SECTION 7: KNOWN UNKNOWNS (Must Clarify Before Starting)

### Unknown 1: Staff Attendance API Response
**Current**: May return student report types
**Status**: 🔍 Needs verification in Phase 1

### Unknown 2: File Download Endpoint
**Current**: Unclear which API serves file by assetCode
**Status**: 🔍 Needs verification in Phase 1

### Unknown 3: UAT Download Endpoint
**Current**: If download API found, how does it work in UAT?
**Status**: 🔍 Investigate in Phase 1

---

## SECTION 8: SUCCESS CRITERIA

### Phase 2 Complete ✓
- [ ] All hardcoded URLs removed from datasource
- [ ] ApiPaths used consistently
- [ ] Tests pass on LOCAL
- [ ] Tests pass on UAT

### Phase 3 Complete ✓
- [ ] Generate report → auto-switch to Generated tab
- [ ] No manual navigation needed
- [ ] Works for all 14 report types

### Phase 4 Complete ✓
- [ ] Switch tabs → state preserved
- [ ] No data reload on tab switch
- [ ] Scroll position preserved
- [ ] Form values preserved

### Phase 5 Complete (Optional) ✓
- [ ] Swipe left/right works
- [ ] Boundaries protected
- [ ] Smooth animation

### Phase 6 Complete (If API Found) ✓
- [ ] Download button functional
- [ ] File saved to device
- [ ] Supports PDF and XLSX
- [ ] Works on Android 13+

---

## SECTION 9: DOCUMENT REVISIONS LOG

| Revision | Date | Changes |
|----------|------|---------|
| v1 | 2026-06-05 | Original comprehensive plan (40-50 hrs) |
| v2 | 2026-06-05 | **Revised per code review** |
| | | - Removed separate repository creation |
| | | - Clarified tab auto-switch (mostly done) |
| | | - Kept TabBarView + KeepAlive (not IndexedStack) |
| | | - Flagged Staff Attendance API as backend issue |
| | | - Identified missing download API endpoint |
| | | - Reduced scope to 13.5-15 hours |

---

## NEXT IMMEDIATE STEPS

### ✅ DONE
- [x] Architecture review complete
- [x] Code patterns analyzed
- [x] Existing Phase 3.3 verified

### ⏳ NEXT (Before Coding)
1. [ ] Phase 1: Verify Staff Attendance API response
   - Use Postman to test: `GET /api/v1/attendance/staff-attendance/reports/recent`
   - Check if response contains `STUDENT_DAILY_ATTENDANCE` (bug) or `STAFF_ATTENDANCE_*` (correct)
   
2. [ ] Phase 1: Find download API endpoint
   - Ask: "What API downloads file by assetCode?"
   - Test endpoint in Postman
   - Confirm returns file bytes
   
3. [ ] Phase 1: Verify existing tests
   - Run: `flutter test`
   - Ensure Phase 3.3 didn't break anything

### Then: Proceed to Phase 2
Once Phase 1 decisions made, begin API URL refactoring.

---

## APPENDIX: FILE-BY-FILE CHANGES

### Phase 2: API Path Refactoring

**File 1**: `lib/core/util/api_paths.dart`
```
ADD (after line 611):
  - studentAttendanceReportsGenerate
  - studentAttendanceReportsRecent
  - staffAttendanceReportsGenerate
  - staffAttendanceReportsRecent
  - studentReportsRecent
  - staffReportsRecent
```

**File 2**: `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart`
```
REPLACE (all occurrences of hardcoded strings):
  - '/api/v1/attendance/student-attendance/reports/generate' 
    → ApiPaths.studentAttendanceReportsGenerate
  - '/api/v1/attendance/student-attendance/reports/recent'
    → ApiPaths.url(ApiPaths.studentAttendanceReportsRecent)
  - (repeat for other 4 endpoints)
```

---

### Phase 3: Tab Auto-Switch

**File 1**: `lib/presentation/features/reports/view/reports_screen.dart`
```
MODIFY:
  - _ReportsScreenState: extend with SingleTickerProviderStateMixin
  - ADD: late TabController _tabController
  - ADD: in initState() → _tabController = TabController(length: 5, vsync: this)
  - MODIFY: TabBar(controller: _tabController)
  - MODIFY: TabBarView(controller: _tabController)
  - WRAP build: with BlocListener<ReportsCubit>
```

---

### Phase 4: Tab Performance

**Files to Modify** (5 files):
1. `lib/presentation/features/reports/view/*_screen.dart`
```
ADD to each:
  - with AutomaticKeepAliveClientMixin
  - override get wantKeepAlive => true
  - super.build(context) in build()
```

---

### Phase 6: Download (If Implemented)

**File 1**: Create `lib/data/services/report_download_service.dart`

**File 2**: `lib/presentation/features/reports/widgets/generated_report_card.dart`
```
ADD:
  - Download button
  - _onDownloadTap() method
  - Loading state management
```

---

**END OF REVISED PLAN**

