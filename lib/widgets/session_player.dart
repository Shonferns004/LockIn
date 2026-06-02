import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/session_state.dart';
import '../models/week_plan.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'skeletons.dart';
import 'animations.dart';

class SessionPlayer extends StatefulWidget {
  const SessionPlayer({super.key});

  @override
  State<SessionPlayer> createState() => _SessionPlayerState();
}

class _SessionPlayerState extends State<SessionPlayer> {
  late final _WorkoutSounds _sounds;
  Timer? _timer;
  bool _faceMode = false;
  int _faceIndex = 0;
  String _guideKey = '';
  Future<Map<String, String>>? _guideFuture;

  @override
  void initState() {
    super.initState();
    _sounds = _WorkoutSounds();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sounds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final plan = app.selectedDayPlan;
        if (plan == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: SkeletonBox(width: 120, height: 16)),
          );
        }

        final displayFaceMode = _faceMode ||
            (app.session.phase == SessionPhase.complete &&
                plan.faceExercises.isNotEmpty);
        _sounds.setMuted(app.soundMuted);

        if (app.session.phase == SessionPhase.complete &&
            plan.faceExercises.isNotEmpty &&
            !_faceMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_faceMode) {
              setState(() {
                _faceMode = true;
                _faceIndex = 0;
              });
            }
          });
        }

        _syncGuideFuture(app, plan, displayFaceMode);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
                final maxWidth =
                    constraints.maxWidth > 680 ? 680.0 : constraints.maxWidth;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(
                            app: app,
                            onClose: () => _closeSession(context, app),
                          ),
                          const SizedBox(height: 18),
                          _HeaderCard(
                            plan: plan,
                            app: app,
                            faceMode: displayFaceMode,
                            faceIndex: _faceIndex,
                          ),
                          const SizedBox(height: 16),
                          _MainCard(
                            plan: plan,
                            app: app,
                            faceMode: displayFaceMode,
                            faceIndex: _faceIndex,
                            onAction: () =>
                                _handlePrimaryAction(context, app, plan),
                            onSkipRest: () => _skipRest(app),
                          ),
                          const SizedBox(height: 16),
                          _GuidePanel(
                            future: _guideFuture,
                            imageUrl: displayFaceMode
                                ? null
                                : app.currentExercise?.imageUrl,
                          ),
                          const SizedBox(height: 16),
                          if (displayFaceMode)
                            _FacePager(
                              total: plan.faceExercises.length,
                              index: _faceIndex,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _syncGuideFuture(AppProvider app, DayPlan plan, bool displayFaceMode) {
    final key = _guideCacheKey(app, plan, displayFaceMode);
    if (key == _guideKey) return;
    _guideKey = key;

    if (displayFaceMode && plan.faceExercises.isNotEmpty) {
      final safeIndex = _faceIndex.clamp(0, plan.faceExercises.length - 1);
      if (safeIndex != _faceIndex) {
        _faceIndex = safeIndex;
      }
      final face = plan.faceExercises[safeIndex];
      _guideFuture = app.getFaceGuide(
        face,
        subtitle: plan.title,
        benefit: face.target,
      );
      return;
    }

    final ex = app.currentExercise;
    _guideFuture = ex == null ? null : app.getExerciseGuide(ex);
  }

  String _guideCacheKey(AppProvider app, DayPlan plan, bool displayFaceMode) {
    if (displayFaceMode && plan.faceExercises.isNotEmpty) {
      final safeIndex = _faceIndex.clamp(0, plan.faceExercises.length - 1);
      return 'face-$safeIndex-${app.session.phase.index}-${app.session.setIdx}';
    }
    return 'main-${app.session.exIdx}-${app.session.setIdx}-${app.session.phase.index}';
  }

  void _closeSession(BuildContext context, AppProvider app) {
    if (app.session.phase.index > 0 &&
        app.session.phase != SessionPhase.complete) {
      showScaleAlert(context, (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.border, width: 4),
        ),
        title: const Text('End workout?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Progress won't be saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: AppTheme.textTheme.labelMedium),
          ),
          NeoButton(
            label: 'END',
            bg: AppTheme.error,
            textColor: Colors.white,
            onTap: () async {
              final dialogNavigator = Navigator.of(ctx);
              final pageNavigator = Navigator.of(context);
              _timer?.cancel();
              _sounds.stopAll();
              await _sounds.playExit();
              if (!mounted) return;
              app.closeSession();
              dialogNavigator.pop();
              pageNavigator.pop();
            },
          ),
        ],
      ));
      return;
    }

    _timer?.cancel();
    _sounds.stopAll();
    app.closeSession();
    Navigator.of(context).pop();
  }

  void _handlePrimaryAction(
      BuildContext context, AppProvider app, dynamic plan) {
    if (_faceMode && app.session.phase == SessionPhase.complete) {
      if (plan.faceExercises.isEmpty || _faceIndex + 1 >= plan.faceExercises.length) {
        _finishSession(context, app);
      } else {
        setState(() {
          _faceIndex++;
        });
      }
      return;
    }

    if (app.session.phase == SessionPhase.idle) {
      _startWorkoutWithWhistle(app, plan);
      return;
    }

    if (app.session.phase == SessionPhase.active) {
      _timer?.cancel();
      setState(() {
        app.sessionAction();
      });
      if (app.session.phase == SessionPhase.complete) {
        if (plan.faceExercises.isNotEmpty) {
          setState(() {
            _faceMode = true;
            _faceIndex = 0;
          });
          return;
        }
      }
      if (app.session.phase == SessionPhase.rest) {
        _sounds.playClock();
        _startRestTimer(app);
      }
      return;
    }

    if (app.session.phase == SessionPhase.rest) {
      _skipRest(app);
      return;
    }

    if (app.session.phase == SessionPhase.complete) {
      if (!_faceMode && plan.faceExercises.isNotEmpty) {
        setState(() {
          _faceMode = true;
          _faceIndex = 0;
        });
        return;
      }
    }
  }

  Future<void> _finishSession(BuildContext context, AppProvider app) async {
    _timer?.cancel();
    final navigator = Navigator.of(context);
    await app.completeWorkoutSession();
    if (!mounted) return;
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _startWorkoutWithWhistle(AppProvider app, DayPlan plan) async {
    _timer?.cancel();
    try {
      await _sounds.playWhistle();
    } catch (_) {}
    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      app.sessionAction();
    });

    final ex = app.currentExercise;
    if (ex == null) {
      setState(() {});
      return;
    }

    if (ex.isTimed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (app.session.timeLeft <= 1) {
          t.cancel();
          setState(() {
            app.sessionAction();
          });
          if (app.session.phase == SessionPhase.complete &&
              plan.faceExercises.isNotEmpty) {
            setState(() {
              _faceMode = true;
              _faceIndex = 0;
            });
            return;
          }
          _startRestTimer(app);
        } else {
          setState(() {
            app.session.timeLeft--;
          });
          _sounds.playClock();
        }
      });
    } else {
      setState(() {});
    }
  }

  void _startRestTimer(AppProvider app) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (app.session.timeLeft <= 1) {
        t.cancel();
        _sounds.stopAll();
        setState(() {
          app.skipRest();
        });
      } else {
        setState(() {
          app.session.timeLeft--;
        });
        unawaited(_sounds.playClock());
      }
    });
  }

  void _skipRest(AppProvider app) {
    _timer?.cancel();
    _sounds.stopAll();
    setState(() {
      app.skipRest();
    });
  }
}

class _WorkoutSounds {
  final AudioPlayer _whistlePlayer = AudioPlayer();
  final AudioPlayer _clockPlayer = AudioPlayer();
  final AudioPlayer _exitPlayer = AudioPlayer();
  bool _muted = false;
  int _generation = 0;

  _WorkoutSounds() {
    _whistlePlayer.setReleaseMode(ReleaseMode.stop);
    _clockPlayer.setReleaseMode(ReleaseMode.stop);
    _exitPlayer.setReleaseMode(ReleaseMode.stop);
  }

  void setMuted(bool muted) {
    _muted = muted;
    _generation++;
    if (_muted) {
      _whistlePlayer.stop();
      _clockPlayer.stop();
    }
  }

  void stopAll() {
    _generation++;
    _whistlePlayer.stop();
    _clockPlayer.stop();
  }

  Future<void> playWhistle() async {
    if (_muted) return;
    try {
      final gen = _generation;
      await _whistlePlayer.stop();
      if (_muted || gen != _generation) return;
      await _whistlePlayer.play(AssetSource('audio/whistle.mp3'), volume: 0.9);
    } catch (_) {}
  }

  Future<void> playClock() async {
    if (_muted) return;
    try {
      final gen = _generation;
      await _clockPlayer.stop();
      if (_muted || gen != _generation) return;
      await _clockPlayer.play(AssetSource('audio/clock.ogg'), volume: 0.8);
    } catch (_) {}
  }

  Future<void> playExit() async {
    if (_muted) return;
    try {
      await _exitPlayer.stop();
      await _exitPlayer.play(AssetSource('audio/abey.wav'), volume: 0.9);
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _whistlePlayer.dispose();
    await _clockPlayer.dispose();
    await _exitPlayer.dispose();
  }
}

class _TopBar extends StatelessWidget {
  final AppProvider app;
  final VoidCallback onClose;

  const _TopBar({required this.app, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('SESSION',
            style: AppTheme.textTheme.labelLarge
                ?.copyWith(letterSpacing: 2, color: AppTheme.primary)),
        const Spacer(),
        GestureDetector(
          onTap: () => app.setSoundMuted(!app.soundMuted),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBright,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: Icon(
              app.soundMuted ? Icons.volume_off : Icons.volume_up,
              size: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBright,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: const Icon(Icons.close,
                size: 14, color: AppTheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DayPlan plan;
  final AppProvider app;
  final bool faceMode;
  final int faceIndex;

  const _HeaderCard({
    required this.plan,
    required this.app,
    required this.faceMode,
    required this.faceIndex,
  });

  @override
  Widget build(BuildContext context) {
    final totalEx = plan.exercises.length;
    final totalSets = app.currentExercise?.sets ?? 1;
    final progress = totalEx == 0
        ? 0.0
        : ((app.session.exIdx * totalSets + app.session.setIdx) /
                (totalEx * totalSets))
            .clamp(0.0, 1.0);
    return NeoCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAY ${plan.day} - ${plan.title}',
              style: AppTheme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Week ${plan.week} · ${plan.focus}',
              style: AppTheme.textTheme.labelMedium
                  ?.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(color: AppTheme.primaryFixedDim),
            ),
          ),
          const SizedBox(height: 10),
          if (!faceMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Exercise ${app.session.exIdx + 1} of ${totalEx == 0 ? 1 : totalEx}',
                    style: AppTheme.textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant)),
                Text('Set ${app.session.setIdx + 1} of $totalSets',
                    style: AppTheme.textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            )
          else
            Text(
              'Face exercise ${faceIndex + 1} of ${plan.faceExercises.length}',
              style: AppTheme.textTheme.labelSmall
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  final DayPlan plan;
  final AppProvider app;
  final bool faceMode;
  final int faceIndex;
  final VoidCallback onAction;
  final VoidCallback onSkipRest;

  const _MainCard({
    required this.plan,
    required this.app,
    required this.faceMode,
    required this.faceIndex,
    required this.onAction,
    required this.onSkipRest,
  });

  @override
  Widget build(BuildContext context) {
    if (faceMode) {
      final face = plan.faceExercises[faceIndex];
      return _exercisePanel(
        title: face.name,
        subtitle: '${face.sets} sets x ${face.reps}',
        target: face.target,
        center: _buildFaceCenter(app),
        actionLabel: faceIndex + 1 >= plan.faceExercises.length
            ? 'FINISH WORKOUT'
            : 'DONE',
        actionColor: AppTheme.primary,
        onAction: onAction,
      );
    }

    final ex = app.currentExercise;
    if (ex == null) {
      return const SizedBox.shrink();
    }

    final timed = ex.isTimed;
    final body = app.session.phase == SessionPhase.idle
        ? _idleBody(app, ex, timed, plan.exercises.length)
        : app.session.phase == SessionPhase.active
            ? _activeBody(app, ex, timed)
            : app.session.phase == SessionPhase.rest
                ? _restBody(app)
                : _completeBody(plan);

    return _exercisePanel(
      title: ex.name,
      subtitle: ex.target,
      target: timed
          ? '${ex.sets} sets x ${ex.repSeconds}s'
          : '${ex.sets} sets x ${ex.reps} reps',
      center: body,
      actionLabel: _buttonLabel(app),
      actionColor: app.session.phase == SessionPhase.rest
          ? AppTheme.secondary
          : AppTheme.primary,
      onAction: onAction,
      showSkipRest: app.session.phase == SessionPhase.rest,
      onSkipRest: onSkipRest,
    );
  }

  Widget _exercisePanel({
    required String title,
    required String subtitle,
    required String target,
    required Widget center,
    required String actionLabel,
    required Color actionColor,
    required VoidCallback onAction,
    bool showSkipRest = false,
    VoidCallback? onSkipRest,
  }) {
    return NeoCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: AppTheme.textTheme.displayMedium?.copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: AppTheme.textTheme.labelMedium
                  ?.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(target,
              style: AppTheme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Center(child: center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: NeoButton(
              label: actionLabel,
              bg: actionColor,
              textColor: Colors.white,
              onTap: onAction,
            ),
          ),
          if (showSkipRest && onSkipRest != null) ...[
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: onSkipRest,
                child: Text('SKIP REST',
                    style: AppTheme.textTheme.labelMedium
                        ?.copyWith(color: AppTheme.outline)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaceCenter(AppProvider app) {
    final face = plan.faceExercises[faceIndex];
    return Column(
      children: [
        Text(
          app.session.phase == SessionPhase.complete
              ? 'READY FOR FACE WORK'
              : 'FACE WORK',
          style: AppTheme.textTheme.labelLarge
              ?.copyWith(color: AppTheme.secondary, letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        Text(
          face.target,
          style: AppTheme.textTheme.displayMedium?.copyWith(fontSize: 42),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _exerciseImage(Exercise ex) {
    final url = ex.imageUrl;
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _idleBody(AppProvider app, Exercise ex, bool timed, int totalEx) {
    return Column(
      children: [
        _exerciseImage(ex),
        Text(
          timed ? '0:${ex.repSeconds.toString().padLeft(2, '0')}' : '-',
          style: AppTheme.textTheme.displayMedium
              ?.copyWith(color: AppTheme.primary, fontSize: 52),
        ),
        const SizedBox(height: 4),
        Text(timed ? 'TIMED' : 'REPS',
            style: AppTheme.textTheme.labelMedium
                ?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(
          timed
              ? 'Hold for ${ex.reps} seconds - Set ${app.session.setIdx + 1} of ${ex.sets}'
              : 'Do ${ex.reps} reps x ${ex.sets} sets - Set ${app.session.setIdx + 1} of ${ex.sets}',
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          'Workout ${app.session.exIdx + 1} of $totalEx',
          style: AppTheme.textTheme.labelSmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _activeBody(AppProvider app, Exercise ex, bool timed) {
    return Column(
      children: [
        _exerciseImage(ex),
        Text(
          timed ? _formatTime(app.session.timeLeft) : ex.reps,
          style: AppTheme.textTheme.displayMedium
              ?.copyWith(color: AppTheme.primary, fontSize: 52),
        ),
        const SizedBox(height: 4),
        Text(
          timed ? 'COUNTDOWN' : 'DO YOUR REPS',
          style: AppTheme.textTheme.labelMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Text(
          timed
              ? '${app.session.timeLeft}s remaining'
              : 'Complete ${ex.reps} reps',
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _restBody(AppProvider app) {
    final next = _nextExerciseName(app);
    return Column(
      children: [
        Text(
          '0:${app.session.timeLeft.toString().padLeft(2, '0')}',
          style: AppTheme.textTheme.displayMedium
              ?.copyWith(color: AppTheme.secondary, fontSize: 52),
        ),
        const SizedBox(height: 4),
        Text('REST',
            style: AppTheme.textTheme.labelMedium
                ?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(
          'Rest ${app.session.timeLeft}s - next: $next',
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _completeBody(DayPlan plan) {
    return Column(
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text('WORKOUT COMPLETE!',
            style: AppTheme.textTheme.headlineMedium
                ?.copyWith(color: AppTheme.primary)),
        const SizedBox(height: 4),
        Text(
          plan.faceExercises.isNotEmpty
              ? 'Face work starts next.'
              : 'Session done.',
          style: AppTheme.textTheme.labelMedium
              ?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _buttonLabel(AppProvider app) {
    switch (app.session.phase) {
      case SessionPhase.idle:
        return 'START SET';
      case SessionPhase.active:
        return 'DONE';
      case SessionPhase.rest:
        return 'RESTING...';
      case SessionPhase.complete:
        return plan.faceExercises.isNotEmpty ? 'FACE EXERCISES' : 'FINISH';
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _nextExerciseName(AppProvider app) {
    final nextIdx = app.session.setIdx + 1 >= (app.currentExercise?.sets ?? 1)
        ? app.session.exIdx + 1
        : app.session.exIdx;
    if (nextIdx >= plan.exercises.length) return 'Finish!';
    return plan.exercises[nextIdx].name;
  }
}

class _GuidePanel extends StatelessWidget {
  final Future<Map<String, String>>? future;
  final String? imageUrl;

  const _GuidePanel({required this.future, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const SizedBox.shrink();
    }

    return NeoCard(
      bg: Colors.white,
      child: FutureBuilder<Map<String, String>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _GuideSkeleton();
          }

          final guide = snapshot.data ?? const {};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Text('AI COACH',
                  style: AppTheme.textTheme.labelLarge
                      ?.copyWith(color: AppTheme.primary, letterSpacing: 2)),
              const SizedBox(height: 12),
              _guideBlock('START POSITION', guide['start_position']),
              _guideBlock('BODY POSITION', guide['body_position']),
              _guideBlock('HOW TO', guide['how_to']),
              _guideBlock('FINISH POSITION', guide['finish_position']),
              _guideBlock('WHY IT MATTERS', guide['why_it_matters']),
              _guideBlock('COMMON MISTAKES', guide['mistakes']),
            ],
          );
        },
      ),
    );
  }

  Widget _guideBlock(String label, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(text,
              style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _GuideSkeleton extends StatelessWidget {
  const _GuideSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 120, height: 14),
        SizedBox(height: 14),
        SkeletonBox(width: 180, height: 12),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 12),
        SizedBox(height: 12),
        SkeletonBox(width: 160, height: 12),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 12),
        SizedBox(height: 8),
        SkeletonBox(width: 220, height: 12),
      ],
    );
  }
}

class _FacePager extends StatelessWidget {
  final int total;
  final int index;

  const _FacePager({required this.total, required this.index});

  @override
  Widget build(BuildContext context) {
    return Text(
      'FACE ${index + 1} OF $total',
      style: AppTheme.textTheme.labelLarge
          ?.copyWith(letterSpacing: 2, color: AppTheme.secondary),
    );
  }
}
