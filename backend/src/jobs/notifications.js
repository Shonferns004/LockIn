import cron from 'node-cron';
import admin from 'firebase-admin';
import { supabase } from '../config/db.js';
import { fcmServiceAccount } from '../config/env.js';

let adminInitialized = false;
function initAdmin() {
  if (adminInitialized) return;
  if (!fcmServiceAccount) {
    console.warn('[notifications] FCM not configured — skipping');
    return;
  }
  admin.initializeApp({ credential: admin.credential.cert(fcmServiceAccount) });
  adminInitialized = true;
}

async function sendToUsers({ column, title, body }) {
  if (!adminInitialized) return;
  const { data: profiles } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq(column, true)
    .not('fcm_token', 'is', null);

  if (!profiles?.length) return;

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
  console.log(`[notifications] "${title}" sent to ${sent}/${profiles.length} devices`);
}

export function startNotificationJobs() {
  initAdmin();
  if (!adminInitialized) return;

  // Workout reminder — every day at 8:00 AM
  cron.schedule('0 8 * * *', () => {
    sendToUsers({
      column: 'daily_reminders',
      title: 'Time to Train',
      body: "Open LockIn and finish today's workout. No excuses.",
    });
  });
  console.log('[notifications] Workout reminder cron — daily at 8:00');

  // Water reminder — every 2 hours (9 AM to 11 PM)
  cron.schedule('0 9-23/2 * * *', () => {
    sendToUsers({
      column: 'water_reminder',
      title: 'Time to Hydrate',
      body: 'Drink a glass of water now. Keep your energy up.',
    });
  });
  console.log('[notifications] Water reminder cron — every 2h (9 AM – 11 PM)');
}
