import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { registerToken, sendRankUp } from '../controllers/notificationsController.js';

const router = Router();

router.post('/register', authMiddleware, registerToken);
router.post('/rank-up', authMiddleware, sendRankUp);

export default router;
