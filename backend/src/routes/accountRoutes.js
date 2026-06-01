import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { deleteAccount } from '../controllers/accountController.js';

const router = Router();

router.delete('/', authMiddleware, deleteAccount);

export default router;
