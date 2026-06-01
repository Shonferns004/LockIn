import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../models/week_plan.dart';
import '../models/progress.dart';
import 'api_service.dart';

class DatabaseService {
  final ApiService _api;
  String _userId = '';

  DatabaseService(this._api);

  void _reportError(String method, Object error, StackTrace stackTrace) {
    debugPrint('DatabaseService.$method failed: $error');
    debugPrint(stackTrace.toString());
  }

  void setUserId(String id) {
    _userId = id;
  }
  String get userId => _userId;
  bool get hasUser => _userId.isNotEmpty;

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day)
        .toIso8601String()
        .substring(0, 10);
  }

  // ── Profile ──

  Future<Profile?> loadProfile() async {
    if (!hasUser) return null;
    try {
      final res = await _api.get('/api/profile');
      return Profile.fromJson(res);
    } catch (e, st) {
      _reportError('loadProfile', e, st);
      return null;
    }
  }

  Future<void> saveProfile(Profile p) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile', p.toJson());
    } catch (e, st) {
      _reportError('saveProfile', e, st);
    }
  }

  Future<void> saveOnboardingProfile(Profile p) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/onboarding', p.toJson());
    } catch (e, st) {
      _reportError('saveOnboardingProfile', e, st);
    }
  }

  Future<void> saveUsername(String username) async {
    if (!hasUser) return;
    try {
      await _api.patch('/api/profile/username', {'username': username});
    } catch (e, st) {
      _reportError('saveUsername', e, st);
    }
  }

  Future<void> saveEmail(String email) async {
    if (!hasUser) return;
    try {
      await _api.patch('/api/profile/email', {'email': email});
    } catch (e, st) {
      _reportError('saveEmail', e, st);
    }
  }

  Future<bool> get dailyReminders async {
    if (!hasUser) return false;
    try {
      final res = await _api.get('/api/profile/reminders');
      return res['daily_reminders'] as bool? ?? false;
    } catch (e, st) {
      _reportError('dailyReminders', e, st);
      return false;
    }
  }

  Future<void> saveDailyReminders(bool val) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/reminders', {'daily_reminders': val});
    } catch (e, st) {
      _reportError('saveDailyReminders', e, st);
    }
  }

  Future<String> get difficultyLevel async {
    if (!hasUser) return 'Beast';
    try {
      final res = await _api.get('/api/profile/difficulty');
      return res['difficulty_level'] as String? ?? 'Beast';
    } catch (e, st) {
      _reportError('difficultyLevel', e, st);
      return 'Beast';
    }
  }

  Future<void> saveDifficultyLevel(String val) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/difficulty', {'difficulty_level': val});
    } catch (e, st) {
      _reportError('saveDifficultyLevel', e, st);
    }
  }

  Future<void> saveGroqKey(String key) async {
    // no-op: groq key is not stored server-side
  }

  Future<String?> loadPlanAnchorDate() async {
    if (!hasUser) return null;
    try {
      final weeks = await _api.getList('/api/weeks');
      if (weeks.isEmpty) return null;
      final startDate = weeks[0]['plan_start_date']?.toString() ?? '';
      if (startDate.isEmpty) return null;
      return startDate;
    } catch (e, st) {
      _reportError('loadPlanAnchorDate', e, st);
      return null;
    }
  }

  Future<void> saveStepGoal(int goal) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/step-goal', {'step_goal': goal});
    } catch (e, st) {
      _reportError('saveStepGoal', e, st);
    }
  }

  Future<void> saveStepEnabled(bool enabled) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/step-enabled', {'step_enabled': enabled});
    } catch (e, st) {
      _reportError('saveStepEnabled', e, st);
    }
  }

  Future<void> saveStrideLength(int cm) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/stride-length', {'stride_length': cm});
    } catch (e, st) {
      _reportError('saveStrideLength', e, st);
    }
  }

  Future<void> saveDailySteps(int steps) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/daily-steps', {
        'daily_steps': steps,
        'last_step_date': _dateKey(DateTime.now()),
      });
    } catch (e, st) {
      _reportError('saveDailySteps', e, st);
    }
  }

  Future<void> saveWaterGoal(int ml) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/water-goal', {'water_goal': ml});
    } catch (e, st) {
      _reportError('saveWaterGoal', e, st);
    }
  }

  Future<void> saveDailyWater(int ml) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/daily-water', {
        'daily_water': ml,
        'last_water_date': _dateKey(DateTime.now()),
      });
    } catch (e, st) {
      _reportError('saveDailyWater', e, st);
    }
  }

  Future<void> saveWaterReminderEnabled(bool enabled) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/profile/water-reminder', {'water_reminder': enabled});
    } catch (e, st) {
      _reportError('saveWaterReminderEnabled', e, st);
    }
  }

  // ── Weeks ──

  Future<List<WeekPlan>> loadWeeks() async {
    if (!hasUser) return [];
    try {
      final list = await _api.getList('/api/weeks');
      return list.map((j) => WeekPlan.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _reportError('loadWeeks', e, st);
      return [];
    }
  }

  Future<void> saveWeeks(List<WeekPlan> weeks) async {
    if (!hasUser) return;
    try {
      await _api.post('/api/weeks', {'weeks': weeks.map((w) => w.toJson()).toList()});
    } catch (e, st) {
      _reportError('saveWeeks', e, st);
    }
  }

  // ── Progress ──

  Future<Progress> loadProgress() async {
    if (!hasUser) return Progress();
    try {
      final res = await _api.get('/api/progress');
      return Progress.fromJson({
        'days': res['total_days'] as int? ?? 0,
        'workouts': res['workouts'] as int? ?? 0,
        'streak': res['streak'] as int? ?? 0,
        'pushup': res['pushup_max'] as int? ?? 0,
        'squat': res['squat_max'] as int? ?? 0,
        'plank': res['plank_max'] as int? ?? 0,
        'burpee': res['burpee_max'] as int? ?? 0,
      });
    } catch (e, st) {
      _reportError('loadProgress', e, st);
      return Progress();
    }
  }

  Future<void> saveProgress(Progress p) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/progress', {
        'total_days': p.days,
        'workouts': p.workouts,
        'streak': p.streak,
        'pushup_max': p.pushup,
        'squat_max': p.squat,
        'plank_max': p.plank,
        'burpee_max': p.burpee,
      });
    } catch (e, st) {
      _reportError('saveProgress', e, st);
    }
  }

  // ── Completed Days ──

  Future<List<int>> loadCompletedDays() async {
    if (!hasUser) return [];
    try {
      final rows = await _api.getList('/api/completed-days');
      return rows.map((r) => (r as Map)['day_index'] as int).toList();
    } catch (e, st) {
      _reportError('loadCompletedDays', e, st);
      return [];
    }
  }

  Future<List<String>> loadCompletedDates() async {
    if (!hasUser) return [];
    try {
      final rows = await _api.getList('/api/completed-days');
      return rows
          .map((r) => (r as Map)['completed_at']?.toString() ?? '')
          .where((v) => v.isNotEmpty && v.length >= 10)
          .map((v) => DateTime.parse(v).toLocal())
          .map((dt) => DateTime(dt.year, dt.month, dt.day)
              .toIso8601String()
              .substring(0, 10))
          .toList();
    } catch (e, st) {
      _reportError('loadCompletedDates', e, st);
      return [];
    }
  }

  Future<List<String>> loadSkippedDates() async {
    if (!hasUser) return [];
    try {
      final rows = await _api.getList('/api/skipped-dates');
      return rows
          .map((r) => (r as Map)['skipped_date']?.toString() ?? '')
          .where((v) => v.isNotEmpty)
          .toList();
    } catch (e, st) {
      _reportError('loadSkippedDates', e, st);
      return [];
    }
  }

  Future<void> markCompletedDay(int dayIdx) async {
    if (!hasUser) return;
    try {
      await _api.post('/api/completed-days', {'day_index': dayIdx});
    } catch (e, st) {
      _reportError('markCompletedDay', e, st);
    }
  }

  Future<void> markSkippedDate(String skippedDate) async {
    if (!hasUser) return;
    try {
      await _api.post('/api/skipped-dates', {'skipped_date': skippedDate});
    } catch (e, st) {
      _reportError('markSkippedDate', e, st);
    }
  }

  Future<void> saveCompletedDays(List<int> days) async {
    if (!hasUser) return;
    try {
      await _api.put('/api/completed-days', {'days': days});
    } catch (e, st) {
      _reportError('saveCompletedDays', e, st);
    }
  }

  // ── Coach Messages ──

  Future<List<Map<String, String>>> loadCoachMessages() async {
    if (!hasUser) return [];
    try {
      final rows = await _api.getList('/api/coach');
      return rows
          .map((r) => {
                'role': (r as Map)['role'] as String,
                'content': r['content'] as String,
              })
          .toList();
    } catch (e, st) {
      _reportError('loadCoachMessages', e, st);
      return [];
    }
  }

  Future<void> saveCoachMessage(String role, String content) async {
    if (!hasUser) return;
    try {
      await _api.post('/api/coach', {'role': role, 'content': content});
    } catch (e, st) {
      _reportError('saveCoachMessage', e, st);
    }
  }

  Future<void> clearCoachMessages() async {
    if (!hasUser) return;
    try {
      await _api.delete('/api/coach');
    } catch (e, st) {
      _reportError('clearCoachMessages', e, st);
    }
  }

  // ── Clear All ──

  Future<void> clearAll() async {
    if (!hasUser) return;
    try {
      await _api.delete('/api/account');
    } catch (e, st) {
      _reportError('clearAll', e, st);
    }
  }
}
