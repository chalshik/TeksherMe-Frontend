import 'package:flutter/material.dart';

enum NeumorphicType {
  flat,
  pressed,
  convex,
  concave,
}

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool allowTap;
  final VoidCallback? onTap;
  final double intensity;
  final NeumorphicType type;
  final double elevation;
  final double width;
  final double? height;
  
  const NeumorphicContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
    this.allowTap = false,
    this.onTap,
    this.intensity = 0.25,
    this.type = NeumorphicType.flat,
    this.elevation = 5.0,
    this.width = double.infinity,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = color ?? theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate shadows based on the surface color
    final shadowColor = isDark 
        ? Colors.black 
        : const Color(0xFF000000);
        
    final highlightColor = isDark 
        ? const Color(0x40FFFFFF) 
        : const Color(0xFFFFFFFF);
    
    // Adjust shadow positions and blurs based on type
    double topLeftBlurRadius, bottomRightBlurRadius;
    double topLeftSpreadRadius, bottomRightSpreadRadius;
    Offset topLeftOffset, bottomRightOffset;
    BoxShape shape = BoxShape.rectangle;
    
    Gradient? gradient;
    
    switch (type) {
      case NeumorphicType.flat:
        topLeftBlurRadius = elevation;
        bottomRightBlurRadius = elevation;
        topLeftSpreadRadius = 0;
        bottomRightSpreadRadius = 0;
        topLeftOffset = Offset(-elevation / 3, -elevation / 3);
        bottomRightOffset = Offset(elevation / 3, elevation / 3);
        gradient = null;
        break;
      case NeumorphicType.pressed:
        topLeftBlurRadius = elevation / 2;
        bottomRightBlurRadius = elevation / 2;
        topLeftSpreadRadius = -1;
        bottomRightSpreadRadius = -1;
        topLeftOffset = Offset(elevation / 5, elevation / 5);
        bottomRightOffset = Offset(-elevation / 5, -elevation / 5);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceColor.withOpacity(1),
            surfaceColor,
          ],
          stops: const [0.0, 1.0],
        );
        break;
      case NeumorphicType.convex:
        topLeftBlurRadius = elevation;
        bottomRightBlurRadius = elevation;
        topLeftSpreadRadius = 0;
        bottomRightSpreadRadius = 0;
        topLeftOffset = Offset(-elevation / 3, -elevation / 3);
        bottomRightOffset = Offset(elevation / 3, elevation / 3);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? surfaceColor.lighten(0.1) : surfaceColor.lighten(0.15),
            isDark ? surfaceColor.darken(0.1) : surfaceColor.darken(0.05),
          ],
        );
        break;
      case NeumorphicType.concave:
        topLeftBlurRadius = elevation;
        bottomRightBlurRadius = elevation;
        topLeftSpreadRadius = 0;
        bottomRightSpreadRadius = 0;
        topLeftOffset = Offset(-elevation / 3, -elevation / 3);
        bottomRightOffset = Offset(elevation / 3, elevation / 3);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? surfaceColor.darken(0.1) : surfaceColor.darken(0.05),
            isDark ? surfaceColor.lighten(0.1) : surfaceColor.lighten(0.15),
          ],
        );
        break;
    }
    
    final boxDecoration = BoxDecoration(
      color: gradient == null ? surfaceColor : null,
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      shape: shape,
      boxShadow: [
        BoxShadow(
          color: shadowColor.withOpacity(isDark ? 0.75 * intensity : 0.25 * intensity),
          blurRadius: topLeftBlurRadius,
          spreadRadius: topLeftSpreadRadius,
          offset: topLeftOffset,
        ),
        BoxShadow(
          color: highlightColor.withOpacity(isDark ? 0.25 * intensity : 0.7 * intensity),
          blurRadius: bottomRightBlurRadius,
          spreadRadius: bottomRightSpreadRadius,
          offset: bottomRightOffset,
        ),
      ],
    );
    
    final container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );
    
    if (allowTap && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    } else {
      return container;
    }
  }
}

// Extension method to lighten and darken colors
extension ColorBrightness on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
} 