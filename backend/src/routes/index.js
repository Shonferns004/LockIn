import authRoutes from './authRoutes.js';
import profileRoutes from './profileRoutes.js';
import weeksRoutes from './weeksRoutes.js';
import progressRoutes from './progressRoutes.js';
import completedDaysRoutes from './completedDaysRoutes.js';
import skippedDatesRoutes from './skippedDatesRoutes.js';
import coachRoutes from './coachRoutes.js';
import accountRoutes from './accountRoutes.js';
import statsRoutes from './statsRoutes.js';
import notificationsRoutes from './notificationsRoutes.js';
import cronRoutes from './cronRoutes.js';

export function registerRoutes(app) {
  app.use('/api/auth', authRoutes);
  app.use('/api/profile', profileRoutes);
  app.use('/api/weeks', weeksRoutes);
  app.use('/api/progress', progressRoutes);
  app.use('/api/completed-days', completedDaysRoutes);
  app.use('/api/skipped-dates', skippedDatesRoutes);
  app.use('/api/coach', coachRoutes);
  app.use('/api/account', accountRoutes);
  app.use('/api/stats', statsRoutes);
  app.use('/api/notifications', notificationsRoutes);
  app.use('/api/cron', cronRoutes);

  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
  });
}
