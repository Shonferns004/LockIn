import { initFcm, sendToUsers } from '../utils/fcm.js';

export async function workoutReminder(req, res) {
  initFcm();
  const sent = await sendToUsers({
    column: 'daily_reminders',
    title: 'Time to Train',
    body: "Open LockIn and finish today's workout. No excuses.",
  });
  res.json({ ok: true, sent });
}

export async function waterReminder(req, res) {
  initFcm();
  const sent = await sendToUsers({
    column: 'water_reminder',
    title: 'Time to Hydrate',
    body: 'Drink a glass of water now. Keep your energy up.',
  });
  res.json({ ok: true, sent });
}
