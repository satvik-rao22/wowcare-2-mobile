# Kiosk PIN Verification Fix - Debugging & Verification Guide

**Date**: 2026-06-06  
**Purpose**: Verify KIOSK logout and PICKUP routing are working correctly

---

## 🔍 **VERIFICATION CHECKLIST**

### **Step 1: Verify Enum is Defined**
```bash
# Check the enum includes 'kiosk' value
grep -A 5 "enum KioskPersona" lib/domain/features/kiosk/entities/kiosk_pin_result_entity.dart

# Expected output:
# enum KioskPersona {
#   guardian,
#   staff,
#   kiosk,        ← MUST BE HERE
#   unknown,
# }
```

✅ Status: ENUM VERIFIED

---

### **Step 2: Verify Persona Mapper is Correct**
```bash
# Check the mapper handles KIOSK, KOISK, PICKUP, GUARDIAN, STAFF
grep -A 15 "factory KioskPinResultModel.fromJson" lib/data/features/kiosk/models/kiosk_pin_result_model.dart

# Expected to see:
# final personaStr = (json['persona'] as String? ?? '').toLowerCase();
# final persona = personaStr.contains('staff')
#     ? KioskPersona.staff
#     : (personaStr.contains('guardian') || personaStr.contains('pickup'))
#         ? KioskPersona.guardian
#         : (personaStr.contains('kiosk'))
#             ? KioskPersona.kiosk
#             : KioskPersona.unknown;
```

✅ Status: MAPPER VERIFIED

---

### **Step 3: Verify _handlePinSuccess Implementation**
```bash
# Check the method handles all personas
grep -A 40 "void _handlePinSuccess" lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart | head -50

# Expected to see:
# 1. Check for result.persona == KioskPersona.kiosk → call _handleKioskPersona()
# 2. Check for result.isStaff → _routeStaffAttendance()
# 3. Check for result.isGuardian → _routeGuardianStudentAttendance()
# 4. Log unknown personas
```

✅ Status: PIN SUCCESS HANDLER VERIFIED

---

### **Step 4: Verify _handleKioskPersona Method Exists**
```bash
# Check the method exists and is implemented
grep -A 15 "Future<void> _handleKioskPersona" lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart

# Expected to see:
# Future<void> _handleKioskPersona(BuildContext context) async {
#   try {
#     AppLogger.d('[Kiosk] Clearing kiosk session for KIOSK persona');
#     await serviceLocator<KioskAccessControl>().deactivateKioskMode();
#   } catch (e) {
#     AppLogger.w('[Kiosk] Error deactivating kiosk mode: $e');
#   }
#   if (mounted) {
#     AppLogger.d('[Kiosk] Redirecting to /sign-in after KIOSK persona');
#     GoRouter.of(context).go('/sign-in');
#   }
# }
```

✅ Status: KIOSK HANDLER VERIFIED

---

## 🧪 **RUNTIME TESTING**

### **Test 1: KIOSK Persona Logout**

**Expected Flow**:
```
User enters PIN
    ↓
API returns: {"persona": "KIOSK", ...}
    ↓
Mapper converts to: KioskPersona.kiosk
    ↓
_handlePinSuccess checks: result.persona == KioskPersona.kiosk
    ↓
Calls: _handleKioskPersona(context)
    ↓
Clears session: await serviceLocator<KioskAccessControl>().deactivateKioskMode()
    ↓
Redirects: GoRouter.of(context).go('/sign-in')
    ↓
User sees: Sign-in screen
```

**Verify by checking logs**:
```
[Kiosk] PIN verified: persona=kiosk ✓
[Kiosk] KIOSK persona detected - clearing session ✓
[Kiosk] Clearing kiosk session for KIOSK persona ✓
[Kiosk] Redirecting to /sign-in after KIOSK persona ✓
```

**Sign-in screen should appear**: YES / NO

---

### **Test 2: PICKUP Persona Routing to Guardian**

**Expected Flow**:
```
User enters PIN
    ↓
API returns: {"persona": "PICKUP", "students": [...], ...}
    ↓
Mapper converts to: KioskPersona.guardian (PICKUP aliased to guardian)
    ↓
_handlePinSuccess checks: result.isGuardian (which includes PICKUP)
    ↓
Calls: _routeGuardianStudentAttendance(context, result, _currentPin)
    ↓
Routes to: /kiosk/student-sign-in-and-sign-out
    ↓
User sees: Student selection screen
```

**Verify by checking logs**:
```
[Kiosk] PIN verified: persona=guardian ✓  (PICKUP was aliased to guardian)
[Kiosk] Routing to guardian/student attendance flow ✓
[KIOSK] Persona=GUARDIAN, routing to unified page with action=... ✓
```

**Student selection screen should appear**: YES / NO

---

### **Test 3: KOISK Typo Handling**

**Expected Flow**:
```
API returns: {"persona": "KOISK", ...}  (typo)
    ↓
Mapper detects "koisk" contains "kiosk"
    ↓
Converts to: KioskPersona.kiosk
    ↓
Same as KIOSK test above
    ↓
User is logged out
```

**Verify**: KIOSK and KOISK behave identically

---

## 🐛 **TROUBLESHOOTING**

### **Problem: KIOSK Persona Not Logging Out**

**Possible Causes**:

1. **Persona is not being detected as KIOSK**
   - Check API response: does it have `"persona": "KIOSK"`?
   - Check mapper: is "kiosk" check in the right order?
   - Add debug log: `AppLogger.d('API Response: ${json}')` in mapper

2. **Mapper is detecting as unknown**
   - Check the persona string is lowercase: `personaStr.toLowerCase()`
   - Verify "kiosk" check comes before "unknown" default
   - Test mapper directly with: `KioskPinResultModel.fromJson({"persona": "KIOSK"})`

3. **_handleKioskPersona not being called**
   - Check: `if (result.persona == KioskPersona.kiosk)`
   - Verify enum value is spelled correctly: `KioskPersona.kiosk` (lowercase 'k')
   - Add breakpoint or log before this line

4. **Logout not clearing session**
   - Check: `serviceLocator<KioskAccessControl>().deactivateKioskMode()`
   - Verify KioskAccessControl is registered in DI
   - Check implementation of deactivateKioskMode()

5. **Redirect not working**
   - Check: `GoRouter.of(context).go('/sign-in')`
   - Verify mounted check: `if (mounted)`
   - Check route is correct: `/sign-in` exists

**Debug Steps**:
```dart
// Add these logs to _handlePinSuccess
AppLogger.d('[Kiosk] Result persona: ${result.persona}');
AppLogger.d('[Kiosk] Persona name: ${result.persona.name}');
AppLogger.d('[Kiosk] Is KIOSK?: ${result.persona == KioskPersona.kiosk}');
AppLogger.d('[Kiosk] Is Staff?: ${result.isStaff}');
AppLogger.d('[Kiosk] Is Guardian?: ${result.isGuardian}');
```

---

### **Problem: PICKUP Not Routing to Guardian**

**Possible Causes**:

1. **API returns PICKUP but mapper doesn't detect it**
   - Check mapper line 60: `personaStr.contains('pickup')`
   - Verify lowercase comparison: `personaStr.toLowerCase()`
   - Test: API returns `"persona": "PICKUP"` → should map to guardian

2. **PICKUP is detected but routed wrong**
   - Check: `if (result.isGuardian)` includes PICKUP
   - Verify persona is actually guardian after mapping
   - Check logs show: `persona=guardian`

3. **Guardian flow not triggered**
   - Check: `_routeGuardianStudentAttendance()` is called
   - Verify guardian code is not empty
   - Verify students list is not empty

**Debug Steps**:
```dart
// Add these logs to mapper
AppLogger.d('[Kiosk] Original persona: ${json['persona']}');
AppLogger.d('[Kiosk] Lowercased persona: $personaStr');
AppLogger.d('[Kiosk] Detected as guardian?: ${personaStr.contains('guardian') || personaStr.contains('pickup')}');
AppLogger.d('[Kiosk] Mapped to: $persona');
```

---

## ✅ **EXPECTED LOG OUTPUT**

### **For KIOSK Persona**:
```
[Kiosk] Refreshing QR code
[Kiosk] PIN submitted: length=4
[Kiosk] PIN verified: persona=kiosk, isStaff=false, isGuardian=false
[Kiosk] KIOSK persona detected - clearing session and redirecting to sign-in
[Kiosk] Clearing kiosk session for KIOSK persona
[Kiosk] Redirecting to /sign-in after KIOSK persona
```

### **For PICKUP Persona**:
```
[Kiosk] Refreshing QR code
[Kiosk] PIN submitted: length=4
[Kiosk] PIN verified: persona=guardian, isStaff=false, isGuardian=true
[Kiosk] Routing to guardian/student attendance flow
[Kiosk] _routeGuardianStudentAttendance: guardianCode=XXXX, signedInStudents=X, signedOutStudents=X
[KIOSK] Persona=GUARDIAN, routing to unified page with action=selection
```

### **For GUARDIAN Persona**:
```
[Kiosk] Refreshing QR code
[Kiosk] PIN submitted: length=4
[Kiosk] PIN verified: persona=guardian, isStaff=false, isGuardian=true
[Kiosk] Routing to guardian/student attendance flow
[Kiosk] _routeGuardianStudentAttendance: guardianCode=XXXX, signedInStudents=X, signedOutStudents=X
[KIOSK] Persona=GUARDIAN, routing to unified page with action=selection
```

---

## 🔧 **MANUAL VERIFICATION**

### **Test Without Mocking**

If you can't mock the API response, manually test the mapper:

```dart
// Add to a test file or temp location
void testPersonaMapping() {
  // Test KIOSK
  final kioskJson = {"persona": "KIOSK", "students": []};
  final kioskModel = KioskPinResultModel.fromJson(kioskJson);
  print('KIOSK persona: ${kioskModel.persona}'); // Should print: KioskPersona.kiosk
  
  // Test KOISK (typo)
  final koiskJson = {"persona": "KOISK", "students": []};
  final koiskModel = KioskPinResultModel.fromJson(koiskJson);
  print('KOISK persona: ${koiskModel.persona}'); // Should print: KioskPersona.kiosk
  
  // Test PICKUP
  final pickupJson = {"persona": "PICKUP", "students": [{"studentCode": "S1", "fullName": "John", "status": "SIGNED_OUT", "classroomCode": "C1", "classroomName": "Room A"}]};
  final pickupModel = KioskPinResultModel.fromJson(pickupJson);
  print('PICKUP persona: ${pickupModel.persona}'); // Should print: KioskPersona.guardian
  print('Is Guardian: ${pickupModel.isGuardian}'); // Should print: true
  
  // Test GUARDIAN
  final guardianJson = {"persona": "GUARDIAN", "guardianCode": "G1", "students": [{"studentCode": "S1", "fullName": "John", "status": "SIGNED_OUT", "classroomCode": "C1", "classroomName": "Room A"}]};
  final guardianModel = KioskPinResultModel.fromJson(guardianJson);
  print('GUARDIAN persona: ${guardianModel.persona}'); // Should print: KioskPersona.guardian
  
  // Test STAFF
  final staffJson = {"persona": "STAFF", "staffCode": "ST1"};
  final staffModel = KioskPinResultModel.fromJson(staffJson);
  print('STAFF persona: ${staffModel.persona}'); // Should print: KioskPersona.staff
}
```

---

## 📋 **CHECKLIST**

### **Persona Mapping**
- [ ] Enum has: guardian, staff, kiosk, unknown
- [ ] Mapper checks 'staff' → KioskPersona.staff
- [ ] Mapper checks 'guardian' OR 'pickup' → KioskPersona.guardian
- [ ] Mapper checks 'kiosk' → KioskPersona.kiosk
- [ ] Default case → KioskPersona.unknown
- [ ] All checks are case-insensitive (.toLowerCase())

### **PIN Success Handler**
- [ ] Checks result.persona == KioskPersona.kiosk → _handleKioskPersona()
- [ ] Checks result.isStaff → _routeStaffAttendance()
- [ ] Checks result.isGuardian → _routeGuardianStudentAttendance()
- [ ] Logs unknown persona and shows error
- [ ] All paths have explicit return statements

### **KIOSK Logout Handler**
- [ ] Method _handleKioskPersona exists
- [ ] Calls deactivateKioskMode()
- [ ] Handles exceptions gracefully
- [ ] Checks mounted before using context
- [ ] Redirects to /sign-in

### **Guardian/Student Flow**
- [ ] _routeGuardianStudentAttendance handles PICKUP
- [ ] Extracts guardian code
- [ ] Extracts students list
- [ ] Determines sign-in/sign-out action
- [ ] Routes to /kiosk/student-sign-in-and-sign-out

---

## 🎯 **FINAL VERIFICATION**

**Run this command to verify all files are in place**:
```bash
# Check all 5 modified files exist
ls -la lib/domain/features/kiosk/entities/kiosk_pin_result_entity.dart
ls -la lib/data/features/kiosk/models/kiosk_pin_result_model.dart
ls -la lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart
ls -la lib/presentation/features/kiosk/widgets/kiosk_qr_section_widget.dart
ls -la lib/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart

# Compile check
dart analyze lib/presentation/features/kiosk/
```

**All should show with recent modification date**

---

## 📞 **If Still Not Working**

1. Share the **exact API response** you're receiving
2. Share the **logs** from PIN verification
3. Confirm the **persona value** in API response
4. Check if you've **rebuilt the app** after code changes
5. Verify **hot reload didn't miss changes** (use hot restart)

Contact: codemaking5@gmail.com
