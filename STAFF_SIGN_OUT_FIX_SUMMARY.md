# Staff Sign-Out Form Fix - Logged-In User Display

**Date**: 2026-06-01  
**Issue**: Sign-out form shows static "Staff Member" instead of actual logged-in user  
**Status**: ✅ FIXED

---

## The Problem

### Before Fix
When opening the sign-out form, it would display:
```
Staff Member
[Generic icon, no photo]
```

This happened because the form had a fallback dummy entity when no staff data was provided:
```dart
} else {
  _selectedStaff = <StaffEntity>[
    StaffEntity(id: 1, name: 'Staff Member', primaryRoomId: 1),
  ];
}
```

---

## The Solution

### Changed Approach
The sign-out form now properly loads the logged-in user's data, similar to the sign-in form:

1. **Load Current Staff Code** from secure storage
2. **Determine User Role** (admin vs. regular staff)
3. **Apply Selection Restrictions**:
   - Regular staff: Show only themselves
   - Admin: Can show/select multiple staff
4. **Pre-populate Form** with actual logged-in user data

### New Initialization Flow

```
StaffSignOutForm.initState()
  ↓
_initializeFormData() [async]
  ├─ Load current staff code from storage
  ├─ Apply staff selection restrictions
  │  ├─ If staffList provided: use it
  │  ├─ If staff provided: use it
  │  ├─ If current staff code exists:
  │  │  ├─ Try to find in staffList
  │  │  └─ If not found, load from storage
  │  └─ Last resort: create from storage (name, code, designation)
  ├─ Load persona flags (admin check, timezone)
  └─ ✅ Form ready with ACTUAL logged-in user
```

---

## Code Changes

### File: `staff_sign_out_form.dart`

**Added Fields**:
```dart
String? _currentStaffCode; // Current user's staff code
```

**Removed**:
- Direct staff initialization in initState
- Dummy "Staff Member" fallback

**Added Methods**:

#### `_initializeFormData()`
Async initialization that:
1. Loads current staff code from storage
2. Calls `_applyStaffSelectionRestrictions()`
3. Loads persona flags (async)
4. Handles QR token if present

#### `_applyStaffSelectionRestrictions()`
Determines which staff to show based on:
- `widget.staffList` - List of available staff (for admin)
- `widget.staff` - Single staff (direct parameter)
- `_currentStaffCode` - Currently logged-in user's code
- Storage fallback - Load name/designation from storage

#### `_createStaffFromStorage()`
Creates a complete StaffEntity from storage when needed:
- `StorageKeys.displayName` - User's full name
- `StorageKeys.staffCode` - User's staff code
- `StorageKeys.staffDesignation` - User's role/designation

---

## How It Works Now

### Regular Staff Sign-Out

```
Regular Staff opens Sign-Out form
  ↓
Form loads logged-in staff data from storage
  ├─ Staff Code: "STAFF001"
  ├─ Display Name: "John Smith"
  ├─ Designation: "Teacher"
  └─ Photo: [Retrieved from avatar]
  ↓
Form displays staff member card with:
  ✓ Photo/Avatar
  ✓ Name: "John Smith"
  ✓ Designation: "Teacher"
  ✓ Cannot be changed (self-only)
  ↓
Staff taps "Sign-Out" button
  ↓
API call submitted with staffCode + location
```

### Admin Sign-Out (Multiple Staff)

```
Admin opens Sign-Out form
  ↓
Form shows list of available staff
  ├─ Can select multiple staff
  ├─ Shows all staff with their data
  └─ Pre-selects logged-in admin
  ↓
Admin selects staff to sign out
  ↓
Form displays selected staff cards
  ├─ Each card shows photo, name, designation
  └─ Cards are removable
  ↓
Admin taps "Sign-Out" button
  ↓
API call submitted for all selected staff
```

---

## Data Sources (Priority Order)

The form tries to populate staff data in this order:

1. **`widget.staffList`** - Staff list provided by navigation
   - Used for multi-staff selection (admin)
   - Contains complete staff entities

2. **`widget.staff`** - Single staff provided by navigation
   - Used when navigating directly with staff object

3. **Found in staffList by code** - Search staffList for current staff code
   - Matches stored `_currentStaffCode` with `staff.staffCode`

4. **Loaded from Storage** - Last resort
   - Loads from secure storage keys:
     - `StorageKeys.staffCode`
     - `StorageKeys.displayName`
     - `StorageKeys.staffDesignation`

---

## API Payload

### Regular Staff Sign-Out
```json
{
  "staffCode": "STAFF001",
  "method": "APP",
  "latitude": 19.226339,
  "longitude": 73.098545,
  "withinGeofence": true,
  "timeZone": "Asia/Kolkata",
  "occurredAt": "2026-06-01T09:35:00Z"
}
```

### Admin Sign-Out (Multiple Staff)
```json
{
  "staffCode": "ADMIN001",
  "staffCodes": ["STAFF001", "STAFF002"],
  "classroomCode": "CR001",
  "classroomCodeByStaffCode": {
    "STAFF001": "CR001",
    "STAFF002": "CR001"
  },
  "method": "APP",
  "latitude": 19.226339,
  "longitude": 73.098545,
  "withinGeofence": true,
  "timeZone": "Asia/Kolkata",
  "occurredAt": "2026-06-01T09:35:00Z"
}
```

---

## Testing Checklist

### Regular Staff Sign-Out

- [ ] Open Staff Sign-Out form
- [ ] ✅ Shows logged-in staff member (not "Staff Member")
- [ ] Shows actual photo/avatar
- [ ] Shows actual name (e.g., "John Smith")
- [ ] Shows actual designation (e.g., "Teacher")
- [ ] Cannot select other staff (form restricted to self)
- [ ] Tap "Sign-Out" button
- [ ] ✅ Sign-out successful
- [ ] Check API call includes correct staffCode

### Admin Sign-Out (Multiple Staff)

- [ ] Open Staff Sign-Out form as admin
- [ ] ✅ Shows available staff list
- [ ] Can select multiple staff members
- [ ] All selected staff display with actual data
- [ ] Each staff card shows photo + name + designation
- [ ] Tap "Sign-Out" button
- [ ] ✅ All selected staff signed out
- [ ] Check API call includes staffCodes array

### QR Code Sign-Out

- [ ] Scan QR code for sign-out
- [ ] Form opens with logged-in staff displayed
- [ ] Form does NOT auto-submit
- [ ] Shows actual staff data (name, photo, designation)
- [ ] Tap "Sign-Out" button manually
- [ ] ✅ Sign-out successful
- [ ] Check API call includes qrToken

### Storage Fallback

- [ ] Scenario: No staff data provided to form
- [ ] Form loads from storage (name, code, designation)
- [ ] ✅ Staff member displayed correctly
- [ ] All data populated from StorageKeys

---

## Storage Keys Used

| Key | Purpose | Example |
|-----|---------|---------|
| `StorageKeys.staffCode` | Logged-in user's staff code | "STAFF001" |
| `StorageKeys.displayName` | User's full name | "John Smith" |
| `StorageKeys.staffDesignation` | User's role/title | "Teacher" |

These are set during login and used for identifying the user.

---

## Benefits

✅ **Actual User Display** - Shows real logged-in user, not generic placeholder  
✅ **Consistent with Sign-In** - Same pattern as sign-in form  
✅ **Graceful Fallback** - Works even without initial staff data  
✅ **Admin Support** - Properly handles multi-staff sign-out  
✅ **QR Support** - Works with QR code scanning  
✅ **Role-Based** - Restricts regular staff to self-only  

---

## No Breaking Changes

- ✅ Still accepts `staff` parameter for direct navigation
- ✅ Still accepts `staffList` parameter for admin multi-select
- ✅ Still accepts `qrToken` for QR-based sign-out
- ✅ API payload structure unchanged
- ✅ All existing functionality preserved

---

## Summary

The sign-out form now properly displays the logged-in user instead of a generic "Staff Member". It uses the same initialization pattern as the sign-in form, loading user data from:
1. Navigation parameters (staff/staffList)
2. Lookup in provided list by staff code
3. Secure storage as fallback

The form works for both regular staff (self-only) and admin (multi-select) scenarios.

✅ **Ready for Testing!**
