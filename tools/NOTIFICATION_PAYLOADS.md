# Push Notification Payload Contract (Mobile)

How the backend should shape FCM pushes so the mobile app redirects + highlights
correctly. **Approved & verified modules: Student, Staff, Classroom, Activity, Attendance, Scheduling, Availability (Movements).**

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
7. **`organizationCode` + `schoolCode` are REQUIRED on every push.** A user can be
   connected to more than one school (same org, different school, or a different
   org). The app compares these to the currently-selected school and, if they
   differ, **auto-switches to that org/school *before* performing the redirect** so
   the target screen loads the correct school's data. Send the org/school the
   affected entity belongs to. (`orgCode` is also accepted as an alias for
   `organizationCode`.)

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
      "studentCode": "STD_7B1D6DFF-8",
      "organizationCode": "ORG_67F60097-C",
      "schoolCode": "SCH_74709D20-7"
    }
  }
}
```

---

## Classroom  (`type: CLASSROOM`)

| `action` | Required `data` keys | Optional |
|---|---|---|
| `ADD_CLASSROOM` | `classroomCode`, `organizationCode`, `schoolCode` | `classroomName` |
| `EDIT_CLASSROOM` | `classroomCode`, `organizationCode`, `schoolCode` | `classroomName` |
| `DELETE_CLASSROOM` | `classroomCode`, `organizationCode`, `schoolCode` | `classroomName` |
| `ASSIGN_STUDENT_TO_CLASSROOM` | `classroomCode`, `studentCode`, `organizationCode`, `schoolCode` | `classroomName` |
| `ASSIGN_STAFF_TO_CLASSROOM` | `classroomCode`, `staffCode`, `organizationCode`, `schoolCode` | `classroomName` |
| `ADD_CLASSROOM_NOTE` | `classroomCode`, `organizationCode`, `schoolCode` | — |

## Student  (`type: STUDENT`)

| `action` | Required `data` keys |
|---|---|
| `ADD_STUDENT` | `studentCode`, `organizationCode`, `schoolCode` |
| `DELETE_STUDENT` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_PARENT_NOT_ADDED` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_SCHEDULE_NOT_ADDED` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_PHYSICAL_NOT_ADDED` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_PHYSICAL_DUE` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_PHYSICAL_OVERDUE` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_IMMUNIZATION_DUE_OVERDUE` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_BIRTHDATE_NOT_ADDED` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_DOCUMENT_CHANGED` | `studentCode`, `documentCode`, `organizationCode`, `schoolCode` |

## Staff  (`type: STAFF`)

| `action` | Required `data` keys |
|---|---|
| `DELETE_STAFF` | `staffCode`, `organizationCode`, `schoolCode` |
| `STAFF_SCHEDULE_NOT_ADDED` | `staffCode`, `organizationCode`, `schoolCode` |
| `STAFF_PHYSICAL_NOT_ADDED` | `staffCode`, `organizationCode`, `schoolCode` |
| `STAFF_DOCUMENT_EXPIRY` | `staffCode`, `documentCode`, `organizationCode`, `schoolCode` |

## Activity  (`type: ACTIVITIES`)

> **`activityDate` is REQUIRED** — the app opens the Activity Feed on that day to
> flash the card. Without it the feed opens on *today* and an older activity won't
> be highlighted. ISO date or datetime accepted (`2026-05-31` or `2026-05-31T16:39:00Z`).

| `action` | Required `data` keys | Optional |
|---|---|---|
| `ACTIVITY_RECORDED` | `activityCode`, `activityDate`, `organizationCode`, `schoolCode` | `studentCode`, `activityType` |
| `INCIDENT_APPROVAL_PENDING` | `activityCode`, `activityDate`, `organizationCode`, `schoolCode` | `studentCode` |
| `INCIDENT_ACKNOWLEDGEMENT_PENDING` | `activityCode`, `activityDate`, `organizationCode`, `schoolCode` | `studentCode` |
| `NAP_ALERT` | `activityCode`, `activityDate`, `organizationCode`, `schoolCode` | `studentCode` |

## Attendance  (`type: ATTENDANCE`)

| `action` | Required `data` keys |
|---|---|
| `RATIO_BREACHED` | `classroomCode`, `organizationCode`, `schoolCode` |
| `CAPACITY_EXCEEDED` | `classroomCode`, `organizationCode`, `schoolCode` |
| `STUDENT_SIGN_IN_OUT` | `studentCode`, `organizationCode`, `schoolCode` |
| `STUDENT_MARKED_ABSENT` | `studentCode`, `organizationCode`, `schoolCode` |
| `STAFF_SIGN_IN_OUT` | `staffCode`, `organizationCode`, `schoolCode` |
| `STAFF_MARKED_ABSENT` | `staffCode`, `organizationCode`, `schoolCode` |
| `ATTENDANCE_NOT_MARKED` | (`studentCode` **or** `staffCode`), `organizationCode`, `schoolCode` |

## Scheduling  (`type: SCHEDULING`)

> The 4 shift actions open the **per-staff Staff Scheduling day view**: it jumps to
> `shiftDate`, selects `staffCode`, and flashes the shift block by `shiftCode`. So
> **`shiftDate` + `staffCode` + `shiftCode` are all required.**
> `SHIFT_UNDER_RATIO` is different — it has **no shift**; it opens the main
> Scheduling **day view** on `blockDate` and flashes the classroom block, so it
> needs **`classroomCode` + `blockDate`**.

| `action` | Required `data` keys | Opens |
|---|---|---|
| `PUBLISH_SHIFT` | `shiftCode`, `staffCode`, `shiftDate`, `organizationCode`, `schoolCode` | staff-scheduling, day=shiftDate, flash shift |
| `UPCOMING_SHIFT` | `shiftCode`, `staffCode`, `shiftDate`, `organizationCode`, `schoolCode` | staff-scheduling, day=shiftDate, flash shift |
| `EDIT_SHIFT` | `shiftCode`, `staffCode`, `shiftDate`, `organizationCode`, `schoolCode` | staff-scheduling, day=shiftDate, flash shift |
| `DELETE_SHIFT` | `shiftCode`, `staffCode`, `shiftDate`, `organizationCode`, `schoolCode` | staff-scheduling, day=shiftDate, flash shift |
| `SHIFT_UNDER_RATIO` | `classroomCode`, `blockDate`, `organizationCode`, `schoolCode` | scheduling **day view**, flash classroom block |

## Availability — Movements  (`type: AVAILABILITY`)

> Movement actions open the **Individual Movements** screen, auto-jump to the bucket
> (Overdue / Upcoming / Confirmed / Rejected) holding the highlighted card, and flash
> it by `movement_id` (or `movement_code`). The two rule actions open the Future
> Availability screen.

| `action` | Required `data` keys | Opens |
|---|---|---|
| `CREATE_MOVEMENT` | `movement_id` (or `movement_code`), `organizationCode`, `schoolCode` | individual-movement, flash movement |
| `UPCOMING_MOVEMENT` | `movement_id` (or `movement_code`), `organizationCode`, `schoolCode` | individual-movement, flash movement |
| `CONFIRMED_MOVEMENT` | `movement_id` (or `movement_code`), `organizationCode`, `schoolCode` | individual-movement, flash movement |
| `MOVEMENT_OVERDUE` | `movement_id` (or `movement_code`), `organizationCode`, `schoolCode` | individual-movement, flash movement |
| `MOVEMENT_REJECTED` | `movement_id` (or `movement_code`), `organizationCode`, `schoolCode` | individual-movement, flash movement |
| `CREATE_RULE` | `organizationCode`, `schoolCode` | future-availability |
| `DEACTIVATE_RULE` | `organizationCode`, `schoolCode` | future-availability |

---

# JSON message bodies (one per action)

Sample codes used below — replace with the real codes of the affected entity and
its org/school:
`ORG_67F60097-C` (organization), `SCH_74709D20-7` (school),
`CLS_72A4628B-8` (Blue-D), `STD_7B1D6DFF-8`, `STF_BA1B3E80-F`,
`AST_AB31A82B-4` (document), `ACG_3F24C869-7` (activity),
`MOV-39A30866-2` / `152` (movement).

## Classroom

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "Classroom Blue-D has been added." },
  "data": { "action": "ADD_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "Classroom Blue-D has been edited." },
  "data": { "action": "EDIT_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "Classroom Blue-D has been deactivated." },
  "data": { "action": "DELETE_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "A student was assigned to Blue-D." },
  "data": { "action": "ASSIGN_STUDENT_TO_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "A staff member was assigned to Blue-D." },
  "data": { "action": "ASSIGN_STAFF_TO_CLASSROOM", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "classroomName": "Blue-D", "staffCode": "STF_BA1B3E80-F", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Classroom", "body": "A note was added to Blue-D." },
  "data": { "action": "ADD_CLASSROOM_NOTE", "type": "CLASSROOM", "classroomCode": "CLS_72A4628B-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

## Student

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "A new student was added." },
  "data": { "action": "ADD_STUDENT", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "A student was deactivated." },
  "data": { "action": "DELETE_STUDENT", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Parent not added." },
  "data": { "action": "STUDENT_PARENT_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Schedule not added." },
  "data": { "action": "STUDENT_SCHEDULE_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Last physical not added." },
  "data": { "action": "STUDENT_PHYSICAL_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Physical due." },
  "data": { "action": "STUDENT_PHYSICAL_DUE", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Physical overdue." },
  "data": { "action": "STUDENT_PHYSICAL_OVERDUE", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Immunization due/overdue." },
  "data": { "action": "STUDENT_IMMUNIZATION_DUE_OVERDUE", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "Birthdate not added." },
  "data": { "action": "STUDENT_BIRTHDATE_NOT_ADDED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Student", "body": "A document was added/deleted." },
  "data": { "action": "STUDENT_DOCUMENT_CHANGED", "type": "STUDENT", "studentCode": "STD_7B1D6DFF-8", "documentCode": "AST_AB31A82B-4", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

## Staff

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "A staff member was deactivated." },
  "data": { "action": "DELETE_STAFF", "type": "STAFF", "staffCode": "STF_BA1B3E80-F", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "Schedule not added." },
  "data": { "action": "STAFF_SCHEDULE_NOT_ADDED", "type": "STAFF", "staffCode": "STF_BA1B3E80-F", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "Last physical not added." },
  "data": { "action": "STAFF_PHYSICAL_NOT_ADDED", "type": "STAFF", "staffCode": "STF_BA1B3E80-F", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Staff", "body": "A document is expiring." },
  "data": { "action": "STAFF_DOCUMENT_EXPIRY", "type": "STAFF", "staffCode": "STF_BA1B3E80-F", "documentCode": "AST_AB31A82B-4", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

## Activity  (`activityDate` required)

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Activity", "body": "A new activity was recorded." },
  "data": { "action": "ACTIVITY_RECORDED", "type": "ACTIVITIES", "activityCode": "ACG_3F24C869-7", "activityDate": "2026-05-31T16:39:00Z", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Incident", "body": "An incident report is pending approval." },
  "data": { "action": "INCIDENT_APPROVAL_PENDING", "type": "ACTIVITIES", "activityCode": "ACG_4F543BBF-4", "activityDate": "2026-05-30T19:07:00Z", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Incident", "body": "An incident report is pending acknowledgement." },
  "data": { "action": "INCIDENT_ACKNOWLEDGEMENT_PENDING", "type": "ACTIVITIES", "activityCode": "ACG_4F543BBF-4", "activityDate": "2026-05-30T19:07:00Z", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Nap Alert", "body": "A nap activity needs your attention." },
  "data": { "action": "NAP_ALERT", "type": "ACTIVITIES", "activityCode": "ACG_028FE987-C", "activityDate": "2026-05-30T11:36:00Z", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

## Scheduling

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A shift was published." },
  "data": { "action": "PUBLISH_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-348896A3-2", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-26", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "You have an upcoming shift." },
  "data": { "action": "UPCOMING_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-348896A3-2", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-26", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A shift was edited." },
  "data": { "action": "EDIT_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-E0209D0B-8", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-29", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A shift was deleted." },
  "data": { "action": "DELETE_SHIFT", "type": "SCHEDULING", "shiftCode": "SFT-348896A3-2", "staffCode": "STF_1E6419E7-5", "shiftDate": "2026-05-26", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Scheduling", "body": "A classroom is under ratio." },
  "data": { "action": "SHIFT_UNDER_RATIO", "type": "SCHEDULING", "classroomCode": "CLS_984ABCFA-B", "blockDate": "2026-05-31", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

## Attendance

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "Student-to-staff ratio breached in Blue-D." },
  "data": { "action": "RATIO_BREACHED", "type": "ATTENDANCE", "classroomCode": "CLS_72A4628B-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "Capacity exceeded in Blue-D." },
  "data": { "action": "CAPACITY_EXCEEDED", "type": "ATTENDANCE", "classroomCode": "CLS_72A4628B-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A student signed in/out." },
  "data": { "action": "STUDENT_SIGN_IN_OUT", "type": "ATTENDANCE", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A student was marked absent." },
  "data": { "action": "STUDENT_MARKED_ABSENT", "type": "ATTENDANCE", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A staff member signed in/out." },
  "data": { "action": "STAFF_SIGN_IN_OUT", "type": "ATTENDANCE", "staffCode": "STF_BA1B3E80-F", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "A staff member was marked absent." },
  "data": { "action": "STAFF_MARKED_ABSENT", "type": "ATTENDANCE", "staffCode": "STF_BA1B3E80-F", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Attendance", "body": "Attendance not marked yet." },
  "data": { "action": "ATTENDANCE_NOT_MARKED", "type": "ATTENDANCE", "studentCode": "STD_7B1D6DFF-8", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

## Availability — Movements

```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "A movement was created." },
  "data": { "action": "CREATE_MOVEMENT", "type": "AVAILABILITY", "movement_id": "152", "movement_code": "MOV-39A30866-2", "student_code": "STD_7B1D6DFF-8", "classroom_code": "CLS_72A4628B-8", "movement_date": "2026-06-01", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "You have an upcoming movement." },
  "data": { "action": "UPCOMING_MOVEMENT", "type": "AVAILABILITY", "movement_id": "155", "movement_code": "MOV-A54B6961-0", "student_code": "STD_7B1D6DFF-8", "classroom_code": "CLS_72A4628B-8", "movement_date": "2026-06-24", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "A movement was confirmed." },
  "data": { "action": "CONFIRMED_MOVEMENT", "type": "AVAILABILITY", "movement_id": "151", "movement_code": "MOV-0BF6BBE8-B", "student_code": "STD_7B1D6DFF-8", "classroom_code": "CLS_72A4628B-8", "movement_date": "2026-06-03", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "A movement is overdue." },
  "data": { "action": "MOVEMENT_OVERDUE", "type": "AVAILABILITY", "movement_id": "152", "movement_code": "MOV-39A30866-2", "student_code": "STD_7B1D6DFF-8", "classroom_code": "CLS_72A4628B-8", "movement_date": "2026-06-01", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "A movement was rejected." },
  "data": { "action": "MOVEMENT_REJECTED", "type": "AVAILABILITY", "movement_id": "156", "movement_code": "MOV-5040B0D5-2", "student_code": "STD_7B1D6DFF-8", "classroom_code": "CLS_72A4628B-8", "movement_date": "2027-07-01", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "A movement rule was created." },
  "data": { "action": "CREATE_RULE", "type": "AVAILABILITY", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Availability", "body": "A movement rule was deactivated." },
  "data": { "action": "DEACTIVATE_RULE", "type": "AVAILABILITY", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
