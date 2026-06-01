import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import * as ctrl from '../controllers/profileController.js';

const router = Router();

router.get('/', authMiddleware, ctrl.getProfile);
router.put('/', authMiddleware, ctrl.updateProfile);
router.put('/onboarding', authMiddleware, ctrl.saveOnboarding);
router.patch('/username', authMiddleware, ctrl.updateUsername);
router.patch('/email', authMiddleware, ctrl.updateEmail);
router.get('/reminders', authMiddleware, ctrl.getReminders);
router.put('/reminders', authMiddleware, ctrl.updateReminders);
router.get('/difficulty', authMiddleware, ctrl.getDifficulty);
router.put('/difficulty', authMiddleware, ctrl.updateDifficulty);
router.put('/step-goal', authMiddleware, ctrl.updateStepGoal);
router.put('/step-enabled', authMiddleware, ctrl.updateStepEnabled);
router.put('/stride-length', authMiddleware, ctrl.updateStrideLength);
router.put('/daily-steps', authMiddleware, ctrl.updateDailySteps);
router.put('/water-goal', authMiddleware, ctrl.updateWaterGoal);
router.put('/daily-water', authMiddleware, ctrl.updateDailyWater);
router.put('/water-reminder', authMiddleware, ctrl.updateWaterReminder);

export default router;
