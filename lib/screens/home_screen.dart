import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'workout_screen.dart';
import 'lookmax_screen.dart';
import 'coach_screen.dart';
import 'profile_screen.dart';
import 'steps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _workoutCtrl;
  late final ScrollController _lookmaxCtrl;
  late final ScrollController _stepsCtrl;
  late final ScrollController _coachCtrl;
  late final ScrollController _profileCtrl;

  @override
  void initState() {
    super.initState();
    _workoutCtrl = ScrollController();
    _lookmaxCtrl = ScrollController();
    _stepsCtrl = ScrollController();
    _coachCtrl = ScrollController();
    _profileCtrl = ScrollController();
  }

  @override
  void dispose() {
    _workoutCtrl.dispose();
    _lookmaxCtrl.dispose();
    _stepsCtrl.dispose();
    _coachCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  ScrollController _controllerFor(int idx) {
    switch (idx) {
      case 0:
        return _workoutCtrl;
      case 1:
        return _lookmaxCtrl;
      case 2:
        return _stepsCtrl;
      case 3:
        return _coachCtrl;
      default:
        return _profileCtrl;
    }
  }

  void _selectTab(BuildContext context, int idx) {
    context.read<AppProvider>().selectTab(idx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controllerFor(idx);
      if (controller.hasClients) {
        controller.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, int>(
      selector: (_, app) => app.currentTab,
      builder: (context, currentTab, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _AppHeader(
                  currentDateLabel: DateTime.now().toLocal(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(currentTab),
                      child: [
                        WorkoutScreen(scrollController: _workoutCtrl),
                        LookmaxScreen(scrollController: _lookmaxCtrl),
                        StepsScreen(scrollController: _stepsCtrl),
                        CoachScreen(scrollController: _coachCtrl),
                        ProfileScreen(scrollController: _profileCtrl),
                      ][currentTab],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _NeoNavBar(
            currentTab: currentTab,
            onTap: (idx) => _selectTab(context, idx),
          ),
        );
      },
    );
  }
}

class _AppHeader extends StatelessWidget {
  final DateTime currentDateLabel;

  const _AppHeader({required this.currentDateLabel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            border: const Border(
                bottom: BorderSide(color: AppTheme.border, width: 4)),
            boxShadow: neoShadow(),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 24, vertical: isNarrow ? 10 : 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LockIn',
                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                          fontSize: isNarrow ? 18 : null, letterSpacing: -0.5),
                    ),
                    Text(
                      '${DateFormat('EEE, d MMM').format(currentDateLabel)} | ${DateFormat('h:mm a').format(currentDateLabel)}',
                      style: AppTheme.textTheme.labelSmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: isNarrow ? 32 : 40,
                  height: isNarrow ? 32 : 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border, width: 4),
                    color: AppTheme.secondaryFixedDim,
                    boxShadow: neoShadow(),
                  ),
                  child: Icon(Icons.person,
                      size: isNarrow ? 16 : 20, color: AppTheme.onBackground),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NeoNavBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;

  const _NeoNavBar({required this.currentTab, required this.onTap});

  static const _tabs = [
    ('Workout', Icons.sports_gymnastics),
    ('Lookmax', Icons.auto_awesome),
    ('Steps', Icons.speed),
    ('Coach', Icons.support_agent),
    ('Profile', Icons.account_circle),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.border, width: 4)),
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isActive = i == currentTab;
            final label = _tabs[i].$1;
            final icon = _tabs[i].$2;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => onTap(i),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  decoration: isActive
                      ? BoxDecoration(
                          color: AppTheme.primary,
                          border: Border.all(color: AppTheme.border, width: 2),
                        )
                      : null,
                  transform: isActive
                      ? Matrix4.translationValues(-2, -2, 0)
                      : Matrix4.identity(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          size: 22,
                          color: isActive
                              ? AppTheme.onPrimary
                              : AppTheme.onBackground),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: AppTheme.textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? AppTheme.onPrimary
                              : AppTheme.onBackground,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
