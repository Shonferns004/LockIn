import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getProgress, updateProgress } from '../controllers/progressController.js';

const router = Router();

router.get('/', authMiddleware, getProgress);
router.put('/', authMiddleware, updateProgress);

export default router;
