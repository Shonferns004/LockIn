class Profile {
  final String username;
  final String email;
  final int laziness;
  final int height;
  final int weight;
  final int age;
  final String gender;
  final String goal;
  final String experience;
  final int timePerSession;
  final String health;
  final bool onboardingCompleted;
  final String groqKey;
  final int stepGoal;
  final bool stepEnabled;
  final int strideLength;
  final int dailySteps;
  final int waterGoal;
  final int dailyWater;
  final bool waterReminder;
  final String lastStepDate;
  final String lastWaterDate;
  final String lastWorkoutDate;
  final String difficultyLevel;
  final bool dailyReminders;
  final bool soundMuted;

  Profile({
    this.username = 'LockIn',
    this.email = '',
    required this.laziness,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.goal,
    required this.experience,
    required this.timePerSession,
    this.health = '',
    this.onboardingCompleted = false,
    this.groqKey = '',
    this.stepGoal = 10000,
    this.stepEnabled = false,
    this.strideLength = 70,
    this.dailySteps = 0,
    this.waterGoal = 2000,
    this.dailyWater = 0,
    this.waterReminder = false,
    this.lastStepDate = '',
    this.lastWaterDate = '',
    this.lastWorkoutDate = '',
    this.difficultyLevel = 'Beast',
    this.dailyReminders = false,
    this.soundMuted = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    int intVal(String key, int fallback) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool boolVal(String key, bool fallback) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
      return fallback;
    }

    String stringVal(String key, String fallback) {
      final value = json[key];
      return value == null ? fallback : value.toString();
    }

    return Profile(
      username: stringVal('username', 'LockIn'),
      email: stringVal('email', ''),
      laziness: intVal('laziness', 5),
      height: intVal('height', 170),
      weight: intVal('weight', 70),
      age: intVal('age', 25),
      gender: stringVal('gender', ''),
      goal: stringVal('goal', 'build_muscle'),
      experience: stringVal('experience', 'beginner'),
      timePerSession: intVal('timePerSession', intVal('time_per_session', 20)),
      health: stringVal('health', ''),
      onboardingCompleted:
          boolVal('onboardingCompleted', boolVal('onboarding_completed', false)),
      groqKey: stringVal('groqKey', stringVal('groq_key', '')),
      stepGoal: intVal('stepGoal', intVal('step_goal', 10000)),
      stepEnabled: boolVal('stepEnabled', boolVal('step_enabled', false)),
      strideLength: intVal('strideLength', intVal('stride_length', 70)),
      dailySteps: intVal('dailySteps', intVal('daily_steps', 0)),
      waterGoal: intVal('waterGoal', intVal('water_goal', 2000)),
      dailyWater: intVal('dailyWater', intVal('daily_water', 0)),
      waterReminder: boolVal('waterReminder', boolVal('water_reminder', false)),
      lastStepDate: stringVal('lastStepDate', stringVal('last_step_date', '')),
      lastWaterDate: stringVal('lastWaterDate', stringVal('last_water_date', '')),
      lastWorkoutDate:
          stringVal('lastWorkoutDate', stringVal('last_workout_date', '')),
      difficultyLevel:
          stringVal('difficultyLevel', stringVal('difficulty_level', 'Beast')),
      dailyReminders: boolVal('dailyReminders', boolVal('daily_reminders', false)),
      soundMuted: boolVal('soundMuted', boolVal('sound_muted', false)),
    );
  }

  Profile copyWith({
    String? username,
    String? email,
    int? laziness,
    int? height,
    int? weight,
    int? age,
    String? gender,
    String? goal,
    String? experience,
    int? timePerSession,
    String? health,
    bool? onboardingCompleted,
    String? groqKey,
    int? stepGoal,
    bool? stepEnabled,
    int? strideLength,
    int? dailySteps,
    int? waterGoal,
    int? dailyWater,
    bool? waterReminder,
    String? lastStepDate,
    String? lastWaterDate,
    String? lastWorkoutDate,
    String? difficultyLevel,
    bool? dailyReminders,
    bool? soundMuted,
  }) {
    return Profile(
      username: username ?? this.username,
      email: email ?? this.email,
      laziness: laziness ?? this.laziness,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      timePerSession: timePerSession ?? this.timePerSession,
      health: health ?? this.health,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      groqKey: groqKey ?? this.groqKey,
      stepGoal: stepGoal ?? this.stepGoal,
      stepEnabled: stepEnabled ?? this.stepEnabled,
      strideLength: strideLength ?? this.strideLength,
      dailySteps: dailySteps ?? this.dailySteps,
      waterGoal: waterGoal ?? this.waterGoal,
      dailyWater: dailyWater ?? this.dailyWater,
      waterReminder: waterReminder ?? this.waterReminder,
      lastStepDate: lastStepDate ?? this.lastStepDate,
      lastWaterDate: lastWaterDate ?? this.lastWaterDate,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      soundMuted: soundMuted ?? this.soundMuted,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'laziness': laziness,
        'height': height,
        'weight': weight,
        'age': age,
        'gender': gender,
        'goal': goal,
        'experience': experience,
        'time_per_session': timePerSession,
        'health': health,
        'onboarding_completed': onboardingCompleted,
        'groq_key': '',
        'step_goal': stepGoal,
        'step_enabled': stepEnabled,
        'stride_length': strideLength,
        'daily_steps': dailySteps,
        'water_goal': waterGoal,
        'daily_water': dailyWater,
        'water_reminder': waterReminder,
        'last_step_date': lastStepDate,
        'last_water_date': lastWaterDate,
        'last_workout_date': lastWorkoutDate,
        'difficulty_level': difficultyLevel,
        'daily_reminders': dailyReminders,
        'sound_muted': soundMuted,
      };

  String get intensityLabel {
    if (laziness <= 3) return 'Chill - easy pace';
    if (laziness <= 6) return 'Moderate - steady effort';
    return 'Intense - push hard';
  }
}
