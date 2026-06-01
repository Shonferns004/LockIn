import { supabase } from '../config/db.js';
import { generateId } from '../utils/helpers.js';

export async function getSkippedDates(req, res) {
  const { data } = await supabase.from('skipped_days').select('skipped_date, skipped_at').eq('profile_id', req.userId).order('skipped_at');
  res.json(data || []);
}

export async function markSkippedDate(req, res) {
  const { data: existing } = await supabase.from('skipped_days').select('id').eq('profile_id', req.userId).eq('skipped_date', req.body.skipped_date).maybeSingle();
  if (existing) return res.json({ ok: true });
  const { error } = await supabase.from('skipped_days').insert({ id: generateId(), profile_id: req.userId, skipped_date: req.body.skipped_date, skipped_at: new Date().toISOString() });
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}
