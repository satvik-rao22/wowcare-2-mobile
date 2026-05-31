#!/usr/bin/env node
/*
 * notif_test.js — fire real FCM pushes to a device to test in-app redirection + highlight.
 *
 * Auth: reuses the Firebase CLI login (refresh token in ~/.config/configstore/firebase-tools.json),
 * which carries the cloud-platform scope — no service-account key needed.
 *
 * Usage:
 *   node tools/notif_test.js <ACTION> key=value key=value ...
 *   node tools/notif_test.js EDIT_CLASSROOM classroomCode=CLS_5739679F-D classroomName=Blue-D
 *   node tools/notif_test.js --list                       # list all actions + which code keys each uses
 *   node tools/notif_test.js EDIT_CLASSROOM ... --dry      # print payload + expected route, don't send
 *
 * Optional flags:
 *   --token <fcmDeviceToken>   override the target device (defaults to DEFAULT_TOKEN below)
 *   --title "..."  --body "..."  override the tray title/body
 *   --dry                       print only, do not send
 */

const https = require('https');
const os = require('os');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'wowcare2-atoconn';
// Device token from the running app's [FCM] Device token log.
const DEFAULT_TOKEN =
  'ehbNXX9QTeGmXp1NpFg9dc:APA91bEaJJh8M79jcXmIm-2YAbz0f-FB0P8jrLcBtC0XOfkKSXF9CzQJgLP0Wyf7KZO2n7Q4nwT5OjBCTg1RbQdmDcYNSfpVx2ZgDpekERjob4cwMs5lqn0';
// Firestore user doc id (the userNotifications/{userId} path, from the console).
const DEFAULT_USER_ID = 'USR_002__SCH_1160DB3B-8';

// well-known PUBLIC firebase-tools OAuth client (embedded in firebase-tools, not a secret)
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

// ── action catalog ────────────────────────────────────────────────────────────
// module is just for the title/grouping; `keys` = code fields this action reads;
// route(d) mirrors lib/.../notification_route_resolver.dart so we can print the
// expected destination for verification.
const first = (d, ks) => { for (const k of ks) { const v = (d[k] || '').trim(); if (v) return v; } return null; };
const K = {
  classroom: ['classroomCode', 'classroom_code'],
  student: ['studentCode', 'student_code'],
  staff: ['staffCode', 'staff_code'],
  shift: ['shift_code', 'shiftCode'],
  movement: ['movement_id', 'movement_code', 'movementCode'],
  activity: ['activityCode', 'activity_code'],
  document: ['documentCode', 'document_code', 'documentUuid'],
};
const hl = (path, d, keys, params = {}) => {
  const q = { ...params };
  const c = first(d, keys);
  if (c) q.highlightCode = c;
  return qs(path, q);
};
const qs = (p, q) => {
  const e = Object.entries(q).filter(([, v]) => v != null && v !== '');
  return e.length ? `${p}?${e.map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&')}` : p;
};
const classroomParam = (d) => { const c = first(d, K.classroom); return c ? { classroomCode: c } : {}; };
const studentProfile = (d, tab, hlKeys = []) => {
  const params = { code: first(d, K.student) || '', tab };
  const h = first(d, hlKeys); if (h) params.highlightCode = h;
  return qs('/dashboard/student-profile-by-code', params);
};
const staffProfile = (d, tab, hlKeys = []) => {
  const params = { code: first(d, K.staff) || '', tab };
  const h = first(d, hlKeys); if (h) params.highlightCode = h;
  return qs('/dashboard/staff-profile-by-code', params);
};

// title/body are generic, human-readable defaults; override with --title/--body.
const A = {
  // ── Classrooms ──
  ADD_CLASSROOM:    { mod: 'Classroom', keys: K.classroom, title: 'Classroom', body: d => `Classroom ${d.classroomName || d.classroomCode} has been added.`, route: d => hl('/classroom', d, K.classroom, classroomParam(d)) },
  EDIT_CLASSROOM:   { mod: 'Classroom', keys: K.classroom, title: 'Classroom', body: d => `Classroom ${d.classroomName || d.classroomCode} has been edited.`, route: d => hl('/classroom', d, K.classroom, classroomParam(d)) },
  DELETE_CLASSROOM: { mod: 'Classroom', keys: K.classroom, title: 'Classroom', body: d => `Classroom ${d.classroomName || d.classroomCode} has been deactivated.`, route: d => hl('/classroom', d, K.classroom, classroomParam(d)) },
  ASSIGN_STUDENT_TO_CLASSROOM: { mod: 'Classroom', keys: [...K.classroom, ...K.student], title: 'Classroom', body: d => `A student was assigned to ${d.classroomName || d.classroomCode}.`, route: d => hl('/classroom', d, K.student, { ...classroomParam(d), tab: '0' }) },
  ASSIGN_STAFF_TO_CLASSROOM:   { mod: 'Classroom', keys: [...K.classroom, ...K.staff], title: 'Classroom', body: d => `A staff member was assigned to ${d.classroomName || d.classroomCode}.`, route: d => hl('/classroom', d, K.staff, { ...classroomParam(d), tab: '1' }) },
  ADD_CLASSROOM_NOTE: { mod: 'Classroom', keys: K.classroom, title: 'Classroom', body: d => `A note was added to ${d.classroomName || d.classroomCode}.`, route: d => hl('/classroom', d, K.classroom, { ...classroomParam(d), tab: '2' }) },

  // ── Students ──
  ADD_STUDENT:    { mod: 'Student', keys: K.student, title: 'Student', body: d => `A new student (${d.studentCode}) was added.`, route: d => hl('/dashboard/students', d, K.student) },
  DELETE_STUDENT: { mod: 'Student', keys: K.student, title: 'Student', body: d => `Student ${d.studentCode} was deactivated.`, route: d => hl('/dashboard/students', d, K.student) },
  STUDENT_PARENT_NOT_ADDED:   { mod: 'Student', keys: K.student, title: 'Student', body: d => `Parent not added for ${d.studentCode}.`, route: d => studentProfile(d, '0') },
  STUDENT_SCHEDULE_NOT_ADDED: { mod: 'Student', keys: K.student, title: 'Student', body: d => `Schedule not added for ${d.studentCode}.`, route: d => studentProfile(d, '0') },
  STUDENT_PHYSICAL_NOT_ADDED: { mod: 'Student', keys: K.student, title: 'Student', body: d => `Last physical not added for ${d.studentCode}.`, route: d => studentProfile(d, '1') },
  STUDENT_PHYSICAL_DUE:       { mod: 'Student', keys: K.student, title: 'Student', body: d => `Physical due for ${d.studentCode}.`, route: d => studentProfile(d, '1') },
  STUDENT_PHYSICAL_OVERDUE:   { mod: 'Student', keys: K.student, title: 'Student', body: d => `Physical overdue for ${d.studentCode}.`, route: d => studentProfile(d, '1') },
  STUDENT_IMMUNIZATION_DUE_OVERDUE: { mod: 'Student', keys: K.student, title: 'Student', body: d => `Immunization due/overdue for ${d.studentCode}.`, route: d => studentProfile(d, '1') },
  STUDENT_BIRTHDATE_NOT_ADDED: { mod: 'Student', keys: K.student, title: 'Student', body: d => `Birthdate not added for ${d.studentCode}.`, route: d => studentProfile(d, '2') },
  STUDENT_DOCUMENT_CHANGED:    { mod: 'Student', keys: [...K.student, ...K.document], title: 'Student', body: d => `A document was added/deleted for ${d.studentCode}.`, route: d => studentProfile(d, '3', K.document) },

  // ── Staff ──
  DELETE_STAFF:            { mod: 'Staff', keys: K.staff, title: 'Staff', body: d => `Staff ${d.staffCode} was deactivated.`, route: d => hl('/dashboard/staff', d, K.staff) },
  STAFF_SCHEDULE_NOT_ADDED:{ mod: 'Staff', keys: K.staff, title: 'Staff', body: d => `Schedule not added for staff ${d.staffCode}.`, route: d => staffProfile(d, '0') },
  STAFF_PHYSICAL_NOT_ADDED:{ mod: 'Staff', keys: K.staff, title: 'Staff', body: d => `Last physical not added for staff ${d.staffCode}.`, route: d => staffProfile(d, '1') },
  STAFF_DOCUMENT_EXPIRY:   { mod: 'Staff', keys: [...K.staff, ...K.document], title: 'Staff', body: d => `A document is expiring for staff ${d.staffCode}.`, route: d => staffProfile(d, '2', K.document) },

  // ── Events & To-Dos ──
  BIRTHDAY: { mod: 'Events', keys: [...K.student, ...K.staff], title: 'Birthday', body: d => `It's a birthday today!`, route: d => first(d, K.student) ? studentProfile(d, '2') : staffProfile(d, '1') },
  UPCOMING_CLASSROOM_EVENT: { mod: 'Events', keys: [], title: 'Events', body: () => `Upcoming classroom event.`, route: () => '/dashboard' },
  UPCOMING_EVENT: { mod: 'Events', keys: [], title: 'Events', body: () => `You have an upcoming event.`, route: () => '/dashboard' },
  ASSIGN_TASK:    { mod: 'Events', keys: [], title: 'Tasks', body: () => `A task was assigned to you.`, route: () => '/dashboard' },
  TASK_DUE:       { mod: 'Events', keys: [], title: 'Tasks', body: () => `A task is due.`, route: () => '/dashboard' },
  TASK_OVERDUE:   { mod: 'Events', keys: [], title: 'Tasks', body: () => `A task is overdue.`, route: () => '/dashboard' },

  // ── Scheduling ──
  PUBLISH_SHIFT:     { mod: 'Scheduling', keys: K.shift, title: 'Scheduling', body: d => `Shift ${d.shift_code} published.`, route: d => hl('/dashboard/scheduling', d, K.shift) },
  UPCOMING_SHIFT:    { mod: 'Scheduling', keys: K.shift, title: 'Scheduling', body: d => `Upcoming shift ${d.shift_code}.`, route: d => hl('/dashboard/scheduling', d, K.shift) },
  SHIFT_UNDER_RATIO: { mod: 'Scheduling', keys: K.shift, title: 'Scheduling', body: d => `Shift ${d.shift_code} is under ratio.`, route: d => hl('/dashboard/scheduling', d, K.shift) },
  EDIT_SHIFT:        { mod: 'Scheduling', keys: K.shift, title: 'Scheduling', body: d => `Shift ${d.shift_code} was edited.`, route: d => hl('/dashboard/scheduling', d, K.shift) },
  DELETE_SHIFT:      { mod: 'Scheduling', keys: K.shift, title: 'Scheduling', body: d => `Shift ${d.shift_code} was deleted.`, route: d => hl('/dashboard/scheduling', d, K.shift) },

  // ── Attendance ──
  RATIO_BREACHED:      { mod: 'Attendance', keys: K.classroom, title: 'Attendance', body: d => `Student-to-staff ratio breached in ${d.classroomCode}.`, route: d => hl('/dashboard/student-attendance-tabbed-view', d, K.classroom) },
  STUDENT_SIGN_IN_OUT: { mod: 'Attendance', keys: K.student, title: 'Attendance', body: d => `Student ${d.studentCode} signed in/out.`, route: d => hl('/dashboard/student-attendance-tabbed-view', d, K.student) },
  STUDENT_MARKED_ABSENT:{ mod: 'Attendance', keys: K.student, title: 'Attendance', body: d => `Student ${d.studentCode} marked absent.`, route: d => hl('/dashboard/student-attendance-tabbed-view', d, K.student) },
  ATTENDANCE_NOT_MARKED:{ mod: 'Attendance', keys: [...K.student, ...K.staff], title: 'Attendance', body: () => `Attendance not marked yet.`, route: d => first(d, K.student) ? hl('/dashboard/student-attendance-tabbed-view', d, K.student) : hl('/dashboard/staff-attendance-tabbed-view', d, K.staff) },
  CAPACITY_EXCEEDED:   { mod: 'Attendance', keys: K.classroom, title: 'Attendance', body: d => `Capacity exceeded in ${d.classroomCode}.`, route: d => hl('/dashboard/student-attendance-tabbed-view', d, K.classroom) },

  // ── Activities ──
  ACTIVITY_RECORDED:                { mod: 'Activities', keys: K.activity, title: 'Activities', body: d => `Activity ${d.activityCode} recorded.`, route: d => hl('/activity-feed', d, K.activity) },
  INCIDENT_APPROVAL_PENDING:        { mod: 'Activities', keys: K.activity, title: 'Activities', body: d => `Incident ${d.activityCode} pending approval.`, route: d => hl('/activity-feed', d, K.activity) },
  INCIDENT_ACKNOWLEDGEMENT_PENDING: { mod: 'Activities', keys: K.activity, title: 'Activities', body: d => `Incident ${d.activityCode} pending acknowledgement.`, route: d => hl('/activity-feed', d, K.activity) },
  NAP_ALERT:                        { mod: 'Activities', keys: K.activity, title: 'Activities', body: d => `Nap alert for activity ${d.activityCode}.`, route: d => hl('/activity-feed', d, K.activity) },

  // ── Availability (movements) ──
  CREATE_RULE:       { mod: 'Availability', keys: [], title: 'Availability', body: () => `A movement rule was created.`, route: () => '/dashboard/future-availability' },
  DEACTIVATE_RULE:   { mod: 'Availability', keys: [], title: 'Availability', body: () => `A movement rule was deactivated.`, route: () => '/dashboard/future-availability' },
  CREATE_MOVEMENT:   { mod: 'Availability', keys: K.movement, title: 'Availability', body: d => `Movement ${d.movement_code || d.movement_id} created.`, route: d => hl('/dashboard/individual-movement', d, K.movement) },
  UPCOMING_MOVEMENT: { mod: 'Availability', keys: K.movement, title: 'Availability', body: d => `Upcoming movement ${d.movement_code || d.movement_id}.`, route: d => hl('/dashboard/individual-movement', d, K.movement) },
  CONFIRMED_MOVEMENT:{ mod: 'Availability', keys: K.movement, title: 'Availability', body: d => `Movement ${d.movement_code || d.movement_id} confirmed.`, route: d => hl('/dashboard/individual-movement', d, K.movement) },
  MOVEMENT_OVERDUE:  { mod: 'Availability', keys: K.movement, title: 'Availability', body: d => `Movement ${d.movement_code || d.movement_id} is overdue.`, route: d => hl('/dashboard/individual-movement', d, K.movement) },
  MOVEMENT_REJECTED: { mod: 'Availability', keys: K.movement, title: 'Availability', body: d => `Movement ${d.movement_code || d.movement_id} was rejected.`, route: d => hl('/dashboard/individual-movement', d, K.movement) },

  // ── Communication ──
  MESSAGE_TO_STAFF:   { mod: 'Communication', keys: [], title: 'Message', body: () => `New message to staff.`, route: () => '/messaging' },
  MESSAGE_TO_STUDENT: { mod: 'Communication', keys: [], title: 'Message', body: () => `New message to student.`, route: () => '/messaging' },
  NEWSLETTER_SENT:    { mod: 'Communication', keys: [], title: 'Newsletter', body: () => `A newsletter was sent.`, route: () => '/messaging?tab=newsletter' },

  // ── Billing ──
  INVOICE_GENERATED:    { mod: 'Billing', keys: [], title: 'Billing', body: () => `New invoice generated.`, route: () => '/dashboard/billing' },
  BILLING_PLAN_CHANGED: { mod: 'Billing', keys: [], title: 'Billing', body: () => `Billing plan changed.`, route: () => '/dashboard/billing' },
  FEE_STRUCTURE_CHANGED:{ mod: 'Billing', keys: [], title: 'Billing', body: () => `Fee structure changed.`, route: () => '/dashboard/billing' },
  INVOICE_DUE:          { mod: 'Billing', keys: [], title: 'Billing', body: () => `An invoice is due.`, route: () => '/parent-billing' },
  PAYMENT_SUCCESS:      { mod: 'Billing', keys: [], title: 'Billing', body: () => `Payment successful.`, route: () => '/parent-billing' },

  // ── Settings ──
  SCHOOL_SETTINGS_CHANGED: { mod: 'Settings', keys: [], title: 'Settings', body: () => `School settings changed.`, route: () => '/notifications' },
};

// canonical aliases (mirror NotificationAction.canonical)
const ALIAS = { CREATE_CLASSROOM: 'ADD_CLASSROOM', EDIT_STUDENT: 'ADD_STUDENT', EDIT_STAFF: 'DELETE_STAFF' };

// ── auth ────────────────────────────────────────────────────────────────────
function getAccessToken() {
  const f = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const rt = JSON.parse(fs.readFileSync(f, 'utf8')).tokens.refresh_token;
  const body = new URLSearchParams({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET, refresh_token: rt, grant_type: 'refresh_token' }).toString();
  return post('https://oauth2.googleapis.com/token', body, { 'Content-Type': 'application/x-www-form-urlencoded' })
    .then(r => { const p = JSON.parse(r); if (p.error) throw new Error('auth: ' + p.error_description); return p.access_token; });
}
function post(url, body, headers) {
  return new Promise((res, rej) => {
    const req = https.request(url, { method: 'POST', headers }, r => { let d = ''; r.on('data', c => d += c); r.on('end', () => res(d)); });
    req.on('error', rej); req.write(body); req.end();
  });
}

// ── Firestore REST: write a doc shaped exactly like the backend's
//    userNotifications/{userId}/notifications/{autoId}: { createdAt, message:{data,notification,token}, read } ──
const sv = (s) => ({ stringValue: String(s) });
const mapVal = (obj) => ({ mapValue: { fields: Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, sv(v)])) } });
async function writeFirestoreDoc(accessToken, userId, data, title, body, token) {
  const nowIso = new Date().toISOString();
  const fields = {
    createdAt: { timestampValue: nowIso },
    read: { booleanValue: false },
    message: {
      mapValue: {
        fields: {
          data: mapVal(data),
          notification: mapVal({ title, body }),
          token: sv(token),
        },
      },
    },
  };
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/userNotifications/${encodeURIComponent(userId)}/notifications`;
  const resp = await post(url, JSON.stringify({ fields }), { 'Content-Type': 'application/json', Authorization: 'Bearer ' + accessToken });
  const parsed = (() => { try { return JSON.parse(resp); } catch { return resp; } })();
  if (parsed && parsed.name) return parsed.name.split('/').pop();
  throw new Error('Firestore write failed: ' + JSON.stringify(parsed));
}

// ── real codes from the running app's API logs (school SCH_1160DB3B-8) ─────────
// Where a real value doesn't exist yet (no shifts/activities in the data), a
// TEST_ placeholder is used: redirect still works, highlight just won't match.
const DEFAULTS = {
  classroomCode: 'CLS_5739679F-D', classroom_code: 'CLS_5739679F-D', classroomName: 'Blue-D',
  studentCode: 'STD_25A1E14D-D', student_code: 'STD_25A1E14D-D',
  staffCode: 'STF_70E73DEF-F', staff_code: 'STF_70E73DEF-F',
  documentCode: 'AST_D4C23AB2-2', documentUuid: 'AST_D4C23AB2-2',
  movement_id: '18', movement_code: 'MOV-DB2B9AF0-B', movement_date: '2026-05-15',
  shift_code: 'SHF_TEST_0001', shift_date: '2026-05-31',
  activityCode: 'ACT_TEST_0001', activityType: 'INCIDENT',
  attendance_date: '2026-05-31',
};
// Full data field list per action (mirrors the redirection-details column); falls
// back to the action's highlight keys when not listed here.
const PAYLOAD = {
  ASSIGN_STUDENT_TO_CLASSROOM: ['classroomCode', 'classroomName', 'studentCode'],
  ASSIGN_STAFF_TO_CLASSROOM: ['classroomCode', 'classroomName', 'staffCode'],
  STUDENT_DOCUMENT_CHANGED: ['studentCode', 'documentCode'],
  STAFF_DOCUMENT_EXPIRY: ['staffCode', 'documentCode'],
  RATIO_BREACHED: ['classroom_code', 'attendance_date'],
  CAPACITY_EXCEEDED: ['classroom_code', 'attendance_date'],
  STUDENT_SIGN_IN_OUT: ['studentCode', 'attendance_date'],
  STUDENT_MARKED_ABSENT: ['studentCode', 'attendance_date'],
  ATTENDANCE_NOT_MARKED: ['student_code', 'attendance_date'],
  PUBLISH_SHIFT: ['shift_code', 'shift_date', 'staff_code', 'classroom_code'],
  UPCOMING_SHIFT: ['shift_code', 'shift_date', 'staff_code', 'classroom_code'],
  SHIFT_UNDER_RATIO: ['shift_code', 'shift_date', 'staff_code', 'classroom_code'],
  EDIT_SHIFT: ['shift_code', 'shift_date', 'staff_code', 'classroom_code'],
  DELETE_SHIFT: ['shift_code', 'shift_date', 'staff_code', 'classroom_code'],
  CREATE_MOVEMENT: ['movement_id', 'movement_code', 'student_code', 'classroom_code', 'movement_date'],
  UPCOMING_MOVEMENT: ['movement_id', 'movement_code', 'student_code', 'classroom_code', 'movement_date'],
  CONFIRMED_MOVEMENT: ['movement_id', 'movement_code', 'student_code', 'classroom_code', 'movement_date'],
  MOVEMENT_OVERDUE: ['movement_id', 'movement_code', 'student_code', 'classroom_code', 'movement_date'],
  MOVEMENT_REJECTED: ['movement_id', 'movement_code', 'student_code', 'classroom_code', 'movement_date'],
  ACTIVITY_RECORDED: ['activityCode', 'activityType', 'studentCode'],
  INCIDENT_APPROVAL_PENDING: ['activityCode', 'activityType', 'studentCode'],
  INCIDENT_ACKNOWLEDGEMENT_PENDING: ['activityCode', 'activityType', 'studentCode'],
  NAP_ALERT: ['activityCode', 'activityType', 'studentCode'],
  BIRTHDAY: ['studentCode'],
};

async function sendOne(at, action, data, title, body, route, token, userId, { fcm, firestore, dry }) {
  console.log(`\n▶ ${action}  →  ${route}`);
  console.log(`  data: ${JSON.stringify(data)}`);
  if (dry) return;
  if (fcm) {
    const message = {
      token, notification: { title, body }, data,
      android: { priority: 'HIGH', notification: { sound: 'default' } },
      apns: { payload: { aps: { sound: 'default' } } },
    };
    const resp = await post(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      JSON.stringify({ message }), { 'Content-Type': 'application/json', Authorization: 'Bearer ' + at });
    const p = (() => { try { return JSON.parse(resp); } catch { return resp; } })();
    if (p && p.name) console.log('  ✅ FCM', p.name.split('/').pop());
    else console.log('  ❌ FCM', JSON.stringify(p));
  }
  if (firestore) {
    const docId = await writeFirestoreDoc(at, userId, data, title, body, token);
    console.log('  ✅ Firestore', docId);
  }
}

// ── main ──────────────────────────────────────────────────────────────────
(async () => {
  const argv = process.argv.slice(2);
  if (argv.includes('--list') || argv.length === 0) {
    console.log('Actions (pass real codes so the highlight matches an on-screen card):\n');
    for (const [name, a] of Object.entries(A)) {
      console.log(`  ${name.padEnd(34)} ${a.mod.padEnd(14)} keys: ${a.keys.length ? a.keys.join(', ') : '(none)'}`);
    }
    console.log('\nExamples:\n  node tools/notif_test.js EDIT_CLASSROOM classroomCode=CLS_5739679F-D classroomName=Blue-D');
    console.log('  node tools/notif_test.js --all --firestore        # fire every action (real codes baked in)');
    return;
  }

  // generic flag + key=value parse
  const flags = {}; const overrides = {}; let positional = null;
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const name = arg.slice(2);
      const next = argv[i + 1];
      if (['token', 'title', 'body', 'user'].includes(name) && next && !next.startsWith('--')) { flags[name] = next; i++; }
      else flags[name] = true;
      continue;
    }
    const eq = arg.indexOf('=');
    if (eq > 0) overrides[arg.slice(0, eq)] = arg.slice(eq + 1);
    else if (!positional) positional = arg.toUpperCase();
  }

  const token = flags.token || DEFAULT_TOKEN;
  const userId = flags.user || DEFAULT_USER_ID;
  const firestore = !!(flags.firestore || flags['firestore-only']);
  const fcm = !flags['firestore-only'];
  const dry = !!flags.dry;
  const at = dry ? null : await getAccessToken();

  if (flags.all) {
    const codes = { ...DEFAULTS, ...overrides };
    console.log(`Firing ${Object.keys(A).length} actions → token ${token.slice(0, 16)}…  firestore=${firestore}\n`);
    for (const [name, spec] of Object.entries(A)) {
      const fields = PAYLOAD[name] || spec.keys;
      const data = { action: name, type: spec.mod.toUpperCase() };
      for (const f of fields) if (codes[f] != null) data[f] = codes[f];
      const merged = { ...codes, ...data };
      const title = spec.title;
      const body = spec.body(merged);
      const route = spec.route(merged);
      await sendOne(at, name, data, title, body, route, token, userId, { fcm, firestore, dry });
      if (!dry) await new Promise((r) => setTimeout(r, 700)); // pace the tray + avoid throttling
    }
    console.log('\nDone. Background the app, then tap each notification to test redirect + highlight.');
    return;
  }

  // single-action mode
  let action = ALIAS[positional] || positional;
  const spec = A[action];
  if (!spec) { console.error(`Unknown action "${action}". Run with --list.`); process.exit(1); }
  const data = { action, type: spec.mod.toUpperCase(), ...overrides };
  const title = flags.title || spec.title;
  const body = flags.body || spec.body(data);
  const route = spec.route(data);
  if (firestore) console.log('Firestore doc:  userNotifications/' + userId + '/notifications/(auto)');
  await sendOne(at, action, data, title, body, route, token, userId, { fcm, firestore, dry });
})();
