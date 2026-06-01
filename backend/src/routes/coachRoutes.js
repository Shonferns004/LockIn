import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { getMessages, saveMessage, clearMessages } from '../controllers/coachController.js';

const router = Router();

router.get('/', authMiddleware, getMessages);
router.post('/', authMiddleware, saveMessage);
router.delete('/', authMiddleware, clearMessages);

export default router;
