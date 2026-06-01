import 'dotenv/config';

export const PORT = process.env.PORT || 2100;
export const JWT_SECRET = process.env.JWT_SECRET || 'lockin-backend-secret';
export const SUPABASE_URL = process.env.SUPABASE_URL;
export const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
