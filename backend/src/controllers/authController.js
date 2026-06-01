import jwt from 'jsonwebtoken';
import { supabase } from '../config/db.js';
import { JWT_SECRET } from '../config/env.js';
import { generateId, sha256 } from '../utils/helpers.js';

export async function signup(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

    const normalizedEmail = email.trim().toLowerCase();
    const { data: existing } = await supabase.from('users').select('id').eq('email', normalizedEmail).maybeSingle();
    if (existing) return res.status(409).json({ error: 'An account with this email already exists.' });

    const id = generateId();
    const passwordHash = sha256(password);

    const { error: ue } = await supabase.from('users').insert({ id, email: normalizedEmail, password_hash: passwordHash });
    if (ue) throw ue;

    const { error: pe } = await supabase.from('profiles').insert({ id, email: normalizedEmail });
    if (pe) throw pe;

    const { error: pre } = await supabase.from('progress').insert({ id: generateId(), profile_id: id });
    if (pre) throw pre;

    const token = jwt.sign({ userId: id }, JWT_SECRET, { expiresIn: '90d' });
    res.json({ token, userId: id, email: normalizedEmail });
  } catch (e) {
    console.error('signup error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

    const normalizedEmail = email.trim().toLowerCase();
    const passwordHash = sha256(password);

    const { data: user } = await supabase.from('users').select('id, email').eq('email', normalizedEmail).eq('password_hash', passwordHash).maybeSingle();
    if (!user) return res.status(401).json({ error: 'Invalid email or password.' });

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '90d' });
    res.json({ token, userId: user.id, email: user.email });
  } catch (e) {
    console.error('login error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function verify(req, res) {
  res.json({ userId: req.userId });
}
