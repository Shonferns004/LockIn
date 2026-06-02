import { supabase } from '../config/db.js';
import { initFcm, sendToAll, sendToUser } from '../utils/fcm.js';

export async function workoutReminder(req, res) {
  initFcm();
  const sent = await sendToAll({
    type: 'workout_reminder',
    column: 'daily_reminders',
  });
  res.json({ ok: true, sent });
}

export async function waterReminder(req, res) {
  initFcm();
  const sent = await sendToAll({
    type: 'water_reminder',
    column: 'water_reminder',
  });
  res.json({ ok: true, sent });
}

export async function workoutMissed(req, res) {
  initFcm();

  const today = new Date().toISOString().slice(0, 10);

  const { data: allProfiles } = await supabase
    .from('profiles')
    .select('id, fcm_token, laziness')
    .eq('daily_reminders', true)
    .not('fcm_token', 'is', null);

  if (!allProfiles?.length) return res.json({ ok: true, sent: 0 });

  const ids = allProfiles.map(p => p.id);

  const { data: completed } = await supabase
    .from('completed_days')
    .select('profile_id')
    .in('profile_id', ids)
    .gte('completed_at', today);

  const completedSet = new Set(completed?.map(c => c.profile_id) ?? []);

  let sent = 0;
  for (const p of allProfiles) {
    if (completedSet.has(p.id)) continue;
    try {
      await sendToUser({ fcmToken: p.fcm_token, type: 'workout_missed', laziness: p.laziness ?? 5 });
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

  res.json({ ok: true, sent, total: allProfiles.length - completedSet.size });
}

export async function workoutCompleted(req, res) {
  initFcm();

  const { data: profile } = await supabase
    .from('profiles')
    .select('fcm_token, laziness')
    .eq('id', req.userId)
    .single();

  if (!profile?.fcm_token) {
    return res.json({ sent: false, reason: 'no token' });
  }

  await sendToUser({ fcmToken: profile.fcm_token, type: 'workout_completed', laziness: profile.laziness ?? 5 });
  res.json({ sent: true });
}
