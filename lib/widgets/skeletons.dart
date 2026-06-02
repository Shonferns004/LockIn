import 'package:flutter/material.dart';
import '../theme.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final base = Color.lerp(
            AppTheme.surfaceContainerHigh,
            AppTheme.surfaceBright,
            0.35,
          )!;
          final highlight = Color.lerp(base, Colors.white, 0.55)!;
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [base, highlight, base],
                  stops: const [0.2, 0.5, 0.8],
                  transform: _SlidingGradientTransform(
                    -1.2 + (_controller.value * 2.4),
                  ),
                ),
              ),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class SkeletonCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? bg;

  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.bg,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blinkAnim,
      child: Container(
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.bg ?? AppTheme.surface,
          border: Border.all(color: AppTheme.surfaceContainerHigh, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.child,
      ),
    );
  }
}

class WorkoutSkeleton extends StatelessWidget {
  const WorkoutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = constraints.maxWidth < 360 ? 12.0 : 24.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonCard(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    SizedBox(width: 68, child: _StatSkeleton()),
                    SizedBox(width: 68, child: _StatSkeleton()),
                    SizedBox(width: 68, child: _StatSkeleton()),
                    SizedBox(width: 68, child: _StatSkeleton()),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const _BlockSkeleton(),
              const SizedBox(height: 12),
              const _BlockSkeleton(),
              const SizedBox(height: 24),
              const _BlockSkeleton(),
              const SizedBox(height: 24),
              const _BlockSkeleton(),
            ],
          ),
        );
      },
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonBox(width: 36, height: 18, radius: 8),
        SizedBox(height: 8),
        SkeletonBox(width: 54, height: 10, radius: 8),
      ],
    );
  }
}

class _BlockSkeleton extends StatefulWidget {
  const _BlockSkeleton();

  @override
  State<_BlockSkeleton> createState() => _BlockSkeletonState();
}

class _BlockSkeletonState extends State<_BlockSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blinkAnim,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.surfaceContainerHigh, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 120, height: 16, radius: 8),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 12, radius: 8),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 12, radius: 8),
            SizedBox(height: 8),
            SkeletonBox(width: 180, height: 12, radius: 8),
          ],
        ),
      ),
    );
  }
}
