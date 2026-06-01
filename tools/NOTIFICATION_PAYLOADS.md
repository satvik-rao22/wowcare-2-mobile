# Push Notification Payload Contract (Mobile)

How the backend should shape FCM pushes so the mobile app redirects + highlights
correctly. **Approved & verified modules: Student, Staff, Classroom, Activity, Attendance, Scheduling.**

## Rules (apply to every notification)

1. Put the structured fields in the FCM **`data`** map (NOT only in `notification`).
   `notification.title` / `notification.body` are just the tray text.
2. **All `data` values are strings** (FCM requirement).
3. `action` is **required** and must match one of the strings below **exactly**
   (UPPER_SNAKE_CASE). It is the only field that drives redirection.
4. `type` is informational (module name) — optional, not used for routing.
5. Code keys may be camelCase or snake_case (`studentCode` or `student_code`);
   **camelCase preferred**.
6. The app routes from the `data` map alone, then loads the entity by its code —
   so **always send the real code** of the affected entity.

### FCM message shape

```json
{
  "message": {
    "token": "<device-fcm-token>",
    "notification": { "title": "Activity", "body": "A new activity was recorded." },
    "data": {
      "action": "ACTIVITY_RECORDED",
      "type": "ACTIVITIES",
      "activityCode": "ACG_3F24C869-7",
      "activityDate": "2026-05-31T16:39:00Z",
      "studentCode": "STD_7B1D6DFF-8"
    }
  }
}
```

---

## Classroom  (`type: CLASSROOM`)

| `action` | Required `data` keys | Optional |
|---|---|---|
| `ADD_CLASSROOM` | `classroomCode` | `classroomName` |
| `EDIT_CLASSROOM` | `classroomCode` | `classroomName` |
| `DELETE_CLASSROOM` | `classroomCode` | `classroomName` |
| `ASSIGN_STUDENT_TO_CLASSROOM` | `classroomCode`, `studentCode` | `classroomName` |
| `ASSIGN_STAFF_TO_CLASSROOM` | `classroomCode`, `staffCode` | `classroomName` |
| `ADD_CLASSROOM_NOTE` | `classroomCode` | — |

## Student  (`type: STUDENT`)

| `action` | Required `data` keys |
|---|---|
| `ADD_STUDENT` | `studentCode` |
| `DELETE_STUDENT` | `studentCode` |
| `STUDENT_PARENT_NOT_ADDED` | `studentCode` |
| `STUDENT_SCHEDULE_NOT_ADDED` | `studentCode` |
| `STUDENT_PHYSICAL_NOT_ADDED` | `studentCode` |
| `STUDENT_PHYSICAL_DUE` | `studentCode` |
| `STUDENT_PHYSICAL_OVERDUE` | `studentCode` |
| `STUDENT_IMMUNIZATION_DUE_OVERDUE` | `studentCode` |
| `STUDENT_BIRTHDATE_NOT_ADDED` | `studentCode` |
| `STUDENT_DOCUMENT_CHANGED` | `studentCode`, `documentCode` |

## Staff  (`type: STAFF`)

| `action` | Required `data` keys |
|---|---|
| `DELETE_STAFF` | `staffCode` |
| `STAFF_SCHEDULE_NOT_ADDED` | `staffCode` |
| `STAFF_PHYSICAL_NOT_ADDED` | `staffCode` |
| `STAFF_DOCUMENT_EXPIRY` | `staffCode`, `documentCode` |

## Activity  (`type: ACTIVITIES`)

> **`activityDate` is REQUIRED** — the app opens the Activity Feed on that day to
> flash the card. Without it the feed opens on *today* and an older activity won't
> be highlighted. ISO date or datetime accepted (`2026-05-31` or `2026-05-31T16:39:00Z`).

| `action` | Required `data` keys | Optional |
|---|---|---|
| `ACTIVITY_RECORDED` | `activityCode`, `activityDate` | `studentCode`, `activityType` |
| `INCIDENT_APPROVAL_PENDING` | `activityCode`, `activityDate` | `studentCode` |
| `INCIDENT_ACKNOWLEDGEMENT_PENDING` | `activityCode`, `activityDate` | `studentCode` |
| `NAP_ALERT` | `activityCode`, `activityDate` | `studentCode` |

## Attendance  (`type: ATTENDANCE`)

| `action` | Required `data` keys |
|---|---|
| `RATIO_BREACHED` | `classroomCode` |
| `CAPACITY_EXCEEDED` | `classroomCode` |
| `STUDENT_SIGN_IN_OUT` | `studentCode` |
| `STUDENT_MARKED_ABSENT` | `studentCode` |
| `STAFF_SIGN_IN_OUT` | `staffCode` |
| `STAFF_MARKED_ABSENT` | `staffCode` |
| `ATTENDANCE_NOT_MARKED` | `studentCode` **or** `staffCode` |

## Scheduling  (`type: SCHEDULING`)

> The 4 shift actions open the **per-staff Staff Scheduling day view**: it jumps to
> `shiftDate`, selects `staffCode`, and flashes the shift block by `shiftCode`. So
> **`shiftDate` + `staffCode` + `shiftCode` are all required.**
> `SHIFT_UNDER_RATIO` is different — it has **no shift**; it opens the main
> Scheduling **day view** on `blockDate` and flashes the classroom block, so it
> needs **`classroomCode` + `blockDate`**.

| `action` | Required `data` keys | Opens |
|---|---|---|
| `PUBLISH_SHIFT` | `shiftCode`, `staffCode`, `shiftDate` | staff-scheduling, day=shiftDate, flash shift |
| `UPCOMING_SHIFT` | `shiftCode`, `staffCode`, `shiftDate` | staff-scheduling, day=shiftDate, flash shift |
| `EDIT_SHIFT` | `shiftCode`, `staffCode`, `shiftDate` | staff-scheduling, day=shiftDate, flash shift |
| `DELETE_SHIFT` | `shiftCode`, `staffCode`, `shiftDate` | staff-scheduling, day=shiftDate, flash shift |
| `SHIFT_UNDER_RATIO` | `classroomCode`, `blockDate` | scheduling **day view**, flash classroom block |

---

# JSON message bodies (one per action)

Sample codes used below — replace with the real codes of the affected entity:
`CLS_72A4628B-8` (Blue-D), `STD_7B1D6DFF-8`, `STF_BA1B3E80-F`,
`AST_AB31A82B-4` (document), `ACG_3F24C869-7` (activity).

## Classroom

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "Classroom Blue-D has been added." },
  "data": { "action": "ADD_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "Classroom Blue-D has been edited." },
  "data": { "action": "EDIT_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "Classroom Blue-D has been deactivated." },
  "data": { "action": "DELETE_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "A student was assigned to Blue-D." },
  "data": { "action": "ASSIGN_STUDENT_TO_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "A staff member was assigned to Blue-D." },
  "data": { "action": "ASSIGN_STAFF_TO_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "staffCode": "STF_BA1B3E80-F" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "A note was added to Blue-D." },
  "data": { "action": "ADD_CLASSROOM_NOTE", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8" } } }
```

## Student

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "A new student was added." },
  "data": { "action": "ADD_STUDENT", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "A student was deactivated." },
  "data": { "action": "DELETE_STUDENT", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Parent not added." },
  "data": { "action": "STUDENT_PARENT_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Schedule not added." },
  "data": { "action": "STUDENT_SCHEDULE_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Last physical not added." },
  "data": { "action": "STUDENT_PHYSICAL_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Physical due." },
  "data": { "action": "STUDENT_PHYSICAL_DUE", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Physical overdue." },
  "data": { "action": "STUDENT_PHYSICAL_OVERDUE", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Immunization due/overdue." },
  "data": { "action": "STUDENT_IMMUNIZATION_DUE_OVERDUE", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Birthdate not added." },
  "data": { "action": "STUDENT_BIRTHDATE_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "A document was added/deleted." },
  "data": { "action": "STUDENT_DOCUMENT_CHANGED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "documentCode": "AST_AB31A82B-4" } } }
```

## Staff

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "A staff member was deactivated." },
  "data": { "action": "DELETE_STAFF", "type": "STAFF", "staffCode": "STF_BA1B3E80-F" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "Schedule not added." },
  "data": { "action": "STAFF_SCHEDULE_NOT_ADDED", "type": "STAFF", "staffCode": "STF_BA1B3E80-F" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "Last physical not added." },
  "data": { "action": "STAFF_PHYSICAL_NOT_ADDED", "type": "STAFF", "staffCode": "STF_BA1B3E80-F" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "A document is expiring." },
  "data": { "action": "STAFF_DOCUMENT_EXPIRY", "type": "STAFF", "staffCode": "STF_BA1B3E80-F", "documentCode": "AST_AB31A82B-4" } } }
```

## Activity  (`activityDate` required)

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Activity", "body": "A new activity was recorded." },
  "data": { "action": "ACTIVITY_RECORDED", "type": "ACTIVITIES", "activityCode": "ACG_3F24C869-7", "activityDate": "2026-05-31T16:39:00Z", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Incident", "body": "An incident report is pending approval." },
  "data": { "action": "INCIDENT_APPROVAL_PENDING", "type": "ACTIVITIES", "activityCode": "ACG_4F543BBF-4", "activityDate": "2026-05-30T19:07:00Z", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Incident", "body": "An incident report is pending acknowledgement." },
  "data": { "action": "INCIDENT_ACKNOWLEDGEMENT_PENDING", "type": "ACTIVITIES", "activityCode": "ACG_4F543BBF-4", "activityDate": "2026-05-30T19:07:00Z", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Nap Alert", "body": "A nap activity needs your attention." },
  "data": { "action": "NAP_ALERT", "type": "ACTIVITIES", "activityCode": "ACG_028FE987-C", "activityDate": "2026-05-30T11:36:00Z", "studentCode": "STD_7B1D6DFF-8" } } }
```

## Scheduling

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A shift was published." },
  "data": { "action": "PUBLISH_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-348896A3-2", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-26" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "You have an upcoming shift." },
  "data": { "action": "UPCOMING_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-348896A3-2", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-26" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A shift was edited." },
  "data": { "action": "EDIT_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-E0209D0B-8", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-29" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A shift was deleted." },
  "data": { "action": "DELETE_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-348896A3-2", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-26" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A classroom is under ratio." },
  "data": { "action": "SHIFT_UNDER_RATIO", "type": "SCHEDULING", "classroomCode": "CLS_984ABCFA-B", "blockDate": "2026-05-31" } } }
```

## Attendance

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "Student-to-staff ratio breached in Blue-D." },
  "data": { "action": "RATIO_BREACHED", "type": "ATTENDANCE", "classroomCode": "CLS_72A4628B-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "Capacity exceeded in Blue-D." },
  "data": { "action": "CAPACITY_EXCEEDED", "type": "ATTENDANCE", "classroomCode": "CLS_72A4628B-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A student signed in/out." },
  "data": { "action": "STUDENT_SIGN_IN_OUT", "type": "ATTENDANCE", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A student was marked absent." },
  "data": { "action": "STUDENT_MARKED_ABSENT", "type": "ATTENDANCE", "studentCode": "STD_7B1D6DFF-8" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A staff member signed in/out." },
  "data": { "action": "STAFF_SIGN_IN_OUT", "type": "ATTENDANCE", "staffCode": "STF_BA1B3E80-F" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A staff member was marked absent." },
  "data": { "action": "STAFF_MARKED_ABSENT", "type": "ATTENDANCE", "staffCode": "STF_BA1B3E80-F" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "Attendance not marked yet." },
  "data": { "action": "ATTENDANCE_NOT_MARKED", "type": "ATTENDANCE", "studentCode": "STD_7B1D6DFF-8" } } }
```
