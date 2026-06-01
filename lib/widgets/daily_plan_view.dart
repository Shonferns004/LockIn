import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/session_player.dart';

class DailyPlanView extends StatelessWidget {
  const DailyPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final day = app.selectedDayPlan;
        if (day == null) {
          return NeoCard(
            child: Text(
              'Select a day from the schedule above',
              style: AppTheme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.onSurfaceVariant),
            ),
          );
        }

        final completed = app.isCompleted(day.day - 1);
        final today = DateTime.now().toLocal();
        final scheduledDate = DateTime.tryParse(day.scheduledDate)?.toLocal();
        final isTodayOrPast = scheduledDate != null &&
            !DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day).isAfter(DateTime(today.year, today.month, today.day));
        final canStart = isTodayOrPast && !day.isRest && !completed;

        if (completed) {
          return NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 DAY ${day.day} — ${day.title}',
                  style: AppTheme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Week ${day.week} · ${day.focus}',
                  style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: Text(
                    'NO WORKOUTS FOR TODAY',
                    textAlign: TextAlign.center,
                    style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          );
        }

        return NeoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 DAY ${day.day} — ${day.title}',
                style: AppTheme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Week ${day.week} · ${day.focus}',
                style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (day.isRest)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: Text(
                    '🛌 REST DAY — RECOVER & COME BACK STRONGER',
                    textAlign: TextAlign.center,
                    style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              if (day.exercises.isNotEmpty) ...[
                _buildExerciseGrid(day.exercises),
                const SizedBox(height: 16),
                if (day.faceExercises.isNotEmpty) ...[
                  Text('🎭 FACIAL EXERCISES', style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.primary, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  _buildFaceGrid(day.faceExercises),
                ],
                if (day.lookmax.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('✨ LOOKMAX DAILY TIPS', style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.secondary, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  ...day.lookmax.map((tip) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2), width: 2),
                        ),
                        child: Text(tip, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                      )),
                ],
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      label: canStart ? 'START SESSION' : 'UNAVAILABLE TODAY',
                      leading: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                      bg: canStart ? AppTheme.primary : AppTheme.surfaceContainer,
                      textColor: canStart ? Colors.white : AppTheme.outline,
                      onTap: canStart ? () => _startSession(context) : null,
                    ),
                  ),
                ],
              ),
              if (!canStart && !day.isRest && !completed) ...[
                const SizedBox(height: 8),
                Text(
                  scheduledDate == null
                      ? 'This session date is missing from the database.'
                      : 'This session opens on ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}.',
                  style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _startSession(BuildContext context) {
    context.read<AppProvider>().startSession();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SessionPlayer(),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildExerciseGrid(List exercises) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 320;
        final veryNarrow = constraints.maxWidth < 260;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: veryNarrow ? 2.6 : (narrow ? 2.2 : 2.0),
            crossAxisSpacing: veryNarrow ? 6 : 8,
            mainAxisSpacing: veryNarrow ? 6 : 8,
          ),
          itemCount: exercises.length,
          itemBuilder: (context, i) {
            final ex = exercises[i];
            return Container(
              padding: EdgeInsets.all(veryNarrow ? 6 : (narrow ? 8 : 12)),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBright,
                border: Border.all(color: AppTheme.border, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ex.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (veryNarrow ? AppTheme.textTheme.labelSmall : (narrow ? AppTheme.textTheme.labelMedium : AppTheme.textTheme.bodyMedium))
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (!veryNarrow && !narrow)
                    Text(
                      ex.target,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: veryNarrow ? 4 : 8, vertical: veryNarrow ? 1 : 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.3),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(
                      '${ex.sets}×${ex.reps}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontSize: veryNarrow ? 8 : 9,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFaceGrid(List exercises) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 320;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: narrow ? 2.3 : 2.6,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: exercises.length,
          itemBuilder: (context, i) {
            final ex = exercises[i];
            return Container(
              padding: EdgeInsets.all(narrow ? 6 : 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBright,
                border: Border.all(color: AppTheme.border, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ex.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (narrow ? AppTheme.textTheme.labelSmall : AppTheme.textTheme.labelMedium)?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (!narrow) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${ex.target} · ${ex.sets}×${ex.reps}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
