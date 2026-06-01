import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/week_plan.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'skeletons.dart';

class ExerciseLibrary extends StatefulWidget {
  const ExerciseLibrary({super.key});

  @override
  State<ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<ExerciseLibrary> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _page = 0;

  static const int _pageSize = 6;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final allItems = _collectItems(app.weeks);
        final filtered = _filterItems(allItems, _query);
        final items = filtered;
        final totalPages = items.isEmpty ? 1 : ((items.length - 1) ~/ _pageSize) + 1;
        final page = _page.clamp(0, totalPages - 1).toInt();
        final start = page * _pageSize;
        final end = (start + _pageSize).clamp(0, items.length);
        final pageItems = items.isEmpty ? <_LibraryExercise>[] : items.sublist(start, end);
        final hasSearch = _query.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOME EXERCISES',
              style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Search every saved movement from your saved plans, then open a card for setup, execution, and common mistakes.',
              style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                  _page = 0;
                });
              },
              style: AppTheme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search workout library',
                hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _page = 0;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                filled: true,
                fillColor: AppTheme.surfaceBright,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.border, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.border, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            if (hasSearch && items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No workout matches your search.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No home exercises yet. Generate a weekly plan to populate this library.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              )
            else ...[
              ...pageItems.map((item) => _libraryCard(context, item)),
              const SizedBox(height: 8),
              _PaginationBar(
                page: page,
                totalPages: totalPages,
                onPrev: page > 0 ? () => setState(() => _page = page - 1) : null,
                onNext: page + 1 < totalPages ? () => setState(() => _page = page + 1) : null,
              ),
            ],
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  List<_LibraryExercise> _collectItems(List<WeekPlan> weeks) {
    final map = <String, _LibraryExercise>{};
    for (final week in weeks) {
      for (final day in week.days) {
        for (final ex in day.exercises) {
          final key = '${ex.name}|${ex.target}|${ex.reps}|${ex.sets}';
          map.putIfAbsent(
            key,
            () => _LibraryExercise(
              name: ex.name.toUpperCase(),
              target: ex.target.toUpperCase(),
              meta: ex.isTimed ? 'TIMED | ${ex.sets} sets' : '${ex.sets} sets | ${ex.reps} reps',
              desc: _dynamicDesc(ex),
              source: 'Week ${week.week} | Day ${day.day}',
              howTo: _getHowTo(ex.name),
            ),
          );
        }
      }
    }
    return map.values.toList();
  }

  List<_LibraryExercise> _filterItems(List<_LibraryExercise> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.target.toLowerCase().contains(q) ||
          item.meta.toLowerCase().contains(q) ||
          item.desc.toLowerCase().contains(q) ||
          item.source.toLowerCase().contains(q);
    }).toList();
  }

  Widget _libraryCard(BuildContext context, _LibraryExercise item) {
    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(0),
      onTap: () => _showDynamicModal(context, item),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTheme.textTheme.headlineMedium?.copyWith(letterSpacing: 0)),
                  Text(
                    item.meta,
                    style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(item.target, style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.primary, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 4),
                  Text(item.source, style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outline, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDynamicModal(BuildContext context, _LibraryExercise item) {
    final app = context.read<AppProvider>();
    final guideFuture = app.getExerciseGuide(
      Exercise(
        name: item.name,
        sets: int.tryParse(RegExp(r'(\d+)').firstMatch(item.meta)?.group(1) ?? '3') ?? 3,
        reps: item.meta.toLowerCase().contains('timed') ? '30s' : '10',
        target: item.target,
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.84,
        minChildSize: 0.45,
        maxChildSize: 0.97,
        expand: false,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border, width: 4)),
            ),
            child: FutureBuilder<Map<String, String>>(
              future: guideFuture,
              builder: (context, snapshot) {
                final loading = snapshot.connectionState != ConnectionState.done;
                final guide = snapshot.data ?? const {};
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (loading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Center(child: SkeletonBox(width: 40, height: 4, radius: 2)),
                          SizedBox(height: 20),
                          SkeletonBox(width: 160, height: 18),
                          SizedBox(height: 10),
                          SkeletonBox(width: 120, height: 12),
                          SizedBox(height: 18),
                          SkeletonCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 96, height: 12),
                                SizedBox(height: 12),
                                SkeletonBox(width: double.infinity, height: 12),
                                SizedBox(height: 8),
                                SkeletonBox(width: double.infinity, height: 12),
                                SizedBox(height: 8),
                                SkeletonBox(width: 220, height: 12),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Container(width: 40, height: 4, color: AppTheme.border)),
                          const SizedBox(height: 20),
                          Text(item.name, style: AppTheme.textTheme.displayMedium?.copyWith(color: AppTheme.primary)),
                          Text(item.target, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          Text(item.desc, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('START POSITION', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['start_position'] ?? item.desc, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('BODY POSITION', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['body_position'] ?? item.desc, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('HOW TO', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['how_to'] ?? item.howTo, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('FINISH POSITION', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['finish_position'] ?? item.desc, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('WHY IT MATTERS', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['why_it_matters'] ?? _getWhy(item.name), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('COMMON MISTAKES', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['mistakes'] ?? _getMistakes(item.name), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('SOURCE', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(item.source, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 40),
                        ],
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getHowTo(String name) {
    switch (name.toUpperCase()) {
      case 'PUSH-UP':
        return 'Start in a high plank with hands a little wider than shoulder-width. Lower the chest under control, keep elbows around 45 degrees, then press back up without letting the hips sag.';
      case 'SQUAT':
        return 'Stand with feet shoulder-width apart. Push the hips back, keep the chest tall, lower until thighs are parallel if you can, then drive through the heels to stand.';
      case 'PLANK':
        return 'Set the forearms on the floor, stack elbows under shoulders, and create a straight line from head to heels. Brace the core and breathe without letting the lower back drop.';
      case 'BURPEE':
        return 'From standing, squat down, plant the hands, jump the feet back, return to a solid plank, then jump or step the feet back in and stand tall with control.';
      case 'LUNGE':
        return 'Step forward with one leg, lower both knees until they bend to about 90 degrees, keep the front knee tracking over the toes, then push back to the start.';
      case 'MOUNTAIN CLIMBER':
        return 'Start in a strong plank. Drive one knee toward the chest, switch feet rhythmically, and keep the hips as stable as possible while you move.';
      case 'CRUNCH':
        return 'Lie on your back with knees bent. Brace the core, lift the shoulder blades off the floor, and lower slowly without pulling on the neck.';
      case 'LEG RAISE':
        return 'Lie flat, press the lower back into the floor, lift the legs without swinging, then lower them slowly with control.';
      case 'BICYCLE CRUNCH':
        return 'Bring opposite elbow toward the opposite knee in a smooth rotation. Keep the movement controlled and avoid yanking the neck.';
      case 'GLUTE BRIDGE':
        return 'Lie on your back, feet flat, and drive the hips upward by squeezing the glutes hard at the top. Pause briefly before lowering.';
      case 'CALF RAISE':
        return 'Stand tall, rise onto the balls of the feet, pause at the top, and lower through a full range without bouncing.';
      case 'WALL SIT':
        return 'Lean your back against a wall, slide down until the knees are around 90 degrees, and hold while keeping the feet flat and the core tight.';
      case 'SUPERMAN HOLD':
        return 'Lie face down, lift the arms and legs slightly off the floor, and hold with a long spine. Keep the neck neutral and avoid overextending.';
      case 'SNOW ANGELS':
        return 'Lie face down and sweep the arms from your sides to overhead in a controlled arc, squeezing the shoulder blades gently throughout the movement.';
      case 'SELF-RESISTANCE CURL':
        return 'Use one arm to resist the other as it curls upward. Keep the motion slow so the biceps have to work against the self-applied resistance.';
      case 'REVERSE PLANK':
        return 'Sit with legs extended, place hands behind you, and lift the hips until the torso is in a straight line. Keep the chest open and glutes engaged.';
      default:
        return 'Move slowly, keep form honest, and stop if you feel sharp pain. If the movement is timed, hold steady; if it is for reps, keep each rep controlled.';
    }
  }

  String _getWhy(String name) {
    switch (name.toUpperCase()) {
      case 'PUSH-UP':
        return 'Builds chest, triceps, and front shoulder strength while teaching core bracing and full-body tension.';
      case 'SQUAT':
        return 'Strengthens quads, glutes, and hips while building leg endurance and control.';
      case 'PLANK':
        return 'Trains anti-extension core strength, which carries over to every push and lower-body movement.';
      case 'BURPEE':
        return 'Combines strength and conditioning to raise work capacity and conditioning quickly.';
      case 'LUNGE':
        return 'Improves single-leg balance, hip stability, and left-right strength symmetry.';
      case 'MOUNTAIN CLIMBER':
        return 'Raises heart rate while teaching the core to stay stable under repeated movement.';
      case 'CRUNCH':
        return 'Builds direct abdominal flexion strength and control.';
      case 'LEG RAISE':
        return 'Targets the lower abs and teaches core control through a bigger range of motion.';
      case 'BICYCLE CRUNCH':
        return 'Trains the obliques and rotation control for a stronger midsection.';
      case 'GLUTE BRIDGE':
        return 'Activates the glutes and posterior chain while reducing stress on the lower back.';
      case 'CALF RAISE':
        return 'Strengthens the calves and improves ankle endurance and stability.';
      case 'WALL SIT':
        return 'Builds isometric leg endurance and mental tolerance under tension.';
      case 'SUPERMAN HOLD':
        return 'Strengthens the lower back and helps balance the push-heavy work in the plan.';
      case 'SNOW ANGELS':
        return 'Improves scapular control and rear shoulder engagement.';
      case 'SELF-RESISTANCE CURL':
        return 'Adds biceps tension without equipment while improving control through the full curl path.';
      case 'REVERSE PLANK':
        return 'Strengthens the posterior chain and opens the chest for better posture.';
      default:
        return 'It helps build movement control, consistency, and better exercise quality.';
    }
  }

  String _getMistakes(String name) {
    switch (name.toUpperCase()) {
      case 'PUSH-UP':
        return 'Do not flare the elbows too wide, sag the lower back, or cut the depth short.';
      case 'SQUAT':
        return 'Do not round the back, collapse the knees inward, or lift the heels off the floor.';
      case 'PLANK':
        return 'Do not let the hips sag, pike too high, or hold your breath.';
      case 'BURPEE':
        return 'Do not rush the landing, lose the plank, or skip full extension at the top.';
      case 'LUNGE':
        return 'Do not step too short, let the knee cave in, or lean forward too much.';
      case 'MOUNTAIN CLIMBER':
        return 'Do not bounce wildly or let the hips drift up and down.';
      case 'CRUNCH':
        return 'Do not yank on the neck or use momentum to finish the rep.';
      case 'LEG RAISE':
        return 'Do not swing the legs or let the lower back arch off the floor.';
      case 'BICYCLE CRUNCH':
        return 'Do not rush the rotation or pull the neck with the hands.';
      case 'GLUTE BRIDGE':
        return 'Do not overarch the lower back or push from the toes instead of the heels.';
      case 'CALF RAISE':
        return 'Do not bounce through the rep or collapse the ankles inward.';
      case 'WALL SIT':
        return 'Do not sit too high, let the knees cave in, or arch away from the wall.';
      case 'SUPERMAN HOLD':
        return 'Do not crank the neck or force the lift too high.';
      case 'SNOW ANGELS':
        return 'Do not shrug aggressively or rush the arm sweep.';
      case 'SELF-RESISTANCE CURL':
        return 'Do not let the shoulder cheat the movement or jerk the arm upward.';
      case 'REVERSE PLANK':
        return 'Do not let the hips drop or the shoulders collapse forward.';
      default:
        return 'Stay controlled and keep the movement honest.';
    }
  }

  String _getStartPosition(_LibraryExercise item) {
    final repMode = item.meta.contains('TIMED') ? 'hold' : 'rep';
    return 'Set up in a stable position for ${item.target.toLowerCase()}. Keep the main working joints stacked, the core braced, and the body ready to ${repMode} with control.';
  }

  String _getBodyPosition(_LibraryExercise item) {
    return 'Keep the body aligned for ${item.target.toLowerCase()}: chest stacked, core tight, neck neutral, and only the working muscles moving.';
  }

  String _getFinishPosition(_LibraryExercise item) {
    return 'Finish every rep or hold in a controlled, balanced position with ${item.target.toLowerCase()} still engaged and no sloppy collapse.';
  }

  String _dynamicDesc(Exercise ex) {
    final intensity = ex.isTimed ? 'hold for ${ex.reps}' : '${ex.reps} reps';
    return 'Planned movement for ${ex.target}. ${ex.sets} sets of $intensity. Keep every rep slow, clean, and controlled.';
  }

}

class _LibraryExercise {
  final String name;
  final String target;
  final String meta;
  final String desc;
  final String source;
  final String howTo;

  const _LibraryExercise({
    required this.name,
    required this.target,
    required this.meta,
    required this.desc,
    required this.source,
    required this.howTo,
  });
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onPrev,
          child: Icon(
            Icons.chevron_left,
            size: 24,
            color: onPrev == null ? AppTheme.outline : AppTheme.onBackground,
          ),
        ),
        Text(
          'PAGE ${page + 1} OF $totalPages',
          style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1),
        ),
        GestureDetector(
          onTap: onNext,
          child: Icon(
            Icons.chevron_right,
            size: 24,
            color: onNext == null ? AppTheme.outline : AppTheme.onBackground,
          ),
        ),
      ],
    );
  }
}
