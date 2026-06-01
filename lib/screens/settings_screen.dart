import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 32, pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(label: 'SETTINGS'),
                  const SizedBox(height: 32),
                  _AccountSection(app: app),
                  const SizedBox(height: 32),
                  _WorkoutPreferences(app: app),
                  const SizedBox(height: 32),
                  _Integrations(),
                  const SizedBox(height: 32),
                  const _GroqKeySection(),
                  const SizedBox(height: 32),
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
  final String label;
  const _Header({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.displayMedium
              ?.copyWith(fontStyle: FontStyle.italic),
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
        color: bg,
        border: Border.all(color: AppTheme.border, width: 2),
      ),
      child: Text(label,
          style: AppTheme.textTheme.labelLarge?.copyWith(color: textColor)),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final AppProvider app;
  const _AccountSection({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.profile;
    final authEmail = AuthService().loggedInEmail ?? '';
    final displayEmail =
        (p?.email != null && p!.email.isNotEmpty) ? p.email : authEmail;
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
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.tertiaryFixed,
                            border:
                                Border.all(color: AppTheme.border, width: 4),
                          ),
                          child: const Icon(Icons.person,
                              size: 40, color: AppTheme.onBackground),
                        ),
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              border:
                                  Border.all(color: AppTheme.border, width: 2),
                              boxShadow: neoShadowSm(),
                            ),
                            child: const Icon(Icons.edit,
                                size: 14, color: AppTheme.onBackground),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p?.username ?? 'LockIn',
                          style: AppTheme.textTheme.headlineMedium,
                        ),
                        Text(
                          displayEmail,
                          style: AppTheme.textTheme.labelMedium
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppTheme.border),
                const SizedBox(height: 16),
                _EditableField(
                  label: 'USERNAME',
                  initialValue: p?.username ?? 'LockIn',
                  onSave: (v) => app.saveUsername(v),
                ),
                const SizedBox(height: 16),
                _EditableField(
                  label: 'EMAIL ADDRESS',
                  initialValue: displayEmail,
                  onSave: (v) => app.saveEmail(v),
                ),
              ],
            )),
      ],
    );
  }
}

class _EditableField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onSave;

  const _EditableField(
      {required this.label, required this.initialValue, required this.onSave});

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
          child: TextField(
            controller: _ctrl,
            style: AppTheme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            onSubmitted: (v) => widget.onSave(v),
          ),
        ),
      ],
    );
  }
}

class _WorkoutPreferences extends StatelessWidget {
  final AppProvider app;
  const _WorkoutPreferences({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge(
            label: 'WORKOUT PREFERENCES',
            bg: AppTheme.primaryContainer,
            textColor: AppTheme.onPrimaryContainer),
        NeoCard(
            bg: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Reminders',
                            style: AppTheme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text('GET PUSHED TO TRAIN',
                            style: AppTheme.textTheme.labelMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                    _ToggleSwitch(
                      value: app.dailyReminders,
                      onChanged: (v) => app.setDailyReminders(v),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Difficulty Level',
                        style: AppTheme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Novice', 'Beast', 'Elite'].map((level) {
                        final active = app.difficultyLevel == level;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => app.setDifficultyLevel(level),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.primaryContainer
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: AppTheme.border, width: 4),
                                  boxShadow: active ? neoShadowSm() : null,
                                ),
                                transform: active
                                    ? Matrix4.translationValues(-2, -2, 0)
                                    : Matrix4.identity(),
                                child: Text(
                                  level.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: AppTheme.textTheme.labelMedium,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            )),
      ],
    );
  }
}

class _ToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch>
    with SingleTickerProviderStateMixin {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ToggleSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _val = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _val = !_val);
        widget.onChanged(_val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: _val ? AppTheme.primaryContainer : AppTheme.surfaceContainer,
          border: Border.all(color: AppTheme.border, width: 4),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: _val ? 28 : 4,
              top: 4,
              child: Container(
                width: 16,
                height: 16,
                color: AppTheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Integrations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBadge(
            label: 'INTEGRATIONS',
            bg: AppTheme.tertiaryContainer,
            textColor: AppTheme.onTertiaryContainer),
        _IntegrationCard(
          iconBg: Color(0xFFFF2D55),
          icon: Icons.favorite,
          label: 'Apple Health',
          buttonText: 'Connected',
          connected: true,
        ),
        SizedBox(height: 12),
        _IntegrationCard(
          iconBg: Color(0xFF4285F4),
          icon: Icons.fitness_center,
          label: 'Google Fit',
          buttonText: 'Connect',
          connected: false,
        ),
      ],
    );
  }
}

class _GroqKeySection extends StatefulWidget {
  const _GroqKeySection();

  @override
  State<_GroqKeySection> createState() => _GroqKeySectionState();
}

class _GroqKeySectionState extends State<_GroqKeySection> {
  late final TextEditingController _ctrl;
  bool _saving = false;
  bool _showKey = true;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _ctrl = TextEditingController(text: app.groqKey ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final key = _ctrl.text.trim();
    setState(() => _saving = true);
    await context.read<AppProvider>().saveGroqKey(key);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Groq API key saved')),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      color: AppTheme.border,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('HOW TO GET A GROQ API KEY',
                      style: AppTheme.textTheme.displayMedium
                          ?.copyWith(fontSize: 28)),
                  const SizedBox(height: 12),
                  Text(
                    'Use this key to power the AI workouts, face guides, and coach responses.',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  _HelpStep(
                      number: '1',
                      text:
                          'Open the Groq console in your browser and sign in or create an account.'),
                  _HelpStep(
                      number: '2',
                      text:
                          'Go to the API keys section and create a new key. Copy it immediately.'),
                  _HelpStep(
                      number: '3',
                      text: 'Paste the key back here, then tap SAVE KEY.'),
                  _HelpStep(
                      number: '4',
                      text:
                          'If the key stops working later, replace it here with a fresh one.'),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.18),
                      border: Border.all(color: AppTheme.border, width: 4),
                    ),
                    child: Text(
                      'Keep the key private. Do not share it in chat or screenshots.',
                      style: AppTheme.textTheme.labelMedium
                          ?.copyWith(color: AppTheme.onBackground, height: 1.5),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final hasKey = (app.groqKey ?? '').trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionBadge(
                label: 'AI KEY',
                bg: AppTheme.primaryContainer,
                textColor: AppTheme.onPrimaryContainer),
            NeoCard(
              bg: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hasKey
                              ? 'Groq key is saved and active.'
                              : 'No Groq key saved. Add one to re-enable AI features.',
                          style: AppTheme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showHelp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            border:
                                Border.all(color: AppTheme.border, width: 2),
                          ),
                          child: Text('HOW?',
                              style: AppTheme.textTheme.labelSmall),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                            obscureText: !_showKey,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: AppTheme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Paste Groq API key',
                              hintStyle: AppTheme.textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.outline),
                              filled: true,
                              fillColor: AppTheme.surfaceBright,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showKey = !_showKey),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryContainer,
                              border: Border(
                                  left: BorderSide(
                                      color: AppTheme.border, width: 4)),
                            ),
                            child: Icon(
                              _showKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: AppTheme.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      label: _saving
                          ? 'SAVING...'
                          : (hasKey ? 'UPDATE KEY' : 'SAVE KEY'),
                      bg: AppTheme.primary,
                      textColor: Colors.white,
                      onTap: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String number;
  final String text;

  const _HelpStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: Text(number, style: AppTheme.textTheme.labelSmall),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String label;
  final String buttonText;
  final bool connected;

  const _IntegrationCard({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.buttonText,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
        bg: Colors.white,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                border: Border.all(color: AppTheme.border, width: 4),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: AppTheme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            NeoButton(
              label: buttonText,
              bg: connected ? AppTheme.onBackground : null,
              textColor: connected ? Colors.white : AppTheme.onBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        ));
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
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
              Text(
                'Erase All Training Data?',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onErrorContainer,
                ),
              ),
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
