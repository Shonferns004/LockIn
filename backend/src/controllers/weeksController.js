import { supabase } from '../config/db.js';
import { generateId } from '../utils/helpers.js';

export async function getWeeks(req, res) {
  try {
    const { data: weeks, error: we } = await supabase.from('week_plans').select().eq('profile_id', req.userId).order('week_number');
    if (we) throw we;

    for (const week of weeks) {
      const { data: days } = await supabase.from('day_plans').select().eq('week_plan_id', week.id).order('day_number');
      week.days = days || [];

      for (const day of week.days) {
        const { data: exs } = await supabase.from('exercises').select().eq('day_plan_id', day.id).order('sort_order');
        day.exercises = exs || [];

        const { data: fexs } = await supabase.from('face_exercises').select().eq('day_plan_id', day.id).order('sort_order');
        day.face_exercises = fexs || [];

        const { data: tips } = await supabase.from('lookmax_tips').select('content').eq('day_plan_id', day.id).order('sort_order');
        day.lookmax = (tips || []).map(r => r.content);
      }
    }

    res.json(weeks);
  } catch (e) {
    console.error('getWeeks error:', e);
    res.status(500).json({ error: e.message });
  }
}

export async function saveWeeks(req, res) {
  try {
    const weeks = req.body.weeks || (Array.isArray(req.body) ? req.body : [req.body]);

    for (const week of weeks) {
      const { data: existing } = await supabase.from('week_plans').select('id').eq('profile_id', req.userId).eq('week_number', week.week_number).maybeSingle();

      if (existing) {
        const { data: oldDays } = await supabase.from('day_plans').select('id').eq('week_plan_id', existing.id);
        for (const d of (oldDays || [])) {
          await supabase.from('exercises').delete().eq('day_plan_id', d.id);
          await supabase.from('face_exercises').delete().eq('day_plan_id', d.id);
          await supabase.from('lookmax_tips').delete().eq('day_plan_id', d.id);
        }
        await supabase.from('day_plans').delete().eq('week_plan_id', existing.id);
        await supabase.from('week_plans').delete().eq('id', existing.id);
      }

      const wpId = generateId();
      await supabase.from('week_plans').insert({ id: wpId, profile_id: req.userId, week_number: week.week_number, plan_start_date: week.plan_start_date || '' });

      for (const day of (week.days || [])) {
        const dpId = generateId();
        await supabase.from('day_plans').insert({ id: dpId, week_plan_id: wpId, day_number: day.day_number ?? day.day, title: day.title, focus: day.focus || '', icon: day.icon || '💪', scheduled_date: day.scheduled_date || '', is_rest: day.is_rest ? 1 : 0 });

        for (let ei = 0; ei < (day.exercises || []).length; ei++) {
          const ex = day.exercises[ei];
          await supabase.from('exercises').insert({ id: generateId(), day_plan_id: dpId, name: ex.name, sets: ex.sets || 3, reps: ex.reps || '10', target: ex.target || '', log_key: ex.log_key || null, log_val: ex.log_val || 0, is_timed: ex.is_timed ? 1 : 0, sort_order: ei });
        }

        for (let fi = 0; fi < (day.face_exercises || []).length; fi++) {
          const fe = day.face_exercises[fi];
          await supabase.from('face_exercises').insert({ id: generateId(), day_plan_id: dpId, name: fe.name, sets: fe.sets || 3, reps: fe.reps || '10', target: fe.target || '', sort_order: fi });
        }

        for (let li = 0; li < (day.lookmax || []).length; li++) {
          await supabase.from('lookmax_tips').insert({ id: generateId(), day_plan_id: dpId, content: day.lookmax[li], sort_order: li });
        }
      }
    }

    res.json({ ok: true });
  } catch (e) {
    console.error('saveWeeks error:', e);
    res.status(500).json({ error: e.message });
  }
}
