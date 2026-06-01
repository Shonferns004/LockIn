import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getCompletedDays, markCompletedDay, saveCompletedDays } from '../controllers/completedDaysController.js';

const router = Router();

router.get('/', authMiddleware, getCompletedDays);
router.post('/', authMiddleware, markCompletedDay);
router.put('/', authMiddleware, saveCompletedDays);

export default router;
