import { supabase } from '../config/db.js';

export async function deleteAccount(req, res) {
  try {
    const { data: weeks } = await supabase.from('week_plans').select('id').eq('profile_id', req.userId);
    for (const w of (weeks || [])) {
      const { data: dpIds } = await supabase.from('day_plans').select('id').eq('week_plan_id', w.id);
      for (const d of (dpIds || [])) {
        await supabase.from('exercises').delete().eq('day_plan_id', d.id);
        await supabase.from('face_exercises').delete().eq('day_plan_id', d.id);
        await supabase.from('lookmax_tips').delete().eq('day_plan_id', d.id);
      }
      await supabase.from('day_plans').delete().eq('week_plan_id', w.id);
    }
    await supabase.from('week_plans').delete().eq('profile_id', req.userId);
    await supabase.from('completed_days').delete().eq('profile_id', req.userId);
    await supabase.from('coach_messages').delete().eq('profile_id', req.userId);
    await supabase.from('progress').delete().eq('profile_id', req.userId);
    await supabase.from('profiles').delete().eq('id', req.userId);
    await supabase.from('users').delete().eq('id', req.userId);
    res.json({ ok: true });
  } catch (e) {
    console.error('deleteAccount error:', e);
    res.status(500).json({ error: e.message });
  }
}
