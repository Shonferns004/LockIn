import express from 'express';
import cors from 'cors';
import { PORT } from './src/config/env.js';
import { registerRoutes } from './src/routes/index.js';
import { startKeepAlive } from './src/jobs/keepAlive.js';
import { startNotificationJobs } from './src/jobs/notifications.js';

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/', (req, res) => res.send('online'));
registerRoutes(app);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`LockIn backend running on port ${PORT}`);
  startKeepAlive();
  startNotificationJobs();
});
