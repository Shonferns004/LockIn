import 'exercise.dart';

class DayPlan {
  int day;
  int week;
  final String title;
  final String focus;
  final String icon;
  String scheduledDate;
  final List<Exercise> exercises;
  final List<FaceExercise> faceExercises;
  final List<String> lookmax;

  DayPlan({
    required this.day,
    required this.week,
    required this.title,
    required this.focus,
    required this.icon,
    this.scheduledDate = '',
    required this.exercises,
    this.faceExercises = const [],
    this.lookmax = const [],
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final exJson = json['exercises'] is List ? json['exercises'] as List<dynamic> : null;
    final faceJson = json['faceExercises'] is List
        ? json['faceExercises'] as List<dynamic>
        : (json['face_exercises'] is List ? json['face_exercises'] as List<dynamic> : null);
    final lookmaxJson = json['lookmax'] is List ? json['lookmax'] as List<dynamic> : null;
    return DayPlan(
      day: json['day'] as int? ?? 0,
      week: json['week'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      icon: json['icon'] as String? ?? '💪',
      scheduledDate:
          json['scheduledDate'] as String? ?? json['scheduled_date'] as String? ?? '',
      exercises:
          exJson?.whereType<Map<String, dynamic>>().map(Exercise.fromJson).toList() ??
              [],
      faceExercises: faceJson?.whereType<Map<String, dynamic>>().map(FaceExercise.fromJson).toList() ?? [],
      lookmax: lookmaxJson?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'week': week,
        'title': title,
        'focus': focus,
        'icon': icon,
        'scheduled_date': scheduledDate,
        'is_rest': isRest,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'face_exercises': faceExercises.map((e) => e.toJson()).toList(),
        'lookmax': lookmax,
      };

  bool get isRest => exercises.isEmpty;
}

class WeekPlan {
  final int week;
  String planStartDate;
  final List<DayPlan> days;

  WeekPlan({required this.week, this.planStartDate = '', required this.days});

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] is List ? json['days'] as List<dynamic> : null;
    return WeekPlan(
      week: json['week'] as int? ?? 0,
      planStartDate:
          json['planStartDate'] as String? ?? json['plan_start_date'] as String? ?? '',
      days: daysJson?.whereType<Map<String, dynamic>>().map(DayPlan.fromJson).toList() ??
          const <DayPlan>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'week': week,
        'plan_start_date': planStartDate,
        'days': days.map((d) => d.toJson()).toList(),
      };

  int get workoutDayCount => days.where((d) => !d.isRest).length;
  int get totalExercises => days.fold(0, (s, d) => s + d.exercises.length);
}
