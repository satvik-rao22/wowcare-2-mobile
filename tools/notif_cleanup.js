#!/usr/bin/env node
/*
 * notif_cleanup.js — list or delete docs under
 *   userNotifications/{userId}/notifications
 * Reuses the Firebase CLI login (cloud-platform scope), same as notif_test.js.
 *
 *   node tools/notif_cleanup.js list                 # show every doc (id, createdAt, action, title)
 *   node tools/notif_cleanup.js delete <id> <id> ... # delete specific docs
 *   node tools/notif_cleanup.js delete-after <ISO>   # delete docs with createdAt >= ISO (mine)
 */
const https = require('https');
const os = require('os');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'wowcare2-atoconn';
const USER_ID = 'USR_002__SCH_1160DB3B-8';
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function req(method, url, body, headers) {
  return new Promise((res, rej) => {
    const r = https.request(url, { method, headers }, (s) => { let d = ''; s.on('data', (c) => d += c); s.on('end', () => res({ status: s.statusCode, body: d })); });
    r.on('error', rej); if (body) r.write(body); r.end();
  });
}
async function token() {
  const f = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const rt = JSON.parse(fs.readFileSync(f, 'utf8')).tokens.refresh_token;
  const b = new URLSearchParams({ client_id: CLIENT_ID, client_secret: CLIENT_SECRET, refresh_token: rt, grant_type: 'refresh_token' }).toString();
  const r = await req('POST', 'https://oauth2.googleapis.com/token', b, { 'Content-Type': 'application/x-www-form-urlencoded' });
  return JSON.parse(r.body).access_token;
}
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/userNotifications/${encodeURIComponent(USER_ID)}/notifications`;

async function listAll(at) {
  const docs = []; let pageToken = '';
  do {
    const url = BASE + '?pageSize=300' + (pageToken ? '&pageToken=' + encodeURIComponent(pageToken) : '');
    const r = await req('GET', url, null, { Authorization: 'Bearer ' + at });
    const j = JSON.parse(r.body);
    (j.documents || []).forEach((d) => docs.push(d));
    pageToken = j.nextPageToken || '';
  } while (pageToken);
  return docs;
}
function info(d) {
  const id = d.name.split('/').pop();
  const f = d.fields || {};
  const createdAt = f.createdAt?.timestampValue || '';
  const data = f.message?.mapValue?.fields?.data?.mapValue?.fields || {};
  const action = data.action?.stringValue || '';
  const notif = f.message?.mapValue?.fields?.notification?.mapValue?.fields || {};
  const title = notif.title?.stringValue || '';
  return { id, createdAt, action, title };
}

(async () => {
  const [cmd, ...rest] = process.argv.slice(2);
  const at = await token();
  if (cmd === 'list' || !cmd) {
    const docs = await listAll(at);
    docs.map(info).sort((a, b) => a.createdAt.localeCompare(b.createdAt))
      .forEach((x) => console.log(`${x.createdAt}  ${x.id}  ${x.action.padEnd(34)} ${x.title}`));
    console.log(`\nTotal: ${docs.length}`);
    return;
  }
  if (cmd === 'delete') {
    for (const id of rest) {
      const r = await req('DELETE', `${BASE}/${id}`, null, { Authorization: 'Bearer ' + at });
      console.log(r.status === 200 ? `🗑  ${id}` : `❌ ${id} (${r.status})`);
    }
    return;
  }
  if (cmd === 'delete-after') {
    const cutoff = rest[0];
    if (!cutoff) { console.error('need ISO timestamp'); process.exit(1); }
    const docs = (await listAll(at)).map(info).filter((x) => x.createdAt >= cutoff);
    console.log(`Deleting ${docs.length} docs with createdAt >= ${cutoff}`);
    for (const x of docs) {
      const r = await req('DELETE', `${BASE}/${x.id}`, null, { Authorization: 'Bearer ' + at });
      console.log(r.status === 200 ? `🗑  ${x.id}  ${x.action}` : `❌ ${x.id} (${r.status})`);
    }
    return;
  }
  console.error('Usage: list | delete <id...> | delete-after <ISO>');
})();
