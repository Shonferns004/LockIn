import { Router } from 'express';
import { workoutReminder, waterReminder } from '../controllers/cronController.js';

const router = Router();

router.get('/workout-reminder', workoutReminder);
router.get('/water-reminder', waterReminder);

export default router;
