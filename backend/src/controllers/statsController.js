import { supabase } from '../config/db.js';

export async function getUserCount(req, res) {
  const { count, error } = await supabase
    .from('users')
    .select('*', { count: 'exact', head: true });

  if (error) {
    console.error('getUserCount error:', error);
    return res.status(500).json({ error: error.message });
  }

  res.json({ users: count ?? 0 });
}
