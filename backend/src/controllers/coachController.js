import { supabase } from '../config/db.js';
import { generateId } from '../utils/helpers.js';

export async function getMessages(req, res) {
  const { data } = await supabase.from('coach_messages').select('role, content').eq('profile_id', req.userId).order('created_at');
  res.json(data || []);
}

export async function saveMessage(req, res) {
  const { error } = await supabase.from('coach_messages').insert({ id: generateId(), profile_id: req.userId, role: req.body.role, content: req.body.content });
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function clearMessages(req, res) {
  await supabase.from('coach_messages').delete().eq('profile_id', req.userId);
  res.json({ ok: true });
}
