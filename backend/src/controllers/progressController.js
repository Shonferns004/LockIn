import { supabase } from '../config/db.js';

export async function getProgress(req, res) {
  const { data } = await supabase.from('progress').select().eq('profile_id', req.userId).maybeSingle();
  res.json(data || {});
}

export async function updateProgress(req, res) {
  const { error } = await supabase.from('progress').upsert({ ...req.body, profile_id: req.userId, updated_at: new Date().toISOString() }, { onConflict: 'profile_id' });
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}
