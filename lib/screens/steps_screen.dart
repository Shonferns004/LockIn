import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/animations.dart';

class StepsScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const StepsScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(label: 'STEPS'),
              const SizedBox(height: 24),
              if (app.stepStatusMessage.isNotEmpty) ...[
                _SensorNotice(
                  message: app.stepStatusMessage,
                  supported: app.stepSensorSupported,
                ),
                const SizedBox(height: 16),
              ],
              _StepCounterCard(app: app),
              const SizedBox(height: 32),
              Text('WATER INTAKE', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2)),
              const SizedBox(height: 16),
              _WaterCard(app: app),
              const SizedBox(height: 32),
              _SettingsCard(app: app),
              const SizedBox(height: 32),
              _StepHistoryCard(app: app),
            ],
          ),
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
          height: 8, width: 96,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            border: Border.all(color: AppTheme.border, width: 2),
          ),
        ),
      ],
    );
  }
}

class _StepCounterCard extends StatelessWidget {
  final AppProvider app;
  const _StepCounterCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DAILY STEPS', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
              GestureDetector(
                onTap: () => app.toggleStepCounter(!app.stepEnabled),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: app.stepEnabled ? AppTheme.primaryContainer : AppTheme.surfaceContainer,
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: Text(
                    app.stepEnabled ? 'ON' : 'OFF',
                    style: AppTheme.textTheme.labelMedium?.copyWith(
                      color: app.stepEnabled ? AppTheme.onPrimaryContainer : AppTheme.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${app.dailySteps}',
              style: AppTheme.textTheme.displayLarge?.copyWith(fontSize: 56, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'goal: ${app.stepGoal}',
              style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: app.stepGoal > 0 ? (app.dailySteps / app.stepGoal).clamp(0, 1) : 0,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'DISTANCE', value: app.distanceStr.isEmpty ? '0 m' : app.distanceStr)),
              Container(width: 1, height: 30, color: AppTheme.border),
              Expanded(child: _MiniStat(label: 'CALORIES', value: app.caloriesStr.isEmpty ? '0 kcal' : app.caloriesStr)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorNotice extends StatelessWidget {
  final String message;
  final bool supported;

  const _SensorNotice({required this.message, required this.supported});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: supported ? AppTheme.secondaryFixed : AppTheme.errorContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            supported ? Icons.verified_outlined : Icons.warning_amber_rounded,
            color: supported ? AppTheme.onSecondaryFixed : AppTheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: supported ? AppTheme.onSecondaryFixed : AppTheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.textTheme.headlineMedium?.copyWith(color: AppTheme.secondary)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
      ],
    );
  }
}

class _WaterCard extends StatelessWidget {
  final AppProvider app;
  const _WaterCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final pct = app.waterProgressPercent;
    return NeoCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TODAY', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
              Text('${app.dailyWater} / ${app.waterGoal} ml', style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppTheme.tertiary),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text('$pct% of daily goal', style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _WaterBtn(ml: 200, icon: Icons.water_drop, label: '200ml')),
              SizedBox(width: 8),
              Expanded(child: _WaterBtn(ml: 350, icon: Icons.local_drink, label: '350ml')),
              SizedBox(width: 8),
              Expanded(child: _WaterBtn(ml: 500, icon: Icons.water, label: '500ml')),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final int ml;
  final IconData icon;
  final String label;
  const _WaterBtn({required this.ml, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AppProvider>().addWater(ml),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.tertiaryContainer.withValues(alpha: 0.3),
          border: Border.all(color: AppTheme.border, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.tertiary),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.textTheme.labelSmall?.copyWith(color: AppTheme.onBackground)),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final AppProvider app;
  const _SettingsCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SETTINGS', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 16),
          _SettingRow(
            label: 'Step goal',
            value: '${app.stepGoal}',
            onTap: () => _editNumber(context, 'Step Goal', app.stepGoal, (v) => app.setStepGoal(v)),
          ),
          const Divider(height: 24, color: AppTheme.border),
          _SettingRow(
            label: 'Stride length',
            value: '${app.strideLength} cm',
            onTap: () => _editNumber(context, 'Stride Length (cm)', app.strideLength, (v) => app.setStrideLength(v)),
          ),
          const Divider(height: 24, color: AppTheme.border),
          _SettingRow(
            label: 'Water goal',
            value: '${app.waterGoal} ml',
            onTap: () => _editNumber(context, 'Water Goal (ml)', app.waterGoal, (v) => app.setWaterGoal(v)),
          ),
          const Divider(height: 24, color: AppTheme.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Water reminders', style: AppTheme.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Push notifications will remind you to drink water every 2 hours.',
                      style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  border: Border.all(color: AppTheme.border, width: 2),
                ),
                child: Text(
                  'AUTO',
                  style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editNumber(BuildContext context, String title, int current, ValueChanged<int> onSave) {
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBright,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.border, width: 4),
        ),
        title: Text(title, style: AppTheme.textTheme.labelLarge),
        content: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border, width: 3),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: AppTheme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          NeoButton(
            label: 'SAVE',
            bg: AppTheme.primary,
            textColor: Colors.white,
            onTap: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) onSave(v);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

class _StepHistoryCard extends StatelessWidget {
  final AppProvider app;
  const _StepHistoryCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final history = app.stepHistory;

    final sorted = history.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final recent = sorted.take(14).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STEP HISTORY',
            style: AppTheme.textTheme.labelLarge
                ?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 2)),
        const SizedBox(height: 16),
        NeoCard(
          bg: Colors.white,
          child: history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Step data will appear here after your first day of walking with the tracker ON.',
                      textAlign: TextAlign.center,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Column(
            children: recent.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final date = e.key;
              final steps = e.value;
              final goal = app.stepGoal;
              final pct = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
              final isToday = date == _dateKey(DateTime.now());
              return StaggeredFadeSlide(
                index: i,
                delayPerItem: const Duration(milliseconds: 50),
                child: Column(
                  children: [
                    if (i != 0)
                      const Divider(height: 16, color: AppTheme.border),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            _formatDate(date),
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                              color: isToday ? AppTheme.primary : AppTheme.onBackground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: AppTheme.surfaceContainer,
                              valueColor: AlwaysStoppedAnimation(
                                pct >= 1 ? AppTheme.tertiary : AppTheme.primary,
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '$steps',
                            textAlign: TextAlign.right,
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(parsed).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${parsed.month}/${parsed.day}';
  }

  String _dateKey(DateTime date) {
    final d = date.toLocal();
    return DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _SettingRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.textTheme.bodyLarge),
          Row(
            children: [
              Text(value, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
