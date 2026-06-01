import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/week_plan.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/face_exercise_card.dart';

class LookmaxScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const LookmaxScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TodayPlan(app: app),
                  const SizedBox(height: 32),
                  _FaceLibrary(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TodayPlan extends StatelessWidget {
  final AppProvider app;
  const _TodayPlan({required this.app});

  @override
  Widget build(BuildContext context) {
    final day = app.selectedDayPlan;
    return NeoCard(
      bg: AppTheme.surfaceBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S LOOKMAX PLAN",
            style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.secondary, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          if (day == null || day.isRest)
            Text(
              'Select a workout day in the Workout tab to see its lookmax plan.',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.onSurfaceVariant,
              ),
            )
          else ...[
            if (day.faceExercises.isNotEmpty) ...[
              Text(
                'FACE EXERCISES',
                style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.primary, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              ...day.faceExercises.map(
                (ex) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ex.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ex.sets}x${ex.reps}',
                        style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (day.lookmax.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'DAILY TIPS',
                style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.secondary, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              ...day.lookmax.map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    tip,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FaceLibrary extends StatefulWidget {
  @override
  State<_FaceLibrary> createState() => _FaceLibraryState();
}

class _FaceLibraryState extends State<_FaceLibrary> {
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
        final allItems = _filterItems(_collectItems(app.weeks), _query);
        final items = allItems;
        final totalPages = items.isEmpty ? 1 : ((items.length - 1) ~/ _pageSize) + 1;
        final page = _page.clamp(0, totalPages - 1).toInt();
        final start = page * _pageSize;
        final end = (start + _pageSize).clamp(0, items.length);
        final pageItems = items.isEmpty ? <FaceLibItem>[] : items.sublist(start, end);
        final hasSearch = _query.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FACE EXERCISES',
              style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Search every saved face move from your saved plans, then open a card for setup, execution, benefits, and mistakes to avoid.',
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
                hintText: 'Search face library',
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
            if (hasSearch && allItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No face move matches your search.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No face exercises yet. Generate a weekly plan to populate this tab.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              )
            else ...[
              ...pageItems.map((item) => FaceExerciseCard(item: item)),
              const SizedBox(height: 8),
              _PaginationBar(
                page: page,
                totalPages: totalPages,
                onPrev: page > 0 ? () => setState(() => _page = page - 1) : null,
                onNext: page + 1 < totalPages ? () => setState(() => _page = page + 1) : null,
              ),
            ],
          ],
        );
      },
    );
  }

  List<FaceLibItem> _collectItems(List<WeekPlan> weeks) {
    final map = <String, FaceLibItem>{};
    for (final week in weeks) {
      for (final day in week.days) {
        for (final ex in day.faceExercises) {
          final key = '${ex.name}|${ex.target}|${ex.reps}|${ex.sets}';
          map.putIfAbsent(
            key,
            () => FaceLibItem(
              ex.name.toUpperCase(),
              ex.target.toUpperCase(),
              ex.reps.toUpperCase().contains('ALL DAY') ? 'ALL DAY' : '${ex.sets}x${ex.reps}',
              '${day.title} | Week ${week.week}',
              _howTo(ex),
              _benefit(ex),
            ),
          );
        }
      }
    }
    return map.values.toList();
  }

  List<FaceLibItem> _filterItems(List<FaceLibItem> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.zone.toLowerCase().contains(q) ||
          item.reps.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.howTo.toLowerCase().contains(q) ||
          item.benefit.toLowerCase().contains(q);
    }).toList();
  }

  String _howTo(FaceExercise ex) {
    switch (ex.name.toUpperCase()) {
      case 'MEWING':
        return 'Press the full tongue to the roof of your mouth, keep the lips closed, and breathe through the nose.';
      case 'JAW CLENCH':
        return 'Clench the back teeth briefly, then relax. Keep the motion short and avoid pain.';
      case 'CHIN TUCK':
        return 'Pull the chin straight back, hold for a moment, and keep the neck tall.';
      case 'CHEEK SCULPTOR':
        return 'Pull the cheeks inward under control, hold, then release slowly.';
      case 'NECK RESISTANCE':
        return 'Push the head gently against your hand in all directions without forcing the motion.';
      case 'EYE SQUINT':
        return 'Narrow the eyes with light tension, hold, then fully relax the face.';
      case 'LIP PRESS':
        return 'Press the lips together firmly, hold, and keep the jaw unclenched.';
      case 'BROW LIFT':
        return 'Lift the brows against light resistance, then lower them slowly.';
      default:
        return 'Use controlled tension, keep the movement clean, and stop if it feels wrong.';
    }
  }

  String _benefit(FaceExercise ex) {
    switch (ex.name.toUpperCase()) {
      case 'MEWING':
        return 'Improves tongue posture and facial awareness.';
      case 'JAW CLENCH':
        return 'Builds masseter engagement and jaw tension control.';
      case 'CHIN TUCK':
        return 'Supports a cleaner neck line and better posture.';
      case 'CHEEK SCULPTOR':
        return 'Helps the mid-face feel more controlled and lifted.';
      case 'NECK RESISTANCE':
        return 'Strengthens the neck frame and head posture.';
      case 'EYE SQUINT':
        return 'Trains focused eye-area control without overdoing it.';
      case 'LIP PRESS':
        return 'Improves lip control and facial tension awareness.';
      case 'BROW LIFT':
        return 'Builds upper-face muscle control and brow awareness.';
      default:
        return 'Useful for controlled facial posture work.';
    }
  }

}

class FaceLibItem {
  final String name;
  final String zone;
  final String reps;
  final String subtitle;
  final String howTo;
  final String benefit;

  const FaceLibItem(this.name, this.zone, this.reps, this.subtitle, this.howTo, this.benefit);
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
