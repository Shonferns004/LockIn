import admin from 'firebase-admin';
import { supabase } from '../config/db.js';
import { fcmServiceAccount } from '../config/env.js';

let initialized = false;
function initAdmin() {
  if (initialized) return;
  if (!fcmServiceAccount) {
    console.warn('FCM service account not configured — notifications disabled');
    return;
  }
  admin.initializeApp({ credential: admin.credential.cert(fcmServiceAccount) });
  initialized = true;
}

export async function registerToken(req, res) {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'token required' });

    const { error } = await supabase
      .from('profiles')
      .update({ fcm_token: token, updated_at: new Date().toISOString() })
      .eq('id', req.userId);

    if (error) return res.status(500).json({ error: error.message });
    res.json({ ok: true });
  } catch (err) {
    console.error('registerToken error:', err);
    res.status(500).json({ error: err.message });
  }
}

export async function sendRankUp(req, res) {
  try {
    initAdmin();
    if (!initialized) {
      return res.status(500).json({ error: 'FCM not configured' });
    }

    const userId = req.userId;
    const { oldRank, newRank } = req.body;

    const { data: profile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', userId)
      .single();

    if (!profile?.fcm_token) {
      return res.status(200).json({ sent: false, reason: 'no token' });
    }

    await admin.messaging().send({
      token: profile.fcm_token,
      notification: {
        title: 'Rank up',
        body: `Your experience changed from ${label(oldRank)} to ${label(newRank)}.`,
      },
    });

    res.json({ sent: true });
  } catch (err) {
    console.error('sendRankUp error:', err);
    res.status(500).json({ error: err.message });
  }
}

function label(rank) {
  switch ((rank || '').toLowerCase()) {
    case 'intermediate': return 'INTERMEDIATE';
    case 'advanced': return 'ADVANCED';
    default: return 'BEGINNER';
  }
}
