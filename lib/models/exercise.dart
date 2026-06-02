class Exercise {
  final String name;
  final int sets;
  final String reps;
  final String target;
  final String? logKey;
  final int logVal;
  String? imageUrl;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.target,
    this.logKey,
    this.logVal = 0,
    this.imageUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      target: json['target'] as String,
      logKey: (json['logKey'] ?? json['log_key']) as String?,
      logVal: (json['logVal'] ?? json['log_val'] ?? 0) as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'target': target,
    'log_key': logKey,
    'log_val': logVal,
    'imageUrl': imageUrl,
  };

  bool get isTimed => reps.contains('s');
  int get repSeconds {
    if (!isTimed) return 0;
    return int.tryParse(reps.replaceAll('s', '')) ?? 30;
  }
}

class FaceExercise {
  final String name;
  final int sets;
  final String reps;
  final String target;

  FaceExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.target,
  });

  factory FaceExercise.fromJson(Map<String, dynamic> json) {
    return FaceExercise(
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      target: json['target'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'target': target,
  };
}

class SetLog {
  final int exIdx;
  final int setIdx;
  final bool completed;

  SetLog({
    required this.exIdx,
    required this.setIdx,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
    'exIdx': exIdx,
    'setIdx': setIdx,
    'completed': completed,
  };
}
