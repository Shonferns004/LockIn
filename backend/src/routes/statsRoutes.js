import { Router } from 'express';
import { getUserCount } from '../controllers/statsController.js';

const router = Router();

router.get('/user-count', getUserCount);

export default router;
