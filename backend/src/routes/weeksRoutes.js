import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getWeeks, saveWeeks } from '../controllers/weeksController.js';

const router = Router();

router.get('/', authMiddleware, getWeeks);
router.post('/', authMiddleware, saveWeeks);

export default router;
