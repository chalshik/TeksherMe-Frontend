import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final Color? tintColor;
  final double opacity;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final Alignment? alignment;
  final BoxConstraints? constraints;
  final VoidCallback? onTap;
  final bool allowTap;
  
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.tintColor,
    this.opacity = 0.1,
    this.blur = 10.0,
    this.padding,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.onTap,
    this.allowTap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = BorderRadius.circular(16);
    final defaultBorder = Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    );
    
    final containerChild = ClipRRect(
      borderRadius: borderRadius ?? defaultBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          constraints: constraints,
          decoration: BoxDecoration(
            color: (tintColor ?? theme.colorScheme.surface).withOpacity(opacity),
            borderRadius: borderRadius ?? defaultBorderRadius,
            border: border ?? defaultBorder,
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
    
    if (allowTap && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: containerChild,
      );
    } else {
      return containerChild;
    }
  }
  
  // Factory constructor for a frosted glass effect
  factory GlassmorphicContainer.frosted({
    required Widget child,
    Color? tintColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    double? width,
    double? height,
    Alignment? alignment,
    BoxConstraints? constraints,
    VoidCallback? onTap,
    bool allowTap = false,
  }) {
    return GlassmorphicContainer(
      child: child,
      tintColor: tintColor ?? Colors.white,
      opacity: 0.07,
      blur: 15.0,
      padding: padding,
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
      width: width,
      height: height,
      alignment: alignment,
      constraints: constraints,
      onTap: onTap,
      allowTap: allowTap,
    );
  }
  
  // Factory constructor for a darker glass effect
  factory GlassmorphicContainer.dark({
    required Widget child,
    Color? tintColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    double? width,
    double? height,
    Alignment? alignment,
    BoxConstraints? constraints,
    VoidCallback? onTap,
    bool allowTap = false,
  }) {
    return GlassmorphicContainer(
      child: child,
      tintColor: tintColor ?? Colors.black,
      opacity: 0.15,
      blur: 15.0,
      padding: padding,
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
      width: width,
      height: height,
      alignment: alignment,
      constraints: constraints,
      onTap: onTap,
      allowTap: allowTap,
    );
  }
  
  // Factory constructor for a bottom sheet glass effect
  factory GlassmorphicContainer.bottomSheet({
    required Widget child,
    Color? tintColor,
    EdgeInsetsGeometry? padding,
    double? width,
    double? height,
    Alignment? alignment,
    BoxConstraints? constraints,
    VoidCallback? onTap,
    bool allowTap = false,
  }) {
    return GlassmorphicContainer(
      child: child,
      tintColor: tintColor ?? Colors.white,
      opacity: 0.1,
      blur: 20.0,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
      width: width,
      height: height,
      alignment: alignment,
      constraints: constraints,
      onTap: onTap,
      allowTap: allowTap,
    );
  }
} 