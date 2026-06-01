import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/stats_bar.dart';
import '../widgets/schedule_grid.dart';
import '../widgets/daily_plan_view.dart';
import '../widgets/exercise_library.dart';
import '../widgets/skeletons.dart';

class WorkoutScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const WorkoutScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
            return SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Column(
                  key: ValueKey(
                      '${app.loading}_${app.loadingKey}_${app.weeks.length}_${app.currentWeekView}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatsBar(),
                    if (app.isHydrating ||
                        (app.loading && app.loadingKey == 'week'))
                      const WorkoutSkeleton(),
                    if (!app.isHydrating &&
                        app.weeks.isEmpty &&
                        !(app.loading && app.loadingKey == 'week'))
                      _EmptyState(app: app),
                    if (!app.isHydrating && app.weeks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _WeekNav(app: app),
                      const SizedBox(height: 12),
                      const ScheduleGrid(),
                      const SizedBox(height: 24),
                      const DailyPlanView(),
                      const SizedBox(height: 24),
                      const ExerciseLibrary(),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppProvider app;
  const _EmptyState({required this.app});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.fitness_center,
              size: 48, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('NO PLAN YET',
              style: AppTheme.textTheme.headlineMedium
                  ?.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Tap GENERATE WEEK 1 below to create your first AI-powered week',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (!app.hasGroqKey)
            Text(
              'Set your Groq API key in Settings first',
              style: AppTheme.textTheme.labelMedium
                  ?.copyWith(color: AppTheme.outline),
            )
          else
            NeoButton(
              label: 'GENERATE WEEK 1',
              leading:
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              bg: AppTheme.primary,
              textColor: Colors.white,
              onTap: () => app.generateWeek(1),
            ),
        ],
      ),
    );
  }
}

class _WeekNav extends StatelessWidget {
  final AppProvider app;
  const _WeekNav({required this.app});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WEEK ${app.currentWeekView + 1} SCHEDULE',
              style: AppTheme.textTheme.labelLarge?.copyWith(
                  fontSize: isNarrow ? 11 : null,
                  color: AppTheme.primary,
                  letterSpacing: 2),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: app.currentWeekView > 0 ? app.prevWeek : null,
                  child: Icon(Icons.chevron_left,
                      color: app.currentWeekView > 0
                          ? AppTheme.onBackground
                          : AppTheme.outline,
                      size: 24),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'WEEK ${app.currentWeekView + 1}',
                      style: AppTheme.textTheme.bodyLarge
                          ?.copyWith(fontSize: isNarrow ? 12 : null),
                    ),
                    Text(
                      app.weekDateRangeLabel(app.currentWeekView),
                      style: AppTheme.textTheme.labelSmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: app.weeks.isNotEmpty &&
                          app.currentWeekView <
                              (app.weeks
                                      .map((w) => w.week)
                                      .reduce((a, b) => a > b ? a : b) -
                                  1)
                      ? app.nextWeek
                      : null,
                  child: Icon(Icons.chevron_right,
                      color: app.currentWeekView <
                              (app.weeks
                                      .map((w) => w.week)
                                      .reduce((a, b) => a > b ? a : b) -
                                  1)
                          ? AppTheme.onBackground
                          : AppTheme.outline,
                      size: 24),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
