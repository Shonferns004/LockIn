import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../widgets/skeletons.dart';
import '../theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_loading) return;
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final auth = AuthService();
    await auth.init();
    try {
      final ok = await auth.signup(email, password);
      if (!mounted) return;
      if (ok) {
        await _routeAfterAuth(auth.userUuid);
      } else {
        setState(() => _error = auth.lastError ?? 'Could not create account. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _routeAfterAuth(String? userId) async {
    if (userId == null || userId.isEmpty) {
      Navigator.of(context).pushReplacementNamed('login');
      return;
    }

    final app = context.read<AppProvider>();
    await app.bindUser(userId);
    if (!mounted) return;

    final profile = app.profile;
    final route =
        profile == null || !profile.onboardingCompleted ? 'onboarding' : 'home';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 720;
            final contentWidth = wide ? 560.0 : double.infinity;
            final horizontalPad = wide ? 48.0 : 20.0;
            return Stack(
              children: [
                Positioned(
                  top: -36,
                  left: -28,
                  child: _AccentBlob(
                    color: AppTheme.secondaryFixedDim.withValues(alpha: 0.22),
                    size: wide ? 180 : 140,
                  ),
                ),
                Positioned(
                  bottom: 46,
                  right: -36,
                  child: _AccentBlob(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.26),
                    size: wide ? 170 : 120,
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPad, 24, horizontalPad, 24 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.vertical -
                          48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroCard(
                              title: 'START STRONG',
                              subtitle:
                                  'Create your account and keep your plan, progress, and calendar saved across devices.',
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _MiniChip(label: 'Track sessions'),
                                _MiniChip(label: 'AI workouts'),
                                _MiniChip(label: 'Face library'),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: neoBorder(bg: AppTheme.surface),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const _BrandMark(),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'CREATE ACCOUNT',
                                                style: AppTheme
                                                    .textTheme.labelLarge
                                                    ?.copyWith(
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Set up your profile and save your progress.',
                                                style: AppTheme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    _field(
                                      'Email',
                                      _emailCtrl,
                                      false,
                                      icon: Icons.mail_outline,
                                    ),
                                    const SizedBox(height: 18),
                                    _field(
                                      'Password',
                                      _passCtrl,
                                      !_showPassword,
                                      icon: Icons.lock_outline,
                                      suffix: IconButton(
                                        onPressed: () => setState(() =>
                                            _showPassword = !_showPassword),
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _field(
                                      'Confirm Password',
                                      _confirmCtrl,
                                      !_showConfirm,
                                      icon: Icons.verified_user_outlined,
                                      suffix: IconButton(
                                        onPressed: () => setState(
                                            () => _showConfirm = !_showConfirm),
                                        icon: Icon(
                                          _showConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorContainer
                                              .withValues(alpha: 0.55),
                                          border: Border.all(
                                              color: AppTheme.error, width: 2),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: AppTheme.textTheme.labelMedium
                                              ?.copyWith(color: AppTheme.error),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      width: double.infinity,
                                      child: NeoButton(
                                        label: _loading
                                            ? 'CREATING...'
                                            : 'CREATE ACCOUNT',
                                        leading: _loading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: SkeletonBox(
                                                    width: 16,
                                                    height: 16,
                                                    radius: 8),
                                              )
                                            : null,
                                        bg: AppTheme.primary,
                                        textColor: Colors.white,
                                        onTap: _loading ? null : _signup,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context)
                                            .pushReplacementNamed('login'),
                                        child: Text(
                                          'Already have an account? LOG IN',
                                          style: AppTheme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: AppTheme.primary,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: false,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.28),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              border:
                                  Border.all(color: AppTheme.border, width: 4),
                              boxShadow: neoShadow(),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Creating account...',
                                  style: AppTheme.textTheme.labelLarge
                                      ?.copyWith(letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    bool obscure, {
    required IconData icon,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.textTheme.labelMedium
                ?.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border, width: 4),
            boxShadow: neoShadowSm(),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: AppTheme.textTheme.bodyMedium,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border, width: 4),
        boxShadow: neoShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppTheme.secondaryFixedDim.withValues(alpha: 0.28),
              border: Border.all(color: AppTheme.border, width: 3),
            ),
            child: const Center(child: _BrandMark()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.textTheme.displayMedium?.copyWith(
                    fontSize: 30,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.onBackground,
        border: Border.all(color: AppTheme.border, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        'LI',
        style: AppTheme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.secondaryFixedDim.withValues(alpha: 0.18),
        border: Border.all(color: AppTheme.border, width: 2),
      ),
      child: Text(
        label,
        style: AppTheme.textTheme.labelSmall?.copyWith(
          color: AppTheme.onBackground,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AccentBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _AccentBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
