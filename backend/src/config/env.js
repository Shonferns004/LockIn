import 'dotenv/config';

export const PORT = process.env.PORT || 2100;
export const JWT_SECRET = process.env.JWT_SECRET || 'lockin-backend-secret';
export const SUPABASE_URL = process.env.SUPABASE_URL;
export const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
export const GROQ_API_KEY = process.env.GROQ_API_KEY;

let _fcmAccount;
try {
  const raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (raw) {
    const json = Buffer.from(raw, 'base64').toString('utf-8');
    _fcmAccount = JSON.parse(json);
  }
} catch (_) {
  console.warn('Failed to parse FCM_SERVICE_ACCOUNT_JSON');
}
export const fcmServiceAccount = _fcmAccount;
