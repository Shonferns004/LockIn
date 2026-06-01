import { supabase } from '../config/db.js';

export async function getProfile(req, res) {
  const { data, error } = await supabase.from('profiles').select().eq('id', req.userId).maybeSingle();
  if (error) return res.status(500).json({ error: error.message });
  if (!data) return res.status(404).json({ error: 'Profile not found' });
  res.json(data);
}

export async function updateProfile(req, res) {
  const { error } = await supabase.from('profiles').update({ ...req.body, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function saveOnboarding(req, res) {
  const { error } = await supabase.from('profiles').update({ ...req.body, onboarding_completed: true, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateUsername(req, res) {
  const { error } = await supabase.from('profiles').update({ username: req.body.username, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateEmail(req, res) {
  const { error: ue } = await supabase.from('users').update({ email: req.body.email }).eq('id', req.userId);
  if (ue) return res.status(500).json({ error: ue.message });
  const { error: pe } = await supabase.from('profiles').update({ email: req.body.email, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (pe) return res.status(500).json({ error: pe.message });
  res.json({ ok: true });
}

export async function getReminders(req, res) {
  const { data } = await supabase.from('profiles').select('daily_reminders').eq('id', req.userId).maybeSingle();
  res.json({ daily_reminders: data ? !!data.daily_reminders : false });
}

export async function updateReminders(req, res) {
  const { error } = await supabase.from('profiles').update({ daily_reminders: req.body.daily_reminders ? 1 : 0, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function getDifficulty(req, res) {
  const { data } = await supabase.from('profiles').select('difficulty_level').eq('id', req.userId).maybeSingle();
  res.json({ difficulty_level: data?.difficulty_level || 'Beast' });
}

export async function updateDifficulty(req, res) {
  const { error } = await supabase.from('profiles').update({ difficulty_level: req.body.difficulty_level, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateStepGoal(req, res) {
  const { error } = await supabase.from('profiles').update({ step_goal: req.body.step_goal, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateStepEnabled(req, res) {
  const { error } = await supabase.from('profiles').update({ step_enabled: req.body.step_enabled ? 1 : 0, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateStrideLength(req, res) {
  const { error } = await supabase.from('profiles').update({ stride_length: req.body.stride_length, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateDailySteps(req, res) {
  const { error } = await supabase.from('profiles').update({ daily_steps: req.body.daily_steps, last_step_date: req.body.last_step_date, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateWaterGoal(req, res) {
  const { error } = await supabase.from('profiles').update({ water_goal: req.body.water_goal, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateDailyWater(req, res) {
  const { error } = await supabase.from('profiles').update({ daily_water: req.body.daily_water, last_water_date: req.body.last_water_date, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}

export async function updateWaterReminder(req, res) {
  const { error } = await supabase.from('profiles').update({ water_reminder: req.body.water_reminder ? 1 : 0, updated_at: new Date().toISOString() }).eq('id', req.userId);
  if (error) return res.status(500).json({ error: error.message });
  res.json({ ok: true });
}
