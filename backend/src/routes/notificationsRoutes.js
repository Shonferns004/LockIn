import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { registerToken, sendRankUp, sendTest } from '../controllers/notificationsController.js';

const router = Router();

router.post('/register', authMiddleware, registerToken);
router.post('/rank-up', authMiddleware, sendRankUp);
router.post('/test', authMiddleware, sendTest);

export default router;
