# REPORTS API IMPLEMENTATION - FINAL ACTION PLAN
**Status**: ✅ READY FOR IMPLEMENTATION  
**Date**: 2026-06-05  
**Estimated Duration**: 12-18 hours (including discovery)  

---

## 🔴 PRIORITY 0: PRE-IMPLEMENTATION VERIFICATION (Must complete before ANY coding)

### P0.1: Verify ReportsScreen Tab Structure (15 minutes)

**BLOCKER**: Tab count and index for auto-switch

**Action**:
```bash
# Open file and check actual tab structure
lib/presentation/features/reports/view/reports_screen.dart
```

**Verify**:
1. [ ] How many tabs exist? Count them
2. [ ] Is there a "Generated Reports" tab as separate tab?
3. [ ] What is its index (0, 1, 2, etc.)?
4. [ ] Or is it nested within another screen?

**Example Scenarios**:

**Scenario A** (5 tabs total):
```dart
TabBar(
  tabs: [
    Tab(text: 'Generate'),       // index 0
    Tab(text: 'Student'),        // index 1
    Tab(text: 'Staff'),          // index 2
    Tab(text: 'Compliance'),      // index 3
    Tab(text: 'Billing'),         // index 4
  ]
)

// Then: _tabController.animateTo(0) for Generate
//       _tabController.animateTo(1) for Student
//       No separate Generated tab!
```

**Scenario B** (6 tabs total):
```dart
TabBar(
  tabs: [
    Tab(text: 'Generate'),       // index 0
    Tab(text: 'Generated'),      // index 1 ← This is what we need
    Tab(text: 'Student'),        // index 2
    Tab(text: 'Staff'),          // index 3
    Tab(text: 'Compliance'),      // index 4
    Tab(text: 'Billing'),         // index 5
  ]
)

// Then: _tabController.animateTo(1) for Generated Reports
```

**Decision Required**:
- [ ] Confirm tab structure
- [ ] Document actual index for auto-switch
- [ ] Update Phase 3 implementation if index != 1

**Impact**: ⏱️ 5 minutes investigation, but critical for correct implementation

---

### P0.2: Download API Endpoint Investigation (30 minutes) 🔴 CRITICAL

**Priority moved earlier to unblock Phase 6 immediately**

**BLOCKER**: May prevent Phase 6 implementation

**Investigation Steps**:

**Step 1: Search Codebase for existing asset/download patterns**

```bash
# Search for existing download/asset implementations
grep -r "assetCode\|downloadFile\|AssetRepository\|DocumentRepository\|MediaService" \
  lib/data --include="*.dart" | head -20

grep -r "Asset\|Document\|Media" lib/domain --include="*.dart" | head -20
```

**Step 2: Check if patterns already exist**

Common patterns in WowCare:
- [ ] `AssetRepository` (manages file downloads by asset code) — if found, reuse it!
- [ ] `DocumentRepository` (manages document APIs) — if found, reuse it!
- [ ] `FileDownloadService` (existing download service) — if found, reuse it!
- [ ] `MediaService` (media file handling) — if found, reuse it!

**Step 3: If no existing service, verify download API exists**

Test in Postman:

```
Test cases to verify (try each):

A) Asset-based endpoint:
   GET /api/v1/assets/{assetCode}
   Response: File bytes (Uint8List)

B) Document-based endpoint:
   GET /api/v1/document/{assetCode}/download
   Response: File bytes

C) Reports-specific endpoint:
   GET /api/v1/attendance/reports/{reportId}/download
   Response: File bytes

D) Generic file endpoint:
   GET /api/v1/files/{assetCode}
   Response: File bytes
```

**Deliverable**:
- [ ] Existing asset/document service found? Link to file → Phase 6 = 30 min
- [ ] Or: Download API tested and verified in Postman → Phase 6 = 2-3 hrs
- [ ] Or: No endpoint found → Phase 6 = DEFER to next sprint

**Timeline**: 20 minutes if existing service found, 10 minutes extra if testing API

---

### P0.3: Staff Attendance API Investigation (30 minutes) 🔴 CRITICAL

**BLOCKER**: May prevent Phase implementation if backend bug

**Investigation Steps**:

**Step 1: Open Postman/Insomnia**

**Step 2: Make GET request**
```
URL: {UAT or LOCAL}/api/v1/attendance/staff-attendance/reports/recent
Method: GET
Headers:
  - Authorization: Bearer {your-token}
  - X-Organization-Code: {your-org}
  - X-School-Code: {your-school}
Query Params:
  - schoolCode: {your-school-code}
```

**Step 3: Inspect Response**

If response contains:
```json
{
  "reports": [
    {
      "reportType": "STUDENT_DAILY_ATTENDANCE",  // ← BUG!
      "fileName": "student_attendance_...",
      ...
    }
  ]
}
```

**Then**: File backend ticket immediately:
- Endpoint: `/api/v1/attendance/staff-attendance/reports/recent`
- Issue: Returns `STUDENT_*` report types instead of `STAFF_*`
- Blocks: Flutter implementation until fixed
- Workaround: None (don't filter in frontend)

If response contains:
```json
{
  "reports": [
    {
      "reportType": "STAFF_ATTENDANCE_PER_WEEK",  // ← CORRECT
      "fileName": "staff_attendance_...",
      ...
    }
  ]
}
```

**Then**: No backend issue. Proceed with implementation.

**Deliverable**:
- [ ] Screenshot of Postman request + response
- [ ] Backend ticket number (if bug found)
- [ ] Decision: Proceed or block?

**Timeline**: Do NOT skip. This is critical.

---

### P0.4: Verify Existing Test Suite (15 minutes)

**Action**:
```bash
cd /Users/supercoolcoder/Downloads/WowCare/wowcare2-mobile
flutter test
```

**Check**:
- [ ] All tests pass?
- [ ] Any failures in report-related tests?
- [ ] Phase 3.3 changes didn't break anything?

**If failures**:
- [ ] Fix before proceeding
- [ ] Don't build on broken foundation

---

### P0.5: Check TabBarView Swipe Support (5 minutes)

**Question**: Does TabBarView already support horizontal swipe?

**Answer**: YES, TabBarView has built-in swipe by default.

**Verification**:
```bash
# Open ReportsScreen implementation
lib/presentation/features/reports/view/reports_screen.dart

# Check if TabBarView exists
# If yes → swipe ALREADY WORKS
# If no → need custom implementation
```

**Impact**: 
- ✅ If TabBarView used: Phase 5 is **DELETED** (save 1.5 hours)
- ❌ If custom PageView/scroll: May need Phase 5

---

### P0.6: Verify Tab Screen Widget Types (10 minutes)

**Action**: Check each tab screen

```bash
# Check if screens are StatefulWidget or StatelessWidget
grep -n "class.*extends" lib/presentation/features/reports/view/

# Check examples:
grep -n "class GenerateTab\|class GeneratedReports\|class StudentReports" \
  lib/presentation/features/reports/view/*
```

**Determine**:
- [ ] GenerateTabScreen: StatefulWidget? → Apply KeepAlive ✅
- [ ] GeneratedReportsScreen: StatefulWidget? → Apply KeepAlive ✅
- [ ] StudentReportsScreen: StatefulWidget? → Apply KeepAlive ✅
- [ ] StaffReportsScreen: StatefulWidget? → Apply KeepAlive ✅
- [ ] ComplianceScreen: StatefulWidget? → Apply KeepAlive ✅

**If any are StatelessWidget**:
- Don't convert to StatefulWidget
- Skip KeepAlive for those
- Document which screens can't preserve state

---

### P0.7: Repository Implementation Audit (20 minutes)

**Purpose**: Verify existing infrastructure AND correctness before refactoring

**Action**:
```bash
# Open repository implementation
lib/data/features/reports/repositories/reports_repository_impl.dart

# Open datasource
lib/data/features/reports/datasources/reports_remote_datasource_impl.dart
```

**Verify Method Existence AND Correctness**:

For each method, verify:
1. Method signature exists
2. Calls correct datasource endpoint
3. Uses cache correctly
4. Maps DTO → Entity correctly

```dart
// ✅ GOOD EXAMPLE
Future<List<RecentReportModel>> getRecentStudentAttendanceReports() async {
  final cacheKey = _buildRecentReportsCacheKey('student_attendance');
  
  // Check cache
  final cachedPayload = await _cacheManager.loadCache(cacheKey);
  if (cachedPayload != null) {
    // Use cache
    return _mapCachedToModels(cachedPayload);
  }
  
  // Hit endpoint
  final models = await _remoteDataSource
      .getRecentStudentAttendanceReports(); // ← Correct endpoint call
  
  // Save cache
  await _cacheManager.saveCache(cacheKey, {'reports': models});
  
  return models;
}

// ❌ BAD EXAMPLE (would cause issues)
Future<List<RecentReportModel>> getRecentStudentAttendanceReports() async {
  // Calls WRONG endpoint (student instead of staff-attendance)
  return await _remoteDataSource.getRecentStudentReports();
}
```

**Checklist**:
- [ ] `generateReport()` exists
  - [ ] Calls datasource.generateReport()
  - [ ] Caches result
  - [ ] Calls loadRecentReports() with unawaited() after success
  
- [ ] `getRecentReports()` exists
  - [ ] Fetches from all 4 sources in parallel
  - [ ] Deduplicates by reportId
  - [ ] Sorts by date descending
  
- [ ] `getRecentStudentAttendanceReports()` exists
  - [ ] Calls: `/api/v1/attendance/student-attendance/reports/recent`
  - [ ] Uses cache with key: `reports:student_attendance_recent`
  - [ ] Maps: RecentReportModel → ReportMetadataEntity
  
- [ ] `getRecentStaffAttendanceReports()` exists
  - [ ] Calls: `/api/v1/attendance/staff-attendance/reports/recent`
  - [ ] Uses cache with key: `reports:staff_attendance_recent`
  - [ ] Maps: RecentReportModel → ReportMetadataEntity
  
- [ ] `getRecentStudentReports()` exists
  - [ ] Calls: `/api/v1/student/student/reports/recent`
  - [ ] Uses cache with key: `reports:student_management_recent`
  - [ ] Maps: RecentReportModel → ReportMetadataEntity
  
- [ ] `getRecentStaffReports()` exists
  - [ ] Calls: `/api/v1/staff/staff/reports/recent`
  - [ ] Uses cache with key: `reports:staff_recent`
  - [ ] Maps: RecentReportModel → ReportMetadataEntity

**Deliverable**:
- [ ] All 6 methods confirmed to exist AND call correct endpoints
- [ ] All methods use correct cache keys
- [ ] All mappings are correct
- [ ] loadRecentReports() flows correctly after generation

**Impact**: 
- ✅ If all correct: Phase 2 just updates datasource URLs
- ⚠️ If endpoint mismatch found: Fix before refactoring
- 🔴 If method missing: Plan Phase 1.5 to add them first

---

### P0.8: Report Type Mapping Audit (15 minutes)

**Purpose**: Verify enum mapping matches backend values (catches mapping bugs before blaming backend)

**The Issue**:
Staff Attendance API investigation revealed suspicious report types. Could be:
- Backend bug (returns wrong type)
- Mapping bug (enum doesn't match backend value)

Spend 15 minutes verifying before filing tickets.

**Action**:
```bash
# Open enum
lib/domain/features/reports/entities/report_type.dart
```

**Verify Enum Mappings**:

Check that each enum value has matching `backendValue`:

```dart
enum ReportType {
  // Student Attendance
  studentDailyAttendance,           // ← Enum name
  studentAbsent,
  studentAttendancePerStudent,
  
  // Staff Attendance
  staffAbsent,
  staffAttendancePerWeek,
  
  // Student Management
  studentsAndFamily,
  studentEmergencyContact,
  schoolImmunization,
  
  // Staff Management
  staffDetails,
  
  // Compliance
  annualStateImmunization,
  
  // Billing
  billingPlan,
  billingTransaction,
}

// And their backend values:
String get backendValue => switch(this) {
  ReportType.studentDailyAttendance => 'STUDENT_DAILY_ATTENDANCE',
  ReportType.studentAbsent => 'STUDENT_ABSENT',
  ReportType.studentAttendancePerStudent => 'STUDENT_ATTENDANCE_PER_STUDENT',
  
  ReportType.staffAbsent => 'STAFF_ABSENT',
  ReportType.staffAttendancePerWeek => 'STAFF_ATTENDANCE_PER_WEEK',
  
  ReportType.studentsAndFamily => 'STUDENTS_AND_FAMILY',
  ReportType.studentEmergencyContact => 'EMERGENCY_CONTACTS',
  ReportType.schoolImmunization => 'IMMUNIZATION',
  
  ReportType.staffDetails => 'STAFF_DETAILS',
  
  ReportType.annualStateImmunization => 'ANNUAL_STATE_IMMUNIZATION',
  
  ReportType.billingPlan => 'BILLING_PLAN',
  ReportType.billingTransaction => 'BILLING_TRANSACTION',
};
```

**Verification Checklist**:
- [ ] All enum values have matching backendValue
- [ ] Student attendance enums start with `STUDENT_*`
- [ ] Staff attendance enums start with `STAFF_*`
- [ ] No typos in backendValue strings
- [ ] Mapping is bidirectional (enum → backend, backend → enum)

**Critical**: If `staffAttendancePerWeek` maps to `STUDENT_*` instead of `STAFF_*`, that would cause the exact behavior seen in Staff Attendance API investigation.

**Deliverable**:
- [ ] All mappings verified correct
- [ ] Or: Mapping bug found and documented
- [ ] Decision: Bug fix needed before proceeding?

**Impact**: 
- ✅ If all correct: No mapping issues
- 🔴 If bug found: Fix before Phase 2
- ⏳ If bug found: May explain Staff Attendance API issue

---

## ✅ PRIORITY 1: API PATH CENTRALIZATION (1.5 hours)

**ONLY start if**:
- [ ] P0.1: Tab structure verified
- [ ] P0.2: Staff Attendance API checked
- [ ] P0.3: Download endpoint found or deferred
- [ ] P0.4: Tests passing

### Phase 2A: Add All Report Endpoints to ApiPaths

**File**: `lib/core/util/api_paths.dart`

**Add after line 611** (after existing attendance endpoints):

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

/// POST /api/v1/student/student/reports/generate
static const String studentReportsGenerate = 
    '/api/v1/student/student/reports/generate';

/// GET /api/v1/student/student/reports/recent
static const String studentReportsRecent = 
    '/api/v1/student/student/reports/recent';

// —— Reports (Staff MS) ——

/// POST /api/v1/staff/staff/reports/generate
static const String staffReportsGenerate = 
    '/api/v1/staff/staff/reports/generate';

/// GET /api/v1/staff/staff/reports/recent
static const String staffReportsRecent = 
    '/api/v1/staff/staff/reports/recent';
```

**Verify**: 8 constants added, 6 GET/2 POST pattern clear

### Phase 2B: Update RemoteDataSource

**File**: `lib/data/features/reports/datasources/reports_remote_datasource_impl.dart`

**Replace all hardcoded URLs**:

```dart
// BEFORE (line 21)
if (reportType.startsWith('STUDENT_')) {
  endpoint = '/api/v1/attendance/student-attendance/reports/generate';
}

// AFTER
if (reportType.startsWith('STUDENT_')) {
  endpoint = ApiPaths.studentAttendanceReportsGenerate;
}

// BEFORE (line 52)
'/api/v1/attendance/student-attendance/reports/recent'

// AFTER
ApiPaths.url(ApiPaths.studentAttendanceReportsRecent)

// (Continue for all 6 hardcoded endpoints)
```

**Checklist**:
- [ ] All hardcoded `/api/v1/attendance/...` replaced
- [ ] All hardcoded `/api/v1/student/student/...` replaced
- [ ] All hardcoded `/api/v1/staff/staff/...` replaced
- [ ] Use `ApiPaths.url()` for full URL with microservice routing

### Phase 2C: Local Validation

```bash
flutter analyze
flutter test
```

**Checklist**:
- [ ] flutter analyze: No errors or warnings
- [ ] flutter test: All tests pass
- [ ] No URL construction errors
- [ ] No import errors
- [ ] Local routing verified (ApiPaths.microserviceKeyFromPath)

### Phase 2D: UAT Smoke Test (15 minutes) 🚨 CRITICAL

**Purpose**: Catch microservice routing issues before moving forward

**Test Procedure** (on UAT environment):

```bash
# 1. Generate Student Attendance Report
# Expected: 201/200 success, no 404, correct microservice called
# Check network logs for endpoint

# 2. Generate Student Report (Students & Family)
# Expected: 201/200 success, no 404, correct microservice called

# 3. Generate Staff Report (Staff Details)
# Expected: 201/200 success, no 404, correct microservice called

# 4. Load Recent Reports
# Expected: All reports grouped correctly
# Check: No cross-report-type mixing

# 5. Verify no wrong microservice routing
# Check Postman/network logs:
# - /api/v1/attendance/... → attendance MS
# - /api/v1/student/student/... → student MS
# - /api/v1/staff/staff/... → staff MS
```

**Verification Checklist**:
- [ ] Student Attendance generate: 200/201
- [ ] Student Report generate: 200/201
- [ ] Staff Report generate: 200/201
- [ ] Recent reports load: no errors
- [ ] No 404 errors from microservice misrouting
- [ ] UAT ApiPathsUat routing verified

**If any fails**:
- Stop here
- Debug ApiPathsUat.microserviceKeyFromPath()
- Fix before proceeding to Phase 3

**Deliverable**:
- [ ] Screenshots of successful generate/load on UAT
- [ ] No 404 errors
- [ ] All endpoints hitting correct microservices

---

## ✅ PRIORITY 2: TAB AUTO-SWITCH (1.5 hours)

**ONLY start if**:
- [ ] P0.1: Tab index verified (confirm if 1 or different)
- [ ] Phase 2: All tests passing

### Phase 3: Add TabController + BlocListener

**File**: `lib/presentation/features/reports/view/reports_screen.dart`

**Step 1: Add TabController field**

```dart
class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;  // ← Add this
  
  @override
  void initState() {
    super.initState();
    
    // Get actual tab count (verified in P0.1)
    final tabCount = 5;  // or 6 if Generated is separate tab
    
    _tabController = TabController(length: tabCount, vsync: this);
    // ... rest of initState
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

**Step 2: Connect TabBar and TabBarView**

```dart
// Find existing TabBar in build()
// ADD: controller: _tabController

TabBar(
  controller: _tabController,  // ← Add this
  tabs: [
    Tab(text: 'Generate'),
    Tab(text: 'Generated'),  // or wherever it is
    // ... rest
  ],
)

// Find existing TabBarView
// ADD: controller: _tabController

TabBarView(
  controller: _tabController,  // ← Add this
  children: [
    // ... existing children
  ],
)
```

**Step 3: Add BlocListener for auto-switch**

```dart
@override
Widget build(BuildContext context) {
  return BlocListener<ReportsCubit, ReportsState>(
    listenWhen: (prev, curr) => 
        curr.generatedReport != null && prev.generatedReport == null,
    listener: (ctx, state) {
      // Switch to Generated Reports tab
      // Use VERIFIED index from P0.1
      _tabController.animateTo(1);  // ← Update if index != 1
    },
    child: Scaffold(
      // ... rest of build
    ),
  );
}
```

**Test**:
```bash
# Generate any report
# Verify: Tab auto-switches
# Verify: Recent reports load automatically
# Verify: No manual navigation needed
```

---

## ✅ PRIORITY 3: TAB STATE PRESERVATION (2 hours)

**ONLY start if**:
- [ ] Phase 3: Auto-switch working

### Phase 4A: Add KeepAlive to StatefulWidget Tabs

**Screens to check** (from P0.6 results):

For each **StatefulWidget** screen:

```dart
// BEFORE
class GenerateTabScreen extends StatefulWidget { ... }
class _GenerateTabScreenState extends State<GenerateTabScreen> { ... }

// AFTER
class GenerateTabScreen extends StatefulWidget { ... }
class _GenerateTabScreenState extends State<GenerateTabScreen>
    with AutomaticKeepAliveClientMixin {  // ← Add mixin
  
  @override
  bool get wantKeepAlive => true;  // ← Add property
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // ← REQUIRED when using mixin
    return // ... existing UI
  }
}
```

**Apply to** (only StatefulWidget screens):
- [ ] GenerateTabScreen
- [ ] GeneratedReportsScreen
- [ ] StudentReportsScreen
- [ ] StaffReportsScreen
- [ ] ComplianceScreen

**Skip** if StatelessWidget (no state to preserve)

**Test**:
```bash
# Switch tabs rapidly
# Switch back to original tab
# Verify: Form values still present
# Verify: Scroll position preserved
# Verify: No data reload
```

---

## ⏳ PRIORITY 4: OPTIONAL ENHANCEMENTS (Only if time permits)

### Phase 5: Swipe Navigation (1.5 hours, ONLY if needed)

**SKIP if**:
- [ ] TabBarView already provides swipe (almost certainly does)

**Only implement if**:
- [ ] Custom PageView/scroll used
- [ ] Swipe explicitly required

**If implementing**:
```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    onHorizontalDragEnd: (details) {
      if (details.primaryVelocity == null) return;
      
      if (details.primaryVelocity! < -50) {
        // Swipe left
        if (_tabController.index < 4) {
          _tabController.animateTo(_tabController.index + 1);
        }
      } else if (details.primaryVelocity! > 50) {
        // Swipe right
        if (_tabController.index > 0) {
          _tabController.animateTo(_tabController.index - 1);
        }
      }
    },
    child: Scaffold(
      // ... rest of build
    ),
  );
}
```

---

### Phase 6: Download Feature (2-3 hours, ONLY if API found)

**BLOCKER**: Only if P0.3 found working endpoint

**If existing Asset/Document service found**:
- Reuse that instead of creating new
- Just add Download button to generated_report_card.dart
- ~30 minutes work

**If new endpoint verified**:
- Create ReportDownloadService
- Add to DI container
- Integrate with Report Card widget
- ~2-3 hours work

**Implementation** (if proceeding):

```dart
// File 1: lib/data/services/report_download_service.dart
class ReportDownloadService {
  final Dio _dio;
  
  ReportDownloadService(this._dio);
  
  Future<Uint8List> downloadReportFile({
    required String assetCode,
  }) async {
    final response = await _dio.get<List<int>>(
      ApiPaths.url('/api/v1/assets/$assetCode/download'),
      options: Options(responseType: ResponseType.bytes),
    );
    
    return Uint8List.fromList(response.data ?? []);
  }
}

// File 2: Update generated_report_card.dart
// Add Download button
// Call service on tap
// Save file to device
```

---

## FINAL IMPLEMENTATION ORDER (PRODUCTION-READY SEQUENCE)

| Priority | Phase | Task | Duration | Dependency | Start When |
|----------|-------|------|----------|------------|-----------|
| 🔴 P0.1 | Verification | Check tab structure | 15 min | None | NOW |
| 🔴 P0.2 | Investigation | Download API discovery | 30 min | None | NOW |
| 🔴 P0.3 | Investigation | Staff Attendance API verify | 30 min | None | NOW |
| 🔴 P0.4 | Verification | Test suite pass | 15 min | None | NOW |
| 🔴 P0.5 | Verification | TabBarView swipe check | 5 min | None | NOW |
| 🔴 P0.6 | Verification | Screen widget types | 10 min | None | NOW |
| 🔴 P0.7 | Audit | **Repository audit** (not just existence) | 20 min | None | NOW |
| 🔴 P0.8 | Audit | **Report type mapping verify** | 15 min | None | NOW |
| ✅ P1 | Phase 2A | Add ApiPaths constants | 30 min | P0 ✓ | After P0 |
| ✅ P1 | Phase 2B | Update datasource URLs | 45 min | 2A ✓ | After 2A |
| ✅ P1 | Phase 2C | Local validation (analyze + test) | 15 min | 2B ✓ | After 2B |
| ✅ P1 | Phase 2D | **UAT smoke test** | 15 min | 2C ✓ | After 2C |
| ✅ P2 | Phase 3 | Add TabController | 1.5 hrs | P1 ✓ | After P1 |
| ✅ P3 | Phase 4 | Add KeepAlive | 2 hrs | P2 ✓ | After P2 |
| ⏳ P4 | Phase 5 | Swipe (optional) | 1.5 hrs | P3 ✓ | If needed |
| ⏳ P4 | Phase 6 | Download (optional) | 0.5-3 hrs | P0.2 ✓ | If API found |
| **TOTAL** | | | **10-14 hrs** | | |

**Key Improvements**:
- ✅ P0 expanded: +40 min for deeper verification (P0.7 audit, P0.8 mapping check)
- ✅ P0.7 now verifies correctness, not just existence
- ✅ P0.8 new: Catches mapping bugs before blaming backend
- ✅ Phase 2 renamed: 2A/2B/2C/2D clearly labeled (ApiPaths → Datasource → Local → UAT)
- ✅ Phase 2C adds flutter analyze (catches import/type errors)
- ✅ All phases have explicit dependencies
- ✅ Total time realistic: 10-14 hours with proper discovery

---

## SUCCESS CRITERIA

### P0 Complete ✓
- [ ] P0.1: Tab count verified (index for animateTo confirmed)
- [ ] P0.2: Download endpoint found (or deferred) — existing service identified?
- [ ] P0.3: Staff Attendance API response checked (bug filed if needed)
- [ ] P0.4: Tests passing locally
- [ ] P0.5: Swipe support understood (TabBarView provides it)
- [ ] P0.6: KeepAlive target screens identified (StatefulWidget only)
- [ ] P0.7: Repository methods audited (existence + correctness verified)
- [ ] P0.8: Report type enum mapping verified (all values match backend)

### Phase 2 Complete ✓
- [ ] Phase 2A: 8 new constants in ApiPaths
- [ ] Phase 2B: All hardcoded URLs removed from datasource
- [ ] Phase 2C: Tests passing locally
- [ ] Phase 2D: UAT smoke test passed (no 404, correct microservice routing)

### Phase 3 Complete ✓
- [ ] TabController integrates with TabBar/TabBarView
- [ ] BlocListener triggers on successful generation
- [ ] Tab auto-switches to correct index
- [ ] Works for all 14 report types

### Phase 4 Complete ✓
- [ ] All StatefulWidget screens have KeepAlive mixin
- [ ] State preserved on tab switch
- [ ] No data reload on navigation
- [ ] Scroll position preserved

### Optional Features
- [ ] Phase 5: Swipe works (or confirm TabBarView already has it)
- [ ] Phase 6: Download button functional (if API endpoint found)

---

## 🚨 CRITICAL REMINDERS

1. **Do NOT skip P0** — 2 hours of verification before coding
2. **File backend ticket if Staff Attendance API bug found** — don't create frontend workarounds
3. **Search for existing asset/document services** before creating ReportDownloadService
4. **Only apply KeepAlive to StatefulWidget screens** — don't unnecessary convert StatelessWidget
5. **Confirm tab index before using _tabController.animateTo()** — off-by-one errors are common
6. **Run tests after Phase 2** — catch URL routing issues early
7. **TabBarView already has swipe** — Phase 5 may be completely unnecessary

---

## 📝 CHECKLIST FORMAT FOR TEAM

```
## P0: PRE-IMPLEMENTATION VERIFICATION (115 minutes total)

- [ ] P0.1: Tab structure (15 min)
  - [ ] Opened reports_screen.dart
  - [ ] Counted actual tabs
  - [ ] Identified "Generated" tab index
  - [ ] Documented: "Generated tab is at index ___"

- [ ] P0.2: Download API discovery (30 min) ← MOVED FIRST
  - [ ] Searched for AssetRepository
  - [ ] Searched for DocumentRepository
  - [ ] Found: _________ or None
  - [ ] If not found: Tested endpoint in Postman
  - [ ] Decision: Use existing / Test new / Defer

- [ ] P0.3: Staff Attendance API (30 min)
  - [ ] Tested in Postman
  - [ ] Captured request/response
  - [ ] Decision: Frontend bug / Backend bug / No issue
  - [ ] If bug: Ticket number ___

- [ ] P0.4: Test suite (15 min)
  - [ ] flutter test completed
  - [ ] All tests passing ✓
  - [ ] No broken Phase 3.3 changes

- [ ] P0.5: TabBarView swipe (5 min)
  - [ ] TabBarView found: Yes / No
  - [ ] Swipe already works: Yes / No
  - [ ] Phase 5 needed: Yes / No

- [ ] P0.6: Screen widget types (10 min)
  - [ ] GenerateTab: StatefulWidget ✓
  - [ ] GeneratedReports: StatefulWidget ✓
  - [ ] StudentReports: StatefulWidget ✓
  - [ ] StaffReports: StatefulWidget ✓
  - [ ] Compliance: StatefulWidget ✓

- [ ] P0.7: Repository audit (20 min) ← NEW & CRITICAL
  - [ ] generateReport() exists & calls datasource correctly
  - [ ] generateReport() caches result
  - [ ] generateReport() calls loadRecentReports() with unawaited()
  - [ ] getRecentReports() exists & merges 4 sources
  - [ ] getRecentStudentAttendanceReports() calls correct endpoint
  - [ ] getRecentStudentAttendanceReports() uses correct cache key
  - [ ] getRecentStaffAttendanceReports() calls correct endpoint
  - [ ] getRecentStaffAttendanceReports() uses correct cache key
  - [ ] getRecentStudentReports() calls correct endpoint
  - [ ] getRecentStudentReports() uses correct cache key
  - [ ] getRecentStaffReports() calls correct endpoint
  - [ ] getRecentStaffReports() uses correct cache key

- [ ] P0.8: Report type mapping audit (15 min) ← NEW & CRITICAL
  - [ ] enum ReportType defined correctly
  - [ ] All enum values have backendValue mapping
  - [ ] Student enums → STUDENT_* strings
  - [ ] Staff enums → STAFF_* strings
  - [ ] No typos in backendValue strings
  - [ ] Mapping is bidirectional (enum ↔ backend)

## Phase 2: API PATH REFACTORING (90 minutes)

- [ ] Phase 2A: ApiPaths constants added
  - [ ] 8 new constants added
  - [ ] Generate + Recent endpoints both included
  - [ ] All 3 microservices covered (attendance, student, staff)

- [ ] Phase 2B: Datasource URLs updated
  - [ ] No hardcoded URLs remain
  - [ ] All use ApiPaths constants
  - [ ] ApiPaths.url() used for full URL construction

- [ ] Phase 2C: Local tests pass
  - [ ] flutter test completed
  - [ ] No URL construction errors
  - [ ] No import errors

- [ ] Phase 2D: UAT smoke test (15 min) ← NEW & CRITICAL
  - [ ] Generate Student Attendance report: 200/201 ✓
  - [ ] Generate Student report: 200/201 ✓
  - [ ] Generate Staff report: 200/201 ✓
  - [ ] Load recent reports: no errors ✓
  - [ ] No 404 from microservice misrouting ✓
  - [ ] Screenshots captured

## Phase 3: TAB AUTO-SWITCH (90 minutes)

- [ ] TabController added to ReportsScreen
- [ ] BlocListener added for generatedReport
- [ ] Tab index set to ___ (from P0.1)
- [ ] Tested: Generate → Auto-switch works
- [ ] Tested: Recent reports auto-load
- [ ] Tested: All 14 report types work

## Phase 4: TAB STATE PRESERVATION (120 minutes)

- [ ] KeepAlive added to ___ screens (list them)
- [ ] Tested: State preserved on tab switch
- [ ] Tested: No data reload
- [ ] Tested: Scroll position preserved
- [ ] Tested: Form values preserved

## Optional Features (Only if time/requirements permit)

- [ ] Phase 5: Swipe (SKIP if TabBarView already has it)
- [ ] Phase 6: Download (implement only if P0.2 found API)
  - [ ] If existing service: Use that (30 min)
  - [ ] If new endpoint: Create service (2-3 hrs)
```

---

**END OF FINAL ACTION PLAN**

Ready for implementation. Start with P0 immediately.
