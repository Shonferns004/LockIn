import 'package:flutter/material.dart';

class StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Offset offset;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 60),
    this.offset = const Offset(0, 20),
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(widget.delayPerItem * widget.index, _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Transform.translate(
        offset: Offset(widget.offset.dx * (1 - _anim.value),
            widget.offset.dy * (1 - _anim.value)),
        child: widget.child,
      ),
    );
  }
}

class CountUp extends StatefulWidget {
  final int target;
  final Duration duration;
  final Widget Function(String value) builder;

  const CountUp({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 800),
    required this.builder,
  });

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CountUp old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final v = (widget.target * _anim.value).round();
        return widget.builder(v.toString());
      },
    );
  }
}

Route slideFadeRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

Route fadeRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    );

Future<T?> showScaleAlert<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (ctx, anim, _) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: builder(ctx)),
    ),
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

Route slideUpRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
