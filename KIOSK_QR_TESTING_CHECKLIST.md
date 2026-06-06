# Kiosk QR Code & School Name - Testing Checklist

**Date**: 2026-06-06  
**Status**: Ready for Testing  
**Bug**: QR and school name disappear on navigation (FIXED)

---

## ✅ **PRE-TEST SETUP**

- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter run`
- [ ] Wait for app to fully load
- [ ] Verify kiosk dashboard shows school name + QR

---

## 🧪 **TEST SCENARIO 1: PIN Flow Navigation**

**Steps**:
1. [ ] Open kiosk dashboard
2. [ ] Verify: School name visible (e.g., "ABC Childcare")
3. [ ] Verify: QR code visible
4. [ ] Enter PIN: `1234`
5. [ ] PIN verification completes
6. [ ] Navigate to student/staff flow
7. [ ] Return to kiosk dashboard (press back)

**Expected Results**:
- [ ] School name visible (NOT blank)
- [ ] QR code visible (NOT blank)
- [ ] QR is FRESH (not stale)

**Check Logs**:
```
[KIOSK] didChangeDependencies called - refreshing QR code
[KIOSK] 🔄 Refreshing QR code
[KIOSK] ✅ QR code loaded successfully (FRESH)
```

**Result**: ✅ PASS / ❌ FAIL

---

## 🧪 **TEST SCENARIO 2: Student Sign-In/Sign-Out Flow**

**Steps**:
1. [ ] Open kiosk dashboard
2. [ ] Verify: School name visible
3. [ ] Verify: QR code visible
4. [ ] Enter PIN for guardian persona
5. [ ] Complete student sign-in
6. [ ] Return to kiosk (via back button)

**Expected Results**:
- [ ] School name visible (NOT blank)
- [ ] QR code visible (NOT blank)
- [ ] Shows loading spinner while fetching fresh QR
- [ ] School name visible even during loading

**Check Logs**:
```
[KIOSK] didChangeDependencies called
[KIOSK] Loading state - using cached school name: ABC Childcare
[KIOSK] ✅ QR code loaded successfully (FRESH)
```

**Result**: ✅ PASS / ❌ FAIL

---

## 🧪 **TEST SCENARIO 3: App Minimize/Resume**

**Steps**:
1. [ ] Open kiosk dashboard
2. [ ] Verify: School name visible
3. [ ] Verify: QR code visible
4. [ ] Note QR content/appearance
5. [ ] Press home button (minimize app)
6. [ ] Wait 5 seconds
7. [ ] Return to app (tap app icon)

**Expected Results**:
- [ ] School name still visible
- [ ] QR code visible
- [ ] QR appears FRESH (may be different content)

**Check Logs**:
```
[KIOSK] App resumed - refreshing QR code
[KIOSK] 🔄 Refreshing QR code
[KIOSK] ✅ QR code loaded successfully (FRESH)
```

**Result**: ✅ PASS / ❌ FAIL

---

## 🧪 **TEST SCENARIO 4: Multiple Navigation Cycles**

**Steps**:
1. [ ] Dashboard → PIN → Student → Dashboard
2. [ ] Dashboard → PIN → Staff → Dashboard
3. [ ] Dashboard → (minimize) → Resume → Dashboard
4. [ ] Dashboard → PIN → Back → Dashboard

**For Each Cycle**:
- [ ] School name visible
- [ ] QR code visible
- [ ] No blank areas

**Result**: ✅ PASS / ❌ FAIL

---

## 🧪 **TEST SCENARIO 5: QR Loading States**

**Steps**:
1. [ ] Open kiosk dashboard
2. [ ] Watch for loading state
3. [ ] Observe school name during loading
4. [ ] Verify QR appears

**Expected During Loading State**:
- [ ] School name visible
- [ ] Loading spinner shown
- [ ] "Loading QR Code..." text shown
- [ ] NO blank areas

**Expected After Loading**:
- [ ] School name visible
- [ ] QR image visible
- [ ] Layout stable

**Result**: ✅ PASS / ❌ FAIL

---

## 🧪 **TEST SCENARIO 6: QR Error State**

**Steps** (simulate error):
1. [ ] Disable network
2. [ ] Return to kiosk dashboard
3. [ ] Observe error state

**Expected**:
- [ ] School name visible (NOT blank)
- [ ] Error message shown
- [ ] QR placeholder shown
- [ ] "Unable to load QR code" message

**Check Logs**:
```
[KIOSK] ❌ QR load failed
[KIOSK] Error state - using cached school name
```

**Result**: ✅ PASS / ❌ FAIL

---

## 📊 **LOG VERIFICATION**

### **Expected Log Messages**

**On First Load**:
```
[KIOSK] 🔄 Refreshing QR code - fetching FRESH QR from API
[KIOSK] ✅ QR code loaded successfully: XXXX chars (FRESH)
```

**On Return Navigation**:
```
[KIOSK] didChangeDependencies called - refreshing QR code
[KIOSK] Loading state - using cached school name: ABC Childcare
[KIOSK] ✅ QR code loaded successfully (FRESH)
```

**On App Resume**:
```
[KIOSK] App resumed - refreshing QR code
[KIOSK] 🔄 Refreshing QR code
[KIOSK] ✅ QR code loaded successfully (FRESH)
```

**On Error**:
```
[KIOSK] ❌ QR load failed: [error details]
[KIOSK] Error state - using cached school name: ABC Childcare
```

---

## 📱 **DEVICE TESTING**

- [ ] Test on Phone (Android)
- [ ] Test on Phone (iOS)
- [ ] Test on Tablet (iPad)
- [ ] Test on Tablet (Android)

---

## ✅ **FINAL VERIFICATION**

### **All Scenarios Pass**:
- [ ] PIN flow navigation
- [ ] Student sign-in/sign-out
- [ ] App minimize/resume
- [ ] Multiple navigation cycles
- [ ] QR loading states
- [ ] QR error states
- [ ] All devices tested

### **Quality Checks**:
- [ ] No blank school names
- [ ] No blank QR areas
- [ ] No missing layouts
- [ ] Smooth transitions
- [ ] Fresh QR on every entry
- [ ] Logs show refresh activity
- [ ] No app crashes

---

## 🎯 **SIGN-OFF**

**Tested By**: _________________  
**Date**: _________________  
**Result**: ✅ ALL PASS / ❌ SOME FAILED  

**Notes**:
_________________________________________________________________
_________________________________________________________________

---

## 🐛 **IF TEST FAILS**

1. **Check logs** - Filter for `[KIOSK]`
2. **Verify** - School name visible in all states
3. **Verify** - QR visible in all states
4. **Report** - Which scenario failed and why

Contact: codemaking5@gmail.com

