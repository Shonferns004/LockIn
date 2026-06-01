class Progress {
  int days;
  int workouts;
  int streak;
  int pushup;
  int squat;
  int plank;
  int burpee;

  Progress({
    this.days = 0,
    this.workouts = 0,
    this.streak = 0,
    this.pushup = 0,
    this.squat = 0,
    this.plank = 0,
    this.burpee = 0,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      days: json['days'] as int? ?? 0,
      workouts: json['workouts'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      pushup: json['pushup'] as int? ?? 0,
      squat: json['squat'] as int? ?? 0,
      plank: json['plank'] as int? ?? 0,
      burpee: json['burpee'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'days': days,
    'workouts': workouts,
    'streak': streak,
    'pushup': pushup,
    'squat': squat,
    'plank': plank,
    'burpee': burpee,
  };
}
