import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minVisible = Duration(milliseconds: 200);
  late final AnimationController _pulseController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _routing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _route();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _route() async {
    if (_routing) return;
    _routing = true;

    try {
      final startedAt = DateTime.now();
      final auth = AuthService();
      await auth.init();
      if (!mounted) return;

      String route = 'login';
      if (auth.isLoggedIn) {
        final userUuid = auth.userUuid;
        if (userUuid != null && userUuid.isNotEmpty) {
          final app = context.read<AppProvider>();
          await app.bindUser(userUuid);
        }
        if (!mounted) return;

        final app = context.read<AppProvider>();
        final profile = app.profile;
        route = profile == null
            ? 'onboarding'
            : (profile.onboardingCompleted ? 'home' : 'onboarding');
      }

      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < _minVisible) {
        await Future.delayed(_minVisible - elapsed);
      }
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(route);
      });
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 26),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border.all(color: AppTheme.border, width: 4),
                      boxShadow: neoShadow(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LI',
                          style: AppTheme.textTheme.displayMedium?.copyWith(
                            fontSize: 34,
                            letterSpacing: -1.2,
                            color: AppTheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 56,
                          height: 4,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
