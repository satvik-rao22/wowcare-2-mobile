# REPORTS API IMPLEMENTATION - CHECKPOINTS & MILESTONES
**Purpose**: Track execution progress with objective go/no-go gates  
**Owner**: Engineering Team  
**Start Date**: [TBD - After P0 complete]

---

## PHASE 0: PRE-IMPLEMENTATION FINDINGS (2 hours)

**Timeline**: Before any code changes  
**Owner**: 1 engineer (verification)  
**Deliverable**: P0 Findings Report

### P0 Verification Checklist
```
P0.1: Tab Structure
  [ ] Generated Reports tab index: ___
  [ ] Total tab count: ___
  [ ] Separate or nested: ___

P0.2: Download Discovery
  [ ] AssetRepository exists: Yes/No
  [ ] DocumentRepository exists: Yes/No
  [ ] MediaService exists: Yes/No
  [ ] Download endpoint tested: Yes/No
  [ ] Endpoint location: ________________

P0.3: Staff Attendance API
  [ ] Backend returns STAFF_*: Yes/No
  [ ] Backend returns STUDENT_*: Yes/No (bug if true)
  [ ] Backend ticket filed: Yes/No
  [ ] Ticket #: ________________

P0.4: Test Suite
  [ ] flutter test passes: Yes/No
  [ ] Phase 3.3 changes stable: Yes/No

P0.5: TabBarView Swipe
  [ ] TabBarView used: Yes/No
  [ ] Swipe already works: Yes/No
  [ ] Phase 5 needed: Yes/No

P0.6: Widget Types
  [ ] GenerateTab: StatefulWidget/StatelessWidget
  [ ] GeneratedReports: StatefulWidget/StatelessWidget
  [ ] StudentReports: StatefulWidget/StatelessWidget
  [ ] StaffReports: StatefulWidget/StatelessWidget
  [ ] Compliance: StatefulWidget/StatelessWidget

P0.7: Repository Audit
  [ ] All 6 methods exist: Yes/No
  [ ] All call correct endpoints: Yes/No
  [ ] All use correct cache keys: Yes/No
  [ ] All map DTO→Entity correctly: Yes/No
  [ ] Issues found: ________________

P0.8: Enum Mapping
  [ ] All mappings verified: Yes/No
  [ ] No reversed mappings: Yes/No
  [ ] No typos: Yes/No
  [ ] Issues found: ________________
```

### Go/No-Go Decision
- [ ] **GO**: All P0 items pass → Proceed to Phase 2
- [ ] **NO-GO**: Blockers found → Document and resolve before Phase 2

---

## CHECKPOINT 1: API PATH REFACTORING (After Phase 2)

**Timeline**: After Phase 2A + 2B + 2C complete  
**Owner**: 1-2 engineers (refactoring)  
**Expected Duration**: 105 minutes  
**Gate**: MUST pass before Phase 3 starts

### Phase 2 Deliverables

**Phase 2A: ApiPaths Constants**
```dart
// lib/core/util/api_paths.dart
static const String studentAttendanceReportsGenerate = '/api/v1/...';
static const String studentAttendanceReportsRecent = '/api/v1/...';
static const String staffAttendanceReportsGenerate = '/api/v1/...';
static const String staffAttendanceReportsRecent = '/api/v1/...';
static const String studentReportsGenerate = '/api/v1/...';
static const String studentReportsRecent = '/api/v1/...';
static const String staffReportsGenerate = '/api/v1/...';
static const String staffReportsRecent = '/api/v1/...';
```

**Phase 2B: Datasource URLs Updated**
```
grep -n "'/api/v1/attendance/" lib/data/features/reports/datasources/reports_remote_datasource_impl.dart
grep -n "'/api/v1/student/student/" lib/data/features/reports/datasources/reports_remote_datasource_impl.dart
grep -n "'/api/v1/staff/staff/" lib/data/features/reports/datasources/reports_remote_datasource_impl.dart
```
Expected: 0 hardcoded URLs found

### Checkpoint 1 Verification
```bash
# MUST PASS before proceeding

flutter analyze
# Expected: No warnings or errors about ApiPaths

flutter test
# Expected: All tests pass

# Test on UAT
# Generate Student Attendance → 200/201
# Generate Student Report → 200/201  
# Generate Staff Report → 200/201
# Load recent reports → Success
# Check network log: No 404 errors
```

### Checkpoint 1 Go/No-Go
- [ ] **GO**: All 3 checks pass → Proceed to Phase 3
- [ ] **NO-GO**: Analyze fails OR tests fail OR UAT fails → Fix before Phase 3
  - [ ] If analyze failed: Fix import/type errors
  - [ ] If tests failed: Verify API paths correct
  - [ ] If UAT failed: Debug microservice routing (ApiPathsUat)

### UAT Baseline Capture (REQUIRED)
Save successful responses for regression testing:

**File**: `docs/reports/UAT_BASELINE_REPORTS_API.json`

```json
{
  "captured_date": "2026-06-05",
  "environment": "UAT",
  "test_school_code": "SCH_TEST_001",
  
  "endpoints": {
    "student_attendance": {
      "endpoint": "/api/v1/attendance/student-attendance/reports/recent",
      "method": "GET",
      "response_code": 200,
      "report_count": 5,
      "report_types": [
        "STUDENT_DAILY_ATTENDANCE",
        "STUDENT_ABSENT",
        "STUDENT_ATTENDANCE_PER_STUDENT"
      ],
      "sample_report": {
        "reportId": "RPT_...",
        "reportType": "STUDENT_DAILY_ATTENDANCE",
        "generatedAt": "2026-06-05T...",
        "fileName": "..."
      }
    },
    
    "student_reports": {
      "endpoint": "/api/v1/student/student/reports/recent",
      "method": "GET",
      "response_code": 200,
      "report_types": [
        "STUDENTS_AND_FAMILY",
        "EMERGENCY_CONTACTS",
        "IMMUNIZATION"
      ]
    },
    
    "staff_attendance": {
      "endpoint": "/api/v1/attendance/staff-attendance/reports/recent",
      "method": "GET",
      "response_code": 200,
      "report_types": [
        "STAFF_ATTENDANCE_PER_WEEK",
        "STAFF_ABSENT"
      ]
    },
    
    "staff_reports": {
      "endpoint": "/api/v1/staff/staff/reports/recent",
      "method": "GET",
      "response_code": 200,
      "report_types": [
        "STAFF_DETAILS"
      ]
    }
  }
}
```

---

## CHECKPOINT 2: TAB AUTO-SWITCH (After Phase 3)

**Timeline**: After Phase 3 complete  
**Owner**: 1 engineer (UI implementation)  
**Expected Duration**: 90 minutes  
**Gate**: MUST verify all 14 report types work

### Phase 3 Deliverables

**Changes**:
- TabController added to ReportsScreen
- BlocListener added for generatedReport state
- Tab index from P0.1 verified and used

### Checkpoint 2 Verification

**Test Case 1**: Student Attendance Report
```
1. Tap Generate on Student Daily Attendance form
2. Fill date field
3. Select format: PDF
4. Tap Generate
   Expected: Loading shown
5. Wait for completion
   Expected: Success snackbar
6. Wait for auto-switch
   Expected: Tab switches to "Generated Reports"
7. Check list
   Expected: New report visible at top
```

**Test Case 2**: All 14 Report Types
```
Repeat above for each:
- Student Daily Attendance ✓
- Student Absent ✓
- Student Attendance Per Student ✓
- Students & Family ✓
- School Immunization ✓
- Emergency Contact ✓
- School Incident ✓

- Staff Absent ✓
- Staff Attendance Per Week ✓
- Staff Details ✓
- Staff Scheduling ✓

- Annual State Immunization ✓
- Billing Plan ✓
- Billing Transaction ✓
```

### Checkpoint 2 Go/No-Go
- [ ] **GO**: All 14 types auto-switch and load → Proceed to Phase 4
- [ ] **NO-GO**: Any type fails → Debug before Phase 4
  - [ ] Tab doesn't switch? Check BlocListener listenWhen
  - [ ] Recent reports don't load? Check loadRecentReports() call
  - [ ] Wrong tab index? Verify P0.1 value used

---

## CHECKPOINT 3: FINAL UAT VALIDATION (After Phase 4)

**Timeline**: After Phase 4 complete  
**Owner**: QA + 1 engineer (validation)  
**Expected Duration**: 60 minutes  
**Gate**: FINAL approval before merge

### Phase 4 Deliverables

**Changes**:
- AutomaticKeepAliveClientMixin added to all StatefulWidget screens
- State preservation verified across tab switches

### Checkpoint 3 Verification

**Test Scenario 1**: Form State Preservation
```
1. Go to Student Daily Attendance form
2. Fill in:
   - Select classroom: "Room A"
   - Pick date: June 1, 2026
   - Select format: XLSX
3. Switch to Student Reports tab
4. Switch back to Student Daily Attendance
   Expected:
   - [ ] Classroom still selected: "Room A"
   - [ ] Date still selected: June 1, 2026
   - [ ] Format still selected: XLSX
   - No API reload
```

**Test Scenario 2**: Scroll Position Preservation
```
1. Go to Generated Reports tab
2. Scroll down to last report
3. Switch to Student Reports
4. Switch back to Generated Reports
   Expected:
   - [ ] Scroll position at last report
   - [ ] No jump to top
   - [ ] No API reload
```

**Test Scenario 3**: No Duplicate API Calls
```
1. Open Network tab in browser dev tools
2. Generate Student Daily Attendance report
3. Observe network tab for:
   Expected:
   - [ ] 1x POST to generate endpoint
   - [ ] 1x GET to recent reports endpoint
   - NO duplicate calls
   - NO cascading refreshes
```

**Test Scenario 4**: All Report Types Work End-to-End
```
For each of 14 report types:
  [ ] Form loads correctly
  [ ] All fields fill
  [ ] Can select format
  [ ] Can generate
  [ ] Tab auto-switches
  [ ] Report appears in recent
  [ ] State preserved on switch
```

**Test Scenario 5**: No Regression from Phase 3.3
```
Verify original Phase 3.3 features still work:
  [ ] Format selector visible
  [ ] PDF/XLSX options work
  [ ] Error snackbar shows on failure
  [ ] Success snackbar shows on success
  [ ] Recent reports auto-refresh
```

### Checkpoint 3 Go/No-Go
- [ ] **GO**: All scenarios pass → APPROVED for merge
- [ ] **NO-GO**: Any scenario fails → Debug and re-test
  - [ ] State not preserved? Check mixin application
  - [ ] Duplicate API calls? Check listener dependencies
  - [ ] Phase 3.3 regression? Revert and investigate

---

## OPTIONAL: PHASE 5 & 6

### Phase 5: Swipe Navigation (ONLY if checkpoint shows TabBarView needs custom implementation)
- [ ] Swipe left works
- [ ] Swipe right works
- [ ] Boundaries protected
- [ ] Test on iOS and Android

### Phase 6: Download Feature (ONLY if P0.2 found API endpoint)
- [ ] Download button visible
- [ ] Tap download → file downloads
- [ ] File saved to device
- [ ] Both PDF and XLSX work
- [ ] Permissions handled (Android 13+)

---

## REGRESSION TESTING

After all checkpoints pass, before merge to main:

```bash
# Run full test suite
flutter test

# Run analyzer
flutter analyze

# Manual regression on UAT
# - Generate all 14 report types
# - Verify no 404 errors
# - Verify all appear in recent reports
# - Compare UAT_BASELINE_REPORTS_API.json
#   (should match or show intentional changes)

# Code review
# - Verify no hardcoded URLs remain
# - Verify ApiPaths used consistently
# - Verify cache keys match
# - Verify error handling present
```

---

## SIGN-OFF

When all checkpoints pass:

```
P0 Findings Report: ✅ Signed by: __________ Date: __________
Checkpoint 1 (API Refactor): ✅ Signed by: __________ Date: __________
Checkpoint 2 (Tab Auto-Switch): ✅ Signed by: __________ Date: __________
Checkpoint 3 (Final Validation): ✅ Signed by: __________ Date: __________

Ready for merge to main: YES/NO

Signed: ________________ Date: __________
```

---

**Total Implementation Time**: 10-14 hours (including all checkpoints)

**Next Step**: Execute P0, then report findings before Phase 2 begins.
