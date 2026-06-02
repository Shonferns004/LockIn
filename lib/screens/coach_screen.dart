import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/skeletons.dart';
import '../widgets/animations.dart';

class CoachScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const CoachScreen({super.key, this.scrollController});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  ScrollController get _activeScrollController => widget.scrollController ?? _scrollCtrl;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _activeScrollController,
                    padding: EdgeInsets.fromLTRB(pad, 16, pad, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (app.profile != null)
                          NeoCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('YOUR PROFILE', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant)),
                                const SizedBox(height: 8),
                                _profileRow('Laziness', '${'😴' * (app.profile!.laziness ~/ 2)} ${app.profile!.laziness}/10'),
                                _profileRow('Body', '${app.profile!.height}cm \u00b7 ${app.profile!.weight}kg \u00b7 ${app.profile!.age}yo'),
                                _profileRow('Goal', app.profile!.goal.replaceAll('_', ' ').toUpperCase()),
                                _profileRow('Experience', app.profile!.experience.toUpperCase()),
                                _profileRow('Time/Session', '${app.profile!.timePerSession} min'),
                                if (app.profile!.health.isNotEmpty)
                                  _profileRow('Health', app.profile!.health),
                              ],
                            ),
                          ),
                        if (app.coachHistory.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Ask the AI coach anything about your workouts, form, diet, or looksmax goals.',
                                textAlign: TextAlign.center,
                                style: AppTheme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        else
                          ...app.coachHistory.toList().asMap().entries.map((entry) {
                            final i = entry.key;
                            final msg = entry.value;
                            final isUser = msg['role'] == 'user';
                            return StaggeredFadeSlide(
                              index: i,
                              delayPerItem: const Duration(milliseconds: 60),
                              offset: const Offset(0, 15),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser) const Padding(
                                      padding: EdgeInsets.only(right: 8, top: 6),
                                      child: Icon(Icons.smart_toy, size: 18, color: AppTheme.secondary),
                                    ),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isUser ? AppTheme.primaryContainer.withValues(alpha: 0.3) : AppTheme.surfaceBright,
                                          border: Border.all(color: isUser ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border, width: 2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          msg['content'] ?? '',
                                          style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.5),
                                        ),
                                      ),
                                    ),
                                    if (isUser) const Padding(
                                      padding: EdgeInsets.only(left: 8, top: 6),
                                      child: Icon(Icons.person, size: 18, color: AppTheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 8),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(top: BorderSide(color: AppTheme.border, width: 4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black,
                        offset: Offset(0, -6),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border, width: 4),
                            boxShadow: neoShadowSm(),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            enabled: !_sending,
                            style: AppTheme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Ask the coach...',
                              hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.outline),
                              filled: true,
                              fillColor: AppTheme.surfaceBright,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeoButton(
                        label: '',
                        leading: _sending
                            ? const SkeletonBox(width: 16, height: 16, radius: 8)
                            : const Icon(Icons.send, size: 16, color: Colors.white),
                        bg: AppTheme.primary,
                        textColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        onTap: _sending ? null : _send,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _profileRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    final reply = await context.read<AppProvider>().coachSend(msg);
    if (!mounted) return;
    setState(() => _sending = false);

    if (reply.startsWith('\u26A0')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reply)),
      );
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _activeScrollController.hasClients) {
        _activeScrollController.animateTo(
          _activeScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

