import admin from 'firebase-admin';
import { supabase } from '../config/db.js';
import { fcmServiceAccount } from '../config/env.js';

let initialized = false;
export function initFcm() {
  if (initialized) return;
  if (!fcmServiceAccount) {
    console.warn('[fcm] Service account not configured');
    return;
  }
  admin.initializeApp({ credential: admin.credential.cert(fcmServiceAccount) });
  initialized = true;
}

export async function sendToUsers({ column, title, body }) {
  if (!initialized) return 0;
  const { data: profiles } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq(column, true)
    .not('fcm_token', 'is', null);

  if (!profiles?.length) return 0;

  let sent = 0;
  for (const p of profiles) {
    try {
      await admin.messaging().send({
        token: p.fcm_token,
        notification: { title, body },
      });
      sent++;
    } catch (err) {
      if (err.code === 'messaging/registration-token-not-registered') {
        await supabase
          .from('profiles')
          .update({ fcm_token: null, updated_at: new Date().toISOString() })
          .eq('fcm_token', p.fcm_token);
      }
    }
  }
  console.log(`[fcm] "${title}" sent to ${sent}/${profiles?.length} devices`);
  return sent;
}
