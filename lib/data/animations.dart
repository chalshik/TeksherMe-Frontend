import 'package:flutter/material.dart';

class TeksherAnimations {
  // Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
    required AnimationController controller,
  }) {
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
  
  // Scale animation
  static Widget scale({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuart,
    required AnimationController controller,
    double from = 0.95,
  }) {
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    
    return ScaleTransition(
      scale: Tween<double>(begin: from, end: 1.0).animate(animation),
      child: child,
    );
  }
  
  // Slide animation
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuint,
    required AnimationController controller,
    Offset from = const Offset(0.0, 0.2),
  }) {
    final Animation<Offset> animation = Tween<Offset>(
      begin: from,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
    
    return SlideTransition(
      position: animation,
      child: child,
    );
  }
  
  // Combined fade and slide
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOutQuint,
    required AnimationController controller,
    Offset from = const Offset(0.0, 0.1),
  }) {
    final Animation<double> opacityAnimation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: from,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
    
    return FadeTransition(
      opacity: opacityAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
  
  // Pulse animation for buttons
  static Animation<double> pulseAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
    ]).animate(controller);
  }
  
  // Shimmer loading effect
  static Widget shimmerLoading({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return ShimmerEffect(
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      child: child,
    );
  }
}

// Shimmer effect widget
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  
  const ShimmerEffect({
    super.key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Gradient transform helper
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  
  const _SlidingGradientTransform({required this.slidePercent});
  
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
} 