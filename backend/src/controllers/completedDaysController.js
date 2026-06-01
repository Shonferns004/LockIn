import { supabase } from '../config/db.js';
import { generateId } from '../utils/helpers.js';

export async function getCompletedDays(req, res) {
  const { data } = await supabase.from('completed_days').select('day_index, completed_at').eq('profile_id', req.userId);
  res.json(data || []);
}

export async function markCompletedDay(req, res) {
  const { data: existing } = await supabase.from('completed_days').select('id').eq('profile_id', req.userId).eq('day_index', req.body.day_index).maybeSingle();
  if (existing) return res.json({ ok: true });
  const { error } = await supabase.from('completed_days').insert({ id: generateId(), profile_id: req.userId, day_index: req.body.day_index, completed_at: new Date().toISOString() });
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function saveCompletedDays(req, res) {
  await supabase.from('completed_days').delete().eq('profile_id', req.userId);
  for (const dayIndex of req.body.days || []) {
    await supabase.from('completed_days').insert({ id: generateId(), profile_id: req.userId, day_index: dayIndex });
  }
  res.json({ ok: true });
}
