# REPORTS API IMPLEMENTATION - HANDOFF TO TEAM
**Date**: 2026-06-05  
**Status**: ✅ READY FOR EXECUTION  
**Total Scope**: 10-14 hours (with discovery)  

---

## 📦 WHAT YOU'RE GETTING

Three comprehensive planning documents in the repo:

1. **REPORTS_API_INTEGRATION_PLAN.md**
   - Complete architecture analysis
   - Deep dive into existing patterns
   - Reference for understanding scope

2. **REPORTS_API_INTEGRATION_PLAN_REVISED.md**
   - Code review corrections applied
   - Architecture decisions clarified
   - Scope refined from 40-50 to 20-25 hours

3. **REPORTS_IMPLEMENTATION_READY.md** ← **START HERE**
   - Production-ready action plan
   - P0 verification checklist (130 minutes)
   - Phase-by-phase implementation (with dependencies)
   - Success criteria and risk mitigation

---

## 🔴 HIGHEST-RISK ITEMS (Do These First)

### P0.2: Download API Discovery (30 min)
**Why it matters**: Could eliminate an entire implementation phase

**Action**: Search codebase first
```bash
grep -r "AssetRepository\|DocumentRepository\|MediaService\|downloadFile" lib/data
```

**Outcome**:
- ✅ Found existing service? → Phase 6 = 30 minutes
- ❌ Not found? → Test endpoint in Postman, may take 2-3 hours

---

### P0.3: Staff Attendance API Verification (30 min)
**Why it matters**: May reveal backend bug (don't code around it)

**Action**: Test in Postman
```
GET /api/v1/attendance/staff-attendance/reports/recent?schoolCode=...
```

**Outcome**:
- ✅ Returns STAFF_* report types? → Proceed with implementation
- ❌ Returns STUDENT_* types? → File backend ticket, block Phase implementation
- 🤷 Other issue? → Investigate root cause

---

### P0.7: Repository Audit (20 min)
**Why it matters**: Methods can exist but call wrong endpoints

**Not just verify existence — verify correctness**:
```dart
getRecentStaffAttendanceReports()
  ✓ Calls: /api/v1/attendance/staff-attendance/reports/recent
  ✓ NOT: /api/v1/attendance/student-attendance/reports/recent
  ✓ Cache key: reports:staff_attendance_recent
  ✓ Maps: RecentReportModel → ReportMetadataEntity
```

---

### P0.8: Report Type Mapping Audit (15 min)
**Why it matters**: Frontend bug masquerading as backend issue

**Verify enum ↔ backend mapping**:
```dart
ReportType.staffAttendancePerWeek ↔ "STAFF_ATTENDANCE_PER_WEEK"
ReportType.studentDailyAttendance ↔ "STUDENT_DAILY_ATTENDANCE"

// NOT reversed:
ReportType.staffAttendancePerWeek ↔ "STUDENT_ATTENDANCE_PER_WEEK"
```

---

## ✅ FIRST CODE CHANGE (Start Here After P0)

### Phase 2: API Path Refactoring (105 minutes)

**Step 1: Phase 2A (30 min)**
```
File: lib/core/util/api_paths.dart
ADD: 8 new constants for report endpoints
```

**Step 2: Phase 2B (45 min)**
```
File: lib/data/features/reports/datasources/reports_remote_datasource_impl.dart
REPLACE: All hardcoded URLs with ApiPaths constants
```

**Step 3: Phase 2C (15 min)**
```bash
flutter analyze   # Catch import/type errors
flutter test      # Verify no breakage
```

**Step 4: Phase 2D (15 min)** 🚨 CRITICAL
```
Test on UAT environment:
  ✓ Generate Student Attendance report → 200/201
  ✓ Generate Student report → 200/201
  ✓ Generate Staff report → 200/201
  ✓ Load recent reports → no errors
  ✓ No 404 from microservice misrouting
```

**Capture baseline for regression testing**:
```json
{
  "student_attendance": {
    "endpoint": "/api/v1/attendance/student-attendance/reports/recent",
    "response_code": 200,
    "report_types": ["STUDENT_DAILY_ATTENDANCE", "STUDENT_ABSENT", ...]
  },
  "student_reports": {
    "endpoint": "/api/v1/student/student/reports/recent",
    "response_code": 200,
    "report_types": ["STUDENTS_AND_FAMILY", "EMERGENCY_CONTACTS", ...]
  },
  "staff_attendance": {
    "endpoint": "/api/v1/attendance/staff-attendance/reports/recent",
    "response_code": 200,
    "report_types": ["STAFF_ATTENDANCE_PER_WEEK", "STAFF_ABSENT"]
  },
  "staff_reports": {
    "endpoint": "/api/v1/staff/staff/reports/recent",
    "response_code": 200,
    "report_types": ["STAFF_DETAILS"]
  }
}
```

Save this as `UAT_BASELINE_REPORTS_API.json` in repo for future regression testing.

---

## 🎯 THEN EXECUTE IN ORDER

1. **Phase 3**: Tab Auto-Switch (90 min)
   - Add TabController to ReportsScreen
   - Add BlocListener to auto-switch on generation success
   - Test all 14 report types

2. **Phase 4**: Tab State Preservation (120 min)
   - Add AutomaticKeepAliveClientMixin to StatefulWidget screens
   - Verify state preserved on tab switch
   - Verify no data reload

3. **Phase 5** (Optional): Horizontal Swipe (90 min)
   - Only if TabBarView doesn't already support it
   - SKIP if TabBarView is used (it has built-in swipe)

4. **Phase 6** (Optional): Download Feature (30 min - 3 hours)
   - Only if P0.2 found API endpoint
   - If existing service found: reuse it (30 min)
   - If new endpoint: create service (2-3 hours)

---

## 🚨 CRITICAL REMINDERS

1. **Do NOT skip P0** — 130 minutes of verification saves 5+ hours of debugging
2. **File backend ticket if P0.3 finds bug** — don't create frontend workarounds
3. **Reuse existing services for P0.2** — don't build duplicate download logic
4. **Only apply KeepAlive to StatefulWidget** — don't unnecessarily convert StatelessWidget
5. **Confirm tab index in P0.1** — off-by-one errors in _tabController.animateTo() are common
6. **Run UAT smoke test before proceeding** — catch routing issues early
7. **Capture UAT baseline data** — makes regression testing future-proof

---

## ✅ SUCCESS CHECKLIST

### After P0 (Before any code):
- [ ] Tab structure verified (index confirmed)
- [ ] Download API found or deferred
- [ ] Staff Attendance API checked (no surprise bugs)
- [ ] Tests passing locally
- [ ] TabBarView swipe support understood
- [ ] KeepAlive target screens identified
- [ ] Repository methods audited (correctness verified)
- [ ] Report type enum mappings verified

### After Phase 2 (API Refactoring):
- [ ] 8 ApiPaths constants added
- [ ] All hardcoded URLs removed
- [ ] flutter analyze passes
- [ ] flutter test passes
- [ ] UAT smoke test passes (all 4 families working)
- [ ] UAT baseline captured

### After Phase 3 (Tab Auto-Switch):
- [ ] Generate report → tab switches automatically
- [ ] Recent reports load automatically
- [ ] No manual navigation needed
- [ ] Works for all 14 report types

### After Phase 4 (State Preservation):
- [ ] Switch tabs → state preserved
- [ ] No data reload
- [ ] Scroll position maintained
- [ ] Form values maintained

### Optional Features:
- [ ] Swipe navigation works (or TabBarView already has it)
- [ ] Download button functional (if endpoint exists)

---

## 📞 DECISION POINTS REQUIRING INPUT

### Decision 1: P0.2 (Download Endpoint)
If not found in codebase or Postman, team needs to decide:
- Defer Phase 6 to next sprint?
- Ask backend team for download API?
- Continue without download feature?

### Decision 2: P0.3 (Staff Attendance API)
If backend bug confirmed:
- Block Phase implementation?
- File ticket and proceed?
- Create temporary frontend workaround? (NOT recommended)

### Decision 3: Phase 5 (Swipe Navigation)
If TabBarView already has swipe:
- Skip Phase 5 entirely (save 1.5 hours)
- Or polish existing implementation?

---

## 📋 EXECUTION CHECKLIST

Print this and track progress:

```
P0: PRE-IMPLEMENTATION VERIFICATION (130 min)
  [ ] P0.1: Tab structure verified
  [ ] P0.2: Download discovery complete
  [ ] P0.3: Staff Attendance API checked
  [ ] P0.4: Test suite passing
  [ ] P0.5: TabBarView swipe verified
  [ ] P0.6: Widget types documented
  [ ] P0.7: Repository audit complete
  [ ] P0.8: Report type mapping verified

PHASE 2: API REFACTORING (105 min)
  [ ] Phase 2A: ApiPaths constants added (8 total)
  [ ] Phase 2B: Datasource URLs updated (6 endpoints)
  [ ] Phase 2C: Local validation passing (analyze + test)
  [ ] Phase 2D: UAT smoke test passing (all 4 families)
  [ ] UAT baseline captured and saved

PHASE 3: TAB AUTO-SWITCH (90 min)
  [ ] TabController added
  [ ] BlocListener implemented
  [ ] Auto-switch tested (all 14 types)
  [ ] Recent reports auto-load verified

PHASE 4: TAB STATE PRESERVATION (120 min)
  [ ] KeepAlive added to all StatefulWidget screens
  [ ] State preservation tested
  [ ] No data reload on switch
  [ ] Scroll position maintained

OPTIONAL: PHASE 5 (90 min - SKIP IF NOT NEEDED)
  [ ] Swipe navigation working

OPTIONAL: PHASE 6 (30 min - 3 hours, IF ENDPOINT FOUND)
  [ ] Download feature implemented
  [ ] Works for PDF and XLSX
  [ ] File permissions handled

FINAL UAT VALIDATION
  [ ] All 14 reports generate successfully
  [ ] Recent reports load for all families
  [ ] Tab navigation smooth
  [ ] No errors on UAT environment
```

---

## 📞 SUPPORT

If you need clarification:
1. Check the detailed plan: **REPORTS_IMPLEMENTATION_READY.md**
2. Reference existing patterns: **REPORTS_API_INTEGRATION_PLAN.md**
3. Review code decisions: **REPORTS_API_INTEGRATION_PLAN_REVISED.md**

---

## 🎉 YOU'RE READY

The plan is mature, scoped, and risk-mitigated. Execute P0 first, then follow the phases in order.

Expected timeline: **10-14 hours total** (including discovery and testing)

Good luck! 🚀
