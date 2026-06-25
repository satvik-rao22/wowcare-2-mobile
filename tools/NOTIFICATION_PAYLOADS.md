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

## Messaging  (`type: MESSAGING`)

> ⚠️ **Proposed contract — pending app support.** Conversation deep-link and
> WhatsApp-style grouping are **not yet implemented** in the app (today
> `MESSAGE_TO_STAFF` / `MESSAGE_TO_STUDENT` open the messaging **list** only). Start
> sending the keys below now; the app will deep-link off `conversationCode` and
> group by it once the mobile work lands.
>
> **Title / body — group vs 1:1** (send `isGroup` + `conversationTitle`). Most chats
> here are **group** chats (room chat, admin chat, staff group); staff DMs are 1:1.
> · **1:1** (2-person STAFF_DIRECT) → title `New message from {senderDisplayName}
>   ({Role})`, body = preview. e.g. *New message from Chess Force (Staff)*.
> · **Group** (ROOM_CHAT / ADMIN_CHAT / staff group) → title = `{conversationTitle}`,
>   body = `{senderDisplayName} ({Role}): {preview}` (WhatsApp-group style). e.g.
>   title *Amy Smith — Blue-D*, body *Chess Force (Staff): Sending to u*.
> Send a prebuilt `notification.title/body` (killed-app tray) **and** the raw fields
> in `data`. `senderRole` → label: `PARENT`/`GUARDIAN`→Parent · `STAFF`→Staff ·
> `TEACHER`→Teacher · `ADMIN`/`SCHOOL_ADMIN`/`ORGANIZATION_ADMIN`→Admin ·
> `DIRECTOR`/`ASSISTANT_DIRECTOR`→Director. **`conversationTitle` is REQUIRED when
> `isGroup=true`** (the app can't title a group from the payload otherwise).
>
> **Body text:** plain text only — strip HTML (`<p>hi</p>` → `hi`). For
> `messageType` `IMAGE`/attachments send a placeholder (`📷 Photo` / `📎 Attachment`);
> the source row may have empty `content` with an attachment.
>
> **Deep-link:** **`conversationCode` is sufficient** — the app fetches the full
> conversation by code (`getConversation(code)`) and opens the thread, then scrolls
> to `messageId`. Still send `conversationType` (`ROOM_CHAT` | `ADMIN_CHAT` |
> `STAFF_DIRECT`) — it decides which persona surface/route backs the thread (see
> *Conversation types* below).
>
> **Grouping:** use `conversationCode` as the thread/collapse key — see *Grouping
> fields* below — so multiple messages in one chat show as **one** notification.

| `action` | Required `data` keys | Optional | Opens |
|---|---|---|---|
| `NEW_MESSAGE` | `conversationCode`, `conversationType`, `isGroup`, `senderDisplayName`, `senderRole`, `senderUserCode`, `messageId`, `messageType`, `organizationCode`, `schoolCode` | `conversationTitle` (req. if `isGroup`), `messageCode`, `preview`, `unreadCount`, `messages` (stringified JSON array — multi-line), `studentCode` (req. for ROOM_CHAT), `classroomCode`, `sentAt` | conversation thread (`conversationCode`), scroll to `messageId` |
| `NEWSLETTER_SENT` | `organizationCode`, `schoolCode` | — | messaging list, `tab=newsletter` |

> Legacy `MESSAGE_TO_STAFF` / `MESSAGE_TO_STUDENT` are still accepted but only open
> the messaging **list** — prefer `NEW_MESSAGE` with `conversationCode`.

### Conversation types — who, group/1:1, and where each persona lands

The app resolves the full conversation from `conversationCode`, but `conversationType`
tells it which surface to open (they differ by persona). `studentCode` is needed for
the **parent** child-scoped screen.

| `conversationType` | Group? | Participants | Staff/Admin lands on | Parent lands on | Extra keys |
|---|---|---|---|---|---|
| `ROOM_CHAT` | **Group** | Parents + Teachers + Staff + Admins (per student) | Messaging → *Parent Messaging* tab | Child-scoped screen (picks child by `studentCode`) | `studentCode` **(required)**, `classroomCode` |
| `ADMIN_CHAT` | Group (usu. 1 parent + admin(s)) | Parents + Admins/Directors (per student) | `/admin-chat` (Admin Chat) | ⚠️ **no parent surface yet** (app gap) | `studentCode` |
| `STAFF_DIRECT` | **1:1** (group if expanded) | Staff/Teachers/Admins/Directors (no parents) | Messaging → *Staff Messaging* tab | n/a (parents excluded) | — |

> Notes: `ADMIN_CHAT` to a **parent** has no parent screen today (app-side gap) — those
> won't open a thread for guardians. `STAFF_DIRECT` is never sent to parents.
> `conversationTitle` for a group = the thread title (e.g. student/room name); for a
> 1:1 it's the peer's name (the app derives this, so it's optional for 1:1).

### Grouping fields (collapse a conversation's messages into one notification)

> **The `android` / `apns` blocks are OPTIONAL and grouping-only.** They are NOT a
> new integration: delivery still goes through the same FCM token (FCM forwards to
> iOS via APNs using the project's configured key — **no APNs tokens/certs for the
> backend to store**, exactly like every other module here, which omit these blocks).
> Include them **only** to get the WhatsApp-style collapse + iOS badge. Omit them and
> messages still deliver — they just won't collapse into one entry and the badge
> won't auto-set.

Send the conversation as the thread/collapse key so multiple messages stack into a
single entry (and `unreadCount` lets the app show *"Bhakti (Parent): 3 new messages"*):

- **Android** (`message.android`): `collapse_key = <conversationCode>`,
  `notification.tag = <conversationCode>`,
  `notification.notification_priority = PRIORITY_HIGH`,
  `notification.channel_id = <messaging channel>`.
- **iOS** (`message.apns`): header `apns-collapse-id: <conversationCode>`;
  payload `aps.thread-id = <conversationCode>`, `apns-priority: 10`,
  `aps.badge = <total unread across all conversations>`.
- Put `unreadCount` (per conversation) in `data`.

**Same ROOM_CHAT push, now WITH the grouping blocks** (compare to the plain version
under *Messaging* below — only the `android` + `apns` blocks are added):
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Chess Force (Staff): Sending to u" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Chess Force", "senderRole": "STAFF", "senderUserCode": "USR-01f5b3d1", "messageId": "454", "messageType": "TEXT", "preview": "Sending to u", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T01:57:26Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 3 } } } } }
```

> **If the `apns` block / headers are NOT included:** the message still arrives on
> iOS (FCM delivers it via APNs automatically) — you just lose the per-chat collapse
> and the app-icon unread badge, so multiple messages show as separate notifications.
>
> **If the `android` block is NOT included:** the message still arrives on Android —
> you just lose the per-chat collapse (`tag`/`collapse_key`), so each message is its
> own notification, and it falls back to the default channel/priority (no forced
> high-priority heads-up).

> **Open question for backend:** one push **per message** (app merges by
> `conversationCode`) or one **aggregated** push per conversation (latest preview +
> `unreadCount`)? This decides the Android grouping strategy.

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

## Messaging

Sample codes: `CNV_K57JWFS5Z1DY` (room chat for student Amy Smith / Blue-D),
`USR-72442fe9` (Bhakti / parent), `USR-01f5b3d1` (Chess Force / staff), `465` (messageId).
**Group** chats (room/admin/staff-group): title = `conversationTitle`, body = "Sender (Role): text".
**1:1** staff DM: title = "New message from Sender (Role)".

> Examples below are `notification` + `data` only — same shape as every other module.
> The optional `android`/`apns` grouping blocks are described under *Grouping fields*
> above; add them only if you want WhatsApp-style collapse (no extra integration).

**ROOM_CHAT (group)** — staff posts in the room:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Chess Force (Staff): Sending to u" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Chess Force", "senderRole": "STAFF", "senderUserCode": "USR-01f5b3d1", "messageId": "454", "messageCode": "MSG_1IQEVV2Q8IRV", "messageType": "TEXT", "preview": "Sending to u", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T01:57:26Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

**ROOM_CHAT (group)** — parent posts; `studentCode` lets a parent recipient land on the right child:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): Good" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "465", "messageCode": "MSG_NTKV4505VVYK", "messageType": "TEXT", "preview": "Good", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T05:12:03Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

**STAFF_DIRECT (1:1 staff DM)** — no `studentCode`, `isGroup:false`, "New message from {sender}" title:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "New message from Chess Force (Staff)", "body": "Can you cover Blue-D at 3?" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_SD_8KQ2MV01", "conversationType": "STAFF_DIRECT", "isGroup": "false", "senderDisplayName": "Chess Force", "senderRole": "STAFF", "senderUserCode": "USR-01f5b3d1", "messageId": "612", "messageType": "TEXT", "preview": "Can you cover Blue-D at 3?", "unreadCount": "1", "sentAt": "2026-06-23T07:10:00Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

**ADMIN_CHAT (group)** — opens `/admin-chat` (admin only; ⚠ no parent surface yet):
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith (Admin Chat)", "body": "Bhakti (Parent): Please review the invoice" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_ADMIN9X2QK1", "conversationType": "ADMIN_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith (Admin Chat)", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "501", "messageType": "TEXT", "preview": "Please review the invoice", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "sentAt": "2026-06-23T06:00:00Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

**Image / attachment** (empty content → placeholder body):
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): 📷 Photo" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "380", "messageCode": "MSG_TLXYZK40WS16", "messageType": "IMAGE", "preview": "📷 Photo", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T01:33:20Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

### Multiple messages — showing each line (WhatsApp-style expand)

Two strategies; the app collapses both into **one** notification per `conversationCode`.

**Option A — one aggregated push carrying all the lines (recommended).** Put the recent
unread lines in a **`messages`** key as a **stringified JSON array** (all FCM `data`
values must be strings). The app renders them as a multi-line notification — each line =
`senderDisplayName (Role): preview`. `unreadCount` = total.
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): 3 new messages" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "465", "messageType": "TEXT", "preview": "Good", "unreadCount": "3", "messages": "[{\"senderDisplayName\":\"Bhakti\",\"senderRole\":\"PARENT\",\"messageId\":\"462\",\"preview\":\"Hi\",\"sentAt\":\"2026-06-23T02:59:24Z\"},{\"senderDisplayName\":\"Bhakti\",\"senderRole\":\"PARENT\",\"messageId\":\"464\",\"preview\":\"How r you ?\",\"sentAt\":\"2026-06-23T02:59:42Z\"},{\"senderDisplayName\":\"Bhakti\",\"senderRole\":\"PARENT\",\"messageId\":\"465\",\"preview\":\"Good\",\"sentAt\":\"2026-06-23T05:12:03Z\"}]", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T05:12:03Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

**Option B — one push per message; the app merges them.** Send each message as its
own push with the **same** `conversationCode`; the app appends each into the single
notification and bumps `unreadCount`. Three messages = the three pushes below:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): Hi" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "462", "messageType": "TEXT", "preview": "Hi", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T02:59:24Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): How r you ?" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "464", "messageType": "TEXT", "preview": "How r you ?", "unreadCount": "2", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T02:59:42Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): Good" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "465", "messageType": "TEXT", "preview": "Good", "unreadCount": "3", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T05:12:03Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" } } }
```

> Without the `android`/`apns` blocks the messages still deliver (like every other
> module) — they just won't auto-collapse into one entry / set the iOS badge. Add the
> optional grouping blocks from *Grouping fields* if/when you want the WhatsApp look.

### Same examples WITH `android` + `apns` (grouping enabled)

Identical to the plain versions above, just with the two grouping blocks appended.
Pattern is always the same: `collapse_key` / `tag` / `apns-collapse-id` / `thread-id`
= the `conversationCode`; `aps.badge` = **total unread across all conversations**
(examples use the single-chat count for simplicity).

**ROOM_CHAT (group)** — staff posts:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Chess Force (Staff): Sending to u" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Chess Force", "senderRole": "STAFF", "senderUserCode": "USR-01f5b3d1", "messageId": "454", "messageCode": "MSG_1IQEVV2Q8IRV", "messageType": "TEXT", "preview": "Sending to u", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T01:57:26Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 1 } } } } }
```

**ROOM_CHAT (group)** — parent posts:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): Good" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "465", "messageCode": "MSG_NTKV4505VVYK", "messageType": "TEXT", "preview": "Good", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T05:12:03Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 1 } } } } }
```

**STAFF_DIRECT (1:1 staff DM):**
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "New message from Chess Force (Staff)", "body": "Can you cover Blue-D at 3?" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_SD_8KQ2MV01", "conversationType": "STAFF_DIRECT", "isGroup": "false", "senderDisplayName": "Chess Force", "senderRole": "STAFF", "senderUserCode": "USR-01f5b3d1", "messageId": "612", "messageType": "TEXT", "preview": "Can you cover Blue-D at 3?", "unreadCount": "1", "sentAt": "2026-06-23T07:10:00Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_SD_8KQ2MV01", "notification": { "tag": "CNV_SD_8KQ2MV01", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_SD_8KQ2MV01", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_SD_8KQ2MV01", "badge": 1 } } } } }
```

**ADMIN_CHAT (group):**
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith (Admin Chat)", "body": "Bhakti (Parent): Please review the invoice" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_ADMIN9X2QK1", "conversationType": "ADMIN_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith (Admin Chat)", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "501", "messageType": "TEXT", "preview": "Please review the invoice", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "sentAt": "2026-06-23T06:00:00Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_ADMIN9X2QK1", "notification": { "tag": "CNV_ADMIN9X2QK1", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_ADMIN9X2QK1", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_ADMIN9X2QK1", "badge": 1 } } } } }
```

**Image / attachment:**
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): 📷 Photo" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "380", "messageCode": "MSG_TLXYZK40WS16", "messageType": "IMAGE", "preview": "📷 Photo", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T01:33:20Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 1 } } } } }
```

**Multiple messages — Option A (aggregated, `messages` array), WITH blocks:**
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): 3 new messages" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "465", "messageType": "TEXT", "preview": "Good", "unreadCount": "3", "messages": "[{\"senderDisplayName\":\"Bhakti\",\"senderRole\":\"PARENT\",\"messageId\":\"462\",\"preview\":\"Hi\",\"sentAt\":\"2026-06-23T02:59:24Z\"},{\"senderDisplayName\":\"Bhakti\",\"senderRole\":\"PARENT\",\"messageId\":\"464\",\"preview\":\"How r you ?\",\"sentAt\":\"2026-06-23T02:59:42Z\"},{\"senderDisplayName\":\"Bhakti\",\"senderRole\":\"PARENT\",\"messageId\":\"465\",\"preview\":\"Good\",\"sentAt\":\"2026-06-23T05:12:03Z\"}]", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T05:12:03Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 3 } } } } }
```

**Multiple messages — Option B (one push per message), WITH blocks** — same `tag`/`collapse_key`/`thread-id`, badge bumps 1 → 2 → 3:
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): Hi" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "462", "messageType": "TEXT", "preview": "Hi", "unreadCount": "1", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T02:59:24Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 1 } } } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): How r you ?" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "464", "messageType": "TEXT", "preview": "How r you ?", "unreadCount": "2", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T02:59:42Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 2 } } } } }
```
```json
{ "message": { "token": "<device-token>",
  "notification": { "title": "Amy Smith — Blue-D", "body": "Bhakti (Parent): Good" },
  "data": { "action": "NEW_MESSAGE", "type": "MESSAGING", "conversationCode": "CNV_K57JWFS5Z1DY", "conversationType": "ROOM_CHAT", "isGroup": "true", "conversationTitle": "Amy Smith — Blue-D", "senderDisplayName": "Bhakti", "senderRole": "PARENT", "senderUserCode": "USR-72442fe9", "messageId": "465", "messageType": "TEXT", "preview": "Good", "unreadCount": "3", "studentCode": "STD_7B1D6DFF-8", "classroomCode": "CLS_72A4628B-8", "sentAt": "2026-06-23T05:12:03Z", "organizationCode": "ORG_67F60097-C", "schoolCode": "SCH_74709D20-7" },
  "android": { "collapse_key": "CNV_K57JWFS5Z1DY", "notification": { "tag": "CNV_K57JWFS5Z1DY", "channel_id": "wowcare_messages", "notification_priority": "PRIORITY_HIGH" } },
  "apns": { "headers": { "apns-collapse-id": "CNV_K57JWFS5Z1DY", "apns-priority": "10" }, "payload": { "aps": { "thread-id": "CNV_K57JWFS5Z1DY", "badge": 3 } } } } }
```
