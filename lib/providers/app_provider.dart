import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../models/week_plan.dart';
import '../models/progress.dart';
import '../models/session_state.dart';
import '../models/exercise.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/workoutx_service.dart';
import '../services/groq_service.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService db;

  AppProvider({required this.db});
  GroqService? _groq;
  WorkoutXService? _workoutX;

  Profile? _profile;
  List<WeekPlan> _weeks = [];
  Progress _progress = Progress();
  List<int> _completedDays = [];
  List<String> _completedDates = [];
  List<String> _skippedDates = [];
  DateTime? _planAnchorDate;
  int _selectedDay = 0;
  int _currentWeekView = 0;
  int _currentTab = 0;
  final SessionState _session = SessionState();
  SessionState? _savedSession;
  bool _loading = false;
  String _loadingKey = '';
  bool _isHydrating = false;
  int _loadToken = 0;
  bool _disposed = false;
  Timer? _stepNotifyTimer;
  DateTime? _lastStepNotifyAt;

  bool _dailyReminders = false;
  String _difficultyLevel = 'Beast';
  bool _soundMuted = false;

  // Coach
  final List<Map<String, String>> _coachHistory = [];
  static const int _coachHistoryLimit = 24;
  final Map<String, Map<String, String>> _exerciseGuideCache = {};
  final Map<String, Map<String, String>> _faceGuideCache = {};
  final Map<String, String> _motivationCache = {};
  final Map<String, ExerciseMedia> _exerciseMediaCache = {};

  // Step tracking
  int _dailySteps = 0;
  int _stepGoal = 10000;
  int _stepCumulative = 0;
  bool _stepEnabled = false;
  StreamSubscription<StepCount>? _stepSub;
  String _distanceStr = '';
  String _caloriesStr = '';
  int _waterGoal = 2000;
  int _dailyWater = 0;
  bool _waterReminder = false;
  static const String _groqPrefsKey = 'groq_api_key';
  static const String _lastPedometerKey = 'last_pedometer_total';
  static const String _stepHistoryKey = 'step_history';
  Map<String, int> _stepHistory = {};
  bool _stepSensorSupported = true;
  bool _stepPermissionGranted = false;
  String _stepStatusMessage = '';

  // Getters
  Profile? get profile => _profile;
  List<WeekPlan> get weeks => _weeks;
  Progress get progress => _progress;
  List<int> get completedDays => _completedDays;
  List<String> get completedDates => _completedDates;
  List<String> get skippedDates => _skippedDates;
  int get selectedDay => _selectedDay;
  int get currentWeekView => _currentWeekView;
  int get currentTab => _currentTab;
  SessionState get session => _session;
  bool get loading => _loading;
  String get loadingKey => _loadingKey;
  bool get isHydrating => _isHydrating;
  List<Map<String, String>> get coachHistory => _coachHistory;
  bool get hasGroqKey => _groq != null;
  bool get hasWorkoutX => _workoutX != null;
  bool get dailyReminders => _dailyReminders;
  String get difficultyLevel => _difficultyLevel;
  bool get soundMuted => _soundMuted;
  int get dailySteps => _dailySteps;
  int get stepGoal => _stepGoal;
  bool get stepEnabled => _stepEnabled;
  bool get stepSensorSupported => _stepSensorSupported;
  bool get stepPermissionGranted => _stepPermissionGranted;
  String get stepStatusMessage => _stepStatusMessage;
  String get distanceStr => _distanceStr;
  String get caloriesStr => _caloriesStr;
  int get waterGoal => _waterGoal;
  int get dailyWater => _dailyWater;
  bool get waterReminderEnabled => _waterReminder;
  Map<String, int> get stepHistory => Map.unmodifiable(_stepHistory);
  int get strideLength => _profile?.strideLength ?? 70;
  String? get groqKey => _profile?.groqKey;
  String get experience => _normalizeExperience(_profile?.experience ?? 'beginner');
  String get todayLabel {
    return DateFormat('EEE, d MMM').format(_todayOnly);
  }

  String get currentTimeLabel {
    final now = DateTime.now().toLocal();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String get currentDateTimeLabel => '$todayLabel | $currentTimeLabel';

  DateTime get _todayOnly {
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    return DateFormat('yyyy-MM-dd')
        .format(DateTime(local.year, local.month, local.day));
  }

  int _recentWorkoutCount({int windowDays = 14}) {
    return _completedDates.where((date) {
      final parsed = _parseDateOnly(date);
      if (parsed == null) return false;
      final age = _todayOnly.difference(parsed).inDays;
      return age >= 0 && age < windowDays;
    }).length;
  }

  String _normalizeExperience(String value) {
    switch (value.toLowerCase()) {
      case 'intermediate':
        return 'intermediate';
      case 'advanced':
        return 'advanced';
      default:
        return 'beginner';
    }
  }

  int _experienceScore() {
    return (_recentWorkoutCount() * 5) +
        _progress.pushup +
        _progress.squat +
        (_progress.plank ~/ 2) +
        (_progress.burpee * 2);
  }

  String _experienceFromScore(int score) {
    if (score < 35) return 'beginner';
    if (score <= 85) return 'intermediate';
    return 'advanced';
  }

  int _experienceIndex(String experience) {
    switch (_normalizeExperience(experience)) {
      case 'intermediate':
        return 1;
      case 'advanced':
        return 2;
      default:
        return 0;
    }
  }

  bool _isExperienceDemotionDue() {
    final lastWorkout = _parseDateOnly(_profile?.lastWorkoutDate);
    if (lastWorkout == null) return false;
    return _todayOnly.difference(lastWorkout).inDays >= 14;
  }

  Future<void> _syncExperienceLevel({required bool notifyRankUp}) async {
    final profile = _profile;
    if (profile == null) return;

    final currentRank = _normalizeExperience(profile.experience);
    final targetRank = _experienceFromScore(_experienceScore());
    final currentIndex = _experienceIndex(currentRank);
    final targetIndex = _experienceIndex(targetRank);
    var nextRank = currentRank;

    if (targetIndex > currentIndex) {
      nextRank = targetRank;
    } else if (targetIndex < currentIndex && _isExperienceDemotionDue()) {
      nextRank = targetRank;
    }

    if (nextRank == currentRank) return;

    _profile = profile.copyWith(experience: nextRank);
    await db.saveProfile(_profile!);

    if (notifyRankUp && _experienceIndex(nextRank) > currentIndex) {
      try {
        await ApiService().post('/api/notifications/rank-up', {
          'oldRank': currentRank,
          'newRank': nextRank,
        });
      } catch (e, st) {
        debugPrint('Failed to send rank-up notification: $e');
        debugPrint(st.toString());
      }
    }
  }

  DateTime? _parseDateOnly(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String weekDateRangeLabel(int weekView) {
    WeekPlan? week;
    for (final w in _weeks) {
      if (w.week == weekView + 1) {
        week = w;
        break;
      }
    }
    final start = _parseDateOnly(week?.planStartDate);
    final scheduledDates = week?.days
            .map((day) => _parseDateOnly(day.scheduledDate))
            .whereType<DateTime>()
            .toList() ??
        const <DateTime>[];
    scheduledDates.sort((a, b) => a.compareTo(b));
    DateTime? end = scheduledDates.isNotEmpty ? scheduledDates.last : null;
    if (start == null) return 'DATE TBA';
    if (end == null ||
        end.isBefore(start) ||
        end.difference(start).inDays < 1) {
      end = start.add(const Duration(days: 6));
    }
    return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
  }

  bool get canStartSelectedDay {
    final plan = selectedDayPlan;
    if (plan == null || plan.isRest) return false;
    final scheduledDate = _parseDateOnly(plan.scheduledDate);
    if (scheduledDate == null) return false;
    return !scheduledDate.isAfter(_todayOnly);
  }

  double get distanceKm {
    if (_stepEnabled && _profile != null) {
      final strideM = (strideLength / 100).toDouble();
      return (_dailySteps * strideM) / 1000;
    }
    return 0;
  }

  double get caloriesBurned {
    if (_profile != null && distanceKm > 0) {
      return distanceKm * _profile!.weight * 0.7;
    }
    return 0;
  }

  int get waterProgressPercent =>
      _waterGoal > 0 ? ((_dailyWater / _waterGoal) * 100).round() : 0;
  int get stepProgressPercent =>
      _stepGoal > 0 ? ((_dailySteps / _stepGoal) * 100).round() : 0;

  WeekPlan? get currentWeek {
    if (_weeks.isEmpty) return null;
    return _weeks.firstWhere(
      (w) => w.week == _currentWeekView + 1,
      orElse: () => _weeks.last,
    );
  }

  DayPlan? get selectedDayPlan {
    final week = currentWeek;
    if (week == null) return null;
    final dayNumber = _selectedDay + 1;
    final matchedDay = week.days.where((d) => d.day == dayNumber).toList();
    if (matchedDay.isNotEmpty) return matchedDay.first;

    final idx = _selectedDay - (_currentWeekView * 7);
    if (idx < 0 || idx >= week.days.length) return null;
    return week.days[idx];
  }

  int get totalDays {
    if (_weeks.isEmpty) return 30;
    return _weeks.length * 7;
  }

  int get completedCount => _completedDays.length;

  // Init
  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> bindUser(String userId) async {
    db.setUserId(userId);
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final token = ++_loadToken;
    await Future<void>.delayed(Duration.zero);
    if (token != _loadToken) return;
    _isHydrating = true;
    notifyListeners();

    _stepSub?.cancel();
    _stepSub = null;
    _stepNotifyTimer?.cancel();
    _stepNotifyTimer = null;
    _lastStepNotifyAt = null;
    _stepCumulative = 0;
    _groq = null;
    _profile = null;
    _weeks = [];
    _progress = Progress();
    _completedDays = [];
    _completedDates = [];
    _skippedDates = [];
    _coachHistory.clear();
    _exerciseGuideCache.clear();
    _faceGuideCache.clear();
    _motivationCache.clear();
    _selectedDay = 0;
    _currentWeekView = 0;
    _currentTab = 0;
    _dailyReminders = false;
    _difficultyLevel = 'Beast';
    _soundMuted = false;
    _dailySteps = 0;
    _stepGoal = 10000;
    _stepEnabled = false;
    _distanceStr = '';
    _caloriesStr = '';
    _waterGoal = 2000;
    _dailyWater = 0;
    _waterReminder = false;
    _stepSensorSupported = true;
    _stepPermissionGranted = false;
    _stepStatusMessage = '';
    _stepHistory = {};

    final results = await Future.wait([
      db.loadProfile(),
      db.loadWeeks(),
      db.loadProgress(),
      db.loadCompletedDays(),
      db.loadCompletedDates(),
      db.loadSkippedDates(),
      db.loadCoachMessages(),
      db.difficultyLevel,
    ]);
    if (token != _loadToken) return;
    _profile = results[0] as Profile?;
    _weeks = (results[1] as List<WeekPlan>?) ?? [];
    _progress = (results[2] as Progress?) ?? Progress();
    _completedDays = (results[3] as List<int>?) ?? [];
    _completedDates = (results[4] as List<String>?) ?? [];
    _skippedDates = (results[5] as List<String>?) ?? [];
    _coachHistory.addAll((results[6] as List<Map<String, String>>?) ?? []);
    _trimCoachHistory();
    _difficultyLevel = (results[7] as String?) ?? 'Beast';
    _sortWeeksAndDays();
    unawaited(populateExerciseMedia());
    final bundledGroqKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (_profile != null && _profile!.groqKey.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final localGroqKey = prefs.getString(_groqPrefsKey) ?? '';
      if (localGroqKey.isNotEmpty) {
        _profile = _profile!.copyWith(groqKey: localGroqKey);
      } else if (bundledGroqKey.isNotEmpty) {
        _profile = _profile!.copyWith(groqKey: bundledGroqKey);
      }
    }
    if (token != _loadToken) return;
    _dailyReminders = _profile?.dailyReminders ?? false;
    _waterReminder = _profile?.waterReminder ?? false;
    _soundMuted = _profile?.soundMuted ?? false;

    if (token != _loadToken) return;

    _progress.streak = _computeStreakFromDates(_completedDates, _skippedDates);
    await db.saveProgress(_progress);

    _dailySteps = _profile?.dailySteps ?? 0;
    _stepGoal = _profile?.stepGoal ?? 10000;
    _stepEnabled = _profile?.stepEnabled ?? false;
    _waterGoal = _profile?.waterGoal ?? 2000;
    _dailyWater = _profile?.dailyWater ?? 0;
    _waterReminder = _profile?.waterReminder ?? false;
    _updateStepStats();

    _loadCurrentSelectionFromSchedule();

    final today = _dateKey(DateTime.now());
    await _loadStepHistory();
    if (_profile != null) {
      var needsSave = false;
      if (_profile!.lastStepDate != today) {
        if (_dailySteps > 0) {
          _stepHistory[_profile!.lastStepDate] = _dailySteps;
          await _saveStepHistory();
        }
        _dailySteps = 0;
        _profile = _profile!.copyWith(dailySteps: 0, lastStepDate: today);
        needsSave = true;
      }
      if (_profile!.lastWaterDate != today) {
        _dailyWater = 0;
        _profile = _profile!.copyWith(dailyWater: 0, lastWaterDate: today);
        needsSave = true;
      }
      if (needsSave) {
        await db.saveProfile(_profile!);
        if (token != _loadToken) return;
      }

      await _syncExperienceLevel(notifyRankUp: false);
      if (token != _loadToken) return;
    }

    if (_stepEnabled) {
      _stepStatusMessage = '';
      _stepPermissionGranted = await _ensureStepPermission();
      if (_stepPermissionGranted) {
        _stepSensorSupported = true;
        _initStepSensor();
      } else {
        _stepEnabled = false;
        await db.saveStepEnabled(false);
        if (_profile != null) {
          _profile = _profile!.copyWith(stepEnabled: false);
        }
        _stepStatusMessage =
            _stepStatusMessage.isNotEmpty
                ? _stepStatusMessage
                : 'Activity recognition permission is needed for step tracking.';
      }
    }

    final key = _profile?.groqKey ?? bundledGroqKey;
    if (key.isNotEmpty) {
      _groq = GroqService(key);
    }

    final wxKey = dotenv.env['WORKOUTX_KEY'] ?? '';
    if (wxKey.isNotEmpty) {
      _workoutX = WorkoutXService(wxKey);
    }

    await _loadPlanAnchorDate();
    _syncCurrentViewWithToday();

    if (_profile != null) {
      _dailyReminders = _profile!.dailyReminders ?? false;
      _waterReminder = _profile!.waterReminder ?? false;
      await FcmService.registerCurrentToken();
    }

    if (token == _loadToken) {
      _isHydrating = false;
      notifyListeners();
    }
  }

  Future<void> _loadPlanAnchorDate() async {
    if (!db.hasUser) {
      _planAnchorDate = null;
      return;
    }
    final raw = await db.loadPlanAnchorDate();
    _planAnchorDate =
        raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
    if (_planAnchorDate == null && _weeks.isNotEmpty) {
      final firstWeek = _weeks.firstWhere((w) => w.planStartDate.isNotEmpty,
          orElse: () => _weeks.first);
      _planAnchorDate = _parseDateOnly(firstWeek.planStartDate) ?? _todayOnly;
    }
  }

  void _sortWeeksAndDays() {
    for (final week in _weeks) {
      week.days.sort((a, b) => a.day.compareTo(b.day));
    }
    _weeks.sort((a, b) => a.week.compareTo(b.week));
  }

  Future<void> _ensurePlanAnchorSaved() async {
    if (!db.hasUser) return;
    _planAnchorDate ??= _todayOnly;
  }

  void _syncCurrentViewWithToday() {
    if (_weeks.isEmpty) {
      _currentWeekView = 0;
      _selectedDay = 0;
      return;
    }
    final todayKey = _dateKey(_todayOnly);
    for (final week in _weeks) {
      final idx = week.days.indexWhere((d) => d.scheduledDate == todayKey);
      if (idx >= 0) {
        _currentWeekView = week.week - 1;
        _selectedDay = week.days[idx].day - 1;
        return;
      }
    }

    final fallbackWeek = _weeks.first;
    _currentWeekView = fallbackWeek.week - 1;
    _selectedDay =
        fallbackWeek.days.isEmpty ? 0 : fallbackWeek.days.first.day - 1;
  }

  void _loadCurrentSelectionFromSchedule() {
    if (_weeks.isEmpty) {
      _currentWeekView = 0;
      _selectedDay = 0;
      return;
    }
    final todayKey = _dateKey(_todayOnly);
    for (final week in _weeks) {
      final idx = week.days.indexWhere((d) => d.scheduledDate == todayKey);
      if (idx >= 0) {
        _currentWeekView = week.week - 1;
        _selectedDay = week.days[idx].day - 1;
        return;
      }
    }
    _currentWeekView = 0;
    _selectedDay =
        _weeks.first.days.isEmpty ? 0 : _weeks.first.days.first.day - 1;
  }

  // ── End of local load helpers removed — all data from Supabase ──

  // Step counter
  void _initStepSensor() {
    _stepSub?.cancel();
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error, stackTrace) {
          _handleStepSensorError(error, stackTrace);
        },
      );
    } catch (e, st) {
      _handleStepSensorError(e, st);
    }
  }

  Future<bool> _ensureStepPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;

    final result = await Permission.activityRecognition.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied) {
      _stepStatusMessage =
          'Activity recognition is permanently denied. Enable it in system settings.';
    } else if (result.isDenied) {
      _stepStatusMessage =
          'Activity recognition permission is needed for step tracking.';
    } else {
      _stepStatusMessage = 'Step tracking permission was not granted.';
    }
    return false;
  }

  void _handleStepSensorError(Object error, StackTrace stackTrace) {
    final text = error.toString().toLowerCase();
    final unsupported = text.contains('sensor') && text.contains('step');
    _stepSensorSupported = !unsupported;
    _stepStatusMessage = unsupported
        ? 'This device does not appear to support step tracking.'
        : 'Step tracking needs permission or the sensor is busy.';
    _stepPermissionGranted = false;
    _stepSub?.cancel();
    _stepSub = null;
    debugPrint(_stepStatusMessage);
    debugPrint(stackTrace.toString());
    notifyListeners();
  }

  void _onStepCount(StepCount event) {
    final current = event.steps;
    if (_stepCumulative == 0) {
      // First event after init — recover any steps that happened while
      // the app was closed by comparing with the last saved sensor total.
      unawaited(_recoverMissedSteps(current));
      _stepCumulative = current;
      return;
    }
    final delta = current - _stepCumulative;
    if (delta < 0) {
      // Sensor reset (e.g. device reboot)
      _stepCumulative = current;
      return;
    }
    if (delta > 0) {
      _dailySteps += delta;
      _stepCumulative = current;
      unawaited(_persistStepState(current));
      _updateStepStats();
      _scheduleStepNotify();
    }
  }

  Future<void> _recoverMissedSteps(int currentTotal) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTotal = prefs.getInt(_lastPedometerKey);
    if (lastTotal != null && currentTotal > lastTotal) {
      final missed = currentTotal - lastTotal;
      if (missed > 0 && missed < 10000) {
        _dailySteps += missed;
        if (_profile != null) {
          _profile = _profile!.copyWith(
              dailySteps: _dailySteps, lastStepDate: _dateKey(DateTime.now()));
        }
        _updateStepStats();
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<void> _persistStepState(int currentTotal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPedometerKey, currentTotal);
    unawaited(db.saveDailySteps(_dailySteps));
    _stepHistory[_dateKey(DateTime.now())] = _dailySteps;
    unawaited(_saveStepHistory());
    if (_profile != null) {
      _profile = _profile!.copyWith(
          dailySteps: _dailySteps, lastStepDate: _dateKey(DateTime.now()));
    }
  }

  Future<void> _loadStepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stepHistoryKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = Map<String, dynamic>.from(
          const JsonDecoder().convert(raw) as Map);
      _stepHistory = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
  }

  Future<void> _saveStepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _stepHistoryKey, const JsonEncoder().convert(_stepHistory));
  }

  void _scheduleStepNotify() {
    final now = DateTime.now();
    final last = _lastStepNotifyAt;
    if (last == null || now.difference(last) >= const Duration(seconds: 5)) {
      _lastStepNotifyAt = now;
      if (_disposed) return;
      notifyListeners();
      return;
    }

    _stepNotifyTimer?.cancel();
    final wait = const Duration(seconds: 5) - now.difference(last);
    _stepNotifyTimer = Timer(wait, () {
      if (_disposed) return;
      _lastStepNotifyAt = DateTime.now();
      notifyListeners();
    });
  }

  void _updateStepStats() {
    if (_profile != null) {
      final strideM = (strideLength / 100).toDouble();
      final km = (_dailySteps * strideM) / 1000;
      if (km >= 1) {
        _distanceStr = '${km.toStringAsFixed(2)} km';
      } else {
        _distanceStr = '${(_dailySteps * strideM).toStringAsFixed(0)} m';
      }
      final cal = km * _profile!.weight * 0.7;
      _caloriesStr = '${cal.toStringAsFixed(0)} kcal';
    }
  }

  Future<void> toggleStepCounter(bool enabled) async {
    if (!enabled) {
      _stepEnabled = false;
      _stepPermissionGranted = false;
      _stepSensorSupported = true;
      _stepStatusMessage = '';
      await db.saveStepEnabled(false);
      if (_profile != null) {
        _profile = _profile!.copyWith(stepEnabled: false);
      }
      _stepSub?.cancel();
      _stepSub = null;
      notifyListeners();
      return;
    }

    _stepEnabled = enabled;
    _stepStatusMessage = '';
    _stepSensorSupported = true;
    final granted = await _ensureStepPermission();
    _stepPermissionGranted = granted;
    if (!granted) {
      _stepEnabled = false;
      await db.saveStepEnabled(false);
      if (_profile != null) {
        _profile = _profile!.copyWith(stepEnabled: false);
      }
      _stepSub?.cancel();
      _stepSub = null;
      notifyListeners();
      return;
    }

    await db.saveStepEnabled(enabled);
    if (_profile != null) {
      _profile = _profile!.copyWith(stepEnabled: enabled);
    }
    _stepCumulative = 0;
    _initStepSensor();
    notifyListeners();
  }

  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    await db.saveStepGoal(goal);
    if (_profile != null) {
      _profile = _profile!.copyWith(stepGoal: goal);
    }
    notifyListeners();
  }

  Future<void> setStrideLength(int cm) async {
    await db.saveStrideLength(cm);
    if (_profile != null) {
      _profile = _profile!.copyWith(strideLength: cm);
    }
    _updateStepStats();
    notifyListeners();
  }

  // Water tracking
  Future<void> addWater(int ml) async {
    _dailyWater += ml;
    await db.saveDailyWater(_dailyWater);
    if (_profile != null) {
      _profile = _profile!.copyWith(
          dailyWater: _dailyWater, lastWaterDate: _dateKey(DateTime.now()));
    }
    notifyListeners();
  }

  Future<void> setWaterGoal(int ml) async {
    _waterGoal = ml;
    await db.saveWaterGoal(ml);
    if (_profile != null) {
      _profile = _profile!.copyWith(waterGoal: ml);
    }
    notifyListeners();
  }

  Future<void> toggleWaterReminder(bool enabled) async {
    _waterReminder = enabled;
    await db.saveWaterReminderEnabled(enabled);
    if (_profile != null) {
      _profile = _profile!.copyWith(waterReminder: enabled);
    }
    notifyListeners();
  }

  // Profile
  Future<void> saveProfile(Profile p) async {
    final email = p.email.isNotEmpty ? p.email : (AuthService().loggedInEmail ?? '');
    _profile = p.copyWith(email: email, onboardingCompleted: true);
    await db.saveProfile(_profile!);
    _dailyReminders = _profile?.dailyReminders ?? false;
    _waterReminder = _profile?.waterReminder ?? false;
    notifyListeners();
  }

  Future<bool> completeOnboarding(Profile p) async {
    final email = p.email.isNotEmpty ? p.email : (AuthService().loggedInEmail ?? '');
    _profile = p.copyWith(email: email, onboardingCompleted: true);
    await db.saveOnboardingProfile(_profile!);
    final saved = await db.loadProfile();
    if (saved != null) {
      _profile = saved;
    }
    notifyListeners();
    return _profile?.onboardingCompleted ?? false;
  }

  Future<void> resetProfile() async {
    await db.clearAll();
    _profile = null;
    _weeks = [];
    _progress = Progress();
    _completedDays = [];
    _selectedDay = 0;
    _currentWeekView = 0;
    _stepSub?.cancel();
    _stepSub = null;
    _stepNotifyTimer?.cancel();
    _stepNotifyTimer = null;
    _lastStepNotifyAt = null;
    _dailySteps = 0;
    _dailyWater = 0;
    _groq = null;
    _workoutX = null;
    _exerciseGuideCache.clear();
    _faceGuideCache.clear();
    _motivationCache.clear();
    _exerciseMediaCache.clear();
    notifyListeners();
  }

  // Settings
  Future<void> saveUsername(String val) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(username: val);
    await db.saveUsername(val);
    notifyListeners();
  }

  Future<void> saveEmail(String val) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(email: val);
    await db.saveEmail(val);
    notifyListeners();
  }

  Future<void> setDailyReminders(bool val) async {
    _dailyReminders = val;
    if (_profile != null) {
      _profile = _profile!.copyWith(dailyReminders: val);
    }
    await db.saveDailyReminders(val);
    notifyListeners();
  }

  Future<void> setDifficultyLevel(String val) async {
    _difficultyLevel = val;
    if (_profile != null) {
      _profile = _profile!.copyWith(difficultyLevel: val);
    }
    await db.saveDifficultyLevel(val);
    notifyListeners();
  }

  Future<void> setSoundMuted(bool val) async {
    _soundMuted = val;
    if (_profile != null) {
      _profile = _profile!.copyWith(soundMuted: val);
      await db.saveProfile(_profile!);
    }
    notifyListeners();
  }

  // Groq key
  Future<void> saveGroqKey(String key) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(groqKey: key);
    }
    final prefs = await SharedPreferences.getInstance();
    if (key.isEmpty) {
      await prefs.remove(_groqPrefsKey);
    } else {
      await prefs.setString(_groqPrefsKey, key);
    }
    _groq = GroqService(key);
    notifyListeners();
  }

  // WorkoutX media
  Future<ExerciseMedia?> lookupExerciseMedia(String exerciseName) async {
    final key = exerciseName.trim().toLowerCase();
    if (_exerciseMediaCache.containsKey(key)) return _exerciseMediaCache[key];
    if (_workoutX == null) return null;

    final media = await _workoutX!.lookup(exerciseName);
    if (media != null) {
      _exerciseMediaCache[key] = media;
    }
    return media;
  }

  Future<void> populateExerciseMedia() async {
    if (_workoutX == null) return;
    final seen = <String>{};
    final futures = <Future<void>>[];
    for (final week in _weeks) {
      for (final day in week.days) {
        for (final ex in day.exercises) {
          final name = ex.name.trim();
          final key = name.toLowerCase();
          if (seen.contains(key)) {
            final cached = _exerciseMediaCache[key];
            if (cached != null) {
              ex.imageUrl = cached.imageUrl;
            }
            continue;
          }
          seen.add(key);
          futures.add(() async {
            final media = await _workoutX!.lookup(name);
            if (media != null) {
              _exerciseMediaCache[key] = media;
              ex.imageUrl = media.imageUrl;
            }
          }());
        }
      }
    }
    await Future.wait(futures);
    notifyListeners();
  }

  // Week generation
  Future<void> generateWeek(int weekNum,
      {bool focusGeneratedWeek = true}) async {
    if (_groq == null || _profile == null) {
      _weeks.add(_createFallbackWeek(weekNum));
      await db.saveWeeks(_weeks);
      if (weekNum == 1) {
        await _ensurePlanAnchorSaved();
      }
      if (focusGeneratedWeek) {
        _currentWeekView = weekNum - 1;
        _selectedDay = _currentWeekView * 7;
      }
      notifyListeners();
      return;
    }

    setLoading('week', true);

    String? prevSummary;
    final prevWeek = _weeks.where((w) => w.week == weekNum - 1).toList();
    if (prevWeek.isNotEmpty) {
      final pw = prevWeek.first;
      final totalWork = pw.workoutDayCount;
      final done =
          pw.days.where((d) => _completedDays.contains(d.day - 1)).length;
      prevSummary = 'Completed $done/$totalWork workout days. Current max: '
          '${_progress.pushup} push-ups, ${_progress.squat} squats, '
          '${_progress.plank}s plank, ${_progress.burpee} burpees.';
    }

    final trainingContext = StringBuffer()
      ..writeln('- Today: $currentDateTimeLabel')
      ..writeln('- Week view: ${_currentWeekView + 1}')
      ..writeln('- Total workouts completed: ${_progress.workouts}')
      ..writeln('- Current streak: ${_progress.streak} days')
      ..writeln('- Steps today: $_dailySteps / $_stepGoal')
      ..writeln('- Water today: $_dailyWater / $_waterGoal ml')
      ..writeln('- Completed workout days stored: ${_completedDays.length}');

    try {
      final text = await _groq!.generateWeekJson(
        weekNum,
        _profile!,
        prevSummary,
        trainingContext: trainingContext.toString(),
      );
      final data = jsonDecode(text) as Map<String, dynamic>;
      final week = WeekPlan.fromJson(data);
      final startDay = (weekNum - 1) * 7 + 1;
      DateTime weekStartDate;
      if (weekNum == 1) {
        weekStartDate = _todayOnly;
      } else {
        final prevWeek = _weeks.where((w) => w.week == weekNum - 1).toList();
        if (prevWeek.isNotEmpty && prevWeek.first.planStartDate.isNotEmpty) {
          weekStartDate =
              (_parseDateOnly(prevWeek.first.planStartDate) ?? _todayOnly)
                  .add(const Duration(days: 7));
        } else if (_planAnchorDate != null) {
          weekStartDate =
              _planAnchorDate!.add(Duration(days: (weekNum - 1) * 7));
        } else {
          weekStartDate = _todayOnly.add(Duration(days: (weekNum - 1) * 7));
        }
      }
      week.planStartDate = _dateKey(weekStartDate);
      for (int i = 0; i < week.days.length; i++) {
        week.days[i].day = startDay + i;
        week.days[i].week = weekNum;
        week.days[i].scheduledDate =
            _dateKey(weekStartDate.add(Duration(days: i)));
        if (i == 3 || i == 6) {
          week.days[i] = DayPlan(
            day: startDay + i,
            week: weekNum,
            title: week.days[i].title,
            focus: week.days[i].focus,
            icon: week.days[i].icon,
            scheduledDate: week.days[i].scheduledDate,
            exercises: [],
            faceExercises: [],
            lookmax: [],
          );
        }
      }
      _weeks.removeWhere((w) => w.week == weekNum);
      _weeks.add(week);
      _sortWeeksAndDays();
      await db.saveWeeks(_weeks);
      if (weekNum == 1) {
        await _ensurePlanAnchorSaved();
      }
      if (focusGeneratedWeek) {
        _currentWeekView = weekNum - 1;
        _selectedDay = _currentWeekView * 7;
      }
    } catch (_) {
      _weeks.add(_createFallbackWeek(weekNum));
      _sortWeeksAndDays();
      await db.saveWeeks(_weeks);
      if (weekNum == 1) {
        await _ensurePlanAnchorSaved();
      }
      if (focusGeneratedWeek) {
        _currentWeekView = weekNum - 1;
        _selectedDay = _currentWeekView * 7;
      }
    }

    setLoading('week', false);
    notifyListeners();
  }

  WeekPlan _createFallbackWeek(int weekNum) {
    final s = (weekNum - 1) * 7 + 1;
    final anchor = _planAnchorDate ?? _todayOnly;
    final start = weekNum == 1
        ? anchor
        : anchor.add(Duration(days: (weekNum - 1) * 7));
    return WeekPlan(week: weekNum, planStartDate: _dateKey(start), days: [
      DayPlan(
          day: s,
          week: weekNum,
          title: 'PUSH DAY',
          focus: 'Chest · Triceps · Shoulders',
          icon: '🔥',
          scheduledDate: _dateKey(start),
          exercises: [
            Exercise(
                name: 'Push-Ups',
                sets: 3,
                reps: '8',
                target: 'Chest · Triceps',
                logKey: 'pushup',
                logVal: 8),
            Exercise(
                name: 'Diamond Push-Ups',
                sets: 3,
                reps: '6',
                target: 'Triceps · Chest'),
            Exercise(
                name: 'Pike Push-Ups', sets: 3, reps: '8', target: 'Shoulders'),
            Exercise(
                name: 'Wide Push-Ups',
                sets: 3,
                reps: '8',
                target: 'Chest',
                logKey: 'pushup',
                logVal: 8),
            Exercise(
                name: 'Plank Hold',
                sets: 3,
                reps: '20s',
                target: 'Core',
                logKey: 'plank',
                logVal: 20),
            Exercise(
                name: 'Incline Push-Ups',
                sets: 3,
                reps: '10',
                target: 'Chest · Shoulders',
                logKey: 'pushup',
                logVal: 10),
          ],
          faceExercises: [
            FaceExercise(
                name: 'Chin Tucks', sets: 3, reps: '15', target: 'Neck · Chin'),
            FaceExercise(
                name: 'Jaw Clenches', sets: 3, reps: '20', target: 'Masseter'),
            FaceExercise(
                name: 'Brow Lifts', sets: 3, reps: '12', target: 'Frontalis'),
            FaceExercise(
                name: 'Lip Presses',
                sets: 3,
                reps: '15',
                target: 'Orbicularis Oris'),
          ],
          lookmax: [
            '🧴 Skincare: Wash face + moisturize AM/PM',
            '👀 Posture: Shoulders back, chin tucked — check hourly',
            '💧 Hydration: 2L water today, no soda',
            '🛌 Sleep: 8h — no phone 30min before bed',
          ]),
      DayPlan(
          day: s + 1,
          week: weekNum,
          title: 'PULL DAY',
          focus: 'Back · Biceps',
          icon: '💪',
          scheduledDate: _dateKey(start.add(const Duration(days: 1))),
          exercises: [
            Exercise(
                name: 'Superman Hold',
                sets: 3,
                reps: '10s',
                target: 'Lower Back'),
            Exercise(
                name: 'Prone Snow Angels',
                sets: 3,
                reps: '8',
                target: 'Rear Delts'),
            Exercise(
                name: 'Self-Resistance Curls',
                sets: 3,
                reps: '10',
                target: 'Biceps'),
            Exercise(
                name: "Child's Pose Stretch",
                sets: 3,
                reps: '15s',
                target: 'Back Stretch'),
            Exercise(
                name: 'Reverse Plank',
                sets: 3,
                reps: '15s',
                target: 'Posterior Chain'),
            Exercise(
                name: 'Prone Cobra Hold',
                sets: 3,
                reps: '15s',
                target: 'Upper Back · Posture'),
          ],
          faceExercises: [
            FaceExercise(
                name: 'Mewing', sets: 3, reps: '30s', target: 'Tongue Posture'),
            FaceExercise(
                name: 'Cheek Sculptor',
                sets: 3,
                reps: '10',
                target: 'Zygomaticus'),
            FaceExercise(
                name: 'Eye Squints',
                sets: 3,
                reps: '12',
                target: 'Eyelid Muscles'),
            FaceExercise(
                name: 'Neck Resistance',
                sets: 3,
                reps: '10',
                target: 'Platysma'),
          ],
          lookmax: [
            '🧴 Grooming: Shape eyebrows · Lip balm after shower',
            '💪 Posture: Roll shoulders back — 10 posture checks today',
            '🥗 Diet: High protein meal prep — no processed food',
            '😴 Sleep: Blackout room + 8h minimum',
          ]),
      DayPlan(
          day: s + 2,
          week: weekNum,
          title: 'LEGS DAY',
          focus: 'Quads · Glutes · Calves',
          icon: '🦵',
          scheduledDate: _dateKey(start.add(const Duration(days: 2))),
          exercises: [
            Exercise(
                name: 'Squats',
                sets: 3,
                reps: '15',
                target: 'Quads · Glutes',
                logKey: 'squat',
                logVal: 15),
            Exercise(
                name: 'Walking Lunges',
                sets: 3,
                reps: '10',
                target: 'Quads · Glutes'),
            Exercise(
                name: 'Glute Bridges', sets: 3, reps: '15', target: 'Glutes'),
            Exercise(
                name: 'Calf Raises', sets: 3, reps: '20', target: 'Calves'),
            Exercise(
                name: 'Wall Sit', sets: 3, reps: '20s', target: 'Quads · Core'),
            Exercise(
                name: 'Bulgarian Split Squats',
                sets: 3,
                reps: '8',
                target: 'Quads · Glutes'),
          ],
          faceExercises: [
            FaceExercise(
                name: 'Chin Tucks', sets: 3, reps: '15', target: 'Neck · Chin'),
            FaceExercise(
                name: 'Jaw Clenches', sets: 3, reps: '20', target: 'Masseter'),
            FaceExercise(
                name: 'Brow Lifts', sets: 3, reps: '12', target: 'Frontalis'),
            FaceExercise(
                name: 'Lip Presses',
                sets: 3,
                reps: '15',
                target: 'Orbicularis Oris'),
          ],
          lookmax: [
            '🧴 Skincare: Exfoliate + sheet mask today',
            '👀 Eye care: 20-20-20 rule — rest eyes from screens',
            '💧 Hydration: 2.5L water today (extra for recovery)',
            '🛌 Sleep: Magnesium before bed · 8h deep sleep',
          ]),
      DayPlan(
          day: s + 3,
          week: weekNum,
          title: 'REST',
          focus: 'Recovery',
          icon: '😴',
          scheduledDate: _dateKey(start.add(const Duration(days: 3))),
          exercises: []),
      DayPlan(
          day: s + 4,
          week: weekNum,
          title: 'FULL BODY',
          focus: 'Total Body',
          icon: '⚡',
          scheduledDate: _dateKey(start.add(const Duration(days: 4))),
          exercises: [
            Exercise(
                name: 'Burpees',
                sets: 3,
                reps: '5',
                target: 'Full Body',
                logKey: 'burpee',
                logVal: 5),
            Exercise(
                name: 'Push-Ups',
                sets: 3,
                reps: '8',
                target: 'Chest',
                logKey: 'pushup',
                logVal: 8),
            Exercise(
                name: 'Squats',
                sets: 3,
                reps: '15',
                target: 'Legs',
                logKey: 'squat',
                logVal: 15),
            Exercise(
                name: 'Mountain Climbers',
                sets: 3,
                reps: '15',
                target: 'Core · Cardio'),
            Exercise(
                name: 'Plank Hold',
                sets: 3,
                reps: '20s',
                target: 'Core',
                logKey: 'plank',
                logVal: 20),
            Exercise(
                name: 'Chair Dips',
                sets: 3,
                reps: '8',
                target: 'Triceps · Shoulders'),
          ],
          faceExercises: [
            FaceExercise(
                name: 'Mewing', sets: 3, reps: '30s', target: 'Tongue Posture'),
            FaceExercise(
                name: 'Cheek Sculptor',
                sets: 3,
                reps: '10',
                target: 'Zygomaticus'),
            FaceExercise(
                name: 'Eye Squints',
                sets: 3,
                reps: '12',
                target: 'Eyelid Muscles'),
            FaceExercise(
                name: 'Neck Resistance',
                sets: 3,
                reps: '10',
                target: 'Platysma'),
          ],
          lookmax: [
            '🧴 Skincare: SPF 50+ — reapply every 3h if outside',
            '👀 Posture: Walk with chest out, shoulders back',
            '🥗 Diet: Cut sugar completely today · green tea',
            '🛌 Sleep: Wind down with stretching · 8h',
          ]),
      DayPlan(
          day: s + 5,
          week: weekNum,
          title: 'CORE DAY',
          focus: 'Abs · Obliques',
          icon: '🏃',
          scheduledDate: _dateKey(start.add(const Duration(days: 5))),
          exercises: [
            Exercise(
                name: 'Mountain Climbers',
                sets: 3,
                reps: '15',
                target: 'Core · Cardio'),
            Exercise(
                name: 'Crunches', sets: 3, reps: '12', target: 'Upper Abs'),
            Exercise(
                name: 'Leg Raises', sets: 3, reps: '10', target: 'Lower Abs'),
            Exercise(
                name: 'Bicycle Crunches',
                sets: 3,
                reps: '12',
                target: 'Obliques'),
            Exercise(
                name: 'Plank Hold',
                sets: 3,
                reps: '30s',
                target: 'Core',
                logKey: 'plank',
                logVal: 30),
            Exercise(
                name: 'Feet-Elevated Plank',
                sets: 3,
                reps: '20s',
                target: 'Core · Shoulders'),
          ],
          faceExercises: [
            FaceExercise(
                name: 'Chin Tucks', sets: 3, reps: '15', target: 'Neck · Chin'),
            FaceExercise(
                name: 'Jaw Clenches', sets: 3, reps: '20', target: 'Masseter'),
            FaceExercise(
                name: 'Brow Lifts', sets: 3, reps: '12', target: 'Frontalis'),
            FaceExercise(
                name: 'Lip Presses',
                sets: 3,
                reps: '15',
                target: 'Orbicularis Oris'),
          ],
          lookmax: [
            '🧴 Grooming: Trim nose hair · Clean up unibrow',
            '👀 Posture: 5min wall angle pose for posture correction',
            '💧 Hydration: Electrolytes + 2L water today',
            '🛌 Sleep: No screens 1h before bed · read instead',
          ]),
      DayPlan(
          day: s + 6,
          week: weekNum,
          title: 'REST',
          focus: 'Recovery',
          icon: '😴',
          scheduledDate: _dateKey(start.add(const Duration(days: 6))),
          exercises: []),
    ]);
  }

  // Navigation
  void selectTab(int idx) {
    _currentTab = idx;
    notifyListeners();
  }

  void selectDay(int idx) {
    _selectedDay = idx;
    notifyListeners();
  }

  void prevWeek() {
    if (_currentWeekView > 0) {
      _currentWeekView--;
      _selectedDay = _currentWeekView * 7;
      notifyListeners();
    }
  }

  void nextWeek() {
    if (_weeks.isEmpty) return;
    final maxW = _weeks.map((w) => w.week).reduce((a, b) => a > b ? a : b);
    if (_currentWeekView < maxW - 1) {
      _currentWeekView++;
      _selectedDay = _currentWeekView * 7;
      notifyListeners();
    }
  }

  // Completion
  Future<void> completeDay(int dayIdx) async {
    if (_completedDays.contains(dayIdx)) return;
    _completedDays.add(dayIdx);
    _completedDays = _completedDays.toSet().toList();
    await db.markCompletedDay(dayIdx);
    _completedDates = await db.loadCompletedDates();
    await _updateProgressFromDays();
    if (_profile != null) {
      _profile = _profile!.copyWith(lastWorkoutDate: _dateKey(_todayOnly));
      await db.saveProfile(_profile!);
    }
    await _syncExperienceLevel(notifyRankUp: true);
    notifyListeners();
    _afterComplete(dayIdx);
  }

  Future<void> _updateProgressFromDays() async {
    final allDays = <DayPlan>[];
    for (final w in _weeks) {
      allDays.addAll(w.days);
    }
    _progress.days = allDays.length;
    _progress.workouts = _completedDays.length;
    _progress.streak = _computeStreakFromDates(_completedDates, _skippedDates);
    await db.saveProgress(_progress);
  }

  void _afterComplete(int dayIdx) {
    final week = currentWeek;
    if (week == null) return;
    final allDone =
        week.days.every((d) => d.isRest || _completedDays.contains(d.day - 1));
    if (allDone) {
      generateWeek(week.week + 1, focusGeneratedWeek: false);
    }
  }

  // Session player
  void startSession() {
    final plan = selectedDayPlan;
    if (plan == null || plan.isRest) return;
    if (!canStartSelectedDay) return;
    if (_completedDays.contains(_selectedDay)) return;

    _session.dayIdx = _selectedDay;
    if (_savedSession != null && _savedSession!.dayIdx == _selectedDay) {
      _session.exIdx = _savedSession!.exIdx;
      _session.setIdx = _savedSession!.setIdx;
      _session.phase = SessionPhase.idle;
      _session.setLogs = List.from(_savedSession!.setLogs);
    } else {
      _session.exIdx = 0;
      _session.setIdx = 0;
      _session.phase = SessionPhase.idle;
      _session.setLogs = [];
    }
    _session.timeLeft = 0;
    notifyListeners();
  }

  void closeSession() {
    if (_session.phase != SessionPhase.complete) {
      _savedSession = SessionState(
        dayIdx: _session.dayIdx,
        exIdx: _session.exIdx,
        setIdx: _session.setIdx,
        setLogs: List.from(_session.setLogs),
      );
    }
    _session.phase = SessionPhase.idle;
    notifyListeners();
  }

  Exercise? get currentExercise {
    final plan = selectedDayPlan;
    if (plan == null || _session.exIdx >= plan.exercises.length) return null;
    return plan.exercises[_session.exIdx];
  }

  void sessionAction() {
    if (_session.phase == SessionPhase.idle) {
      _session.phase = SessionPhase.active;
      final ex = currentExercise;
      if (ex != null && ex.isTimed) {
        _session.timeLeft = ex.repSeconds;
      }
      notifyListeners();
    } else if (_session.phase == SessionPhase.active) {
      _recordExerciseResult(currentExercise);
      _session.setLogs.add(SetLog(
          exIdx: _session.exIdx, setIdx: _session.setIdx, completed: true));
      _advanceSet();
    } else if (_session.phase == SessionPhase.complete) {
      return;
    }
  }

  void _recordExerciseResult(Exercise? ex) {
    if (ex == null || ex.logKey == null || ex.logVal <= 0) return;

    var changed = false;
    switch (ex.logKey) {
      case 'pushup':
        if (_progress.pushup < ex.logVal) {
          _progress.pushup = ex.logVal;
          changed = true;
        }
        break;
      case 'squat':
        if (_progress.squat < ex.logVal) {
          _progress.squat = ex.logVal;
          changed = true;
        }
        break;
      case 'plank':
        if (_progress.plank < ex.logVal) {
          _progress.plank = ex.logVal;
          changed = true;
        }
        break;
      case 'burpee':
        if (_progress.burpee < ex.logVal) {
          _progress.burpee = ex.logVal;
          changed = true;
        }
        break;
    }

    if (changed) {
      unawaited(db.saveProgress(_progress));
    }
  }

  void _advanceSet() {
    final ex = currentExercise;
    if (ex == null) return;
    _session.setIdx++;
    if (_session.setIdx >= ex.sets) {
      _session.setIdx = 0;
      _session.exIdx++;
      final plan = selectedDayPlan;
      if (plan != null && _session.exIdx >= plan.exercises.length) {
        _session.phase = SessionPhase.complete;
        notifyListeners();
        return;
      }
    }
    _session.phase = SessionPhase.rest;
    _session.timeLeft = 45;
    notifyListeners();
  }

  void skipRest() {
    if (_session.phase != SessionPhase.rest) return;
    _session.phase = SessionPhase.idle;
    notifyListeners();
  }

  Future<void> completeWorkoutSession() async {
    _savedSession = null;
    await completeDay(_session.dayIdx);
    _session.phase = SessionPhase.idle;
    notifyListeners();
    try {
      await ApiService().post('/api/cron/workout-completed', {});
    } catch (_) {}
  }

  int _computeStreakFromDates(
      List<String> completedDates, List<String> skippedDates) {
    final markers = <String, bool>{};
    for (final date in completedDates) {
      markers[date] = false;
    }
    for (final date in skippedDates) {
      markers[date] = true;
    }
    if (markers.isEmpty) return 0;

    final uniqueDates = markers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    int streak = 0;
    DateTime? previous;
    for (final entry in uniqueDates) {
      final current = DateTime.tryParse(entry.key);
      if (current == null) continue;
      final day = DateTime(current.year, current.month, current.day);
      if (entry.value) {
        streak = 0;
        previous = day;
        continue;
      }
      if (previous == null) {
        streak = 1;
      } else {
        final diff = day.difference(previous).inDays;
        streak = diff == 1 ? streak + 1 : 1;
      }
      previous = day;
    }
    return streak;
  }

  Future<void> _syncSkippedWorkoutDays() async {
    if (!db.hasUser || _weeks.isEmpty) return;
    final completed = _completedDates.toSet();
    final skipped = _skippedDates.toSet();
    final today = _todayOnly;
    var added = false;

    for (final week in _weeks) {
      for (final day in week.days) {
        if (day.isRest) continue;
        final scheduled = _parseDateOnly(day.scheduledDate);
        if (scheduled == null || !scheduled.isBefore(today)) continue;
        final key = _dateKey(scheduled);
        if (completed.contains(key) || skipped.contains(key)) continue;
        await db.markSkippedDate(key);
        skipped.add(key);
        added = true;
      }
    }

    if (added) {
      _skippedDates = await db.loadSkippedDates();
    }
  }

  // Loading
  void setLoading(String key, bool val) {
    _loading = val;
    _loadingKey = key;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stepNotifyTimer?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }

  // Coach
  Future<String> coachSend(String message) async {
    final groq = _groq;
    final profile = _profile;
    if (groq == null || profile == null) {
      return '\u26A0\uFE0F Set your Groq API key in Settings first.';
    }

    _coachHistory.add({'role': 'user', 'content': message});
    await db.saveCoachMessage('user', message);
    notifyListeners();

    try {
      final reply = await groq.coachChat(_recentCoachHistory(), profile);
      _coachHistory.add({'role': 'assistant', 'content': reply});
      await db.saveCoachMessage('assistant', reply);
      _trimCoachHistory();
      notifyListeners();
      return reply;
    } catch (e) {
      final errorReply = '\u26A0\uFE0F Error: $e';
      _coachHistory.add({'role': 'assistant', 'content': errorReply});
      await db.saveCoachMessage('assistant', errorReply);
      _trimCoachHistory();
      notifyListeners();
      return errorReply;
    }
  }

  Future<void> clearCoachHistory() async {
    _coachHistory.clear();
    await db.clearCoachMessages();
    notifyListeners();
  }

  List<Map<String, String>> _recentCoachHistory() {
    if (_coachHistory.length <= _coachHistoryLimit) {
      return List<Map<String, String>>.unmodifiable(_coachHistory);
    }
    return List<Map<String, String>>.unmodifiable(
      _coachHistory.sublist(_coachHistory.length - _coachHistoryLimit),
    );
  }

  void _trimCoachHistory() {
    if (_coachHistory.length <= _coachHistoryLimit) return;
    _coachHistory.removeRange(0, _coachHistory.length - _coachHistoryLimit);
  }

  Future<Map<String, String>> getExerciseGuide(Exercise ex) async {
    final key = '${ex.name}|${ex.target}|${ex.reps}|${ex.sets}';
    final cached = _exerciseGuideCache[key];
    if (cached != null) return cached;

    final guide = _groq == null
        ? <String, String>{
            'start_position':
                'Set up tall and stable for ${ex.target.toLowerCase()} with the core braced and the body ready to move.',
            'body_position':
                'Keep the working joints stacked and move with control through the target area.',
            'how_to':
                'Move slowly, stay controlled, and keep the tension where it belongs.',
            'finish_position':
                'End in a balanced position with the target muscles still engaged.',
            'why_it_matters':
                'Helps you build control, form, and clean execution.',
            'mistakes':
                'Do not rush, twist, or lose tension in the target area.',
          }
        : await _groq!.generateExerciseGuide(
            name: ex.name,
            target: ex.target,
            meta: ex.isTimed
                ? 'TIMED | ${ex.sets} sets'
                : '${ex.sets} sets | ${ex.reps} reps',
            desc: 'Planned movement for ${ex.target}.',
          );

    _exerciseGuideCache[key] = guide;
    return guide;
  }

  Future<Map<String, String>> getFaceGuide(FaceExercise ex,
      {String subtitle = '', String benefit = ''}) async {
    final key = '${ex.name}|${ex.target}|${ex.reps}|${ex.sets}';
    final cached = _faceGuideCache[key];
    if (cached != null) return cached;

    final guide = _groq == null
        ? <String, String>{
            'start_position':
                'Set the face and neck in a neutral relaxed position for ${ex.target.toLowerCase()}.',
            'body_position':
                'Keep the motion controlled and the neck steady while the target area works.',
            'how_to':
                'Move with control, keep the face relaxed except for the target muscle, and avoid clenching.',
            'finish_position':
                'Return to a neutral relaxed face with the target area calm.',
            'why_it_matters': benefit.isNotEmpty
                ? benefit
                : 'Builds control and awareness in the target area.',
            'mistakes': 'Do not strain, over-clench, or force the movement.',
          }
        : await _groq!.generateFaceGuide(
            name: ex.name,
            zone: ex.target,
            reps: ex.reps,
            subtitle: subtitle,
            howTo: 'Move with control and keep the neck stable.',
            benefit: benefit,
          );

    _faceGuideCache[key] = guide;
    return guide;
  }

  Future<String> getWorkoutMotivation({
    required DayPlan? plan,
    required bool faceMode,
    required int faceIndex,
  }) async {
    if (_profile == null) {
      return 'You’ve got this. One clean rep at a time.';
    }

    final key = faceMode
        ? 'face-${plan?.day ?? 0}-$faceIndex-${_session.phase.index}'
        : 'main-${plan?.day ?? 0}-${_session.exIdx}-${_session.setIdx}-${_session.phase.index}';
    final cached = _motivationCache[key];
    if (cached != null) return cached;

    final workoutName = plan?.title ?? 'WORKOUT';
    final target = faceMode
        ? (plan?.faceExercises.isNotEmpty == true
            ? plan!.faceExercises[faceIndex].target
            : 'Face & posture')
        : (plan?.exercises.isNotEmpty == true
            ? plan!.exercises[_session.exIdx].target
            : 'Full body');
    final phase = _session.phase.name.toUpperCase();
    final contextLine = faceMode
        ? 'face exercise ${faceIndex + 1} in the current workout'
        : 'exercise ${_session.exIdx + 1} of ${plan?.exercises.length ?? 1}';

    String text;
    if (_groq != null) {
      text = await _groq!.generateWorkoutMotivation(
        workoutName: workoutName,
        target: target,
        phase: phase,
        contextLine: contextLine,
      );
    } else {
      const fallbackLines = [
        'Breathe in, lock in, and make this set count.',
        'Small effort now, big pride later.',
        'You’re built for this moment. Go.',
        'Smooth reps, strong mind, no wasted motion.',
        'Keep moving. Your future self is watching.',
      ];
      text = fallbackLines[key.hashCode.abs() % fallbackLines.length];
    }

    _motivationCache[key] = text;
    return text;
  }

  bool isCompleted(int dayIdx) => _completedDays.contains(dayIdx);

  bool isWeekComplete(int weekNum) {
    final week = _weeks.where((w) => w.week == weekNum).toList();
    if (week.isEmpty) return false;
    return week.first.days
        .every((d) => d.isRest || _completedDays.contains(d.day - 1));
  }

  String getOverallProgress() {
    if (_progress.workouts == 0) return 'Start your first workout!';
    return '🔥 $_progress.workouts workouts · $_progress.streak day streak';
  }
}

