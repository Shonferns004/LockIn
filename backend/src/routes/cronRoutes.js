import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { workoutReminder, waterReminder, workoutMissed, workoutCompleted } from '../controllers/cronController.js';

const router = Router();

router.get('/workout-reminder', workoutReminder);
router.get('/water-reminder', waterReminder);
router.get('/workout-missed', workoutMissed);
router.post('/workout-completed', authMiddleware, workoutCompleted);

export default router;
