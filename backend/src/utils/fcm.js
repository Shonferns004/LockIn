import admin from 'firebase-admin';
import { supabase } from '../config/db.js';
import { fcmServiceAccount } from '../config/env.js';
import { generateMessage } from './aiMessages.js';

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

export async function sendToAll({ type, column, lazinessColumn = 'laziness' }) {
  if (!initialized) return 0;

  const { data: profiles } = await supabase
    .from('profiles')
    .select(`fcm_token, ${lazinessColumn}`)
    .eq(column, true)
    .not('fcm_token', 'is', null);

  if (!profiles?.length) return 0;

  let sent = 0;
  for (const p of profiles) {
    try {
      const laziness = p[lazinessColumn] ?? 5;
      const body = await generateMessage(type, laziness);
      await admin.messaging().send({
        token: p.fcm_token,
        notification: { title: titleFor(type), body },
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
  console.log(`[fcm] "${type}" sent to ${sent}/${profiles.length} devices`);
  return sent;
}

export async function sendToUser({ fcmToken, type, laziness = 5 }) {
  if (!initialized || !fcmToken) return false;
  const body = await generateMessage(type, laziness);
  await admin.messaging().send({
    token: fcmToken,
    notification: { title: titleFor(type), body },
  });
  return true;
}

function titleFor(type) {
  switch (type) {
    case 'workout_reminder': return 'Time to Train';
    case 'workout_missed': return "Don't Skip Today";
    case 'workout_completed': return 'Workout Complete';
    case 'water_reminder': return 'Time to Hydrate';
    default: return 'LockIn';
  }
}
