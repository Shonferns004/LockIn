import cron from 'node-cron';
import { PORT } from '../config/env.js';

export function startKeepAlive() {
  async function ping() {
    try {
      const url = `http://localhost:${PORT}/api/stats/user-count`;
      const res = await fetch(url);
      const data = await res.json();
      console.log(`[keepAlive] Backend online — Users: ${data.users}`);
    } catch (err) {
      console.error('[keepAlive] failed:', err.message);
    }
  }

  // Run immediately on startup, then every 9 minutes
  ping();
  cron.schedule('*/9 * * * *', ping);

  console.log('[keepAlive] Cron started — every 9 min');
}
