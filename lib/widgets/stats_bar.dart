import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

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
                _statItem(app.weeks.length.toString(), 'WEEKS', !isCompact),
                _statItem(app.progress.streak.toString(), 'STREAK', !isCompact),
                _statItem('${app.profile?.timePerSession ?? 20}MIN', 'SESSION', !isCompact),
                _statItem('0', 'GEAR', !isCompact),
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

  Widget _statItem(String val, String label, bool isWide) {
    return Column(
      children: [
        Text(val, style: AppTheme.textTheme.headlineMedium?.copyWith(fontSize: isWide ? null : 14, color: AppTheme.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.textTheme.labelMedium?.copyWith(fontSize: isWide ? null : 9, color: AppTheme.onSurfaceVariant, letterSpacing: 2)),
      ],
    );
  }
}
