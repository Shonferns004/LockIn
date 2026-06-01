import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const ProfileScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(pad, 32, pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 32),
                  _AccountCard(app: app),
                  const SizedBox(height: 24),
                  _SoundCard(app: app),
                  const SizedBox(height: 24),
                  _TrainingCalendarCard(app: app),
                  const SizedBox(height: 24),
                  _ProgressCard(app: app),
                  const SizedBox(height: 24),
                  _DangerZone(app: app),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROFILE',
            style: AppTheme.textTheme.displayMedium
                ?.copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Container(
            height: 8,
            width: 96,
            decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                border: Border.all(color: AppTheme.border, width: 2))),
      ],
    );
  }
}

class _SectionBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const _SectionBadge(
      {required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, border: Border.all(color: AppTheme.border, width: 2)),
      child: Text(label,
          style: AppTheme.textTheme.labelLarge?.copyWith(color: textColor)),
    );
  }
}

class _ExperienceBadge extends StatelessWidget {
  final String experience;
  const _ExperienceBadge({required this.experience});

  @override
  Widget build(BuildContext context) {
    final normalized = experience.toLowerCase();
    final bg = switch (normalized) {
      'advanced' => AppTheme.secondaryFixedDim,
      'intermediate' => AppTheme.tertiaryContainer,
      _ => AppTheme.primaryContainer,
    };
    final textColor = switch (normalized) {
      'advanced' => AppTheme.onSecondaryFixed,
      'intermediate' => AppTheme.onTertiaryContainer,
      _ => AppTheme.onPrimaryContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppTheme.border, width: 2),
        boxShadow: neoShadowSm(),
      ),
      child: Text(
        experience.toUpperCase(),
        style: AppTheme.textTheme.labelSmall?.copyWith(
          color: textColor,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AppProvider app;
  const _AccountCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.profile;
    final authEmail = AuthService().loggedInEmail ?? '';
    final displayEmail = (p?.email.isNotEmpty ?? false) ? p!.email : authEmail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge(
            label: 'ACCOUNT',
            bg: AppTheme.secondaryContainer,
            textColor: AppTheme.onSecondaryContainer),
        NeoCard(
          bg: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: AppTheme.tertiaryFixed,
                          border: Border.all(color: AppTheme.border, width: 4)),
                      child: const Icon(Icons.person, size: 38)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p?.username ?? 'LockIn',
                                style: AppTheme.textTheme.headlineMedium,
                              ),
                            ),
                            if ((p?.experience.isNotEmpty ?? false))
                              _ExperienceBadge(experience: app.experience),
                          ],
                        ),
                        Text(displayEmail,
                            style: AppTheme.textTheme.labelMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EditableField(
                label: 'USERNAME',
                initialValue: p?.username ?? 'LockIn',
                onSave: app.saveUsername,
              ),
              const SizedBox(height: 12),
              _EditableField(
                label: 'EMAIL',
                initialValue: displayEmail,
                onSave: app.saveEmail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoundCard extends StatelessWidget {
  final AppProvider app;
  const _SoundCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge(
          label: 'SOUND',
          bg: AppTheme.primaryContainer,
          textColor: AppTheme.onPrimaryContainer,
        ),
        NeoCard(
          bg: Colors.white,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  border: Border.all(color: AppTheme.border, width: 3),
                ),
                child: Icon(
                  app.soundMuted ? Icons.volume_off : Icons.volume_up,
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workout sound',
                        style: AppTheme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      app.soundMuted
                          ? 'Muted during workouts'
                          : 'Whistle, clock, and voice are enabled',
                      style: AppTheme.textTheme.labelMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: app.soundMuted,
                onChanged: (val) => app.setSoundMuted(val),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onSave;

  const _EditableField({
    required this.label,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _ctrl.text != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    widget.onSave(value);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppTheme.textTheme.labelMedium
                ?.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border, width: 4),
            boxShadow: neoShadowSm(),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: AppTheme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.onBackground),
                  cursorColor: AppTheme.primary,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
              GestureDetector(
                onTap: _save,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    border: Border(
                        left: BorderSide(color: AppTheme.border, width: 4)),
                  ),
                  child: const Icon(Icons.check, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainingCalendarCard extends StatefulWidget {
  final AppProvider app;
  const _TrainingCalendarCard({required this.app});

  @override
  State<_TrainingCalendarCard> createState() => _TrainingCalendarCardState();
}

class _TrainingCalendarCardState extends State<_TrainingCalendarCard> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final now = DateTime.now().toLocal();
    final baseMonth = DateTime(now.year, now.month + _monthOffset, 1);
    final monthStart = DateTime(baseMonth.year, baseMonth.month, 1);
    final monthEnd = DateTime(baseMonth.year, baseMonth.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final firstWeekday = monthStart.weekday;
    final completedDays = _completedDatesForMonth(
        app.completedDates, baseMonth.year, baseMonth.month);
    final skippedDays = _completedDatesForMonth(
        app.skippedDates, baseMonth.year, baseMonth.month);
    final trainingsThisMonth = completedDays.length;
    final monthName = DateFormat('MMMM yyyy').format(monthStart);
    final weeks = ((firstWeekday - 1) + daysInMonth + 6) ~/ 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge(
            label: 'TRAINING CALENDAR',
            bg: AppTheme.primaryContainer,
            textColor: AppTheme.onPrimaryContainer),
        NeoCard(
          bg: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _monthOffset--),
                    child: const Icon(Icons.chevron_left,
                        color: AppTheme.onBackground),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(monthName,
                            style: AppTheme.textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        Text(
                          '$trainingsThisMonth training day${trainingsThisMonth == 1 ? '' : 's'} recorded',
                          style: AppTheme.textTheme.labelMedium
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _monthOffset == 0
                        ? null
                        : () => setState(() => _monthOffset++),
                    child: Icon(
                      Icons.chevron_right,
                      color: _monthOffset == 0
                          ? AppTheme.outline
                          : AppTheme.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTheme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              for (int week = 0; week < weeks; week++) ...[
                Row(
                  children: List.generate(7, (dayIndex) {
                    final cellIndex = week * 7 + dayIndex;
                    final dayNumber = cellIndex - (firstWeekday - 1) + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 44));
                    }
                    final date =
                        DateTime(baseMonth.year, baseMonth.month, dayNumber);
                    final isTrainingDay =
                        completedDays.contains(_dateKey(date));
                    final isSkippedDay = skippedDays.contains(_dateKey(date));
                    final isToday = DateUtils.isSameDay(date, now);
                    final isFuture =
                        date.isAfter(DateTime(now.year, now.month, now.day));

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isTrainingDay
                                ? AppTheme.primaryContainer
                                    .withValues(alpha: 0.24)
                                : isSkippedDay
                                    ? AppTheme.errorContainer
                                        .withValues(alpha: 0.18)
                                    : isToday
                                        ? AppTheme.secondaryContainer
                                            .withValues(alpha: 0.18)
                                        : AppTheme.surfaceContainerLow,
                            border: Border.all(
                              color: isToday
                                  ? AppTheme.secondary
                                  : isSkippedDay
                                      ? AppTheme.error
                                      : isTrainingDay
                                          ? AppTheme.primary
                                          : AppTheme.border,
                              width: isToday || isTrainingDay || isSkippedDay
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '$dayNumber',
                                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                                    color: isFuture
                                        ? AppTheme.outline
                                        : isSkippedDay
                                            ? AppTheme.error
                                            : AppTheme.onBackground,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isTrainingDay)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (isSkippedDay)
                                const Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 10,
                                    color: AppTheme.error,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _legendDot(AppTheme.primary, 'Trained'),
                  _legendDot(AppTheme.secondary, 'Today'),
                  _legendDot(AppTheme.error, 'Skipped'),
                  _legendDot(AppTheme.border, 'No session'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Training days in this month are marked with a solid dot. Use the arrows to review past months and see exactly when you trained.',
                style: AppTheme.textTheme.labelMedium
                    ?.copyWith(color: AppTheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),
              _TrainingList(completedDays: completedDays),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.textTheme.labelMedium),
      ],
    );
  }

  Set<String> _completedDatesForMonth(
      List<String> allDates, int year, int month) {
    return allDates.where((d) {
      final parsed = DateTime.tryParse(d);
      return parsed != null && parsed.year == year && parsed.month == month;
    }).toSet();
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}

class _TrainingList extends StatelessWidget {
  final Set<String> completedDays;

  const _TrainingList({required this.completedDays});

  @override
  Widget build(BuildContext context) {
    final sorted = completedDays.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT TRAINING DAYS',
            style: AppTheme.textTheme.labelLarge?.copyWith(letterSpacing: 1)),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text(
            'No training sessions recorded for this month yet.',
            style: AppTheme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted
                .map(
                  (date) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      border: Border.all(color: AppTheme.border, width: 2),
                    ),
                    child: Text(
                      DateFormat('EEE, d MMM').format(DateTime.parse(date)),
                      style: AppTheme.textTheme.labelMedium,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final AppProvider app;
  const _ProgressCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge(
            label: 'PROGRESS',
            bg: AppTheme.primaryContainer,
            textColor: AppTheme.onPrimaryContainer),
        NeoCard(
          bg: Colors.white,
          child: Column(
            children: [
              _row('Workouts done', '${p.workouts}'),
              const Divider(height: 24),
              _row('Streak', '${p.streak} days'),
              const Divider(height: 24),
              _row('Push-up max', '${p.pushup}'),
              const Divider(height: 24),
              _row('Squat max', '${p.squat}'),
              const Divider(height: 24),
              _row('Plank max', '${p.plank}s'),
              const Divider(height: 24),
              _row('Burpee max', '${p.burpee}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.textTheme.bodyLarge),
        Text(value, style: AppTheme.textTheme.labelLarge),
      ],
    );
  }
}

class _DangerZone extends StatelessWidget {
  final AppProvider app;
  const _DangerZone({required this.app});

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.errorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.border, width: 4),
        ),
        title: const Text('Erase All Training Data?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will delete all your data permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          NeoButton(
            label: 'DELETE',
            bg: AppTheme.error,
            textColor: Colors.white,
            onTap: () async {
              Navigator.pop(ctx);
              await app.resetProfile();
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('login');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge(
            label: 'DANGER ZONE',
            bg: AppTheme.errorContainer,
            textColor: AppTheme.onErrorContainer),
        NeoCard(
          bg: AppTheme.errorContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Erase All Training Data?',
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onErrorContainer)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'Log Out',
                  bg: AppTheme.secondary,
                  textColor: Colors.white,
                  onTap: () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('login');
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'Delete Account',
                  bg: AppTheme.error,
                  textColor: Colors.white,
                  onTap: () => _confirmReset(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
