import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';
import '../theme.dart';
import '../widgets/responsive_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  double _laziness = 5;
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');
  final _ageCtrl = TextEditingController(text: '25');
  String _gender = 'male';
  String _goal = 'build_muscle';
  String _experience = 'beginner';
  int _timePerSession = 20;
  final _healthCtrl = TextEditingController();

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _healthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ResponsiveScaffold(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SETUP YOUR PROFILE', style: AppTheme.textTheme.displayMedium?.copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  Text(
                    "This helps the AI tailor workouts for you",
                    style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),

                  // Laziness
                  Text('LAZINESS LEVEL — ${_laziness.toInt()}/10', style: AppTheme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.outlineVariant,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: _laziness,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (v) => setState(() => _laziness = v),
                    ),
                  ),
                  Text(
                    _laziness <= 3 ? 'Chill — easy pace' : _laziness <= 6 ? 'Moderate — steady effort' : 'Intense — push hard',
                    style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.outline),
                  ),
                  const SizedBox(height: 20),

                  // Height, Weight, Age row
                  Row(
                    children: [
                      Expanded(child: _buildTextField('HEIGHT (CM)', _heightCtrl, '170')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('WEIGHT (KG)', _weightCtrl, '70')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('AGE', _ageCtrl, '25')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  Text('GENDER', style: AppTheme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _genderChip('male', '♂ MALE'),
                      const SizedBox(width: 8),
                      _genderChip('female', '♀ FEMALE'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Goal
                  Text('GOAL', style: AppTheme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  _wrapChoiceChips(
                    ['build_muscle', 'lose_fat', 'get_toned', 'overall_fitness'],
                    ['💪 BUILD MUSCLE', '🔥 LOSE FAT', '✨ GET TONED', '⚡ OVERALL FITNESS'],
                    _goal,
                    (v) => setState(() => _goal = v),
                  ),
                  const SizedBox(height: 20),

                  // Experience
                  Text('EXPERIENCE', style: AppTheme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  _wrapChoiceChips(
                    ['beginner', 'intermediate', 'advanced'],
                    ['🌱 BEGINNER', '📈 INTERMEDIATE', '🏆 ADVANCED'],
                    _experience,
                    (v) => setState(() => _experience = v),
                  ),
                  const SizedBox(height: 20),

                  // Time per session
                  Text('TIME PER SESSION', style: AppTheme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  _wrapChoiceChips(
                    [15, 20, 30, 45],
                    ['15 MIN', '20 MIN', '30 MIN', '45 MIN'],
                    _timePerSession,
                    (v) => setState(() => _timePerSession = v as int),
                  ),
                  const SizedBox(height: 20),

                  // Health
                  Text('HEALTH CONCERNS (OPTIONAL)', style: AppTheme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border, width: 3),
                      boxShadow: neoShadowSm(),
                    ),
                    child: TextFormField(
                      controller: _healthCtrl,
                      maxLines: 2,
                      style: AppTheme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Injuries, limitations, or anything to avoid...',
                        hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.outline),
                        filled: true,
                        fillColor: AppTheme.surfaceBright,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      label: '✓ START MY JOURNEY',
                      bg: AppTheme.primary,
                      textColor: Colors.white,
                      onTap: _submit,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border, width: 3),
            boxShadow: neoShadowSm(),
          ),
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: AppTheme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.outline),
              filled: true,
              fillColor: AppTheme.surfaceBright,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceBright,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: 3),
          boxShadow: selected ? neoShadowSm() : null,
        ),
        transform: selected ? Matrix4.translationValues(-2, -2, 0) : Matrix4.identity(),
        child: Text(
          label,
          style: AppTheme.textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppTheme.onPrimary : AppTheme.onBackground,
          ),
        ),
      ),
    );
  }

  Widget _wrapChoiceChips(List values, List<String> labels, dynamic current, Function(dynamic) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(values.length, (i) {
        final selected = current == values[i];
        return GestureDetector(
          onTap: () => onTap(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.surfaceBright,
              border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: 3),
              boxShadow: selected ? neoShadowSm() : null,
            ),
            transform: selected ? Matrix4.translationValues(-2, -2, 0) : Matrix4.identity(),
            child: Text(
              labels[i],
              style: AppTheme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.onPrimary : AppTheme.onBackground,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _submit() async {
    final h = int.tryParse(_heightCtrl.text) ?? 170;
    final w = int.tryParse(_weightCtrl.text) ?? 70;
    final a = int.tryParse(_ageCtrl.text) ?? 25;
    if (h < 100 || h > 250 || w < 20 || w > 300 || a < 10 || a > 120) return;

    final profile = Profile(
      laziness: _laziness.toInt(),
      height: h,
      weight: w,
      age: a,
      gender: _gender,
      goal: _goal,
      experience: _experience,
      timePerSession: _timePerSession,
      health: _healthCtrl.text.trim(),
    );

    final ok = await context.read<AppProvider>().completeOnboarding(profile);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save onboarding. Please try again.')),
      );
    }
  }
}
