import 'exercise.dart';

enum SessionPhase { idle, active, rest, complete }

class SessionState {
  int dayIdx;
  int exIdx;
  int setIdx;
  SessionPhase phase;
  int timeLeft;
  List<SetLog> setLogs;

  SessionState({
    this.dayIdx = 0,
    this.exIdx = 0,
    this.setIdx = 0,
    this.phase = SessionPhase.idle,
    this.timeLeft = 0,
    List<SetLog>? setLogs,
  }) : setLogs = setLogs ?? [];
}
