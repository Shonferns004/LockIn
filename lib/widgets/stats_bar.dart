import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/animations.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return NeoCard(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;
              final stats = [
                _countUpStat(app.weeks.length, 'WEEKS', !isCompact, ''),
                _countUpStat(app.progress.streak, 'STREAK', !isCompact, ''),
                _countUpStat(app.profile?.timePerSession ?? 20, 'SESSION', !isCompact, 'MIN'),
                _countUpStat(0, 'GEAR', !isCompact, ''),
              ];

              if (isCompact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: stats[0]),
                        Expanded(child: stats[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: stats[2]),
                        Expanded(child: stats[3]),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: stats[0]),
                  Container(width: 1, height: 30, color: AppTheme.border),
                  Expanded(child: stats[1]),
                  Container(width: 1, height: 30, color: AppTheme.border),
                  Expanded(child: stats[2]),
                  Container(width: 1, height: 30, color: AppTheme.border),
                  Expanded(child: stats[3]),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _countUpStat(int val, String label, bool isWide, String suffix) {
    return Column(
      children: [
        CountUp(
          target: val,
          duration: const Duration(milliseconds: 600),
          builder: (v) => Text(
            '$v$suffix',
            style: AppTheme.textTheme.headlineMedium?.copyWith(
              fontSize: isWide ? null : 14,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.textTheme.labelMedium?.copyWith(
          fontSize: isWide ? null : 9,
          color: AppTheme.onSurfaceVariant,
          letterSpacing: 2,
        )),
      ],
    );
  }
}
