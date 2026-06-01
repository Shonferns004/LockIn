import { Router } from 'express';
import { signup, login, verify } from '../controllers/authController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = Router();

router.post('/signup', signup);
router.post('/login', login);
router.get('/verify', authMiddleware, verify);

export default router;
