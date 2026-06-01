import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final p = app.progress;
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 32, pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(label: 'PROGRESS'),
                  const SizedBox(height: 32),
                  _AllTimeStats(p: p, app: app),
                  const SizedBox(height: 40),
                  _ExerciseRecords(p: p),
                  const SizedBox(height: 40),
                  _WeeklyBreakdown(app: app),
                  const SizedBox(height: 40),
                  _MotivationBanner(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  const _Header({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.displayMedium?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: 96,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            border: Border.all(color: AppTheme.border, width: 2),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2),
      ),
    );
  }
}

class _AllTimeStats extends StatelessWidget {
  final dynamic p;
  final AppProvider app;
  const _AllTimeStats({required this.p, required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'All-Time Stats'),
        _StatItem(
          icon: Icons.fitness_center,
          iconBg: AppTheme.primaryContainer,
          label: '🔥 WORKOUTS DONE',
          value: '${p.workouts}',
          valueColor: AppTheme.tertiary,
        ),
        const SizedBox(height: 12),
        _StatItem(
          icon: Icons.local_fire_department,
          iconBg: AppTheme.secondaryFixedDim,
          label: '📅 DAY STREAK',
          value: '${p.streak} days',
          valueColor: AppTheme.secondary,
        ),
        const SizedBox(height: 12),
        _StatItem(
          icon: Icons.calendar_month,
          iconBg: AppTheme.tertiaryContainer,
          label: '📊 TOTAL DAYS',
          value: '${app.totalDays}',
          valueColor: AppTheme.onBackground,
          borderColor: AppTheme.primary,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;
  final Color? borderColor;

  const _StatItem({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: AppTheme.surfaceBright,
      borderColor: borderColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: Icon(icon, size: 22, color: AppTheme.onBackground),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
          ),
          Text(
            value,
            style: AppTheme.textTheme.headlineMedium?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRecords extends StatelessWidget {
  final dynamic p;
  const _ExerciseRecords({required this.p});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Exercise Records'),
        _ExRecord(icon: Icons.fitness_center, iconColor: AppTheme.primary, label: '👊 PUSH-UPS (MAX)', value: '${p.pushup}'),
        const SizedBox(height: 12),
        _ExRecord(icon: Icons.fitness_center, iconColor: AppTheme.primary, label: '🦵 SQUATS (MAX)', value: '${p.squat}'),
        const SizedBox(height: 12),
        _ExRecord(icon: Icons.timer, iconColor: AppTheme.tertiary, label: '🧘 PLANK (MAX)', value: '${p.plank}s', fill: true),
        const SizedBox(height: 12),
        _ExRecord(icon: Icons.fitness_center, iconColor: AppTheme.primary, label: '⚡ BURPEES (MAX)', value: '${p.burpee}'),
      ],
    );
  }
}

class _ExRecord extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool fill;

  const _ExRecord({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(bg: Colors.white, child: Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant))),
        Text(value, style: AppTheme.textTheme.headlineMedium),
      ],
    ));
  }
}

class _WeeklyBreakdown extends StatelessWidget {
  final AppProvider app;
  const _WeeklyBreakdown({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Weekly Breakdown'),
        if (app.weeks.isNotEmpty)
          ...app.weeks.map((w) {
            final done = w.days.where((d) => app.isCompleted(d.day - 1)).length;
            final total = w.workoutDayCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WeekCard(week: w.week, done: done, total: total),
            );
          })
        else
          _EmptyWeek(),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  final int week;
  final int done;
  final int total;
  const _WeekCard({required this.week, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.onBackground,
        border: Border.all(color: AppTheme.border, width: 4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: neoShadow(),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -16,
            top: -16,
            child: Opacity(
              opacity: 0.2,
              child: Icon(Icons.trending_up, size: 120, color: AppTheme.primaryFixed),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WEEK $week',
                    style: AppTheme.textTheme.headlineMedium?.copyWith(color: AppTheme.primaryFixed, fontStyle: FontStyle.italic),
                  ),
                  Text(
                    '$done/$total days done',
                    style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.surfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 4),
                  color: AppTheme.surfaceBright,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: total > 0 ? done / total : 0,
                  child: Container(color: AppTheme.primaryFixedDim),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                done == 0
                    ? "You're just starting your journey. Keep the momentum going!"
                    : 'Keep crushing it! $done workouts completed this week.',
                style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.surfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: AppTheme.onBackground,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEK 1',
            style: AppTheme.textTheme.headlineMedium?.copyWith(color: AppTheme.primaryFixed, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Container(
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border, width: 4),
              color: AppTheme.surfaceBright,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You're just starting your journey. Keep the momentum going!",
            style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.surfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: AppTheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DON'T STOP UNTIL YOU'RE PROUD.",
            style: AppTheme.textTheme.headlineMedium?.copyWith(height: 1.1),
          ),
          const SizedBox(height: 16),
          NeoButton(
            label: 'START WORKOUT',
            bg: AppTheme.onBackground,
            textColor: Colors.white,
            onTap: () => context.read<AppProvider>().selectTab(0),
          ),
        ],
      ),
    );
  }
}
