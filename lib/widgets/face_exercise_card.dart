import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/app_provider.dart';
import '../screens/lookmax_screen.dart';
import '../theme.dart';
import 'skeletons.dart';

class FaceExerciseCard extends StatelessWidget {
  final FaceLibItem item;

  const FaceExerciseCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(0),
      onTap: () => _showModal(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _tag(item.zone, AppTheme.secondary),
                      const SizedBox(width: 6),
                      _tag(item.reps, AppTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.name, style: AppTheme.textTheme.headlineMedium?.copyWith(letterSpacing: 0)),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text, style: TextStyle(fontSize: 7, color: color, letterSpacing: 1, fontWeight: FontWeight.w700)),
    );
  }

  void _showModal(BuildContext context) {
    final app = context.read<AppProvider>();
    final guideFuture = app.getFaceGuide(
      FaceExercise(
        name: item.name,
        sets: 3,
        reps: item.reps,
        target: item.zone,
      ),
      subtitle: item.subtitle,
      benefit: item.benefit,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.84,
        minChildSize: 0.45,
        maxChildSize: 0.97,
        expand: false,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border, width: 4)),
            ),
            child: FutureBuilder<Map<String, String>>(
              future: guideFuture,
              builder: (context, snapshot) {
                final loading = snapshot.connectionState != ConnectionState.done;
                final guide = snapshot.data ?? const {};
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (loading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Center(child: SkeletonBox(width: 40, height: 4, radius: 2)),
                          SizedBox(height: 20),
                          SkeletonBox(width: 110, height: 12),
                          SizedBox(height: 12),
                          SkeletonBox(width: 180, height: 18),
                          SizedBox(height: 12),
                          SkeletonBox(width: 220, height: 12),
                          SizedBox(height: 18),
                          SkeletonCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 96, height: 12),
                                SizedBox(height: 12),
                                SkeletonBox(width: double.infinity, height: 12),
                                SizedBox(height: 8),
                                SkeletonBox(width: double.infinity, height: 12),
                                SizedBox(height: 8),
                                SkeletonBox(width: 220, height: 12),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
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
                          Row(
                            children: [
                              _tag(item.zone, AppTheme.secondary),
                              const SizedBox(width: 8),
                              _tag(item.reps, AppTheme.primary),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(item.name, style: AppTheme.textTheme.displayMedium?.copyWith(color: AppTheme.secondary)),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                          ),
                          const SizedBox(height: 20),
                          Text('HOW TO DO IT', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['how_to'] ?? item.howTo, style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('START POSITION', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['start_position'] ?? _startPosition(), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('BODY / FACE POSITION', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['body_position'] ?? _bodyPosition(), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('FINISH POSITION', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['finish_position'] ?? _finishPosition(), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('WHY IT HELPS', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['why_it_matters'] ?? _whyItHelps(), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Text('MISTAKES TO AVOID', style: AppTheme.textTheme.labelLarge?.copyWith(color: AppTheme.onBackground)),
                          const SizedBox(height: 8),
                          Text(guide['mistakes'] ?? _mistakes(), style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.7)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15), width: 2),
                            ),
                            child: Row(
                              children: [
                                const Text('TARGET ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.benefit, style: AppTheme.textTheme.labelMedium?.copyWith(color: AppTheme.primary))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _whyItHelps() {
    switch (item.name) {
      case 'MEWING':
        return 'Builds better resting tongue posture and can improve awareness of jaw, neck, and oral positioning.';
      case 'JAW CLENCH':
        return 'Hits the masseter under tension and helps build stronger jaw muscle engagement.';
      case 'CHIN TUCK':
        return 'Trains deep neck flexors and helps reduce forward-head posture and the look of a double chin.';
      case 'CHEEK SCULPTOR':
        return 'Targets facial compression and cheek control, giving the mid-face more tone and awareness.';
      case 'NECK RESISTANCE':
        return 'Strengthens the neck frame and improves posture support around the head and jaw.';
      case 'EYE SQUINT':
        return 'Helps train controlled orbicularis oculi engagement for a more focused eye area.';
      case 'LIP PRESS':
        return 'Builds control in the lips and perioral muscles while improving facial tension awareness.';
      case 'BROW LIFT':
        return 'Strengthens the forehead lift pattern and helps with upper-face muscle control.';
      default:
        return 'It helps you build better control and posture awareness in the target area.';
    }
  }

  String _mistakes() {
    switch (item.name) {
      case 'MEWING':
        return 'Do not push only the tongue tip. Do not force the jaw closed or clench the teeth hard.';
      case 'JAW CLENCH':
        return 'Do not over-clench to pain. Keep the movement short and controlled.';
      case 'CHIN TUCK':
        return 'Do not tilt the head down. Pull straight back, not down.';
      case 'CHEEK SCULPTOR':
        return 'Do not wrinkle the neck or hold your breath. Keep the motion smooth.';
      case 'NECK RESISTANCE':
        return 'Do not crank the head aggressively. Apply steady pressure only.';
      case 'EYE SQUINT':
        return 'Do not create eye strain or headache. Use moderate tension.';
      case 'LIP PRESS':
        return 'Do not over-pucker or clamp the jaw. Keep the pressure centered in the lips.';
      case 'BROW LIFT':
        return 'Do not arch the neck back. Keep the forehead moving independently.';
      default:
        return 'Keep it controlled and stop if something feels wrong.';
    }
  }

  String _startPosition() {
    return 'Set the face and neck in a relaxed neutral position with the target area ready to work for ${item.zone.toLowerCase()}.';
  }

  String _bodyPosition() {
    return 'Keep the motion controlled through the ${item.zone.toLowerCase()} area. Stay relaxed everywhere else, avoid jaw clenching unless the move calls for it, and keep the neck stable.';
  }

  String _finishPosition() {
    return 'End back in a neutral relaxed face position, with the target area calm and the neck stacked.';
  }
}
