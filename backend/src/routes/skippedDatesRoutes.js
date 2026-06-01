import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getSkippedDates, markSkippedDate } from '../controllers/skippedDatesController.js';

const router = Router();

router.get('/', authMiddleware, getSkippedDates);
router.post('/', authMiddleware, markSkippedDate);

export default router;
